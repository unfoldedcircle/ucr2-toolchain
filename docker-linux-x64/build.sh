#!/bin/bash

set -o errexit
set -o pipefail

UBUNTU_VERSION=24.04
QT_VERSION_MINOR=5.15
QT_VERSION_PATCH=19
QT_VERSION=$QT_VERSION_MINOR.$QT_VERSION_PATCH
IMAGE=unfoldedcircle/remote-ui-toolchain-qt-$QT_VERSION-static-x64
# Image version: bump with every published change of this Dockerfile (Qt patch, base image, packages).
IMAGE_VERSION=1.0.0

VERSION_ARGS="\
--build-arg UBUNTU_VERSION=$UBUNTU_VERSION \
--build-arg QT_VERSION_MINOR=$QT_VERSION_MINOR \
--build-arg QT_VERSION_PATCH=$QT_VERSION_PATCH"

# Optional local mirror for the Qt source archive, see ../docker/build.sh. The URL must contain the base path
# **before** `/archive/qt/`: the Dockerfile appends /archive/qt/5.15/5.15.19/single/qt-everywhere-opensource-src-5.15.19.tar.xz
#MIRROR_ARGS="--build-arg QT_MIRROR=http://172.16.16.10"

BUILD_LABELS="\
--build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
--build-arg VERSION=$(git describe --match "v[0-9]*" --tags HEAD --always) \
--build-arg REVISION=$(git log -1 --format="%H")"

docker build $VERSION_ARGS $MIRROR_ARGS $BUILD_LABELS \
    -t $IMAGE \
    -t $IMAGE:$IMAGE_VERSION .
