# Store assets

`compose.py` turns raw simulator captures into composed App Store screenshots: one headline and the device on a flat orange or indigo background, rendered natively at the exact Apple size, saved as PNG with no alpha channel.

## Requirements

- macOS (uses SF Pro Display from `/System/Library/Fonts/SFNS.ttf`).
- Python 3 with Pillow, in a throwaway venv:

  ```bash
  python3 -m venv /tmp/raid-assets/venv
  /tmp/raid-assets/venv/bin/pip install pillow
  ```

## Usage

Raw captures go in `marketing/screenshots/1.7.0/raw/`; output goes to `marketing/screenshots/1.7.0/store/<set>/`.

```bash
# every shot listed in SHOTS
/tmp/raid-assets/venv/bin/python scripts/store-assets/compose.py

# one shot from SHOTS
/tmp/raid-assets/venv/bin/python scripts/store-assets/compose.py --only 03-saved-setup

# ad hoc
/tmp/raid-assets/venv/bin/python scripts/store-assets/compose.py \
  --raw raw.png --out out.png --size 1320x2868 \
  --bg orange --device iphone --headline "See what your next drive adds"
```

Backgrounds: `orange` (near-black text) and `indigo` (white text); the script asserts both pairs pass 4.5:1. Devices: `iphone`, `ipad`, `duo-outer`, `duo-inner`. Portrait canvases put the headline on top; landscape canvases put it on the left.

The script refuses headlines with em dashes, straight quotes, or a misspelled “iPhone”/“iPad”. Check the rest of the copy rules (trademarks, true claims) by eye.

Verify every output:

```bash
sips -g pixelWidth -g pixelHeight -g hasAlpha marketing/screenshots/1.7.0/store/*/*.png
```

## Capturing

Use the iPhone 17 Pro Max simulator (1320 × 2868 natively). Override the status bar first:

```bash
xcrun simctl status_bar <udid> override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
xcrun simctl ui <udid> appearance light   # or dark
```

Drive the app with launch arguments (see `launchApp` / `launchNAS` in the UI tests). A saved current setup can be seeded through the legacy key, for example:

```bash
hex() { printf '%s' "$1" | xxd -p | tr -d '\n'; }
xcrun simctl launch <udid> <bundle-id> -selectedTab nas -nas.system synology -nas.bayCount 4 \
  -synology.bays "<$(hex '[8,4,8,8]')>" -synology.currentBays "<$(hex '[4,4,8,8]')>" \
  -nas.settings "" -nas.currentSetup "" -nas.hasSavedCurrent YES -unit TB
```

States that need a scroll or a tap need a temporary UI test that saves `XCUIScreen.main.screenshot()`; delete it afterwards. Clear the status bar override (`xcrun simctl status_bar <udid> clear`) when done.
