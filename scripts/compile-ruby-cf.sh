#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: compile-ruby-cf.sh [ruby version] [destination]"
  echo "Use RUBYGEMS_VERSION, BUNDLER_VERSION, LIBYAML_DIR"
  exit 1
fi

set -e

RUBY_VERSION=$1
DESTINATION=$2

if [ -z "${LIBYAML_DIR}" ]; then LIBYAML_DIR="/var/vcap/packages/libyaml"; fi

MAJOR_RUBY_VERSION=${RUBY_VERSION:0:3}
MINOR_RUBY_VERSION=${RUBY_VERSION:0:5}

RUBY_TARBALL=ruby-${RUBY_VERSION}.tar.gz
wget ftp://ftp.ruby-lang.org/pub/ruby/${MAJOR_RUBY_VERSION}/${RUBY_TARBALL}

tar zxvf ${RUBY_TARBALL}
(
  cd ruby-${RUBY_VERSION}
  ./configure --prefix=${DESTINATION} --disable-install-doc --with-opt-dir=${LIBYAML_DIR} --enable-load-relative
  make
  make install
)

if [ -z "${RUBYGEMS_VERSION}" ]; then RUBYGEMS_VERSION="1.8.24"; fi

RUBYGEMS_TARBALL="rubygems-${RUBYGEMS_VERSION}.tgz"
wget http://production.cf.rubygems.org/rubygems/${RUBYGEMS_TARBALL}

tar zxvf ${RUBYGEMS_TARBALL}
(
  cd rubygems-${RUBYGEMS_VERSION}
  $DESTINATION/bin/ruby setup.rb
)

if [ -z "${BUNDLER_VERSION}" ]; then BUNDLER_VERSION="1.3.2"; fi

$DESTINATION/bin/gem install bundler --version ${BUNDLER_VERSION} --no-rdoc --no-ri

if [ $MINOR_RUBY_VERSION -eq "1.8.7" -o $MINOR_RUBY_VERSION -eq "1.9.2" ]; then
(
cd $DESTINATION/bin
for FILENAME in irb testrb ri rdoc erb rake gem bundle
do
sed -i -e '1c\
#!/bin/sh\
# -*- ruby -*-\
bindir=`cd -P "${0%/*}" 2>/dev/null; pwd`\
prefix="${bindir%/bin}"\
export LD_LIBRARY_PATH="$prefix/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"\
exec "$bindir/ruby" -x "$0" "$@"\
#!/usr/bin/env ruby' $FILENAME
done
)
fi

RUBY_PACKAGE=ruby-${MINOR_RUBY_VERSION}.tgz
echo "Creating ${RUBY_PACKAGE}..."
tar czf $RUBY_PACKAGE -C $DESTINATION .
echo "done"
