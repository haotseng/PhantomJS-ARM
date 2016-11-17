#!/bin/bash
 
function exit_with_error {
  echo "Error: ${1}"
  exit 1
} 

#
# Architecture Selection
#
 
TTY_X=$(($(stty size | awk '{print $2}')-6)) # determine terminal width
TTY_Y=$(($(stty size | awk '{print $1}')-6)) # determine terminal height

# Install `dialog` package
[[ $(dpkg-query -W -f='${db:Status-Abbrev}\n' dialog 2>/dev/null) != *ii* ]] && \
	apt-get -qq -y --no-install-recommends install dialog
	

if [ -z ${TARGET_ARCH} ]; then	 
  options=()
  options+=("armhf" "Build for ARMHF architecture ")
  options+=("aarch64" "Build for ARM64 architecture")
  TARGET_ARCH=$(dialog --stdout --title "Choose a architecture" --backtitle "$backtitle" --menu "Select one of supported architecture" $TTY_Y $TTY_X $(($TTY_Y - 8)) "${options[@]}")
  unset options
  [[ -z ${TARGET_ARCH} ]] && exit_with_error "No architecture selected" 
	
fi

echo "Select Target=${TARGET_ARCH}"


#
# Start build
#

set -e

case ${TARGET_ARCH} in
  armhf)
    DOCKER_IMAGE_NAME=ebspace/armhf-debian:jessie
    TARGET_ARCH_NAME=armhf
    ;;   
  aarch64)
    DOCKER_IMAGE_NAME=ebspace/aarch64-debian:jessie
    TARGET_ARCH_NAME=arm64
    ;;
  *)
    exit_with_error "This Architecture type (${TARGET_ARCH}) not supported"
    ;;
esac

SCRIPT_PATH=$(cd $(dirname $0) && pwd)
BIN_OUTPUT_PATH=${SCRIPT_PATH}/${TARGET_ARCH}_output

mkdir -p ${BIN_OUTPUT_PATH}

#
# Removed old phantomjs
#
rm -rf  ${BIN_OUTPUT_PATH}/phantomjs*
rm -f  ${BIN_OUTPUT_PATH}/*.deb

#
# Build phantomjs
#
docker run -ti --rm \
       -v ${BIN_OUTPUT_PATH}:/output \
       -v ${SCRIPT_PATH}/docker-build-arm.sh:/run.sh \
       ${DOCKER_IMAGE_NAME} \
       /run.sh

#
# Pack the binary to DEB package
#
package_name=phantomjs_2.1.1-01_${TARGET_ARCH}
deb_build_dir=${BIN_OUTPUT_PATH}/${package_name}
mkdir -p ${deb_build_dir}/DEBIAN
cat << EOF > ${deb_build_dir}/DEBIAN/control
Package: phantomjs
Version: 2.1.1-01
Architecture: ${TARGET_ARCH_NAME}
Maintainer: Hao Tseng <ebspace@gmail.com>
Installed-Size: 1
Depends: libfontconfig1
Section: misc
Priority: optional
Description: PhantomJS for ${TARGET_ARCH_NAME} architecture. It's not official version, only for persional testing. 
EOF

mkdir -p ${deb_build_dir}/usr/bin
install -m 755 ${BIN_OUTPUT_PATH}/phantomjs ${deb_build_dir}/usr/bin/

cd ${deb_build_dir}/..
dpkg -b ${package_name}




