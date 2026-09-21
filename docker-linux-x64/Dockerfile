# Static Qt build image for the remote-ui Linux x64 desktop simulator.
#
# Produces a self-contained (no Qt libraries at runtime) remote-ui binary that runs on Ubuntu 24.04 and newer and on
# Debian 13 and newer. Counterpart of ../docker/Dockerfile, which cross-compiles the same app for the Remote Two/3.
#
# The binary still links the system libraries listed in README.md (glibc, X11/xcb, OpenGL, fontconfig, PulseAudio,
# ALSA); everything else (Qt, its plugins, zlib, png, jpeg, pcre, harfbuzz, sqlite) is linked in. The base image
# defines the oldest supported target: a binary needs the glibc of the distribution it was built on, or newer.

# global default definitions
ARG UBUNTU_VERSION=24.04
ARG QT_VERSION_MINOR=5.15
ARG QT_VERSION_PATCH=19

# -----------------------------------------------------------------------------------------------------------------
# Stage 1: build a static Qt. Sources and build tree are dropped with this stage.
# -----------------------------------------------------------------------------------------------------------------
FROM ubuntu:${UBUNTU_VERSION} AS builder

ARG QT_VERSION_MINOR
ARG QT_VERSION_PATCH
# Qt mirrors: https://download.qt.io/archive/qt/5.15/5.15.19/single/qt-everywhere-opensource-src-5.15.19.tar.xz.mirrorlist
# The URL must contain the base path **before** `/archive/qt/`; download.qt.io redirects to a nearby mirror.
ARG QT_MIRROR=https://download.qt.io

ENV QT_VERSION=${QT_VERSION_MINOR}.${QT_VERSION_PATCH}
ENV QT_PREFIX=/usr/local/qt_${QT_VERSION_MINOR}.${QT_VERSION_PATCH}_x64_static
ENV DEBIAN_FRONTEND=noninteractive

# Build tools plus the development packages of the system libraries Qt links dynamically.
# Kept in sync with the final stage below (same list minus perl, python3, wget, xz-utils).
RUN apt-get update -q \
    && apt-get install --no-install-recommends -y \
    build-essential ca-certificates perl python3 pkg-config wget xz-utils \
    libfontconfig1-dev libfreetype-dev libssl-dev \
    libx11-dev libx11-xcb-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev \
    libxcb1-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev \
    libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev \
    libxcb-render0-dev libxcb-util-dev libxcb-xinerama0-dev libxcb-xkb-dev libxcb-xinput-dev \
    libxkbcommon-dev libxkbcommon-x11-dev libgl1-mesa-dev libegl-dev \
    libpulse-dev libasound2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO- ${QT_MIRROR}/archive/qt/${QT_VERSION_MINOR}/${QT_VERSION}/single/qt-everywhere-opensource-src-${QT_VERSION}.tar.xz \
    | tar -xJ -C /opt

# Same configuration as remote-ui/scripts/qt/configure-qt-linux.sh (static desktop build), with two differences:
# - `-openssl` instead of `-openssl-linked`: OpenSSL is loaded at runtime like on the device, so libssl.so.3 is not a
#   hard dependency of the binary and both OpenSSL 3.0 (Ubuntu 24.04) and 3.5 (Debian 13) work.
# - `-no-gstreamer`: remote-ui only uses QSoundEffect, whose PulseAudio backend does not need GStreamer. This removes
#   a dozen runtime libraries and 40 development packages from the image.
# Only the modules remote-ui needs are built (qtbase, qtdeclarative, qtquickcontrols2, qtgraphicaleffects, qtsvg,
# qtmultimedia, qtwebsockets, qtvirtualkeyboard, qttools for lupdate/lrelease); the xcb platform plugin is compiled
# in and is the default platform (works on X11 and on Wayland desktops through XWayland).
RUN mkdir -p /opt/qt-everywhere-src-${QT_VERSION}/build \
    && cd /opt/qt-everywhere-src-${QT_VERSION}/build \
    && ../configure -prefix "${QT_PREFIX}" \
    -static -release -opensource -confirm-license \
    -nomake examples -nomake tests \
    -platform linux-g++ -c++std c++17 \
    -qt-zlib -qt-libpng -qt-libjpeg -system-freetype -qt-pcre -qt-harfbuzz -qt-sqlite \
    -fontconfig -xcb -xkbcommon -opengl desktop \
    -openssl \
    -no-gstreamer -pulseaudio -alsa \
    -no-widgets -no-icu -no-dbus -no-gtk -no-cups -no-glib -no-zstd -no-libudev -no-feature-vulkan \
    -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcharts -skip qtconnectivity -skip qtdatavis3d \
    -skip qtdoc -skip qtgamepad -skip qtimageformats -skip qtlocation -skip qtlottie -skip qtmacextras \
    -skip qtnetworkauth -skip qtpurchasing -skip qtquick3d -skip qtquickcontrols -skip qtquicktimeline \
    -skip qtremoteobjects -skip qtscript -skip qtscxml -skip qtsensors -skip qtserialbus -skip qtserialport \
    -skip qtspeech -skip qttranslations -skip qtwayland -skip qtwebchannel -skip qtwebengine -skip qtwebglplugin \
    -skip qtwebview -skip qtwinextras -skip qtx11extras -skip qtxmlpatterns \
    && make -j$(nproc) \
    && make install \
    && cp config.summary config.opt "${QT_PREFIX}/"

# Slim down: keep only the tools qmake needs to build remote-ui (qmake, moc, rcc, the linguist tools with their
# *-pro helpers, qmlimportscanner, qmlcachegen). The QML runtime and profiling tools alone are 85 MB.
RUN cd "${QT_PREFIX}/bin" \
    && find . -type f ! -name qmake ! -name moc ! -name rcc ! -name 'lupdate*' ! -name 'lrelease*' \
        ! -name lconvert ! -name lprodump ! -name qmlimportscanner ! -name qmlcachegen -delete \
    && rm -rf "${QT_PREFIX}/doc"

# -----------------------------------------------------------------------------------------------------------------
# Stage 2: the build image: compiler, development packages and the static Qt.
# -----------------------------------------------------------------------------------------------------------------
FROM ubuntu:${UBUNTU_VERSION}

ARG UBUNTU_VERSION
ARG QT_VERSION_MINOR
ARG QT_VERSION_PATCH

ENV QT_VERSION=${QT_VERSION_MINOR}.${QT_VERSION_PATCH}
ENV QT_PREFIX=/usr/local/qt_${QT_VERSION_MINOR}.${QT_VERSION_PATCH}_x64_static
ENV PATH="${QT_PREFIX}/bin:$PATH"
ENV DEBIAN_FRONTEND=noninteractive

# git: qmake runs `git describe` in remote-ui.pro to determine the app version.
RUN apt-get update -q \
    && apt-get install --no-install-recommends -y \
    build-essential ca-certificates git pkg-config \
    libfontconfig1-dev libfreetype-dev libssl-dev \
    libx11-dev libx11-xcb-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev \
    libxcb1-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev \
    libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev \
    libxcb-render0-dev libxcb-util-dev libxcb-xinerama0-dev libxcb-xkb-dev libxcb-xinput-dev \
    libxkbcommon-dev libxkbcommon-x11-dev libgl1-mesa-dev libegl-dev \
    libpulse-dev libasound2-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder ${QT_PREFIX} ${QT_PREFIX}

# default user if not overridden with --user=uid:gid. Ubuntu 24.04 ships a user `ubuntu` with UID 1000 already;
# the bind-mounted sources decide the ownership of the build output anyway.
USER ubuntu

# Host project should be bind-mounted here: -v ~/projects/remote-ui:/sources
VOLUME /sources
WORKDIR /sources

# Binary output path inside the bind mount (remote-ui.pro reads UC_BIN). Mirrors the device layout
# binaries/linux-arm64/release; intermediate files go to build/linux-x86_64/release-static/ in the sources.
ENV UC_BIN=/sources/binaries/linux-x64/release

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Labels, see: https://github.com/opencontainers/image-spec/blob/master/annotations.md
ARG BUILD_DATE
ARG VERSION
ARG REVISION
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.authors="markus.z@unfoldedcircle.com"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/unfoldedcircle/remote-ui-toolchain-qt-${QT_VERSION_MINOR}.${QT_VERSION_PATCH}-static-x64"
LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.revision=$REVISION
LABEL org.opencontainers.image.vendor="Unfolded Circle"
LABEL org.opencontainers.image.title="Unfolded Circle Qt ${QT_VERSION_MINOR}.${QT_VERSION_PATCH} static Linux x64 build toolchain"
LABEL org.opencontainers.image.description="Qt toolchain for building the static Linux x64 desktop simulator of the remote-ui app (Ubuntu ${UBUNTU_VERSION} base)"
