# This function will install a version of Ruby onto the
# system for the buidlpack to use. It coordinates download
# and setting appropriate env vars for execution
#
# Example:
#
#   heroku_buildpack_ruby_install_ruby "$BIN_DIR" "$ROOT_DIR"
#
# Takes two arguments, the first is the location of the buildpack's
# `bin` directory. This is where the `download_ruby` script can be
# found. The second argument is the root directory where Ruby
# can be installed.
#
# Returns the directory where ruby was downloaded
heroku_buildpack_ruby_install_ruby()
{
  local bin_dir=$1
  local root_dir=$2
  heroku_buildpack_ruby_dir="$root_dir/vendor/ruby/$STACK"

  if [ ! -d "$root_dir/vendor/ruby/$STACK" ]; then
    heroku_buildpack_ruby_dir=$(mktemp -d)
    # bootstrap ruby
    $bin_dir/support/download_ruby $heroku_buildpack_ruby_dir
    function atexit {
      rm -rf $heroku_buildpack_ruby_dir
    }
    trap atexit EXIT
  fi

  export PATH=$heroku_buildpack_ruby_dir/bin/:$PATH
  unset GEM_PATH
}
