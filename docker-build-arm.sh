#!/usr/bin/env bash

set -e

#
# Working and output dir for PhantomJS
#
PHANTOMJS_SRC_PATH=/src
PHANTOMJS_OUTPUT_PATH=/output
mkdir -p ${PHANTOMJS_SRC_PATH}
mkdir -p ${PHANTOMJS_OUTPUT_PATH}

#
# Working dir for openssl & icu
#
BUILD_PATH=$HOME/build
mkdir -p $BUILD_PATH

#
# Add source-list let 'apt' can get the source code
#
echo "deb-src http://ftp.tw.debian.org/debian jessie main contrib non-free" >> /etc/apt/sources.list

apt-get update

#
# Get necessary packages for 'apt-get source xxxx' command
#
apt-get install -y dpkg-dev

#
# Get necessary for phantomjs 
#
apt-get install -y build-essential git flex bison gperf python ruby git libfontconfig1-dev

#
# Build openssl
#
cd $BUILD_PATH

OENSSL_VERSION=1.0.1t
OPENSSL_FLAGS='no-idea no-mdc2 no-rc5 no-zlib enable-tlsext no-ssl2 no-ssl3 no-ssl3-method enable-rfc3779 enable-cms'
OPENSSL_TARGET='linux-armv4'

echo "Recompiling OpenSSL for ${OPENSSL_TARGET}..." && sleep 1

apt-get source openssl
cd openssl-${OENSSL_VERSION}
./Configure --prefix=/usr --openssldir=/etc/ssl --libdir=lib ${OPENSSL_FLAGS} ${OPENSSL_TARGET}
make depend && make && make install


#
# Build ICU
#
cd $BUILD_PATH

ICU_VERSION=52.1

echo "Building the static version of ICU library..." && sleep 1

apt-get source icu
cd icu-${ICU_VERSION}/source
./configure --prefix=/usr --enable-static --disable-shared
make && make install


echo "Recreating the build directory $BUILD_PATH..."
rm -rf $BUILD_PATH && mkdir -p $BUILD_PATH
echo


#
# Download and Build PhantomJS
#
echo "Downloading PhantomJS source code..."
mkdir -p ${PHANTOMJS_SRC_PATH}
cd ${PHANTOMJS_SRC_PATH}
git clone git://github.com/ariya/phantomjs.git
cd phantomjs
git checkout 2.1.1
git submodule init
git submodule update
echo 

echo "Compiling PhantomJS..." && sleep 1
python build.py --confirm --release --qt-config="-no-pkg-config" --git-clean-qtbase --git-clean-qtwebkit
echo

echo "Stripping the executable..." && sleep 1
ls -l bin/phantomjs
strip bin/phantomjs

echo "Copying the executable..." && sleep 1
ls -l bin/phantomjs
cp bin/phantomjs $PHANTOMJS_OUTPUT_PATH
echo

echo "Finished."

