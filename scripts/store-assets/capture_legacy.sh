#!/bin/bash
# RAID Calc2 1.8.0 App Store captures on iPhone (1320 x 2868) or iPad 13" (2064 x 2752).
#
#   scripts/store-assets/capture_legacy.sh iphone|ipad
#
# Boot the one Simulator first (iPhone 17 Pro Max, or iPad Pro 13-inch) and install
# the legacy build. Captures every scene in light and dark, never overwriting
# a raw (a re-run adds -v2, -v3...), then composes with compose.py --legacy.
#
# Env: UDID (default: the booted device), PY (default: /tmp/raid-assets/venv/bin/python).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
PY="${PY:-/tmp/raid-assets/venv/bin/python}"
BUNDLE=com.mrballistic.RaidCalculator2
U="${UDID:-$(xcrun simctl list devices booted | awk -F'[()]' '/Booted/{print $2; exit}')}"
TMP="$(mktemp -d /tmp/raid-legacy-shots.XXXXXX)"

case "${1:-}" in
  iphone) W=1320; H=2868; SCENES="01-moving 02-usable-space 03-rebuild-caution 04-invalid-fix" ;;
  ipad)   W=2064; H=2752; SCENES="01-moving 02-usable-space 03-rebuild-caution" ;;
  *) echo "usage: $0 iphone|ipad" >&2; exit 2 ;;
esac
SET="$1-${W}x${H}"
RAW="$REPO/marketing/screenshots/raidcalc2-1.8.0/raw/$SET"

[ -n "$U" ] || { echo "No booted Simulator." >&2; exit 1; }
[ -x "$PY" ] || { echo "Pillow venv missing: python3 -m venv /tmp/raid-assets/venv && /tmp/raid-assets/venv/bin/pip install pillow" >&2; exit 1; }
xcrun simctl get_app_container "$U" "$BUNDLE" >/dev/null 2>&1 || { echo "RAID Calc2 ($BUNDLE) is not installed on $U." >&2; exit 1; }

ORIG_APPEARANCE=$(xcrun simctl ui "$U" appearance 2>/dev/null || echo light)
cleanup() {
  xcrun simctl status_bar "$U" clear >/dev/null 2>&1 || true
  case "$ORIG_APPEARANCE" in light|dark) xcrun simctl ui "$U" appearance "$ORIG_APPEARANCE" >/dev/null 2>&1 || true ;; esac
  rm -rf "$TMP"
}
trap cleanup EXIT

xcrun simctl status_bar "$U" override --time 9:41 --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3
COMMON=(-unit TB -AppleLanguages "(en)" -AppleLocale en_US)
SEEN=(-legacy.hasSeenRetirementNotice YES)

keep() {
  local dest="$2.png" n=2
  while [ -e "$dest" ]; do dest="$2-v$n.png"; n=$((n + 1)); done
  mkdir -p "$(dirname "$dest")"; cp "$1" "$dest"; echo "  $dest"
}

for mode in light dark; do
  xcrun simctl ui "$U" appearance "$mode"
  for scene in $SCENES; do
    xcrun simctl terminate "$U" "$BUNDLE" >/dev/null 2>&1 || true
    case "$scene" in
      01-moving)          args=(-legacy.resetNotice YES -selectedLevel "R 6" -driveCount 6 -driveSize 12) ;;
      02-usable-space)    args=("${SEEN[@]}" -selectedLevel "R 6" -driveCount 6 -driveSize 12) ;;
      03-rebuild-caution) args=("${SEEN[@]}" -selectedLevel "R 5" -driveCount 8 -driveSize 20) ;;
      04-invalid-fix)     args=("${SEEN[@]}" -selectedLevel "R 10" -driveCount 5 -driveSize 8) ;;
    esac
    xcrun simctl launch "$U" "$BUNDLE" "${args[@]}" "${COMMON[@]}" >/dev/null
    sleep 4
    xcrun simctl io "$U" screenshot "$TMP/$scene-$mode.png" >/dev/null 2>&1
    size=$(sips -g pixelWidth -g pixelHeight "$TMP/$scene-$mode.png" | awk '/pixel/{printf "%s ", $2}')
    [ "$size" = "$W $H " ] || { echo "capture is $size, expected $W $H: wrong device or orientation" >&2; exit 1; }
    keep "$TMP/$scene-$mode.png" "$RAW/$scene-$mode"
  done
done

"$PY" "$HERE/compose.py" --legacy --only "$1-" --contact
