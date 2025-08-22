#!/usr/bin/env bash

set -euo pipefail

curl_retry_on_18() {
  local ec=18;
  local attempts=0;
  while (( ec == 18 && attempts++ < 3 )); do
    curl "$@" # -C - would return code 33 if unsupported by server
    ec=$?
  done
  return $ec
}

which_java()
{
  which java > /dev/null
}

# Detects if a given Gemfile.lock has jruby in it
# $ cat Gemfile.lock | grep jruby # => ruby 2.5.7p001 (jruby 9.2.13.0)
detect_needs_java()
{
  local app_dir=$1
  local gemfile_lock="$app_dir/Gemfile.lock"
  # local needs_jruby=0
  local skip_java_install=1

  if which_java; then
    build_data::kv_raw "which_java" "true"
    return $skip_java_install
  fi

  grep "(jruby " "$gemfile_lock" --quiet &> /dev/null
}

# Runs another buildpack against the build dir
#
# Example:
#
#   compile_buildpack_v2 "$build_dir" "$cache_dir" "$env_dir" "https://buildpack-registry.s3.us-east-1.amazonaws.com/buildpacks/heroku/nodejs.tgz" "heroku/nodejs"
#
compile_buildpack_v2()
{
  local build_dir=$1
  local cache_dir=$2
  local env_dir=$3
  local buildpack=$4
  local name=$5

  local dir
  local url
  local branch

  dir=$(mktemp -t buildpackXXXXX)
  rm -rf "$dir"

  url=${buildpack%#*}
  branch=${buildpack#*#}

  if [ "$branch" == "$url" ]; then
    branch=""
  fi

  if [ "$url" != "" ]; then
    echo "-----> Downloading Buildpack: ${name}"

    if [[ "$url" =~ \.tgz$ ]] || [[ "$url" =~ \.tgz\? ]]; then
      mkdir -p "$dir"
      curl_retry_on_18 -s --fail --retry 3 --retry-connrefused --connect-timeout "${CURL_CONNECT_TIMEOUT:-3}" "$url" | tar xvz -C "$dir" >/dev/null 2>&1 || {
        build_data::kv_string "failure_reason" "compile_buildpack_v2_download_fail"
        build_data::kv_string "failure_detail" "url: $url"
        exit 1
      }
    else
      git clone "$url" "$dir" >/dev/null 2>&1 || {
        echo "Failed to clone $url"
        build_data::kv_string "failure_reason" "compile_buildpack_v2_download_fail"
        build_data::kv_string "failure_detail" "url: $url"
        exit 1
      }
    fi
    cd "$dir" || return

    if [ "$branch" != "" ]; then
      git checkout "$branch" >/dev/null 2>&1 || {
        echo "Failed to checkout branch $branch"
        build_data::kv_string "failure_reason" "compile_buildpack_v2_checkout_fail"
        build_data::kv_string "failure_detail" "buildpack: $buildpack, branch: $branch"
        exit 1
      }
    fi

    # we'll get errors later if these are needed and don't exist
    chmod -f +x "$dir/bin/{detect,compile,release}" || true

    framework=$("$dir"/bin/detect "$build_dir") || {
      echo "Couldn't detect any framework for this buildpack. Exiting."
      build_data::kv_string "failure_reason" "compile_buildpack_v2_detect_fail"
      build_data::kv_string "failure_detail" "buildpack: $buildpack"

      exit 1
    }

    echo "-----> Detected Framework: $framework"
    "$dir"/bin/compile "$build_dir" "$cache_dir" "$env_dir" || {
      build_data::kv_string "failure_reason" "compile_buildpack_v2_compile_fail"
      build_data::kv_string "failure_detail" "buildpack: $buildpack"
      exit 1
    }

    # check if the buildpack left behind an environment for subsequent ones
    if [ -e "$dir/export" ]; then
      set +u # http://redsymbol.net/articles/unofficial-bash-strict-mode/#sourcing-nonconforming-document
      # shellcheck disable=SC1091
      source "$dir/export"
      set -u # http://redsymbol.net/articles/unofficial-bash-strict-mode/#sourcing-nonconforming-document
    fi

    if [ -x "$dir/bin/release" ]; then
      "$dir"/bin/release "$build_dir" > "$1"/last_pack_release.out || {
        build_data::kv_string "failure_reason" "compile_buildpack_v2_release_fail"
        build_data::kv_string "failure_detail" "buildpack: $buildpack"
        exit 1
      }
    fi
  fi
}

# After a stack is EOL, updates to the buildpack may fail with unexpected or unhelpful errors.
# This can happen when the buildpack is being used off of the platform such as with `dokku`
# which is not officially supported.
function checks::ensure_supported_stack() {
	local stack="${1}"

	case "${stack}" in
		# When removing support from a stack, move it to the bottom of the list
		heroku-22 | heroku-24)
			return 0
			;;
		heroku-18 | heroku-20)
			build_data::kv_string "failure_reason" "stack_eol"
			build_data::kv_string "failure_detail" "${stack} stack"
			# This error will only ever be seen on non-Heroku environments, since the
			# Heroku build system rejects builds using EOL stacks.
			cat <<-EOF
				Error: The '${stack}' stack is no longer supported.

				This buildpack no longer supports the '${stack}' stack since it has
				reached its end-of-life:
				https://devcenter.heroku.com/articles/stack#stack-support-details

				Upgrade to a newer stack to continue using this buildpack.
			EOF
			exit 1
			;;
		*)
			build_data::kv_string "failure_reason" "stack_unknown"
			build_data::kv_string "failure_detail" "${stack} stack"
			cat <<-EOF
				Error: The '${stack}' stack isn't recognised.

				This buildpack doesn't recognise or support the '${stack}' stack.

				If '${stack}' is a valid stack, make sure that you are using the latest
				version of this buildpack and haven't pinned to an older release:
				https://devcenter.heroku.com/articles/managing-buildpacks#view-your-buildpacks
				https://devcenter.heroku.com/articles/managing-buildpacks#classic-buildpacks-references
			EOF
			exit 1
			;;
	esac
}

## ==============================
# Start of build_report section
## ==============================

# Contains functions for storing build report from the buildpack in bash.
#
# The format of the report file is JSON.
#
# Example:
#   {
#     "ruby_version": "3.3.3",
#     "ruby_install_duration": 1.234
#   }
#
# All keys get `ruby.` prepended to them in the backend automatically.

# Variables shared by this whole module
BUILD_DATA_FILE=""
# Exported for use by Ruby code
HEROKU_RUBY_BUILD_REPORT_FILE=""

# Must be called before you can use any other methods
build_data::init() {
	local cache_dir="${1}"
	BUILD_DATA_FILE="${cache_dir}/build-data/ruby.json"
	HEROKU_RUBY_BUILD_REPORT_FILE="${BUILD_DATA_FILE}"

	# Used later in the `HerokuBuildReport.set_global` call in `bin/support/ruby_compile`
	export HEROKU_RUBY_BUILD_REPORT_FILE
}

# This should be called after build_data::init in bin/compile
build_data::clear() {
	mkdir -p "$(dirname "${BUILD_DATA_FILE}")"
	echo "{}" >"${BUILD_DATA_FILE}"
}

# Adds a key-value pair to the report file without any attempt to quote or escape the value.
build_data::kv_raw() {
	local key="${1}"
	local value="${2}"
	build_report::_set "${key}" "${value}" "false"
}
# Adds a key-value pair to the report file, quoting the value.
build_data::kv_string() {
	local key="${1}"
	local value="${2}"
	build_report::_set "${key}" "${value}" "true"
}

# Internal helper to write a key/value pair to the build data store. The buildpack shouldn't call this directly.
# Takes a key, value, and a boolean flag indicating whether the value needs to be quoted.
#
# Usage:
# ```
# build_report::_set "foo_string" "quote me" "true"
# build_report::_set "bar_number" "99" "false"
# ```
function build_report::_set() {
	local key="${1}"
	# Truncate the value to an arbitrary 200 characters since it will sometimes contain user-provided
	# inputs which may be unbounded in size. Ideally individual call sites will perform more aggressive
	# truncation themselves based on the expected value size, however this is here as a fallback.
	# (Honeycomb supports string fields up to 64KB in size, however, it's not worth filling up the
	# build data store or bloating the payload passed back to Vacuole/submitted to Honeycomb given the
	# extra content in those cases is not normally useful.)
	local value="${2:0:200}"
	local needs_quoting="${3}"

	if [[ "${needs_quoting}" == "true" ]]; then
		# Values passed using `--arg` are treated as strings, and so have double quotes added and any JSON
		# special characters (such as newlines, carriage returns, double quotes, backslashes) are escaped.
		local jq_args=(--arg value "${value}")
	else
		# Values passed using `--argjson` are treated as raw JSON values, and so aren't escaped or quoted.
		local jq_args=(--argjson value "${value}")
	fi

	local new_data_file_contents
	new_data_file_contents="$(jq --arg key "${key}" "${jq_args[@]}" '. + { ($key): ($value) }' "${BUILD_DATA_FILE}")"
	echo "${new_data_file_contents}" >"${BUILD_DATA_FILE}"
}

build_data::quote_string() {
	local value="${1}"
	echo "'${value//\'/\'\'}'"
}

# Returns the current time since the UNIX Epoch, as a float with microseconds precision
# E.g. build_data::current_unix_realtime => 1755879324.771610 # 2025-08-22 11:15 UTC
build_data::current_unix_realtime() {
	LC_ALL=C
	echo "${EPOCHREALTIME}"
}

# Adds a key=duration to the report file
#
# Example:
#   start_time=$(build_data::current_unix_realtime)
#   sleep 1
#   build_data::kv_duration_since "ruby_install" "${start_time}"
#
#   build_data::print
#   # => ruby_install: 1.234
build_data::kv_duration_since() {
	local key="${1}"
	local start_time="${2}"
	local end_time duration
	end_time="$(build_data::current_unix_realtime)"
	duration="$(awk -v start="${start_time}" -v end="${end_time}" 'BEGIN { printf "%f", (end - start) }')"

	build_data::kv_raw "${key}" "${duration}"
}

# Does what it says on the tin.
build_data::print() {
	local report=${HEROKU_RUBY_BUILD_REPORT_FILE:-'(unset)'}
	if [[ -f "${report}" ]]; then
		jq --sort-keys '.' "${report}"
	else
		echo "{}" | jq --arg report "${report}" '.report_file_path = $report | .report_file_missing = true'
	fi
}

## ==============================
# End of metrics section
## ==============================
