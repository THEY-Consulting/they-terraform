#!/bin/sh

# fail on first error
set -e

SOURCE_PATH=$1
BUILD_DIR=$2
BUILD_COMMAND=$3

# switch to source directory
cd "$SOURCE_PATH"

# build
if ! BUILD_RESULT=$(sh -c "$BUILD_COMMAND");
then
  echo "$BUILD_RESULT" >&2
  exit 1
fi

# avoid timestamps changing the hash on every build
if ! STAMP_RESULT=$(find $BUILD_DIR/ -exec touch -m -d '1970-01-01T00:00:00Z' {} +);
then
  echo "$STAMP_RESULT" >&2
  exit 1
fi

echo "{ \"source_path\": \"$SOURCE_PATH\", \"build_dir\": \"$BUILD_DIR\" }"
