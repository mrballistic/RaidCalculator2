# App Store assets brief: RAID Calculator 1.7.0

What to produce for the 1.7.0 listing, and what we learned doing the same job for Wax Wishlist 1.3.0 on 2026-10-06. This extends Step 7 of `docs/superpowers/plans/2026-10-06-1.7.0-duo-and-review.md`; where they differ, follow the plan for app behavior and this brief for store assets.

## 1. What to deliver

All PNG, **no alpha channel**, exact pixel sizes (check every file with `sips -g pixelWidth -g pixelHeight`). English only. Write them to `marketing/screenshots/1.7.0/<set>/NN-name.png` and make a contact sheet per set.

| Set | Size (px) | Notes |
|---|---|---|
| iPhone 6.9″ (Pro Max) | 1320 × 2868 | Required for iPhone. The 1206 × 2622 (Dynamic Island, medium) size is also accepted as the required minimum, but keep the Pro Max set you already use. |
| iPad 13″ | 2064 × 2752 | Required because the app ships on iPad (device family 1,2). |
| iPhone Duo, outer display | 1398 × 2034 portrait, 2034 × 1398 landscape | Optional per Apple's spec, but Apple's “Prepare for iPhone Duo” page asks listings to show the app across orientations, and featuring will expect it. |
| iPhone Duo, inner display | 2007 × 2853 portrait, 2853 × 2007 landscape | Same. Shows the two-column layout, which is the best Duo story. |
| Search / header images | 5244 × 2950, 3840 × 2560, 1920 × 1280 | New product-page images. 5244 × 2950 is about 16:9, the other two are 3:2: lay each out natively, don't stretch one master. Keep key content inside the middle ~80% width / ~75% height in case the store crops. |

Up to 10 screenshots per size. 4–6 is plenty.

**Raw or composed?** (Decided for 1.7.0: composed, with `scripts/store-assets/compose.py`; see its README.) RAID's existing listing uses raw captures; that's fine and consistent. If the user asks for composed images (framed device, headline, wordmark), Wax Wishlist's `tools/store-assets/compose_ios.py` and `feature_ios.py` in `/Users/todd.greco/current_work/rsd-app/wax-wishlist-ios/` are a working starting point (Pillow, exact-size output). Ask the user before choosing composed.

## 2. Capturing

- **Status bar:** `xcrun simctl status_bar <udid> override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3`. Clear it afterwards.
- **Light and dark** per the plan (`xcrun simctl ui <udid> appearance light|dark`).
- **Data:** use realistic, generic drive setups. Nothing in RAID needs royalty-free substitution (no album art or third-party imagery), but don't show real people's NAS names or serial numbers.
- **Duo simulator facts (verified):**
  - The Duo runs only on the iOS 27.1 runtime; regular iPhones and iPads stay on 27.0. Use your own “RAID Duo” device, not the shared “iPhone Duo”.
  - Screenshots from the closed device capture the **outer** display at exactly 1398 × 2034.
  - **Rotation and pose can't be scripted.** `XCUIDevice.shared.orientation` does not rotate the Duo simulator, and neither `simctl` nor XCUITest can set the half-open or open pose. The user does it: Device › Rotate Left in the Simulator, and the pose in Xcode's Device Hub.
  - So split the work: capture everything automatable first, then hand the user a ready-to-run script (e.g. `scripts/capture_duo_inner.sh portrait|landscape`) that checks the inner display is lit before it starts, drives the app to the screens, captures, and composes. Tell the user exactly which pose and rotation to set for each run.
  - When the device is folded, screenshots default to the **inner** display, which is dark, so an all-black capture means the pose is wrong, not the app.

## 3. Copy and trademark rules (check every image)

- **“iPhone”** keeps its exact capitalization (lowercase i, capital P). Never set it in all caps or a stylized display face, never letterspace it into caps, never pluralize it or use it as a verb. Use it as a plain compatibility statement: “Built for iPhone Duo.” Same for “iPad”. No Apple logo, nothing implying Apple endorsement, App Store badge only per Apple's badge guidelines.
- **Third-party names in RAID** (Synology, SHR, Unraid, ZFS, SnapRAID, Btrfs): exact spelling and capitalization, descriptive use only (“works out Synology SHR”), no logos, nothing implying affiliation.
- Smart punctuation (curly quotes and apostrophes). No em dashes in store copy. American English.
- Any factual claim (free, no ads, no account, no network calls) must be true for the shipping build. Ask the user to confirm claims before they go on an image.

## 4. Before you call the Duo work done: traps we hit

These cost Wax Wishlist several rounds on the half-open Duo, and none showed up on the simulator's reachable poses:

1. **A sheet sized by its content hung the app.** On a half-open Duo the system sizes and places sheets around the fold. An unsized `.sheet` followed the content's width while the content's layout switched on that width, giving 600 ↔ 460 pt forever. The symptom: a freeze with thousands of cancelled image downloads (POSIX error 89) in the console. Present task screens full-screen at regular width, or give sheets a size that doesn't depend on their content.
2. **Never let a measured size drive state that changes the same measurement.** Measure a parent-determined container (`frame(maxWidth: .infinity)`), round to whole points, add a dead band (≥ 2 pt, and a hysteresis band on thresholds), write state only on real change, and consider a flip guard that locks a two-way layout after several flips per second.
3. **Fold math must check the fold actually crosses the view.** A `.division` region beside the view (negative x) turned into ever-growing padding. Clamp any shift.
4. **`ArrangementView` can collapse its secondary pane** on the closed Duo's landscape display. Use it only when an active fold divides the view, with a plain two-pane fallback.
5. **Don't pin split-view column widths.** A `navigationSplitViewColumnWidth(max: 460)` stopped the system moving the divider onto the fold (about 475 pt on the inner display).
6. **Side insets on Duo:** the tab bar sits in a trailing safe-area inset. Backgrounds that ignore only `.bottom` leave a hard-edged column behind it; include `.horizontal`.

Debugging tip that found #1 in one round: temporary `let _ = Self._printChanges()` in suspect bodies plus a counter on every layout-state write, filtered in Xcode's console. The value whose counter races is the loop.

## 5. Also due with 1.7.0

- **Featuring nomination** in App Store Connect (Featuring → Nominations, type **App Enhancements**), at least **3 weeks** before the publish date. In **Helpful Details**, say the app is optimized for iPhone Duo and supports all device poses (Apple's Duo page asks for exactly that).
- **Listing preview:** check the screenshots in App Store Connect's new iPhone Duo preview tool.
- **Build SDK:** the upload must be built with the iOS 27.1 SDK (Xcode 27.1). GitHub's `macos-26` image tops out at Xcode 26.6, and as of 2026-10-07 the `xcode-27` image's Xcode 27.1 is still a beta, not the RC, so a CI-built upload isn't usable for release. Don't spend time on the CI deploy path until GitHub puts the 27.1 RC on that image.
