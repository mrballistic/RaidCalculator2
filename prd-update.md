## PRD update: nested RAID, ZFS and the NAS tab (1.5.0 and 1.6.0)

Planned work for the next feature releases. **1.5.0** shipped the RAID tab (plan 1: FR-8, FR-9, the RAID-tab half of FR-17, and FR-20’s RAID-tab motion), tagged `v1.5.0` on 2026-10-04. **1.6.0** carries the rest: the NAS tab, compare systems, iPad layouts, and copy, trademarks and the website. This file holds only the delta; `prd.md` stays as the original v1 spec, and the two get merged when this ships.

It describes changes against 1.4.0, which is in App Review as of 2026-10-02 and already goes beyond `prd.md`: a second **Synology** tab models drives bay by bay, with SHR/SHR-2, DiskStation presets, unused capacity, Biggest Upgrade and a before/after comparison.

**Status:** planning. Decided 2026-10-02; nothing built yet. Because 1.4.0 hasn’t launched, this can be a fast follow, and phase 0 below is ready as a fast update if App Review objects to Synology’s name in the app.

---

### 1. Product requirements

#### 1.1 Summary

Two additions, one per tab:

* **RAID tab:** nested and ZFS layouts for identical drives: RAID 50, RAID 60, RAID-Z1, RAID-Z2, RAID-Z3.
* **The Synology tab becomes NAS:** the same bay-by-bay model, with a system picker. Synology stays and gains company: Unraid, ZFS, SnapRAID and Btrfs RAID1.

The tabs split by the question they answer, not by vendor. The RAID tab is “I have *N* identical drives; what does each layout give me?” The NAS tab is “I have *these* drives, bay by bay; what do I get, and what should I buy?”

iPad becomes a design target for this release. Wide arrays and side-by-side comparisons are where the larger screen earns its keep.

#### 1.2 Goals and non-goals

**Goals**

* Cover the layouts home-lab owners actually run, beyond Synology.
* Keep the app’s core insight, “how much space does *this mix* of drives give me, and what should I buy next?”, working for every system.
* Show the same drives under every system, so choosing a system reads as a tradeoff.
* Get Synology’s name out of the tab bar.

**Non-goals**

* ZFS mirror groups and mixed-size multi-group pools.
* dRAID, Windows Storage Spaces, Ceph and Drobo (Drobo is gone).
* SnapRAID split parity, Unraid cache pools and SSD caches of any kind.
* Exactness. Every figure stays a simplified formula, and the ZFS figure is a labeled estimate.

#### 1.3 Users

The same personas as `prd.md`. This release mostly serves **Alex, the home-lab tinkerer**, who is likely to run Unraid, TrueNAS (ZFS), SnapRAID or Btrfs rather than, or alongside, a Synology box.

#### 1.4 User stories

* As an Unraid or SnapRAID user, **I want to enter my drives and parity** so I can see usable space and whether my parity drive is large enough.
* As someone planning a purchase, **I want the app to tell me when a bigger drive has to become parity first**, so I don’t buy a drive I can’t use.
* As a ZFS user, **I want a realistic figure, not just the textbook one**, so the number matches what my pool reports.
* As someone choosing a system, **I want to see the same drives under every system at once**, so I can pick the one that fits.
* As someone with a large server, **I want arrays bigger than 12 bays**, legible on iPad.

---

### 1.5 Functional requirements

These continue `prd.md`’s numbering.

**FR-8: Nested and ZFS levels on the RAID tab**

* New levels: `RAID 50`, `RAID 60`, `RAID-Z1`, `RAID-Z2`, `RAID-Z3`.
* New input, **Groups** (*G*): shown only for these five levels. Width *W* = drives ÷ groups.

| Level | Parity per group (*p*) | Minimum width | Usable (textbook) |
|---|---|---|---|
| RAID 50 | 1 | 3 | *G* × (*W* − 1) × size |
| RAID 60 | 2 | 4 | *G* × (*W* − 2) × size |
| RAID-Z1 | 1 | 2 | *G* × (*W* − 1) × size |
| RAID-Z2 | 2 | 3 | *G* × (*W* − 2) × size |
| RAID-Z3 | 3 | 4 | *G* × (*W* − 3) × size |

* **Validation:** the drive count must divide evenly into groups, and each group must meet the minimum width. The one-tap fix generalizes, for example “Use 12 drives” or “Use 3 groups”.
* **Fault tolerance:** *p* failures guaranteed, up to *G* × *p* depending on which drives fail. Use the same conditional wording RAID 10 uses today.
* **Drive strip:** still one bar per drive, with a visible gap between groups.
* **Picker:** the six current levels plus five new ones won’t fit a segmented control. Keep a segmented control for the common levels, and put the full list in a sectioned menu: **Standard** (0, 1, 5, 6, 10, JBOD), **Nested** (50, 60), **ZFS** (Z1, Z2, Z3).
* **Ratings:** fixed and relative, like today. Decided 2026-10-02: each new level is rated against its closest existing level, adjusted only for what structurally changes. ZFS gets no bonus for checksums or self-healing; those are integrity strengths, not speed or availability, and they go in the info sheets’ pros instead (FR-17).

| Level | Speed | Availability |
|---|---|---|
| RAID 50 | 4 | 3 |
| RAID 60 | 3 | 4 |
| RAID-Z1 | 3 | 3 |
| RAID-Z2 | 2 | 4 |
| RAID-Z3 | 2 | 5 |

* **Info sheets** for all five levels (FR-17).

**FR-9: ZFS capacity estimate**

For any ZFS figure (FR-8’s RAID-Z levels and the NAS tab’s ZFS system), show the textbook figure plus **“≈ X as ZFS reports it”**. That replaces the existing “≈ X TiB as most NAS systems report it” line for ZFS, rather than adding a second competing number.

The estimate assumes OpenZFS defaults (4K sectors, `ashift=12`; 128K records) and subtracts:

1. **RAID-Z allocation padding, per group.** A 128K record is 32 data sectors. Parity sectors = *p* × ceil(32 ÷ (*W* − *p*)). The allocation is rounded up to a multiple of *p* + 1 sectors. Efficiency = 32 ÷ allocated sectors.
   * Example: RAID-Z2 at width 6 loses nothing (efficiency 4/6, the same as the textbook figure).
   * Example: RAID-Z2 at width 7 allocates 48 sectors instead of 44.8, so it gets 2/3 rather than 5/7. This is why some widths are worse than others, and the info sheet can say so.
2. **Slop space,** verified in the OpenZFS source on 2026-10-02 (`spa_get_slop_space()` in `module/zfs/spa_misc.c`):
   * ZFS reserves 1/32 of the pool (`spa_slop_shift = 5`).
   * The reservation is capped at **128 GiB** (`spa_max_slop`, present since OpenZFS 2.1.0 and unchanged through 2.4.4), with a floor of 128 MiB (`spa_min_slop`).
   * The intent-log space ZFS sets aside is already excluded from the pool's free space and is subtracted back from the reservation, so the two cancel. The source's own comment confirms usable space per `zfs list` is a constant ~97% before the cap applies.
   * **Formula:** reported ≈ *D* − min(*D* ÷ 32, 128 GiB), where *D* is the capacity after parity and padding.
   * The cap applies above 4 TiB, so for most home pools this is a flat 128 GiB. For example, RAID-Z2 on 6 × 16 TB is 58.21 TiB in theory and ≈ 58.08 TiB as ZFS reports it; RAID-Z1 on 3 × 2 TB is 3.64 TiB in theory and ≈ 3.52 TiB.
   * Assume OpenZFS 2.1 or later; current TrueNAS, Unraid 7 and Proxmox all ship it. Older releases had no cap.
   * Padding matters far more than slop for large pools, because slop is a rounding error by then.

* **Caveat** (info sheet and VoiceOver): “Estimated for default ZFS settings. Compression, record size and sector size change the real number.” A further small amount for on-disk metadata isn’t modeled.
* There are no user-facing settings for `ashift` or record size in this release.

**FR-10: The NAS tab**

* Rename the **Synology** tab to **NAS**.
* A **system picker** at the top, as a menu: Synology, Unraid, ZFS, SnapRAID, Btrfs RAID1. Upgraders default to Synology, so existing users land where they were. Stored bays carry over; the old model and custom-bay-count keys are no longer read, and the bay count comes from the stored bays.
* **Drives are shared across systems.** Bays and sizes stay put when the system changes; the system is a lens on the same drives, which is what makes FR-13 work.
* **One bay-count stepper for every system,** decided 2026-10-03. The Synology **Model picker and its DiskStation presets are removed.** They only ever answered “how many bays?”, and model names were the most product-specific Synology mentions in the app. The stepper sits directly under the system picker.
* **Bay-count limits per system,** decided 2026-10-02:

| System | Bays | Why |
|---|---|---|
| Synology | 2–12 | Desktop DiskStations top out at 12; rack and expansion units are out of scope. |
| Unraid | 2–30 | Unraid’s hard limit: 30 array devices, 28 data plus 2 parity ([Licensing FAQ](https://docs.unraid.net/unraid-os/troubleshooting/licensing-faq/)). Validate it: “Unraid arrays hold up to 30 drives.” Unraid’s separate pools are out of scope. |
| SnapRAID, Btrfs RAID1, ZFS | 2–30 | None has a home-relevant hard limit; 30 keeps the bay diagram’s worst case bounded. |
* The bay diagram, the unused-capacity callout, Biggest Upgrade (FR-12) and Save as Current Setup / Revert work for every system. The saved setup records the system too.

**FR-11: NAS system rules**

| System | Parity | Usable | Tolerates | Rule worth surfacing |
|---|---|---|---|---|
| **Synology** | as today | as today | as today | as today |
| **Unraid** | 1–2 parity drives | sum of data drives | parity count | Each parity drive must be ≥ the largest data drive. Real-time parity. |
| **SnapRAID** | 1–6 parity drives | sum of data drives | parity count | Same parity-size rule. **Protection is only as current as the last sync**, which the info sheet must say plainly. See the parity hint below. |
| **ZFS** | RAID-Z1/Z2/Z3, one group | (*n* − *p*) × smallest drive, then FR-9’s estimate | *p* | Every drive counts only up to the smallest drive’s size; the rest is hatched as unused. See the wide-group note below. |
| **Btrfs RAID1** | two copies | min(total ÷ 2, total − largest drive) | 1 | One very large drive can’t be fully mirrored, and its excess is hatched as unused. |

* **Unraid and SnapRAID parity assignment:** a parity-count stepper. The largest drives become parity automatically, which is standard practice, so users never assign roles by hand.
* **Segments for the bay diagram:**
  * Unraid and SnapRAID: parity bays are fully parity, and data bays are fully data.
  * ZFS: each drive’s slice up to the smallest size is split into data and parity in proportion, and the remainder is unused.
  * Btrfs: each drive’s used portion is half data and half mirror, and any excess on the largest drive is unused.
* **SnapRAID parity hint** (advice, not a block): when the parity count is below [SnapRAID’s published recommendation](https://www.snapraid.it/faq), say so. For example: “SnapRAID recommends 2 parity drives for 5–14 data drives.”

| Data drives | Recommended parity |
|---|---|
| 2–4 | 1 |
| 5–14 | 2 |
| 15–21 | 3 |
| 22–28 | 4 |

  (SnapRAID’s table continues to 6 parity for 36–42 data drives, beyond the 30-bay limit.)
* **Wide ZFS group note** (advice, not a block): above 12 drives in one RAID-Z group, note that very wide groups take a long time to rebuild after a failure. This is in the spirit of the existing RAID 5 rebuild caution. It also applies to FR-8’s RAID-Z levels when a single group is wider than 12.
* **Validation**, inline, in the existing style. For example: “Parity must be at least as large as your largest data drive (16 TB).”

**FR-12: Biggest Upgrade per system**

The current engine tries a largest-size drive in an empty bay, or in place of the smallest drive. Generalize it to per-system candidate purchases, ranked by usable gain:

* **Synology:** unchanged.
* **Unraid and SnapRAID:** add a data drive no larger than parity; replace the smallest data drive; or **buy a bigger drive as the new parity and move the old parity drive to data.** That last move is one purchase, and it’s the system’s non-obvious insight, the equivalent of SHR’s. For example, with an empty bay: “Buy a 20 TB for parity. Your old 16 TB parity drive becomes data: +16 TB usable.” Without an empty bay, the old parity drive replaces the smallest data drive, and the gain is the difference between the two.
* **ZFS:** replace the smallest drive. The gain only appears when that drive was uniquely the smallest, which the gain calculation handles naturally.
* **Btrfs RAID1:** add a drive in an empty bay, or replace the smallest drive.

**FR-13: Compare systems**

* Show the current drives under every NAS system at once: usable capacity, failures tolerated and unused capacity, sorted by usable capacity.
* **iPad:** columns, side by side. **iPhone:** a list, or a sheet reached from the results card.
* Tapping a system switches the NAS tab to it.

**FR-14: iPad layouts**

* Size-class adaptive, never iPad-only. The RAID tab already has a two-column iPad layout; extend that pattern to the NAS tab and the new views: inputs and results side by side at regular width, stacked at compact width.
* Bay diagrams stay legible up to 30 bays on iPad. iPhone may scroll horizontally, but must not shrink bars below a readable size.
* Grouped drive strips for nested and ZFS levels use the extra width to show groups as rows.
* Also check iPad multitasking widths, where a compact width can occur on an iPad.

**FR-15: Persistence**

* **Rename the tab’s stored value** from `"synology"` to `"nas"` in `@AppStorage("selectedTab")`, decided 2026-10-02.
  * There is **no migration**. 1.4.0’s only tester is the developer, who clears the local store when 1.5.0 ships.
  * **Fallback:** any stored value that matches no tab opens the RAID tab, so an unexpected value never leaves `TabView` with nothing selected.
* New keys: the NAS system, Unraid/SnapRAID parity counts, the ZFS parity level, and RAID tab groups. Existing Synology keys keep working unchanged.
* `RaidLevel` raw values double as display labels (`"R 0"`). New cases follow that pattern, and an unknown stored value falls back to the default, as today.

**FR-16: Copy, trademarks and the website**

* **Not-affiliated lines** for **Synology**, **Unraid** (Lime Technology) and **ZFS** (Oracle). All three get factual, nominative mentions only, and no vendor logos. Placement, decided 2026-10-02:
  * **In the app,** each system’s line lives in its **info sheet** (FR-17), not on the main view. Three brands in a main-view footer would grow into a legal paragraph. The line isn’t a legal requirement for nominative use; it guards against implied endorsement, and the sheet does that equally well.
  * Synology’s line moves from the bottom of the NAS view into the Synology sheet, along with the SHR explanation that sits beside it today (`shr_footnote`).
  * **The App Store description and the website footer** keep all the lines; that’s what a reviewer reads.
  * **Leave 1.4.0 as it is** while it’s in review. If App Review objects, phase 0 handles it.
* **Localization:** all new strings in English, Spanish, French, Italian and Japanese. System names stay untranslated.
* **Website (`www/`):**
  * Update the FAQ “What doesn’t it cover?”: RAID 50/60, ZFS and Unraid come off the list; SSD cache, expansion units and cost/power/IOPS stay on it.
  * Rewrite the model-presets paragraph under the Synology section (`.models` in `www/index.html`), since 1.5.0 has no presets. Bay counts take their place.
  * Refresh the screenshots, and consider a NAS-tab comparison shot.
  * Ship as a `www-v*` release once the app is live.

**FR-17: Info sheets (the “i” button)**

* The RAID tab’s `RaidInfoSheet` becomes **one shared info sheet** with these sections:
  * Overview
  * Pros
  * Cons
  * Typical uses
  * **Ratings** (optional)
  * **“How the app calculates this”** (new, optional)
* Copy stays keyed by prefix in `Localizable.xcstrings` (`raid50_pros`, `unraid_cons` and so on).
* **RAID tab:** every level keeps its ratings section. The RAID-Z sheets add:
  * Pros: checksums and self-healing (integrity, not speed).
  * “How the app calculates this”: FR-9’s estimate, its default-settings assumption and its caveat.
  * For widths that pad badly, a note that this group width loses space to padding.
* **NAS tab:** gains the same “i” toolbar button, opening the sheet for the selected system. These sheets have **no ratings**: NAS speed depends on implementation, such as Unraid’s cache and write mode, so stars would read as benchmark claims. “How the app calculates this” carries each system’s key rule:
  * **Synology:** how SHR builds layers from mixed drive sizes. The sheet covers SHR, SHR-2 and the classic levels.
  * **Unraid:** each parity drive must be at least as large as the largest data drive; parity is real-time.
  * **SnapRAID:** protection is only as current as the last sync, plus the parity-count recommendation.
  * **ZFS:** each drive counts only up to the smallest drive’s size, plus FR-9’s estimate and caveat.
  * **Btrfs RAID1:** two copies on different drives, so one very large drive can’t be fully mirrored.
* **Each system’s sheet ends with its not-affiliated line** (FR-16), as a section footer.
* **VoiceOver** reads every section, including the caveats, in full.


**FR-18: One-line “Drive failures tolerated”**

* Both tabs show the label and value on one line (“Drive failures tolerated … 1”) instead of stacking them.
* One shared row, replacing the duplicated code in `ContentView.swift` and `SynologyView.swift`, built with `ViewThatFits`:
  * When it fits, use the single-line form.
  * When it doesn’t, fall back to today’s stacked form. This covers the conditional values (“Up to 4 (depends on which drives fail)”), the largest Dynamic Type sizes and Japanese.
* The conditional wording is never shortened to make it fit. It’s the honesty rule.
* VoiceOver reads it as a single element, as today.

**FR-19: Drive-size cursor (bug fix, shipped early as 1.4.1)**

* **Bug in 1.4.0:** on the RAID tab, tapping the drive size and pressing backspace often deleted nothing, so the size couldn’t be replaced without fiddling the cursor to the right.
* **Root cause, reproduced in a UI test on 2026-10-02:**
  * The field is trailing-aligned in a frame up to 140 pt wide, but a size like “4” is one digit.
  * A tap anywhere left of the digits put the cursor *before* them. Backspace did nothing, and typing “8” produced “84”.
  * Clearing the field and typing decimals already worked, which ruled out the value binding.
* **Fix (`DriveSizeField` in `ContentView.swift`):** on focus, the cursor moves to the end of the number, wherever the tap landed.
  * SwiftUI only offers `selection:` on text-bound fields, so the field now edits its own text, pushing each value that parses.
  * Parsing is locale-aware, so the decimal comma works.
  * An empty field restores the last size when editing ends.
* **Tests:** UI tests cover:
  * tapping the middle, then replacing the size
  * clearing the field
  * a decimal
  * empty plus Done restoring the size
  * a Spanish decimal comma
* **Still open for 1.5.0:**
  * An explicit “Enter a drive size” results state while the field is empty. Today the results keep the last size while you type.
  * The NAS tab’s custom-size alert. It is full-width and left-aligned, so it doesn’t have this cursor bug, but tapping Done with an empty field silently keeps the old size.

**FR-20: Motion**

Motion shows *what a change did to your drives*. The drive strip and bay diagram are the app’s subject, so they’re what moves.

* **The signature moment, on the NAS tab:** drives stay put when the system changes, so switching systems re-splits the same bays in place. Parity moves to its new drives, and unused space hatches in or out.
* **RAID tab:** changing Groups opens and closes visible gaps in the drive strip as the bars regroup. Applying a one-tap fix animates the configuration into its valid state.
* **Biggest Upgrade:** “Try it” grows the bay to its new size, and the gain counts up (`.numericText()`).
* **Defaults:** `.snappy` for layout changes, and `.numericText()` for every changing number.
* **Haptics:** `.selection` for steppers and pickers; `.success` only when a setup becomes valid.
* **Reduce Motion:** every animation falls back to a short crossfade with no movement.
* **Restraint:** no decorative or entrance animations; one authored moment per tab.
---

### 1.6 Non-functional requirements

As in `prd.md` §1.6, plus:

* **Time to answer stays under 10 seconds** on the RAID tab. The new levels sit behind the menu, so common levels are no slower to reach than today.
* **Accessibility:**
  * VoiceOver reads group structure (“Group 2 of 3, drive 1…”), parity assignment and the ZFS caveat.
  * Every new layout holds at the largest Dynamic Type sizes, in all five languages.
* **Performance:** comparing all five systems at 30 bays recalculates instantly.

### 1.7 Testing

Unit tests per calculator, with worked examples pinned:

| Case | Expected |
|---|---|
| RAID 50, 12 × 8 TB, 3 groups | 72 TB usable; tolerates 1, up to 3 |
| RAID 60, 12 × 8 TB, 2 groups | 64 TB usable; tolerates 2, up to 4 |
| RAID 60, 12 drives, 5 groups | invalid, with a fix offered |
| Unraid, parity 16; data 16, 8, 8, 4 TB | 36 TB usable; tolerates 1 |
| Unraid, parity 12; data 16 TB | invalid: parity smaller than the largest data drive |
| SnapRAID, parity 20, 20; data 16, 12, 8 TB | 36 TB usable; tolerates 2 |
| Unraid, 31 bays | invalid: Unraid arrays hold up to 30 drives |
| SnapRAID, 1 parity, 6 data drives | valid, with the 2-parity hint |
| Btrfs RAID1, 16, 8, 8, 4 TB | 18 TB usable |
| Btrfs RAID1, 20, 4, 4 TB | 8 TB usable; 12 TB unused on the 20 TB |
| ZFS RAID-Z1, 16, 8, 8, 4 TB | 12 TB textbook; 20 TB unused; padding efficiency 32/44 |
| RAID-Z2 padding at widths 6 and 7 | 2/3 for both (width 7 loses capacity against its 5/7 textbook figure) |
| ZFS reported, RAID-Z2, 6 × 16 TB | ≈ 58.08 TiB (58.21 TiB minus the 128 GiB cap) |
| ZFS reported, RAID-Z1, 3 × 2 TB | ≈ 3.52 TiB (1/32 applies, under the cap) |
| Biggest Upgrade, Unraid with parity 16 and data 16, 8, 8, 4 TB | Includes “new 20 TB parity, old 16 TB becomes data” |

Plus two persistence tests:

* An unknown stored tab value, such as `"synology"`, opens the RAID tab.
* Stored Synology bays open the NAS tab on Synology, with the same drives.

---

### 2. Suggested phasing

0. **Fast update, only if App Review objects to Synology’s name in 1.4.0:**
   * Rename the tab to NAS (FR-10, plus FR-15’s rename and fallback), with Synology as the only system.
   * Tighten the nominative copy and the not-affiliated line.
   * This is small and self-contained, and ships as 1.4.1.
   * Everything below still follows.
1. **RAID tab:** FR-8 and FR-9, including the picker redesign, the shared info sheet (FR-17) and the RAID tab’s motion (FR-20). Plan: `docs/superpowers/plans/2026-10-03-raid-tab-nested-zfs.md`.
2. **NAS tab:** FR-10, FR-11, FR-12 and FR-17’s system sheets for Unraid, then ZFS, with FR-15’s rename.
3. **SnapRAID and Btrfs RAID1,** cheap on the same engine.
4. **Compare systems (FR-13) and the iPad layouts (FR-14).** These can start alongside phase 2, since the NAS tab’s layout should be designed adaptive from the start.
5. **Copy, trademarks and the website** (FR-16) at release.

FR-19’s cursor fix shipped early as 1.4.1. FR-18, and FR-19’s remaining items, are small and independent, so they can go in any phase.

### 3. Open questions

None. All four questions were resolved on 2026-10-02:

| Question | Resolved in |
|---|---|
| ZFS slop fraction and cap | FR-9 |
| Bay-count limits | FR-10 |
| Ratings for the new levels | FR-8 and FR-17 |
| The tab’s stored value | FR-15 |
