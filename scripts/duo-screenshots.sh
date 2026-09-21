#!/bin/bash
# Build GoodWalk for the iPhone Duo simulator, run the unit tests there, and capture every screen.
#
#   scripts/duo-screenshots.sh                 # open (inner display): builds, tests, captures 13 screens
#   scripts/duo-screenshots.sh --pose closed   # fold the simulator first (Device menu), then capture again
#   scripts/duo-screenshots.sh --no-tests      # skip the test run
#
# Needs Xcode 27.1 or newer with the iOS 27.1 simulator runtime installed
# (Xcode > Settings > Components). Writes docs/screenshots/duo/<screen>.png for the open pose and
# docs/screenshots/duo/closed-<screen>.png for the closed pose, plus small-* thumbnails.
# CI runs the same script (screenshots.yml, "duo" job) once the runner image ships Xcode 27.
set -euo pipefail
cd "$(dirname "$0")/.."

POSE=open; RUN_TESTS=1; CI_MODE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --pose) POSE="$2"; shift 2 ;;
    --no-tests) RUN_TESTS=0; shift ;;
    --ci) CI_MODE=1; RUN_TESTS=0; shift ;;
    *) echo "unknown option $1"; exit 2 ;;
  esac
done

# 1. Xcode 27+. Prefer whatever is selected; fall back to Xcode-beta / Xcode_27*.
pick_xcode() {
  local cand
  for cand in "${DEVELOPER_DIR:-}" "$(xcode-select -p 2>/dev/null | sed 's#/Contents/Developer##')" \
              /Applications/Xcode-beta.app $(ls -d /Applications/Xcode_27*.app 2>/dev/null | sort -V) ; do
    [ -n "$cand" ] && [ -d "$cand" ] || continue
    cand="${cand%/Contents/Developer}"
    local v; v=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$cand/Contents/Info.plist" 2>/dev/null || echo 0)
    if [ "${v%%.*}" -ge 27 ]; then echo "$cand/Contents/Developer"; return; fi
  done
}
export DEVELOPER_DIR="$(pick_xcode)"
if [ -z "$DEVELOPER_DIR" ]; then
  echo "Xcode 27.1 or newer not found. Install Xcode-beta from developer.apple.com/download, then rerun."; exit 1
fi
echo "Using $(xcodebuild -version | head -1) at $DEVELOPER_DIR"

# 2. iOS 27 runtime + iPhone Duo device (created on first run).
RT=$(xcrun simctl list runtimes available | grep -E "iOS 27" | tail -1 | sed -E 's/.* - (com\.apple[^ ]+).*/\1/' || true)
if [ -z "$RT" ]; then
  echo "No iOS 27 simulator runtime installed yet. Installed runtimes:"; xcrun simctl list runtimes available | tail -n +2
  echo "Wait for 'iOS 27.1 Simulator' to finish in Xcode > Settings > Components, then rerun."; exit 1
fi
DEVICE=$(xcrun simctl list devices available | grep -E "^\s+iPhone Duo" | head -1 | sed -E 's/^ *(.+) \([0-9A-F-]+\) \(.*/\1/' || true)
if [ -z "$DEVICE" ]; then
  xcrun simctl create "iPhone Duo" com.apple.CoreSimulator.SimDeviceType.iPhone-Duo "$RT" >/dev/null
  DEVICE="iPhone Duo"
fi
echo "Simulator: $DEVICE ($RT)"

# 3. Generate, build, test.
command -v xcodegen >/dev/null || { echo "brew install xcodegen first"; exit 1; }
xcodegen generate >/dev/null
DEST="platform=iOS Simulator,name=$DEVICE"
set -o pipefail
xcodebuild build -project GoodWalk.xcodeproj -scheme GoodWalk -destination "$DEST" -derivedDataPath DerivedData \
  -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO 2>&1 | tee duo-build.log | grep -E "error:|warning: .*deprecated|BUILD (SUCCEEDED|FAILED)" || true
grep -q "BUILD SUCCEEDED" duo-build.log || { echo "Build failed, see duo-build.log"; exit 1; }
if [ "$RUN_TESTS" = 1 ]; then
  xcodebuild test -project GoodWalk.xcodeproj -scheme GoodWalk -destination "$DEST" -derivedDataPath DerivedData \
    -only-testing:GoodWalkTests -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO 2>&1 | tee duo-test.log \
    | grep -E "error:|Test Case .* (passed|failed)|TEST (SUCCEEDED|FAILED)|Executed" || true
  grep -q "TEST SUCCEEDED" duo-test.log || { echo "Tests failed on the Duo simulator, see duo-test.log"; exit 1; }
fi

# 4. Boot, install, capture.
xcrun simctl boot "$DEVICE" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$DEVICE" -b >/dev/null
# Xcode 27 replaced Simulator.app with Device Hub; it also owns the fold (pose) control.
[ "$CI_MODE" = 1 ] || open -b com.apple.dt.Devices >/dev/null 2>&1 || true
xcrun simctl ui "$DEVICE" appearance dark >/dev/null 2>&1 || true
APP=$(find DerivedData/Build/Products -name "GoodWalk.app" -maxdepth 2 | head -1)
xcrun simctl install "$DEVICE" "$APP"

if [ "$POSE" = closed ] && [ "$CI_MODE" = 0 ]; then
  echo; echo "Fold the simulator now: the pose control on the Device Hub window."
  read -r -p "Press Return when the outer display is showing... " _
fi

OUT=docs/screenshots/duo; mkdir -p "$OUT"
PREFIX=""; [ "$POSE" = open ] || PREFIX="$POSE-"
SCREENS="hook dog size breed usual reveal plan first result paywall home dogs walking log milestone stats day walkcard settings share"
[ "$CI_MODE" = 1 ] && SCREENS="hook dog size breed usual"

brightness() {  # mean pixel value 0-255, or "fallback" when Pillow is missing
  python3 - "$1" 2>/dev/null <<'PYEOF' || echo "fallback"
import sys
from PIL import Image, ImageStat
print(int(ImageStat.Stat(Image.open(sys.argv[1]).convert("L")).mean[0]))
PYEOF
}

# A black PNG compresses to almost nothing; a real screenshot does not.
# Used when Pillow is not installed, so a blank frame is never mistaken for a good one.
looks_blank() {
  local f="$1" mean
  [ -s "$f" ] || return 0
  mean=$(brightness "$f")
  if [ "$mean" = "fallback" ]; then
    [ "$(stat -f%z "$f" 2>/dev/null || echo 0)" -lt 40000 ]
  else
    [ "$mean" -le 6 ]
  fi
}


# The Duo has two displays and only one is lit in a given pose. simctl's default
# is not reliably the lit one (it changes after `simctl erase`), so find it once.
pick_display() {
  local d probe
  probe=$(mktemp -t duoprobe).png
  for d in primary internal; do
    if xcrun simctl io "$DEVICE" screenshot --display "$d" "$probe" >/dev/null 2>&1; then
      if ! looks_blank "$probe"; then rm -f "$probe"; echo "$d"; return; fi
    fi
  done
  rm -f "$probe"
  echo primary
}
DISPLAY_ARG=$(pick_display)
echo "Capturing the lit display: $DISPLAY_ARG"

for s in $SCREENS; do
  f="$OUT/$PREFIX$s.png"
  for attempt in 1 2 3; do
    xcrun simctl terminate "$DEVICE" app.getgoodwalk.goodwalk >/dev/null 2>&1 || true; sleep 1
    xcrun simctl launch "$DEVICE" app.getgoodwalk.goodwalk -screenshot "$s" >/dev/null; sleep 8
    xcrun simctl io "$DEVICE" screenshot --display "$DISPLAY_ARG" "$f" >/dev/null 2>&1
    looks_blank "$f" || break
    echo "  $s: blank frame, relaunching ($attempt)"
  done
  echo "captured $f ($(sips -g pixelWidth -g pixelHeight "$f" | awk '/pixel/ {printf "%s ", $2}'))"
done
for f in "$OUT"/"$PREFIX"*.png; do
  case "$(basename "$f")" in small-*) continue ;; esac
  sips -Z 700 "$f" --out "$OUT/small-$(basename "$f")" >/dev/null
done
rm -f duo-build.log duo-test.log

echo
echo "Done: $OUT/$PREFIX*.png"
if [ "$POSE" = open ] && [ "$CI_MODE" = 0 ]; then
  echo "Next: fold the simulator and run  scripts/duo-screenshots.sh --pose closed --no-tests"
  echo "Then: git add docs/screenshots/duo && git commit -m 'iPhone Duo simulator screenshots' && git push"
fi
