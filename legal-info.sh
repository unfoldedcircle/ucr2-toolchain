#!/bin/bash

set -e

LICENSE_DIR="./licenses"

# Determine build version
BUILD_VERSION=$("./buildroot-external/scripts/git-version.sh" "./buildroot-external/version")
BUILDROOT_VERSION=$(cd buildroot; git describe)

rm -Rf output/legal-info
make ucr2_toolchain-legal-info

echo "Syncinc licenses and manifest file"
rsync -va --delete ./output/legal-info/licenses/  "$LICENSE_DIR/"
cp ./output/legal-info/manifest.csv "$LICENSE_DIR/"
echo "${BUILD_VERSION}" > "$LICENSE_DIR/version"


echo ""
echo "Created license information for ucr2-toolchain $BUILD_VERSION (using Buildroot $BUILDROOT_VERSION)"
