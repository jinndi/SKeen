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

(
  cd "$ROOT_DIR/tools/shell-i18n"
  go test ./...
)

for locale in en ru; do
  case "$locale" in
    en) output=skeen ;;
    ru) output=skeen_ru ;;
  esac

  (
    cd "$ROOT_DIR/tools/shell-i18n"
    go run . \
      -input "$ROOT_DIR/skeen.sh" \
      -catalog "$ROOT_DIR/translations.json" \
      -locale "$locale"
  ) > "$BUILD_DIR/$output.source"

  shfmt -s -mn "$BUILD_DIR/$output.source" > "$BUILD_DIR/$output.formatted"
  (
    cd "$ROOT_DIR/tools/shell-minifier"
    go run .
  ) < "$BUILD_DIR/$output.formatted" > "$BUILD_DIR/$output"
  sh -n "$BUILD_DIR/$output"
  mv "$BUILD_DIR/$output" "$OUTPUT_DIR/$output"
done
