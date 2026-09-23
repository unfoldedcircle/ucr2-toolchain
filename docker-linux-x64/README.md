# Dockerized Static Build Toolchain for the Linux x64 Desktop Simulator

Builds a statically linked `remote-ui` desktop simulator for Linux x64 that runs on **Ubuntu 24.04 or newer** and
**Debian 13 or newer** without a Qt installation. It is the desktop counterpart of the
[Remote Two/3 cross-compile image](../docker/README.md): same usage, same entry point, a different Qt configuration
(`xcb` platform plugin and desktop OpenGL instead of `eglfs`).

The image is published in our [Docker Hub repository](https://hub.docker.com/u/unfoldedcircle).
See the [build](#build) section if you'd like to build it yourself.

## Usage

The container automatically builds a bind-mounted `remote-ui` project.

Adjust the `~/projects/unfoldedcircle/remote-ui` source path to where you've checked out the `remote-ui` project on
your host.

```shell
docker run --rm -it \
  --user=$(id -u):$(id -g) \
  -v ~/projects/unfoldedcircle/remote-ui:/sources \
  unfoldedcircle/remote-ui-toolchain-qt-5.15.19-static-x64
```

- The static release binary will be accessible on your host at
  `~/projects/unfoldedcircle/remote-ui/binaries/linux-x64/release/remote-ui`
  (the `UC_BIN` environment variable of the image; override it with `-e UC_BIN=/sources/<path>`).
- Intermediate files are written to `build/linux-x86_64/release-static/` in the sources, the same directory a
  `make linux-static` on the host uses. Run `make clean-static` on the host when switching between the two.
- The user id and group id from your host are mapped into the container (`--user=$(id -u):$(id -g)`), so the build
  artifacts have the same permissions as your source files.

If the Qt project file is not named `remote-ui.pro` then the project file name can be specified as the first argument.
QMake build parameters can be specified as an optional second argument.

```shell
docker run --rm -it \
  --user=$(id -u):$(id -g) \
  -v ~/projects/unfoldedcircle/remote-ui:/sources \
  unfoldedcircle/remote-ui-toolchain-qt-5.15.19-static-x64 my-project.pro "CONFIG+=static CONFIG+=release"
```

### Manual build

Start the shell:
```shell
docker run --rm -it \
  --user=$(id -u):$(id -g) \
  -v ~/projects/unfoldedcircle/remote-ui:/sources \
  unfoldedcircle/remote-ui-toolchain-qt-5.15.19-static-x64 bash
```

Now you can build the project inside the container:

```shell
mkdir /tmp/build
cd /tmp/build
qmake /sources/remote-ui.pro CONFIG+=static CONFIG+=release
make -j$(nproc)
```

## Running the binary

"Static" means no Qt at runtime: Qt, its plugins and the QML modules are linked into the executable. The binary still
uses these system libraries, which every Linux desktop installation has (package names for Ubuntu 24.04 / Debian 13):

```shell
sudo apt install libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-shape0 \
  libxcb-sync1 libxcb-xfixes0 libxcb-xinerama0 libxcb-xinput0 libxcb-xkb1 libxcb-util1 libxcb-glx0 \
  libxkbcommon-x11-0 libgl1 libegl1 libgbm1 libfontconfig1 libfreetype6 libpulse0 libasound2t64
```

`libssl3t64` (Ubuntu) / `libssl3` (Debian) is loaded at runtime when TLS is used (`wss://`, `https://`); without it
the app runs, TLS is unavailable. `ldd remote-ui | grep 'not found'` lists anything that is missing.

The app needs the runtime settings from the `remote-ui` README (`UC_MODEL`, `UC_DISPLAY_*`, `UC_TOKEN_PATH`, the
Poppins and Space Mono fonts) and a running Remote-Core Simulator. `scripts/env/linux-static.sh` in the remote-ui
repository sets the defaults:

```shell
cd ~/projects/unfoldedcircle/remote-ui
. scripts/env/linux-static.sh && binaries/linux-x64/release/remote-ui
```

The default platform plugin is `xcb`, which works on X11 and on Wayland desktops through XWayland. On a machine
without a GPU (virtual machine) Mesa's software renderer is used automatically; `QT_QUICK_BACKEND=software` is
available as a fallback.

## Build

### Requirements

1. Docker installation
2. 10 GB free disk space
3. Optional: local web-server for the Qt source archive, see `build.sh` (`QT_MIRROR`).

### Docker Image

1. Optionally edit `build.sh` and set `MIRROR_ARGS`.
2. Run `build.sh`
3. Wait 10 - 60 minutes depending on build machine speed & core count.

Final Docker image: `unfoldedcircle/remote-ui-toolchain-qt-$QT_VERSION-static-x64:$IMAGE_VERSION`
The built image is also tagged with `latest`.

### What is in the image

Two stages: the first builds Qt 5.15.19 from source and is discarded, the second contains only what a remote-ui
build needs: Ubuntu 24.04, `build-essential`, `git` (qmake runs `git describe` for the app version), the
development packages of the system libraries listed above, and the static Qt in `/usr/local/qt_5.15.19_x64_static`
(`qt-config.summary` and `config.opt` next to `bin/` document the configuration). Qt tools that qmake does not need
for building remote-ui (`qml`, `qmltestrunner`, `qmlprofiler`, ...) are removed.

Qt configuration, compared with the desktop build in `remote-ui/scripts/qt/configure-qt-linux.sh`:

| Option                     | Reason                                                                     |
|----------------------------|----------------------------------------------------------------------------|
| `-xcb -opengl desktop`     | one platform plugin that works on X11 and Wayland (XWayland); no `wayland`, `eglfs`, `linuxfb` |
| `-openssl`                 | loaded at runtime (like the device image): no hard dependency on `libssl.so.3`, OpenSSL 3.0 and 3.5 both work |
| `-no-gstreamer -pulseaudio -alsa` | remote-ui only uses `QSoundEffect`, whose PulseAudio backend needs no GStreamer |
| `-no-widgets -no-icu -no-dbus -no-glib` | not used by remote-ui                                            |
| `-skip` x 33               | only qtbase, qtdeclarative, qtquickcontrols2, qtgraphicaleffects, qtsvg, qtmultimedia, qtwebsockets, qtvirtualkeyboard, qttools |

**Why Ubuntu 24.04 as base:** a static Qt binary still links glibc and libstdc++ dynamically, so it runs only on
distributions with the same or newer glibc. Ubuntu 24.04 (glibc 2.39) is the oldest supported target; Debian 13
(glibc 2.41) and newer releases of both are covered. Building on Debian 13 would exclude Ubuntu 24.04.
