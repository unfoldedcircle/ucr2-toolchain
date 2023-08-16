#!/bin/bash

set -o errexit
set -o pipefail

SDK_VERSION=1.0.0
QT_VERSION_MINOR=5.15
QT_VERSION_PATCH=8
QT_VERSION=$QT_VERSION_MINOR.$QT_VERSION_PATCH

VERSION_ARGS="\
--build-arg BUILDROOT_SDK_VERSION=$SDK_VERSION \
--build-arg QT_VERSION_MINOR=$QT_VERSION_MINOR \
--build-arg QT_VERSION_PATCH=$QT_VERSION_PATCH"

# use a local webserver to speed up archive downloads
# Qt mirrors: https://download.qt.io/archive/qt/5.15/5.15.8/single/qt-everywhere-opensource-src-5.15.8.tar.xz.mirrorlist
# QT_MIRROR URL must contain base path **before** `/archive/qt/`
# Local file server example for SDK_VERSION=1.0.0, QT_VERSION_MINOR=5.15, QT_VERSION_PATCH=8 with files located at:
# - toolchain: /archive/ucr2/v1.0.0/ucr2-aarch64-toolchain-1.0.0-noqt.tar.gz
# - qt:        /qt/5.15/5.15.8/single/qt-everywhere-opensource-src-5.15.8.tar.xz
#MIRROR_ARGS="\
#--build-arg SDK_BASE_URL=http://172.16.16.10/archive/ucr2 \
#--build-arg QT_MIRROR=http://172.16.16.10"

BUILD_LABELS="\
--build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
--build-arg VERSION=$(git describe --match "v[0-9]*" --tags HEAD --always) \
--build-arg REVISION=$(git log -1 --format="%H")"

docker build $VERSION_ARGS $MIRROR_ARGS $BUILD_LABELS \
    -t unfoldedcircle/r2-toolchain-qt-$QT_VERSION-static \
    -t unfoldedcircle/r2-toolchain-qt-$QT_VERSION-static:$SDK_VERSION .
