#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(dirname "$SCRIPT_DIR")
OUTPUT_DIR=${1:-dist}

case "$OUTPUT_DIR" in
  /*) ;;
  *) OUTPUT_DIR="$ROOT_DIR/$OUTPUT_DIR" ;;
esac

cd "$ROOT_DIR"
mkdir -p "$OUTPUT_DIR"
BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT HUP INT TERM

for source in skeen.sh skeen_ru.sh; do
  output=${source%.sh}
  shfmt -s -mn "$source" > "$BUILD_DIR/$output.formatted"
  (
    cd "$ROOT_DIR/tools/shell-minifier"
    go run .
  ) < "$BUILD_DIR/$output.formatted" > "$BUILD_DIR/$output"
  sh -n "$BUILD_DIR/$output"
  mv "$BUILD_DIR/$output" "$OUTPUT_DIR/$output"
done
