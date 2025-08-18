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
    metrics::kv_raw "which_java" "true"
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
        metrics::kv_string "failure_reason" "compile_buildpack_v2_download_fail"
        metrics::kv_string "failure_detail" "url: $url"
        exit 1
      }
    else
      git clone "$url" "$dir" >/dev/null 2>&1 || {
        echo "Failed to clone $url"
        metrics::kv_string "failure_reason" "compile_buildpack_v2_download_fail"
        metrics::kv_string "failure_detail" "url: $url"
        exit 1
      }
    fi
    cd "$dir" || return

    if [ "$branch" != "" ]; then
      git checkout "$branch" >/dev/null 2>&1 || {
        echo "Failed to checkout branch $branch"
        metrics::kv_string "failure_reason" "compile_buildpack_v2_checkout_fail"
        metrics::kv_string "failure_detail" "buildpack: $buildpack, branch: $branch"
        exit 1
      }
    fi

    # we'll get errors later if these are needed and don't exist
    chmod -f +x "$dir/bin/{detect,compile,release}" || true

    framework=$("$dir"/bin/detect "$build_dir") || {
      echo "Couldn't detect any framework for this buildpack. Exiting."
      metrics::kv_string "failure_reason" "compile_buildpack_v2_detect_fail"
      metrics::kv_string "failure_detail" "buildpack: $buildpack"

      exit 1
    }

    echo "-----> Detected Framework: $framework"
    "$dir"/bin/compile "$build_dir" "$cache_dir" "$env_dir" || {
      metrics::kv_string "failure_reason" "compile_buildpack_v2_compile_fail"
      metrics::kv_string "failure_detail" "buildpack: $buildpack"
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
        metrics::kv_string "failure_reason" "compile_buildpack_v2_release_fail"
        metrics::kv_string "failure_detail" "buildpack: $buildpack"
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
			metrics::kv_string "failure_reason" "stack_eol"
			metrics::kv_string "failure_detail" "${stack} stack"
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
			metrics::kv_string "failure_reason" "stack_unknown"
			metrics::kv_string "failure_detail" "${stack} stack"
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
# Start of metrics section
## ==============================

# Contains functions for storing metrics from the buildpack in bash.
#
# The format of the report file is YAML withline separated key-value pairs.
#
# Example:
#   ---
#   ruby_version: "3.3.3"
#   ruby_install_duration: 1.234
#
# All keys get `ruby.` prepended to them in the backend automatically.

set -euo pipefail

# Variables shared by this whole module
HEROKU_RUBY_BUILD_REPORT_FILE=""

# Must be called before you can use any other methods
metrics::init() {
	local cache_dir="${1}"
	HEROKU_RUBY_BUILD_REPORT_FILE="${cache_dir}/.heroku/ruby/build_report.yml"

	# Used later in the `HerokuBuildReport.set_global` call in `bin/support/ruby_compile`
	export HEROKU_RUBY_BUILD_REPORT_FILE
}

# This should be called after metrics::init in bin/compile
metrics::clear() {
	mkdir -p "$(dirname "${HEROKU_RUBY_BUILD_REPORT_FILE}")"
	echo "---" > "${HEROKU_RUBY_BUILD_REPORT_FILE}"
}

# Adds a key-value pair to the report file without any attempt to quote or escape the value.
metrics::kv_raw() {
	local key="${1}"
	local value="${2}"
	if [[ -n "${value}" ]]; then
		echo "${key}: ${value}" >> "${HEROKU_RUBY_BUILD_REPORT_FILE}"
	fi
}

# Adds a key-value pair to the report file, quoting the value.
metrics::kv_string() {
	local key="${1}"
	local value="${2}"
	if [[ -n "${value}" ]]; then
		metrics::kv_raw "$key" "$(metrics::quote_string "${value}")"
	fi
}

metrics::quote_string() {
	local value="${1}"
	echo "'${value//\'/\'\'}'"
}

# Returns the current time, in milliseconds.
# E.g. metrics::nowms => 1755207400269 # 2025-08-14 21:36 UTC
metrics::nowms() {
	# Try Linux format first (date +%s%3N)
	local timestamp
	timestamp=$(date +%s%3N 2>/dev/null)

	# Check if it worked (should be numeric and longer than 10 digits)
	if [[ "$timestamp" =~ ^[0-9]{13,}$ ]]; then
		echo "$timestamp"
		return 0
	fi

	# Fallback for BSD systems: use date +%s and add milliseconds
	local seconds
	seconds=$(date +%s)
	local nanoseconds
	nanoseconds=$(date +%N 2>/dev/null || echo "000000000")
	# Convert nanoseconds to milliseconds (first 3 digits)
	local milliseconds=${nanoseconds:0:3}
	echo "${seconds}${milliseconds}"
}

metrics::start_timer() {
	metrics::nowms
}

# Adds a key=duration to the report file
#
# Example:
#   start_time=$(metrics::start_timer)
#   sleep 1
#   metrics::kv_duration_since "ruby_install" "${start_time}"
#
#   metrics::print
#   # => ruby_install: 1.234
metrics::kv_duration_since() {
	local key="${1}"
	local start="${2}"
	local end="${3:-$(metrics::start_timer)}"
	local time
	time="$(echo "${start}" "${end}" | awk '{ printf "%.3f", ($2 - $1)/1000 }')"
	metrics::kv_raw "$key" "${time}"
}

# Does what it says on the tin.
metrics::print() {
	local report=${HEROKU_RUBY_BUILD_REPORT_FILE:-'(unset)'}
	if [[ -f "${report}" ]]; then
		cat "${report}"
	else
		echo "---"
		echo "report_file_path: $(metrics::quote_string "${report}")"
		echo "report_file_missing: true"
	fi
}

## ==============================
# End of metrics section
## ==============================
