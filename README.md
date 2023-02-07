# Remote Two Cross Compile Toolchain

This repository contains the cross compile toolchain for [Unfolded Circle Remote Two](https://www.unfoldedcircle.com/)
products and is based on [Buildroot](https://buildroot.org/).

The toolchain contains the [sysroot directory](https://www.baeldung.com/linux/sysroot) for cross-compiling binaries
targeted for the Remote Two device. It is **not** the embedded Linux system running on the device!

## Build

Checkout project and git submodule:

```shell
git clone https://github.com/unfoldedcircle/ucr2-toolchain.git
cd ucr2-toolchain
git submodule update --init
```

Build toolchain:

```shell
./build.sh ucr2-toolchain-sdk
```

- The toolchain archive will be stored in: `./release/ucr2-aarch64-toolchain-$VERSION-noqt.tar.gz`
- For more information about the Buildroot cross-compilation toolchain, please see the [Buildroot manual](https://buildroot.org/downloads/manual/manual.html#_cross_compilation_toolchain)

## Recent changes

The major changes found in each new release of a toolchain are listed in the [changelog](./CHANGELOG.md) and
under the GitHub [releases](https://github.com/unfoldedcircle/core-api/releases).

## Contributions

Please read our [contribution guidelines](./CONTRIBUTING.md) before opening a pull request.
