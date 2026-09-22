#!/bin/bash

set -o errexit
set -o pipefail

UBUNTU_VERSION=24.04
# MXE commit to build from (src/qtbase.mk of that commit defines the Qt version)
MXE_COMMIT=215428bf6f9c4e634f2fb827849a9c027dfe950a
QT_VERSION=5.15.19
IMAGE=unfoldedcircle/remote-ui-toolchain-qt-$QT_VERSION-static-windows-x64
# Image version: bump with every published change of this Dockerfile (MXE commit, Qt patch, base image, packages).
IMAGE_VERSION=1.0.0

VERSION_ARGS="\
--build-arg UBUNTU_VERSION=$UBUNTU_VERSION \
--build-arg MXE_COMMIT=$MXE_COMMIT \
--build-arg QT_VERSION=$QT_VERSION"

BUILD_LABELS="\
--build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
--build-arg VERSION=$(git describe --match "v[0-9]*" --tags HEAD --always) \
--build-arg REVISION=$(git log -1 --format="%H")"

docker build $VERSION_ARGS $BUILD_LABELS \
    -t $IMAGE \
    -t $IMAGE:$IMAGE_VERSION .
