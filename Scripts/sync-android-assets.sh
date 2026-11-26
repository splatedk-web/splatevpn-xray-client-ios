#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_ASSETS="${1:-$ROOT_DIR/../SplateClient/app/src/main/assets}"
OUT_DIR="$ROOT_DIR/Resources"

mkdir -p "$OUT_DIR"

for file in geoip.dat geosite.dat; do
  if [[ -f "$ANDROID_ASSETS/$file" ]]; then
    cp "$ANDROID_ASSETS/$file" "$OUT_DIR/$file"
    echo "Copied $file"
  else
    echo "Warning: $ANDROID_ASSETS/$file not found"
  fi
done
