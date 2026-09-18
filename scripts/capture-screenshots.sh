#!/usr/bin/env bash
# Captures every -screenshot screen from an already-booted simulator with Good Walk installed.
# Usage: bash scripts/capture-screenshots.sh "<simulator name or UDID>"
set -euo pipefail
DEVICE="${1:?simulator name or UDID}"
OUT="$(cd "$(dirname "$0")/.." && pwd)/docs/screenshots"
mkdir -p "$OUT"
for s in hook dog size breed usual reveal plan first result paywall home walking log milestone settings share; do
  xcrun simctl launch --terminate-running-process "$DEVICE" app.goodwalk.goodwalk -screenshot "$s" >/dev/null
  sleep 6
  xcrun simctl io "$DEVICE" screenshot "$OUT/$s.png" >/dev/null 2>&1
  echo "captured $s"
done
xcrun simctl terminate "$DEVICE" app.goodwalk.goodwalk >/dev/null 2>&1 || true
# Downscaled copies for quick review in the repo.
cd "$OUT" && for f in $(ls *.png | grep -v '^small-'); do sips -Z 600 "$f" --out "small-$f" >/dev/null; done
