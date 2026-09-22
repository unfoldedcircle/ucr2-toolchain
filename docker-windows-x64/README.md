# Dockerized Cross-Compile Toolchain for the Windows x64 Desktop Simulator

Cross-compiles a statically linked `remote-ui.exe` for Windows x64 (Windows 10 or newer) on a Linux host or CI
runner, using [MXE](https://mxe.cc) (mingw-w64). It is the Windows counterpart of the
[Remote Two/3 cross-compile image](../docker/README.md) and the [Linux x64 image](../docker-linux-x64/README.md):
same usage, same entry point.

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
  unfoldedcircle/remote-ui-toolchain-qt-5.15.19-static-windows-x64
```

- The static release executable will be accessible on your host at
  `~/projects/unfoldedcircle/remote-ui/binaries/windows-x64/release/remote-ui.exe`
  (the `UC_BIN` environment variable of the image; override it with `-e UC_BIN=/sources/<path>`).
- Intermediate files are written to `build/windows-x86_64/release-static/` in the sources.
- The user id and group id from your host are mapped into the container (`--user=$(id -u):$(id -g)`), so the build
  artifacts have the same permissions as your source files.

If the Qt project file is not named `remote-ui.pro` then the project file name can be specified as the first argument.
QMake build parameters can be specified as an optional second argument.

### Manual build

Start the shell:
```shell
docker run --rm -it \
  --user=$(id -u):$(id -g) \
  -v ~/projects/unfoldedcircle/remote-ui:/sources \
  unfoldedcircle/remote-ui-toolchain-qt-5.15.19-static-windows-x64 bash
```

Now you can cross-compile the project inside the container. The MXE tools are prefixed with the target triplet:

```shell
mkdir /tmp/build
cd /tmp/build
x86_64-w64-mingw32.static-qmake-qt5 /sources/remote-ui.pro CONFIG+=static CONFIG+=release
make -j$(nproc)
```

## Running the executable

`remote-ui.exe` is self-contained: Qt, its plugins and QML modules, OpenSSL, freetype, harfbuzz and the image
libraries are linked in, and only Windows system DLLs are used. Graphics: Qt is built with `-opengl dynamic`, so
it uses the OpenGL driver when one is available and falls back to the bundled ANGLE (OpenGL ES on Direct3D 11)
otherwise, e.g. in virtual machines. The remote-ui QML uses shader effects (`QtGraphicalEffects`), which the Qt Quick
software renderer cannot draw, so one of the two GPU paths is required. `QT_OPENGL=angle` forces the ANGLE path.

The app needs the runtime settings from the `remote-ui` README (`UC_MODEL`, `UC_DISPLAY_*`, `UC_TOKEN_PATH`, the
Poppins and Space Mono fonts) and a running Remote-Core Simulator, e.g. in PowerShell:

```powershell
$env:UC_MODEL="DEV"; $env:UC_DISPLAY_WIDTH="480"; $env:UC_DISPLAY_HEIGHT="850"; $env:UC_DISPLAY_SCALE="1"
$env:UC_TOKEN_PATH="C:\path\to\core-simulator\docker\ui-env\ws-token"
.\remote-ui.exe
```

## Build

### Requirements

1. Docker installation
2. 20 GB free disk space
3. Time: MXE builds the mingw-w64 GCC, every dependency and Qt from source, see below.

### Docker Image

1. Optionally edit `build.sh`: `MXE_COMMIT` pins the MXE revision (and with it the Qt version in MXE's
   `src/qtbase.mk`), `QT_VERSION` only names the image.
2. Run `build.sh`
3. Wait 40 - 180 minutes depending on build machine speed & core count (40 minutes on 12 cores, of which 38 are
   the MXE build: 7 minutes for qtbase, 4 for qtdeclarative, the rest for the cross GCC and the libraries).

Final Docker image: `unfoldedcircle/remote-ui-toolchain-qt-$QT_VERSION-static-windows-x64:$IMAGE_VERSION`
The built image is also tagged with `latest`.

### What is in the image

Two stages: the first clones MXE at the pinned commit, builds the `x86_64-w64-mingw32.static` toolchain and the Qt
modules remote-ui needs (qtbase, qtdeclarative, qtquickcontrols2, qtgraphicaleffects, qtsvg, qtmultimedia,
qtwebsockets, qtvirtualkeyboard, qttools) with all their dependencies, and is discarded. The second contains
Ubuntu 24.04, `make`, `git` (qmake runs `git describe` for the app version) and the MXE prefix `/opt/mxe/usr`
(cross compiler, static libraries, Qt). Qt tools that a command line build does not need (`qml`, `qmlprofiler`,
`designer.exe`, `linguist.exe`, ...) are removed; MXE's Qt configuration is kept as `/opt/mxe/qt-qconfig.pri`.

Sizes on the reference build: image 3.2 GB uncompressed, 771 MB to pull (the Linux x64 image: 1.3 GB / 316 MB);
`/opt/mxe/usr` is 2.1 GB, a third of it static libraries remote-ui never links (PostgreSQL, FreeTDS, D-Bus, Mesa
are qtbase dependencies in MXE), a candidate for trimming. A remote-ui build in the container takes about a minute
and produces a 65 MB `remote-ui.exe` (already stripped by MXE) that imports only Windows system DLLs (kernel, GDI,
WinSock, Media Foundation for audio, Direct3D 11 for ANGLE).

Why MXE instead of a hand-written Qt cross build like the other two images: MXE carries the MinGW patches Qt 5.15
needs, builds the toolchain and every dependency from a pinned commit, and configures Qt with `-opengl dynamic`
(ANGLE included) and `-openssl-linked`, which is what remote-ui needs on Windows. The price is a longer image build
and a larger image than the Linux x64 one.
