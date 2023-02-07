# Dockerized Cross-compile Toolchain for Qt

The Docker image is also published in our [Docker Hub repository](https://hub.docker.com/u/unfoldedcircle).  
See the [build](#build) section if you'd like to build it yourself.

## Usage

The container will automatically build a bind-mounted `remote-ui` project.

Adjust the `~/projects/unfoldedcircle/remote-ui` source path to where you've checked out the `remote-ui` project on
your host.

```shell
docker run --rm -it \
  --user=$(id -u):$(id -g) \
  -v ~/projects/unfoldedcircle/remote-ui:/sources \
  unfoldedcircle/r2-toolchain-qt-5.15.8-static
```

- The static release binary will be accessible on your host at
  `~/projects/unfoldedcircle/remote-ui/binaries/linux-arm64/release/remote-ui`
- The user id and group id from your host are mapped into the container (`--user=$(id -u):$(id -g) `), so the build
  artifacts have the same permissions as your source files.

If the Qt project file is not named `remote-ui.pro` then the project file name can be specified as the first argument.  
QML build parameters can be specified as an optional second argument.

```shell
docker run --rm -it \
  --user=$(id -u):$(id -g) \
  -v ~/projects/unfoldedcircle/remote-ui:/sources \
  unfoldedcircle/r2-toolchain-qt-5.15.8-static my-project.pro "CONFIG+=static CONFIG+=release"
```

### Manual build

Start the shell:
```shell
docker run --rm -it \
  --user=$(id -u):$(id -g) \
  -v ~/projects/unfoldedcircle/remote-ui:/sources \
  unfoldedcircle/r2-toolchain-qt-5.15.8-static bash
```

Now you can crosscompile the project inside the container:

```shell
mkdir /tmp/build
cd /tmp/build
qmake /sources/remote-ui.pro CONFIG+=static CONFIG+=release
make -j$(nproc)
```

## Build

### Requirements

1. Docker installation
2. 20 GB free disk space
3. Pre-built UCR2 toolchain SDK archive.
4. Recommended: local web-server to download the SDK & Qt source archives.  
   E.g. from a Synology NAS Web Station or a simple nginx webserver.
    - SDK archive path: `/archive/ucr2/0.6.0/ucr2-aarch64-toolchain-0.6.0-lite.tar.gz`
    - Qt archive path:  `/archive/qt/5.15/5.15.8/single/qt-everywhere-opensource-src-5.15.8.tar.xz`

### Docker Image

1. Edit `build.sh` and set preferred `MIRRORS` for the UCR2 Buildroot SDK & Qt anywhere source archives.
2. Run `build.sh`
3. Wait 10 - 100 minutes depending on build machine speed & core count...

Final Docker image: `unfoldedcircle/r2-toolchain-qt-$QT_VERSION-static:$SDK_VERSION`  
The built image is also tagged with `latest`.
