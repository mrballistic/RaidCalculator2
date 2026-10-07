# Store assets

`compose.py` turns raw simulator captures into composed App Store screenshots: one headline and the device on a flat orange or indigo background, rendered natively at the exact Apple size, saved as PNG with no alpha channel.

## Requirements

- macOS (uses SF Pro Display from `/System/Library/Fonts/SFNS.ttf`).
- Python 3 with Pillow, in a throwaway venv:

  ```bash
  python3 -m venv /tmp/raid-assets/venv
  /tmp/raid-assets/venv/bin/pip install pillow
  ```

## Folders

```
marketing/screenshots/1.7.0/
  raw/<set>/<NN-scene>-light.png   uncomposed captures, both modes for every
  raw/<set>/<NN-scene>-dark.png    scene, native size, status bar overridden
  store/<set>/<NN-name>.png        composed App Store images
  store/header/header-<WxH>.png    header / search images
  store/contact-<set>.png          one contact sheet per set
```

`<set>` is the device and size, e.g. `iphone-1320x2868`, `ipad-2064x2752`, `duo-inner-2853x2007`, `duo-outer-1398x2034`. Raws are kept for the website as well as the store, so they are never overwritten or deleted: a re-capture is saved as `-v2`, `-v3`, and `compose.py` uses the newest version.

## Usage

```bash
# everything: all sets, header images, contact sheets
/tmp/raid-assets/venv/bin/python scripts/store-assets/compose.py --headers --contact

# shots whose set or file name contains a string
/tmp/raid-assets/venv/bin/python scripts/store-assets/compose.py --only iphone --contact

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
xcrun simctl status_bar <udid> override --time 9:41 --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3
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

## iPhone Duo

The pose and rotation can't be scripted, so set them by hand, then run one pose at a time:

```bash
scripts/store-assets/capture_duo.sh inner-landscape   # open, Device > Rotate Left
scripts/store-assets/capture_duo.sh inner-portrait    # open, portrait
scripts/store-assets/capture_duo.sh outer-portrait    # closed, portrait
scripts/store-assets/capture_duo.sh outer-landscape   # closed, rotated (if Device Hub allows)
```

The script checks the capture size matches the pose and that the display is lit, sets the status bar, captures each scene in light and dark into `raw/duo-…/`, composes that set, and writes its contact sheet. It uses the “RAID Duo” simulator unless `DUO_UDID` is set.
