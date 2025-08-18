#!/usr/bin/env bash

source "$(dirname "$0")/metrics.sh"

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
