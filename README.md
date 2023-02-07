# Remote Two Cross Compile Toolchain

This repository contains the cross compile toolchain for [Unfolded Circle Remote Two](https://www.unfoldedcircle.com/)
products and is based on [Buildroot](https://buildroot.org/).

The toolchain contains the [sysroot directory](https://www.baeldung.com/linux/sysroot) for cross-compiling binaries
targeted for the Remote Two device. It is **not** the embedded Linux system running on the device!

This toolchain is used to build our [Docker cross-compile image with static Qt](https://hub.docker.com/r/unfoldedcircle/r2-toolchain-qt-5.15.8-static)
which can be pulled from Docker Hub. It's a ready-made image to cross-compile the `remote-ui` Qt app for the Remote Two
device. Therefore, there's usually no need to tinker with this toolchain or compile it yourself, if you simply want to
build a custom remote-ui app for your device 😎

## Build

Clone project with git submodules:

```shell
git clone --recurse-submodules https://github.com/unfoldedcircle/ucr2-toolchain.git
```

### Build toolchain with sysroot

```shell
./build.sh ucr2-toolchain-sdk
```

- After a successful build the toolchain archive will be stored in: `./release/ucr2-aarch64-toolchain-$VERSION-noqt.tar.gz`
- For more information about the Buildroot cross-compilation toolchain, please see the [Buildroot manual](https://buildroot.org/downloads/manual/manual.html#_cross_compilation_toolchain)
- ⚠ This toolchain **does not contain Qt**.
  - Building and cross-compiling Qt for an embedded platform can be quite a challenge!
  - Unfortunately static Qt library compilation in Buildroot [has been removed](https://github.com/buildroot/buildroot/commit/2215b8a75edea384182f0511b6649306e60b55d1)
    a while ago when switching to the modular Qt5 version.
  - Thanks to the toolchain containing a properly prepared sysroot and the [Qt everywhere archives](https://download.qt.io/archive/qt/),
    it becomes a little less daunting task, especially when combined with Docker. See next section!

### Docker Cross Compile Image with static Qt 

See [docker/README.md](./docker) how to build and use a cross-compile image with a static Qt version for the Remote Two.

The Docker image is also published in our [Docker Hub repository](https://hub.docker.com/u/unfoldedcircle).

TLDR - this is how you cross-compile your Qt project on your host for the Remote Two:

```shell
docker run --rm -it \
  --user=$(id -u):$(id -g) \
  -v ~/projects/unfoldedcircle/remote-ui:/sources \
  unfoldedcircle/r2-toolchain-qt-5.15.8-static
```

Static Qt app will be on your host: `~/projects/unfoldedcircle/remote-ui/binaries/linux-arm64/release/remote-ui` 

## Recent changes

The major changes found in each new release of a toolchain are listed in the [changelog](./CHANGELOG.md) and
under the GitHub [releases](https://github.com/unfoldedcircle/core-api/releases).

## Contributions

Please read our [contribution guidelines](./CONTRIBUTING.md) before opening a pull request.
