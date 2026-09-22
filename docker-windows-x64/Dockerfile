# Static Qt cross-compile image for the remote-ui Windows x64 desktop simulator, built with MXE (https://mxe.cc).
#
# Produces a single self-contained remote-ui.exe (Qt, its plugins and QML modules, OpenSSL, zlib, png, jpeg, pcre,
# harfbuzz, freetype and sqlite are linked in). Counterpart of ../docker/Dockerfile (Remote Two/3) and
# ../docker-linux-x64/Dockerfile (Linux desktop): same usage and entry point.
#
# MXE is used instead of a hand-written Qt cross build because it carries the MinGW patches Qt 5.15 needs and
# builds every dependency (mingw-w64 GCC, OpenSSL, freetype, harfbuzz, ...) reproducibly from a pinned commit.
# Qt is configured by MXE with `-opengl dynamic`: real OpenGL when a driver is available, otherwise ANGLE on
# Direct3D 11, loaded at runtime from libEGL.dll / libGLESv2.dll next to the executable (not part of the static
# build, see README.md). That is what Qt's official Windows binaries do and what the QtGraphicalEffects shaders in
# remote-ui need (the Qt Quick software renderer cannot draw them).

# global default definitions
ARG UBUNTU_VERSION=24.04
# MXE master commit to build from; its src/qtbase.mk defines the Qt version (5.15.19 at this commit)
ARG MXE_COMMIT=215428bf6f9c4e634f2fb827849a9c027dfe950a
ARG MXE_TARGET=x86_64-w64-mingw32.static

# -----------------------------------------------------------------------------------------------------------------
# Stage 1: build the MXE cross toolchain and the static Qt. Sources, downloads and logs are dropped with this stage.
# -----------------------------------------------------------------------------------------------------------------
FROM ubuntu:${UBUNTU_VERSION} AS builder

ARG MXE_COMMIT
ARG MXE_TARGET
ENV DEBIAN_FRONTEND=noninteractive

# MXE host requirements (https://mxe.cc/#requirements-debian) without the 32-bit packages (g++-multilib,
# libc6-dev-i386): only the x86_64 target is built. python3-yaml is not in MXE's list but required by mesa 26
# (a qtbase dependency), whose meson build needs PyYAML.
RUN apt-get update -q \
    && apt-get install --no-install-recommends -y \
    autoconf automake autopoint bash bison bzip2 ca-certificates flex g++ gettext git gperf intltool \
    libclang-dev libgdk-pixbuf2.0-dev libltdl-dev libgl-dev libpcre2-dev libssl-dev libtool-bin \
    libxml-parser-perl lzip make openssl p7zip-full patch perl python3 python3-mako python3-packaging \
    python3-pkg-resources python3-setuptools python3-yaml python-is-python3 ruby sed sqlite3 unzip wget xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN git clone -q https://github.com/mxe/mxe.git /opt/mxe \
    && git -C /opt/mxe checkout -q ${MXE_COMMIT}

# Only the Qt modules remote-ui needs (qttools for lupdate/lrelease, which remote-ui.pro runs at qmake time).
# MXE resolves and builds their dependencies. `-j` builds packages in parallel, JOBS is the parallelism inside
# one package; qtbase is the long pole, so JOBS gets all cores.
RUN cd /opt/mxe \
    && make -j2 JOBS=$(nproc) MXE_TARGETS=${MXE_TARGET} MXE_PLUGIN_DIRS= \
       qtbase qtdeclarative qtquickcontrols2 qtgraphicaleffects qtsvg qtmultimedia qtwebsockets qtvirtualkeyboard qttools \
    && rm -rf /opt/mxe/pkg /opt/mxe/log /opt/mxe/tmp-* /opt/mxe/.ccache /opt/mxe/.git

# Slim down the Qt tools: keep what qmake needs to build remote-ui, drop the QML runtime/profiling tools and the
# Windows executables of the Qt tools (designer, linguist, assistant, ... are not used by a command line build).
RUN cd "/opt/mxe/usr/${MXE_TARGET}/qt5/bin" \
    && find . -type f ! -name qmake ! -name moc ! -name rcc ! -name uic ! -name 'lupdate*' ! -name 'lrelease*' \
        ! -name lconvert ! -name lprodump ! -name qmlimportscanner ! -name qmlcachegen ! -name qmltyperegistrar \
        ! -name 'qt.conf' -delete \
    && rm -rf "/opt/mxe/usr/${MXE_TARGET}/qt5/doc" \
    && cp /opt/mxe/usr/${MXE_TARGET}/qt5/mkspecs/qconfig.pri /opt/mxe/qt-qconfig.pri

# -----------------------------------------------------------------------------------------------------------------
# Stage 2: the build image: MXE toolchain with the static Qt, make and git.
# -----------------------------------------------------------------------------------------------------------------
FROM ubuntu:${UBUNTU_VERSION}

ARG MXE_COMMIT
ARG MXE_TARGET

ENV DEBIAN_FRONTEND=noninteractive
ENV MXE_TARGET=${MXE_TARGET}
ENV MXE_COMMIT=${MXE_COMMIT}
# MXE cross tools (x86_64-w64-mingw32.static-gcc, -qmake-qt5, ...) and the Qt host tools (lupdate, lrelease, moc, ...)
ENV PATH="/opt/mxe/usr/bin:/opt/mxe/usr/${MXE_TARGET}/qt5/bin:$PATH"
# qmake to use in the entry point
ENV QMAKE=${MXE_TARGET}-qmake-qt5

# git: qmake runs `git describe` in remote-ui.pro to determine the app version.
# perl, python3: used by MXE's tool wrappers and pkg-config scripts.
RUN apt-get update -q \
    && apt-get install --no-install-recommends -y \
    ca-certificates git make perl python3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/mxe/usr /opt/mxe/usr
COPY --from=builder /opt/mxe/qt-qconfig.pri /opt/mxe/qt-qconfig.pri

# default user if not overridden with --user=uid:gid. Ubuntu 24.04 ships a user `ubuntu` with UID 1000 already;
# the bind-mounted sources decide the ownership of the build output anyway.
USER ubuntu

# Host project should be bind-mounted here: -v ~/projects/remote-ui:/sources
VOLUME /sources
WORKDIR /sources

# Binary output path inside the bind mount (remote-ui.pro reads UC_BIN). Mirrors binaries/linux-arm64/release and
# binaries/linux-x64/release; intermediate files go to build/windows-x86_64/release-static/ in the sources.
ENV UC_BIN=/sources/binaries/windows-x64/release

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Labels, see: https://github.com/opencontainers/image-spec/blob/master/annotations.md
ARG BUILD_DATE
ARG VERSION
ARG REVISION
ARG QT_VERSION
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.authors="markus.z@unfoldedcircle.com"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/unfoldedcircle/remote-ui-toolchain-qt-${QT_VERSION}-static-windows-x64"
LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.revision=$REVISION
LABEL org.opencontainers.image.vendor="Unfolded Circle"
LABEL org.opencontainers.image.title="Unfolded Circle Qt ${QT_VERSION} static Windows x64 cross-compile toolchain (MXE)"
LABEL org.opencontainers.image.description="MXE / mingw-w64 toolchain with a static Qt for cross-compiling the Windows x64 desktop simulator of the remote-ui app"
