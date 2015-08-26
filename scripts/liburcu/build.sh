#!/bin/sh -exu
#
# Copyright (C) 2015 - Jonathan Rajotte-Julien <jonathan.rajotte-julien@efficios.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# Create build directory
rm -rf $WORKSPACE/build
mkdir -p $WORKSPACE/build

PREFIX="$WORKSPACE/build"

./bootstrap

CONF_OPTS=""

case "$conf" in
static)
    echo "Static build"
    CONF_OPTS="--enable-static --disable-shared"
    ;;
tls_fallback)  
    echo  "Using pthread_getspecific() to emulate TLS"
    CONF_OPTS="--disable-compiler-tls"
    ;;
*)
    echo "Standard build"
    CONF_OPTS=""
    ;;
esac

# Build type
# oot : out-of-tree build
# dist: build via make dist
# *   : normal tree build
#
# Make sure to move to the build_path and configure
# before continuing

BUILD_PATH=$WORKSPACE
case "$build" in
	oot)
		echo "Out of tree build"
		BUILD_PATH=$WORKSPACE/oot
		mkdir -p $BUILD_PATH
		cd $BUILD_PATH
		$WORKSPACE/configure --prefix=$PREFIX $CONF_OPTS
		;;
	dist)
		echo "Distribution out of tree build"
		BUILD_PATH=`mktemp -d`

		# Initial configure and generate tarball
		./configure
		make dist

		mkdir -p $BUILD_PATH
		cp *.tar.* $BUILD_PATH/
		cd $BUILD_PATH

		# Ignore level 1 of tar
		tar xvf *.tar.* --strip 1

		$BUILD_PATH/configure --prefix=$PREFIX $CONF_OPTS
		;;
	*)
		BUILD_PATH=$WORKSPACE
		echo "Standard tree build"
		$WORKSPACE/configure --prefix=$PREFIX $CONF_OPTS
		;;
esac

make
make install
make clean

# Cleanup rpath and libtool .la files
find $WORKSPACE/build/lib -name "*.so" -exec chrpath --delete {} \;
find $WORKSPACE/build/lib -name "*.la" -exec rm -f {} \;

# Cleanup temp directory of dist build
if [ $build = "dist" ]; then
	rm -rf $BUILD_PATH
fi
