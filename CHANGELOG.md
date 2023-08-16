# Remote Two Cross Compile Toolchain Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

_Changes for the next release will be listed here_

---

## 1.0.0
### Changed
- Clean up Buildroot configuration to use the same libraries as in the 1.0.x
  release version of the Unfolded Circle Operating System for Remote Two (UCOS).

## 0.6.0
⚠️ Deprecated: this version does not correspond to the release firmware shipped with the Remote Two Kickstarter units!

> The sysroot contains libraries which are no longer present in the firmware.  
Note: the _included_ remote-ui Qt application v0.29.x can still be compiled and runs on the 1.0.x release firmware.  
However, this can change anytime and we urge you to update to the 1.0.0 or later ucr2-toolchain.  
This version will be marked as pre-release.

### Changed
- First public release using Buildroot 2022.02.9

### Added
- Docker cross-compile build image with static Qt libraries.
