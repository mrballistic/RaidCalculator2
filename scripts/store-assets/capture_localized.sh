#!/bin/bash
# Localized App Store raws for iPhone (1320 x 2868) or iPad 13" (2064 x 2752),
# one language at a time, then composed with that language's headlines.
#
#   scripts/store-assets/capture_localized.sh iphone|ipad <lang> [<lang>...]
#   e.g. scripts/store-assets/capture_localized.sh iphone fr de ja
#
# Languages: es fr it ja de zh-Hant zh-Hans ko pt-BR (en is the 1.7.0 set).
# For each language it sets the Simulator's own language too (so the iPad
# status bar's date matches), reboots it, overrides the status bar, then runs
# the StoreScreenshots UI test in light and in dark. Raws go to
# marketing/screenshots/1.7.1/raw/<lang>/<set>/ (never overwritten: a re-run
# adds -v2, -v3...), composed images to marketing/screenshots/1.7.1/store/<lang>/.
#
# WEB=1 captures the extra scenes the website uses instead (iPhone: rebuild
# caution light, saved setup and RAID 10 dark; iPad: saved setup light, 30
# bays dark) into marketing/screenshots/1.7.1/web/<lang>/<set>/, without
# composing; scripts/www_shots.py turns them into the site's images.
#
# Env: UDID (default: iPhone 17 Pro Max or iPad Pro 13-inch (M5)),
#      PY (default: /tmp/raid-assets/venv/bin/python), WEB.
# One Simulator and one xcodebuild at a time: shut others down first.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
PY="${PY:-/tmp/raid-assets/venv/bin/python}"
DD=/tmp/raid-171/dd

case "${1:-}" in
  iphone) DEFAULT=D1CFAB45-141B-4C12-B10B-846FDC2593C3; SET=iphone-1320x2868; W=1320; H=2868 ;;
  ipad)   DEFAULT=31B61869-9A85-4093-A059-5B67FDBAC8E0; SET=ipad-2064x2752; W=2064; H=2752 ;;
  *) echo "usage: $0 iphone|ipad <lang>..." >&2; exit 2 ;;
esac
KIND=$1; shift
[ $# -gt 0 ] || { echo "name at least one language" >&2; exit 2; }
U="${UDID:-$DEFAULT}"
[ -x "$PY" ] || { echo "Pillow venv missing: python3 -m venv /tmp/raid-assets/venv && /tmp/raid-assets/venv/bin/pip install pillow" >&2; exit 1; }

locale_for() {
  case "$1" in
    es) echo es_ES ;; fr) echo fr_FR ;; it) echo it_IT ;; ja) echo ja_JP ;; de) echo de_DE ;;
    zh-Hant) echo zh_TW ;; zh-Hans) echo zh_CN ;; ko) echo ko_KR ;; pt-BR) echo pt_BR ;;
    *) echo "unsupported language: $1" >&2; exit 2 ;;
  esac
}

echo "Building for testing…"
xcodebuild build-for-testing -project "$REPO/RAID Calculator.xcodeproj" -scheme "RAID Calc" \
  -destination "id=$U" -derivedDataPath "$DD" > /tmp/raid-171/build.log 2>&1 \
  || { tail -20 /tmp/raid-171/build.log; exit 1; }

cleanup() { xcrun simctl status_bar "$U" clear >/dev/null 2>&1 || true; }
trap cleanup EXIT

for lang in "$@"; do
  loc=$(locale_for "$lang")
  if [ "${WEB:-0}" = 1 ]; then RAW="$REPO/marketing/screenshots/1.7.1/web/$lang/$SET"
  else RAW="$REPO/marketing/screenshots/1.7.1/raw/$lang/$SET"; fi
  TMP="$(mktemp -d /tmp/raid-171/shots.XXXXXX)"
  echo "== $lang ($loc) on $SET"

  # The Simulator's own language, for its status bar; it takes effect on boot.
  xcrun simctl boot "$U" 2>/dev/null || true
  xcrun simctl bootstatus "$U" >/dev/null
  xcrun simctl spawn "$U" defaults write -g AppleLanguages -array "$lang"
  xcrun simctl spawn "$U" defaults write -g AppleLocale "$loc"
  xcrun simctl shutdown "$U"
  xcrun simctl boot "$U"
  xcrun simctl bootstatus "$U" >/dev/null
  xcrun simctl status_bar "$U" override --time 9:41 --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3

  for mode in light dark; do
    xcrun simctl ui "$U" appearance "$mode"
    if [ "${WEB:-0}" = 1 ]; then
      case "$KIND-$mode" in
        iphone-light) tests=(test04RebuildCaution) ;;
        iphone-dark)  tests=(test03SavedSetup test07Raid10) ;;
        ipad-light)   tests=(test03SavedSetup) ;;
        ipad-dark)    tests=(test06ThirtyBays) ;;
      esac
    elif [ "$mode" = light ]; then
      tests=(test01UsableSpace test02CompareSystems test03SavedSetup test05InvalidFix test06ThirtyBays)
    else
      tests=(test04RebuildCaution)
    fi
    only=()
    for t in "${tests[@]}"; do only+=(-only-testing:"RAID CalcUITests/StoreScreenshots/$t"); done
    TEST_RUNNER_STORE_WEB="${WEB:-}" TEST_RUNNER_STORE_SHOTS_DIR="$TMP" TEST_RUNNER_STORE_LANG="$lang" TEST_RUNNER_STORE_LOCALE="$loc" TEST_RUNNER_STORE_MODE="$mode" \
      xcodebuild test-without-building -project "$REPO/RAID Calculator.xcodeproj" -scheme "RAID Calc" \
      -destination "id=$U" -derivedDataPath "$DD" -parallel-testing-enabled NO "${only[@]}" \
      > "/tmp/raid-171/test-$KIND-$lang-$mode.log" 2>&1 \
      || { grep -E "error:|failed" "/tmp/raid-171/test-$KIND-$lang-$mode.log" | head -10; exit 1; }
  done

  # Keep every capture, checked for size, without overwriting an earlier raw.
  mkdir -p "$RAW"
  for f in "$TMP"/*.png; do
    size=$(sips -g pixelWidth -g pixelHeight "$f" | awk '/pixel/{printf "%s ", $2}')
    [ "$size" = "$W $H " ] || { echo "$(basename "$f") is $size, expected $W $H" >&2; exit 1; }
    base="$RAW/$(basename "$f" .png)"; dest="$base.png"; n=2
    while [ -e "$dest" ]; do dest="$base-v$n.png"; n=$((n + 1)); done
    cp "$f" "$dest"
  done
  echo "  $(ls "$TMP" | wc -l | tr -d ' ') raws in $RAW"
  rm -r "$TMP"

  [ "${WEB:-0}" = 1 ] || "$PY" "$HERE/compose.py" --lang "$lang" --only "${KIND}-" --contact
done

# Back to English for whoever uses the Simulator next.
xcrun simctl spawn "$U" defaults write -g AppleLanguages -array en
xcrun simctl spawn "$U" defaults write -g AppleLocale en_US
