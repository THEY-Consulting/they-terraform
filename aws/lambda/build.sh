#!/bin/sh

# fail on first error
set -e

# TODO: use variable for build command
yarn run --top-level build > /dev/null 2>&1
find dist/ -exec touch -m -d '1970-01-01T00:00:00Z' {} +

echo "{ \"build_dir\": \"dist\" }"
