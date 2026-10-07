#!/bin/bash
# iPhone Duo App Store captures, one pose at a time.
#
#   scripts/store-assets/capture_duo.sh outer-portrait|outer-landscape|inner-portrait|inner-landscape
#
# Neither simctl nor XCUITest can set the Duo's pose or rotate it, so set
# them by hand first (pose in Xcode's Device Hub, rotation with
# Device > Rotate Left in Simulator). This script then checks the pose by the
# capture's size and that the display isn't dark, overrides the status bar,
# launches the app into each scene in light and dark, captures, and composes.
#
# Raws go to marketing/screenshots/1.7.0/raw/duo-<display>-<WxH>/NN-scene-<mode>.png
# and are never overwritten (a re-run adds -v2, -v3...). Composed images go to
# marketing/screenshots/1.7.0/store/<same set>/, plus a contact sheet.
#
# Env: DUO_UDID (default: RAID Duo), PY (default: /tmp/raid-assets/venv/bin/python).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
U="${DUO_UDID:-E9EE5C1F-BDED-41CD-9C51-CDCA75209EE7}"
PY="${PY:-/tmp/raid-assets/venv/bin/python}"
BUNDLE=53Q4825KDF
TMP="$(mktemp -d /tmp/raid-duo.XXXXXX)"

case "${1:-}" in
  outer-portrait)  display_w=1398; W=1398; H=2034 ;;
  outer-landscape) display_w=1398; W=2034; H=1398 ;;
  inner-portrait)  display_w=2007; W=2007; H=2853 ;;
  inner-landscape) display_w=2007; W=2853; H=2007 ;;
  *) echo "usage: $0 outer-portrait|outer-landscape|inner-portrait|inner-landscape" >&2; exit 2 ;;
esac
SET="duo-${1%%-*}-${W}x${H}"
RAW="$REPO/marketing/screenshots/1.7.0/raw/$SET"

[ -x "$PY" ] || { echo "Pillow venv missing: python3 -m venv /tmp/raid-assets/venv && /tmp/raid-assets/venv/bin/pip install pillow" >&2; exit 1; }
xcrun simctl list devices | grep -q "$U) (Booted)" || { echo "Device $U is not booted. Boot RAID Duo in Simulator first." >&2; exit 1; }
xcrun simctl get_app_container "$U" "$BUNDLE" >/dev/null 2>&1 || {
  echo "RAID Calculator is not installed on $U. Build and install it, e.g.:" >&2
  echo "  xcodebuild -project \"$REPO/RAID Calculator.xcodeproj\" -scheme \"RAID Calc\" -destination id=$U -derivedDataPath /tmp/raid-assets/dd build" >&2
  echo "  xcrun simctl install $U \"/tmp/raid-assets/dd/Build/Products/Debug-iphonesimulator/RAID Calc.app\"" >&2
  exit 1; }

# The display to capture, found by its native width (outer 1398, inner 2007).
DISPLAY_ID=$(xcrun simctl io "$U" enumerate | awk -v w="$display_w" '/UUID:/{u=$2} $0 ~ "Default width: " w "$" {print u; exit}')
[ -n "$DISPLAY_ID" ] || { echo "No display $display_w px wide on $U; is this an iPhone Duo?" >&2; exit 1; }

shoot() { xcrun simctl io "$U" screenshot --display="$DISPLAY_ID" "$1" >/dev/null 2>&1; }

# check <png>: exact size for this pose, and not a dark (unlit) display.
check() {
  "$PY" - "$1" "$W" "$H" <<'EOF'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
w, h = int(sys.argv[2]), int(sys.argv[3])
if im.size != (w, h):
    sys.exit(f"capture is {im.size[0]}x{im.size[1]}, expected {w}x{h}: check the pose and rotation")
if im.resize((16, 16)).convert("L").getextrema()[1] < 8:
    sys.exit("the display is dark: the pose is wrong for this display (open the Duo for inner, close it for outer)")
EOF
}

ORIG_APPEARANCE=$(xcrun simctl ui "$U" appearance 2>/dev/null || echo light)
cleanup() {
  xcrun simctl status_bar "$U" clear >/dev/null 2>&1 || true
  case "$ORIG_APPEARANCE" in light|dark) xcrun simctl ui "$U" appearance "$ORIG_APPEARANCE" >/dev/null 2>&1 || true ;; esac
  rm -rf "$TMP"
}
trap cleanup EXIT

# Pose check before touching anything else.
xcrun simctl launch "$U" "$BUNDLE" >/dev/null
sleep 3
shoot "$TMP/probe.png"
check "$TMP/probe.png"

xcrun simctl status_bar "$U" override --time 9:41 --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3

hex() { printf '%s' "$1" | xxd -p | tr -d '\n'; }
COMMON=(-unit TB -AppleLanguages "(en)" -AppleLocale en_US)
NAS=(-selectedTab nas -nas.system synology -nas.bayCount 4 -nas.settings "" -nas.currentSetup "")

# keep <src> <dest base>: copy without ever overwriting an existing raw.
keep() {
  local dest="$2.png" n=2
  while [ -e "$dest" ]; do dest="$2-v$n.png"; n=$((n + 1)); done
  mkdir -p "$(dirname "$dest")"; cp "$1" "$dest"; echo "  $dest"
}

echo "Capturing $SET on display $DISPLAY_ID"
for mode in light dark; do
  xcrun simctl ui "$U" appearance "$mode"
  for scene in 01-usable-space 02-rebuild-caution; do
    xcrun simctl terminate "$U" "$BUNDLE" >/dev/null 2>&1 || true
    case "$scene" in
      01-usable-space)
        xcrun simctl launch "$U" "$BUNDLE" "${NAS[@]}" -synology.bays "<$(hex '[4,4,8,8]')>" \
          -synology.currentBays "" -nas.hasSavedCurrent NO "${COMMON[@]}" >/dev/null ;;
      02-rebuild-caution)
        xcrun simctl launch "$U" "$BUNDLE" -selectedTab raid -selectedLevel "R 5" -driveCount 8 \
          -driveSize 20 -groups 1 "${COMMON[@]}" >/dev/null ;;
    esac
    sleep 4
    shoot "$TMP/$scene-$mode.png"
    check "$TMP/$scene-$mode.png"
    keep "$TMP/$scene-$mode.png" "$RAW/$scene-$mode"
  done
done

"$PY" "$HERE/compose.py" --only "$SET" --contact
echo "Done. Check the contact sheet above before moving on to the next pose."
