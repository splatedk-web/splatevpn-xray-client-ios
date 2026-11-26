#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CORE_DIR="$ROOT_DIR/Core"
OUT_DIR="$ROOT_DIR/Frameworks"
OUT_XCFRAMEWORK="$OUT_DIR/SplateCore.xcframework"

mkdir -p "$OUT_DIR"

if ! command -v gomobile >/dev/null 2>&1; then
  echo "Installing gomobile..."
  go install golang.org/x/mobile/cmd/gomobile@latest
  go install golang.org/x/mobile/cmd/gobind@latest
  export PATH="$(go env GOPATH)/bin:$PATH"
fi

echo "Building SplateCore.xcframework for iOS (device + simulator)..."
cd "$CORE_DIR"
gomobile init
gomobile bind \
  -v \
  -target=ios,iossimulator \
  -iosversion=16.0 \
  -ldflags="-s -w" \
  -o "$OUT_XCFRAMEWORK" \
  ./mobile

echo "Done: $OUT_XCFRAMEWORK"
