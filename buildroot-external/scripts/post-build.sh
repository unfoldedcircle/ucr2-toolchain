#!/bin/bash
#
# Buildroot post-build script: configured in BR2_ROOTFS_POST_BUILD_SCRIPT.
# Parameters:
# $1: target output directory (Buildroot default, also set in $TARGET_DIR)

set -u
set -e

SCRIPT_DIR="$(dirname $0)"


# Determine build version
BR2_EXTERNAL=$(sed -ne 's/BR2_EXTERNAL_UNFOLDEDOS_PATH="\(.*\)"/\1/p' $BR2_CONFIG)
BUILD_VERSION=$("$SCRIPT_DIR/git-version.sh" "$BR2_EXTERNAL/version")

# We need the Git hash of remote-os and not of the buildroot submodule!
GIT_HASH=`cd $SCRIPT_DIR; git rev-parse HEAD`

echo "$BUILD_VERSION" > $HOST_DIR/VERSION
echo "$GIT_HASH" >> $HOST_DIR/VERSION

# FIXME quick & dirty hack to get swupdate lib & includes into sysroot. We should fix the BR package...
rsync -va $TARGET_DIR/usr/lib/libswupdate.* $HOST_DIR/aarch64-buildroot-linux-gnu/sysroot/usr/lib/
install -m 0644 $BUILD_DIR/swupdate*/include/*ipc.h $HOST_DIR/aarch64-buildroot-linux-gnu/sysroot/usr/include/
install -m 0644 $BUILD_DIR/swupdate*/include/swupdate_status.h $HOST_DIR/aarch64-buildroot-linux-gnu/sysroot/usr/include/

