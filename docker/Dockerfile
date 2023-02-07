# global default definitions
ARG BUILDROOT_SDK_NAME=aarch64-buildroot-linux-gnu_sdk-buildroot
ARG BUILDROOT_SDK_VERSION=0.6.0
ARG BUILDROOT_SDK_VERSION_VARIANT=-noqt
ARG QT_VERSION_MINOR=5.15
ARG QT_VERSION_PATCH=8

FROM debian:bookworm-slim AS builder

ARG BUILDROOT_SDK_NAME
ARG BUILDROOT_SDK_VERSION
ARG BUILDROOT_SDK_VERSION_VARIANT
ARG QT_VERSION_MINOR
ARG QT_VERSION_PATCH
ARG SDK_BASE_URL=https://github.com/unfoldedcircle/ucr2-toolchain/releases/download
# Qt mirrors: https://download.qt.io/archive/qt/5.15/5.15.8/single/qt-everywhere-opensource-src-5.15.8.tar.xz.mirrorlist
ARG QT_MIRROR=https://ftp.acc.umu.se/mirror/qt.io/qtproject

ENV TOOLCHAIN_PATH /opt/${BUILDROOT_SDK_NAME}
ENV QT_VERSION=${QT_VERSION_MINOR}.${QT_VERSION_PATCH}
ENV PATH="${TOOLCHAIN_PATH}/bin:${TOOLCHAIN_PATH}/sbin:$PATH"
ENV PKG_CONFIG="${TOOLCHAIN_PATH}/bin/pkg-config"

RUN apt update -q \
    && apt install --no-install-recommends -y \
    build-essential \
    # required for https download from github
    ca-certificates \
    # file: required for Buildroot relocate-sdk.sh
    file \
    gzip \
    make \
    tar \
    wget \
    && apt clean

# install Buildroot SDK for the Remote Two
RUN mkdir -p /opt \
    && wget -qO- "$SDK_BASE_URL/${BUILDROOT_SDK_VERSION}/ucr2-aarch64-toolchain-${BUILDROOT_SDK_VERSION}${BUILDROOT_SDK_VERSION_VARIANT}.tar.gz" | tar -xz -C /opt \
    && /opt/${BUILDROOT_SDK_NAME}/relocate-sdk.sh

RUN wget -qO- ${QT_MIRROR}/archive/qt/${QT_VERSION_MINOR}/${QT_VERSION}/single/qt-everywhere-opensource-src-${QT_VERSION}.tar.xz | tar -xJ -C /opt

COPY ./devices/ /opt/qt-everywhere-src-${QT_VERSION}/qtbase/mkspecs/devices/

RUN mkdir -p /opt/qt-everywhere-src-${QT_VERSION}/build \
    && cd /opt/qt-everywhere-src-${QT_VERSION}/build \
    && MAKEFLAGS="-j$(nproc) --no-print-directory" \
    ../configure -v \
    -release -static \
    -opensource -confirm-license \
    -prefix "/usr/local/qt_${QT_VERSION}_arm64_static" \
    -hostprefix "${TOOLCHAIN_PATH}" \
    -sysroot "${TOOLCHAIN_PATH}/aarch64-buildroot-linux-gnu/sysroot" \
    -no-rpath -nomake tests -nomake examples \
    -device ucr2 \
    -device-option CROSS_COMPILE="${TOOLCHAIN_PATH}/bin/aarch64-none-linux-gnu-" \
    -device-option BR_COMPILER_CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -O2 -g0 -D_FORTIFY_SOURCE=1" \
    -device-option BR_COMPILER_CXXFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -O2 -g0 -D_FORTIFY_SOURCE=1" \
    -optimized-qmake -no-feature-relocatable -no-optimize-debug -no-sse2 \
    -skip qt3d \
    -skip qtcanvas3d \
    -skip qtcharts \
    -skip qtconnectivity \
    -skip qtdatavis3d \
    -skip qtgamepad \
    -skip purchasing \
    -skip qtquick3d \
    -skip qtsensors \
    -skip serialbus \
    -skip qtserialport \
    -skip qtwebengine \
    -skip script \
    -skip scxml \
    -skip speech \
    -fontconfig -system-freetype -no-harfbuzz \
    -glib \
    -gui -widgets \
    -journald \
    -openssl \
    -system-libjpeg -system-libpng -system-zlib -system-pcre \
    -no-iconv -no-pch \
    -no-cups \
    -no-dbus \
    -no-icu \
    -no-gtk \
    -no-libinput \
    -no-linuxfb -no-directfb -no-xcb -opengl es2 -qpa eglfs -eglfs -kms -gbm \
    -no-sql-mysql -no-sql-psql -no-sql-sqlite \
    -no-syslog \
    -no-tslib \
    -no-zstd

RUN cd /opt/qt-everywhere-src-${QT_VERSION}/build \
    && make -j$(nproc) \
    && make -j$(nproc) install

# slim down toolchain, we don't need every host package! This frees around 1.1 GB
RUN rm -Rf ${TOOLCHAIN_PATH}/lib/go \
    rm -Rf ${TOOLCHAIN_PATH}/lib/go*bootstrap* \
    rm -Rf ${TOOLCHAIN_PATH}/bin/go \
    rm -Rf ${TOOLCHAIN_PATH}/share/go-* \
    rm -Rf ${TOOLCHAIN_PATH}/lib/python* \
    rm -Rf ${TOOLCHAIN_PATH}/bin/python* \
    rm -Rf ${TOOLCHAIN_PATH}/include/python*

FROM debian:bookworm-slim

ARG BUILDROOT_SDK_NAME
ARG BUILDROOT_SDK_VERSION
ARG BUILDROOT_SDK_VERSION_VARIANT
ARG QT_VERSION_MINOR
ARG QT_VERSION_PATCH

ENV BUILDROOT_SDK_VERSION=${BUILDROOT_SDK_VERSION}${BUILDROOT_SDK_VERSION_VARIANT}
ENV TOOLCHAIN_PATH /opt/${BUILDROOT_SDK_NAME}
ENV PATH="${TOOLCHAIN_PATH}/bin:${TOOLCHAIN_PATH}/sbin:$PATH"
ENV PKG_CONFIG="${TOOLCHAIN_PATH}/bin/pkg-config"
ENV QT_VERSION=${QT_VERSION_MINOR}.${QT_VERSION_PATCH}

# instead of ~8GB we are down to 2GB without the sources & build artifacts
COPY --from=builder ${TOOLCHAIN_PATH} ${TOOLCHAIN_PATH}
# save the Qt configuration
COPY --from=builder /opt/qt-everywhere-src-${QT_VERSION}/build/config.log ${TOOLCHAIN_PATH}/qt-config.log
COPY --from=builder /opt/qt-everywhere-src-${QT_VERSION}/build/config.opt ${TOOLCHAIN_PATH}/qt-config.opt
COPY --from=builder /opt/qt-everywhere-src-${QT_VERSION}/build/config.summary ${TOOLCHAIN_PATH}/qt-config.summary

# add some convenience tools
RUN apt update -q \
    && apt install --no-install-recommends -y \
    ca-certificates \
    # git is used in qmake to determine version of remote-ui project
    git \
    gzip \
    less \
    make \
    nano \
    rsync \
    tar \
    wget \
    && apt clean

# default location for ccache if no user home is set
RUN mkdir -p /buildroot && chmod 777 /buildroot
# default user if not overriden with --user=uid:gid. UID 1000 should match most Ubuntu default installations with one user account.
RUN useradd -u 1000 -m ucr2

USER ucr2

# Host project should be bind-mounted here: -v ~/projects/remote-ui:/sources
VOLUME /sources

WORKDIR /sources

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Labels, see: https://github.com/opencontainers/image-spec/blob/master/annotations.md
ARG BUILD_DATE
ARG VERSION
ARG REVISION
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.authors="markus.z@unfoldedcircle.com"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/unfoldedcircle/r2-qt-crosscompile"
LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.revision=$REVISION
LABEL org.opencontainers.image.vendor="Unfolded Circle"
LABEL org.opencontainers.image.title="Unfolded Circle Qt $QT_VERSION static cross compile toolchain"
LABEL org.opencontainers.image.description="Qt toolchain for cross compiling the Remote Two remote-ui app"
