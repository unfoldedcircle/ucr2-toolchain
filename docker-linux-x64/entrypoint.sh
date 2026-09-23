#!/bin/bash

set -e

if [ "$1" == "--help" ]; then
  echo "Qt static build toolchain for the remote-ui Linux x64 desktop simulator"
  echo ""
  echo "The Qt project must be bind-mounted to /sources"
  echo "  Example: -v ~/projects/remote-ui:/sources"
  echo ""
  echo "Usage: [[\$QT_PROJECT_FILE [\$QMAKE_ARGS]] | bash]"
  echo "  If run with no arguments it is expected that the remote-ui project is bind mounted."
  echo "  If run with a single parameter 'bash' a shell will be started."
  echo "  The binary is written to \$UC_BIN ($UC_BIN), override it with -e UC_BIN=/sources/<path>."
  exit 0
fi

if [ "$1" == "bash" ]; then
  exec bash
fi

PROJECT_FILE=${1:-remote-ui.pro}
QMAKE_ARGS=${2:-CONFIG+=static CONFIG+=release}

if [ ! -f "/sources/$PROJECT_FILE" ]; then
  echo "Qt project file not found: $PROJECT_FILE"
  exit 1
fi

mkdir -p /tmp/build "$UC_BIN"
cd /tmp/build
qmake "/sources/$PROJECT_FILE" $QMAKE_ARGS
make -j$(nproc)
