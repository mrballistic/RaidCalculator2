
## 1. Product Requirements Document (PRD)

**Status:** current as of **1.6.0** (2026-10-05). This merges the original v1 spec with the 1.5.0 and 1.6.0 delta that lived in `prd-update.md`. FR-1 to FR-7 are the v1 requirements, updated where later releases changed them; FR-8 to FR-20 keep the numbers they had in the delta, so references in code, plans and commits still resolve.

**Release history**

| Version | What it added |
|---|---|
| 1.4.0 | The iOS 26 rebuild, and a second **Synology** tab: drives bay by bay, SHR/SHR-2, DiskStation presets, unused capacity, Biggest Upgrade and a before/after comparison. In App Review as of 2026-10-02. |
| 1.4.1 | The drive-size cursor fix (FR-19). |
| 1.5.0 | The RAID tab’s nested and ZFS levels (FR-8), the ZFS estimate (FR-9), the RAID-tab half of the shared info sheet (FR-17) and the RAID tab’s motion (FR-20). Tagged `v1.5.0` on 2026-10-04. |
| 1.6.0 | The NAS tab (FR-10 to FR-12, FR-15), compare systems (FR-13), iPad layouts (FR-14), copy, trademarks and the website (FR-16), the NAS system sheets (FR-17), the one-line failures row (FR-18) and FR-19’s remaining items. |

### 1.1 Product overview

**Product name:** RAID Calculator (RAID in capitals). “RAIDGauge” was a working name and doesn’t appear in product copy.
**Platform:** iOS and iPadOS 26, native (Swift / SwiftUI)
**Summary:**
A visually polished iOS app that shows storage tradeoffs instantly. It has two tabs, split by the question they answer, not by vendor:

* **RAID tab:** “I have *N* identical drives; what does each layout give me?” The user selects:
  * a RAID level: RAID 0, 1, 5, 6, 10, 50, 60, JBOD, or ZFS RAID-Z1, Z2 or Z3 (FR-1, FR-8)
  * a number of drives, and groups for nested and RAID-Z levels
  * a capacity per drive
* **NAS tab:** “I have *these* drives, bay by bay; what do I get, and what should I buy?” The user picks a system (Synology, Unraid, ZFS, SnapRAID or Btrfs RAID1), a bay count, and each bay’s drive size (FR-10).

The RAID tab calculates:

* **Usable storage capacity**, raw capacity and efficiency
* **Number of drive failures tolerated**
* **Relative speed rating** (as stars)
* **Relative availability / resilience rating** (as stars)

The NAS tab calculates usable, unused and raw capacity, failures tolerated, the single upgrade that unlocks the most space, and the same drives under every system.

The UI should feel like a modern iOS app: Liquid Glass, SF Symbols, system typography.

---

### 1.2 Goals & non-goals

**Goals**

* Make RAID capacity and resiliency easy to understand for non-experts.
* Show a clear, immediate visual sense of tradeoffs: performance vs availability.
* Look and feel like a first-party iOS utility (native materials, Dynamic Type, SF Symbols).
* Be usable in <10 seconds: open app → pick RAID → see answers.
* Cover the layouts home-lab owners actually run, beyond Synology.
* Keep the app’s core insight, “how much space does *this mix* of drives give me, and what should I buy next?”, working for every NAS system.
* Show the same drives under every system, so choosing a system reads as a tradeoff.
* Keep Synology’s name out of the tab bar.
* Make iPad a design target: wide arrays and side-by-side comparisons are where the larger screen earns its keep (FR-14).

**Non-goals**

* No actual disk / hardware management.
* No OS-level integration, no real RAID configuration.
* No iCloud sync, multi-device state, or account system.
* ZFS mirror groups and mixed-size multi-group pools.
* dRAID, Windows Storage Spaces, Ceph and Drobo (Drobo is gone).
* SnapRAID split parity, Unraid cache pools and SSD caches of any kind.
* Exactness. Every figure stays a simplified formula, and the ZFS figure is a labeled estimate.

---

### 1.3 Target users & personas

**Persona 1 – Home Lab Tinkerer (“Alex”)**

* Self-hosts NAS, Plex, small clusters.
* Knows roughly what RAID is, but wants to sanity-check capacity and redundancy.
* Likely to run Unraid, TrueNAS (ZFS), SnapRAID or Btrfs rather than, or alongside, a Synology box. The NAS tab mostly serves Alex.

**Persona 2 – Curious Learner (“Sam”)**

* New to RAID (student, junior engineer).
* Wants intuitive understanding: “If I pick RAID 5 instead of RAID 1, what changes?”

**Persona 3 – IT Generalist (“Jordan”)**

* Needs a quick reference / planning tool for rough RAID capacity planning.
* Uses app offline, in a meeting or at a whiteboard.

---

### 1.4 User stories

* As a user, **I want to select a RAID level and number of drives** so I can see usable capacity.
* As a user, **I want to know how many drives can fail** before data loss, so I can understand risk.
* As a user, **I want a quick visual for performance vs availability** (stars) instead of raw numbers.
* As a user, **I want a short explanation of each RAID level** so I can learn the differences.
* As a user, **I want the app to look modern and “native iOS”** so it feels trustworthy and nice to use.
* As a NAS owner with mixed drives, **I want to set each bay’s size** so I can see what my system does with them, and what stays unused.
* As an Unraid or SnapRAID user, **I want to enter my drives and parity** so I can see usable space and whether my parity drive is large enough.
* As someone planning a purchase, **I want the app to name the one drive worth buying**, so I don’t buy a drive I can’t use.
* As a ZFS user, **I want a realistic figure, not just the textbook one**, so the number matches what my pool reports.
* As someone choosing a system, **I want to see the same drives under every system at once**, so I can pick the one that fits.
* As someone with a large server, **I want arrays bigger than 12 bays**, legible on iPad.

---

### 1.5 Functional requirements

#### RAID tab (FR-1 to FR-9)

**FR-1: RAID selection**

* The user can choose a RAID level from a set:
  `RAID 0, RAID 1, RAID 5, RAID 6, RAID 10, JBOD`, plus the nested and ZFS levels of FR-8: `RAID 50, RAID 60, RAID-Z1, RAID-Z2, RAID-Z3`.
* **Picker** (decided for 1.5.0): eleven levels won’t fit a segmented control. Keep a segmented control for the common levels, and put the full list in a sectioned menu: **Standard** (0, 1, 5, 6, 10, JBOD), **Nested** (50, 60), **ZFS** (Z1, Z2, Z3). Common levels are no slower to reach than before.

**FR-2: Drive configuration input**

* User can select **number of drives**:

  * Integer, min 1, max 24.
* User can input **drive size**:

  * Numeric value (e.g., 1, 2, 4, 8, 16).
  * Unit selection: GB / TB (simple Picker).
  * The field’s editing behavior is FR-19.
* **Groups** (*G*), shown only for the nested and ZFS levels (FR-8).
* Validation:

  * Show inline messaging if the RAID level requires a minimum drive count (e.g., RAID 5 ≥ 3 drives, RAID 6 ≥ 4, RAID 10 ≥ 4 and even), with a one-tap fix (“Use 6 drives”). FR-8 extends this to groups.

**FR-3: Calculations**

Given:

* `n` = number of drives
* `S` = size per drive (in GB or TB → normalize internally to one unit)

**Capacity model (simplified):**

* **JBOD:** usable = `n * S`, failures tolerated = 0 (any drive loss loses part of data).
* **RAID 0:** usable = `n * S`, failures tolerated = 0.
* **RAID 1:** usable = `S`, failures tolerated = `n - 1`.
* **RAID 5:** usable = `(n - 1) * S`, failures tolerated = 1 (only valid if n ≥ 3).
* **RAID 6:** usable = `(n - 2) * S`, failures tolerated = 2 (only valid if n ≥ 4).
* **RAID 10:** usable = `(n / 2) * S` (n must be even and ≥ 4),
  failures tolerated: up to `n / 2` in best case, shown as
  “Up to n/2 (depends on which drives fail)”.
* **RAID 50, RAID 60 and RAID-Z1/Z2/Z3:** FR-8.
* **TiB:** the results also show “≈ X TiB as most NAS systems report it”, since drives are sold in TB. ZFS levels show FR-9’s estimate in its place.
* **Rebuild caution** (decided for 1.5.0): every single-parity layout on drives of 8 TB or more warns that a rebuild can take days and that a second failure during it loses the array. It suggests RAID 5 → RAID 6, RAID 50 → RAID 60 and RAID-Z1 → RAID-Z2, and only a level the current drives can reach.

**FR-4: Ratings (stars)**

Fixed 1–5 ★ ratings. They compare levels with each other and aren’t benchmarks.

**Performance rating:**

* RAID 0: 5★
* RAID 10: 4★
* RAID 5: 3★
* RAID 6: 2★
* RAID 1: 2★
* JBOD: 2★ (sequential okay, but no striping)
* RAID 50, RAID 60 and RAID-Z: FR-8.

**Availability rating:**

* RAID 0: 1★
* JBOD: 1★
* RAID 5: 3★
* RAID 6: 4★
* RAID 1: 5★
* RAID 10: 5★ (high redundancy)
* RAID 50, RAID 60 and RAID-Z: FR-8.

**FR-5: Results presentation**

* A **“Results Card”** shows:

  * Usable capacity (e.g., “24 TB usable”), with raw capacity and efficiency beneath it.
  * A drive strip: one bar per drive, colored by role (data, parity, mirror), with groups shown per FR-8 and FR-14.
  * Drive failures tolerated, on one line when it fits (FR-18).
  * Speed rating (stars + label: “High”, “Medium”, etc.).
  * Availability rating (stars + label: “Very High”, etc.).
* If configuration is invalid for that RAID level:

  * Show an inline error card (e.g., “RAID 5 requires at least 3 drives”), with a one-tap fix.
* While the drive size is empty or zero, the card asks for a size instead (FR-19).

**FR-6: RAID info sheet**

* Tap on an “info” button (`i`) for the selected RAID level:

  * Short description.
  * Pros & cons list.
  * Typical use cases.
  * Ratings, and for RAID-Z “How the app calculates this”.
* Since 1.5.0 this is one shared sheet for RAID levels and NAS systems: FR-17.

**FR-7: Settings / defaults**

* No settings screen. The app remembers the last configuration on both tabs with `UserDefaults` (FR-15), and nothing stands in front of the answer.

**FR-8: Nested and ZFS levels on the RAID tab** (1.5.0)

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
  * Decided for 1.5.0: RAID 50 and RAID 60 need at least 2 groups. With one group, they’re RAID 5 or RAID 6.
  * Decided for 1.5.0: one-tap fixes never suggest more than 24 drives; at the ceiling they offer a group count instead.
  * A leftover groups value never affects the standard levels, and zero groups is treated as one.
* **Fault tolerance:** *p* failures guaranteed, up to *G* × *p* depending on which drives fail, with the same conditional wording RAID 10 uses.
* **Drive strip:** still one bar per drive, with a visible gap between groups. At regular width, each group is its own row (FR-14).
* **Ratings,** decided 2026-10-02: fixed and relative. Each new level is rated against its closest existing level, adjusted only for what structurally changes. ZFS gets no bonus for checksums or self-healing; those are integrity strengths, not speed or availability, and they go in the info sheets’ pros instead (FR-17).

| Level | Speed | Availability |
|---|---|---|
| RAID 50 | 4 | 3 |
| RAID 60 | 3 | 4 |
| RAID-Z1 | 3 | 3 |
| RAID-Z2 | 2 | 4 |
| RAID-Z3 | 2 | 5 |

* **Wide RAID-Z note:** when a single RAID-Z group is wider than 12 drives, note that very wide groups take a long time to rebuild (as FR-11).
* **Info sheets** for all five levels (FR-17).

**FR-9: ZFS capacity estimate** (1.5.0)

For any ZFS figure (FR-8’s RAID-Z levels and the NAS tab’s ZFS system), show the textbook figure plus **“≈ X as ZFS reports it”**. That replaces the “≈ X TiB as most NAS systems report it” line for ZFS, rather than adding a second competing number.

The estimate assumes OpenZFS defaults (4K sectors, `ashift=12`; 128K records) and subtracts:

1. **RAID-Z allocation padding, per group.** A 128K record is 32 data sectors. Parity sectors = *p* × ceil(32 ÷ (*W* − *p*)). The allocation is rounded up to a multiple of *p* + 1 sectors. Efficiency = 32 ÷ allocated sectors.
   * Example: RAID-Z2 at width 6 loses nothing (efficiency 4/6, the same as the textbook figure).
   * Example: RAID-Z2 at width 7 allocates 48 sectors instead of 44.8, so it gets 2/3 rather than 5/7. This is why some widths are worse than others, and the info sheet says so.
   * RAID-Z1 at its minimum width of 2 is 50% efficient, with no padding loss reported.
2. **Slop space,** verified in the OpenZFS source on 2026-10-02 (`spa_get_slop_space()` in `module/zfs/spa_misc.c`):
   * ZFS reserves 1/32 of the pool (`spa_slop_shift = 5`).
   * The reservation is capped at **128 GiB** (`spa_max_slop`, present since OpenZFS 2.1.0 and unchanged through 2.4.4), with a floor of 128 MiB (`spa_min_slop`).
   * The intent-log space ZFS sets aside is already excluded from the pool’s free space and is subtracted back from the reservation, so the two cancel. The source’s own comment confirms usable space per `zfs list` is a constant ~97% before the cap applies.
   * **Formula:** reported ≈ *D* − min(*D* ÷ 32, 128 GiB), where *D* is the capacity after parity and padding.
   * The cap applies above 4 TiB, so for most home pools this is a flat 128 GiB. For example, RAID-Z2 on 6 × 16 TB is 58.21 TiB in theory and ≈ 58.08 TiB as ZFS reports it; RAID-Z1 on 3 × 2 TB is 3.64 TiB in theory and ≈ 3.52 TiB.
   * Assume OpenZFS 2.1 or later; current TrueNAS, Unraid 7 and Proxmox all ship it. Older releases had no cap.
   * Padding matters far more than slop for large pools, because slop is a rounding error by then.
   * Sizes in GB convert with 1e9 bytes, not 1e12.

* **Caveat** (info sheet and VoiceOver): “Estimated for default ZFS settings. Compression, record size and sector size change the real number.” A further small amount for on-disk metadata isn’t modeled.
* There are no user-facing settings for `ashift` or record size.
* No estimate is shown for an invalid setup.

#### NAS tab (FR-10 to FR-13)

The NAS tab replaced 1.4.0’s Synology tab in 1.6.0. It models drives bay by bay, so mixed sizes work.

**FR-10: The NAS tab** (1.6.0)

* The tab is named **NAS**, not Synology, so no vendor sits in the tab bar.
* A **system picker** at the top, as a menu: Synology, Unraid, ZFS, SnapRAID, Btrfs RAID1. Upgraders default to Synology, so existing users land where they were. Stored bays carry over; the old model and custom-bay-count keys are no longer read, and the bay count comes from the stored bays.
* **Drives are shared across systems.** Bays and sizes stay put when the system changes; the system is a lens on the same drives, which is what makes FR-13 work.
  * Decided in plan 2: **switching system never deletes drives.** A system with a lower bay limit shows the first *N* bays and hides the rest, and switching back shows them again. Lowering the bay stepper trims bays from the end (ruled to stand: hidden bays beyond the new count go too, and Revert drops hidden drives beyond the saved bays).
* **One bay-count stepper for every system,** decided 2026-10-03. The Synology **Model picker and its DiskStation presets are removed.** They only ever answered “how many bays?”, and model names were the most product-specific Synology mentions in the app. The stepper sits directly under the system picker, in a section headed “Setup”.
* Each bay can be empty or hold a drive, chosen from common sizes or a **Custom Size…** alert (FR-19).
* **Bay-count limits per system,** decided 2026-10-02:

| System | Bays | Why |
|---|---|---|
| Synology | 2–12 | Desktop DiskStations top out at 12; rack and expansion units are out of scope. |
| Unraid | 2–30 | Unraid’s hard limit: 30 array devices, 28 data plus 2 parity ([Licensing FAQ](https://docs.unraid.net/unraid-os/troubleshooting/licensing-faq/)). Validated as “Unraid arrays hold up to 28 data drives plus 2 parity drives.”, so 30 drives with 1 parity is invalid. Unraid’s separate pools are out of scope. |
| SnapRAID, Btrfs RAID1, ZFS | 2–30 | None has a home-relevant hard limit; 30 keeps the bay diagram’s worst case bounded. |

* **Results, for every system:**
  * The **bay diagram**: every drive drawn to scale and split into what it holds (data, parity, mirror, or unused), with unused capacity hatched.
  * The **unused-capacity callout**, with the number spelled out (“8 TB unused with this mix of drives.”).
  * Usable, raw and unused capacity and failures tolerated (FR-18).
  * **Biggest Upgrade** (FR-12), with one tap to try it.
  * **Save as Current Setup / Revert**, and every change compared with the saved setup (“+4 TB usable”). The saved setup records the system and its settings too.
  * The system’s hints (FR-11) and, for ZFS, FR-9’s estimate.
  * Compare Systems (FR-13).

**FR-11: NAS system rules** (1.6.0)

| System | Parity | Usable | Tolerates | Rule worth surfacing |
|---|---|---|---|---|
| **Synology** | SHR, SHR-2, or classic RAID 1, 5 or 6 | SHR: layers, below. Classic: every drive counts as the smallest | SHR 1 (with 2+ drives), SHR-2 2, RAID 1 *n* − 1, RAID 5 1, RAID 6 2 | A single large drive can’t be fully used until a second one joins it. |
| **Unraid** | 1–2 parity drives | sum of data drives | parity count | Each parity drive must be ≥ the largest data drive. Real-time parity. |
| **SnapRAID** | 1–6 parity drives | sum of data drives | parity count | Same parity-size rule. **Protection is only as current as the last sync**, which the info sheet says plainly. See the parity hint below. |
| **ZFS** | RAID-Z1/Z2/Z3, one group | (*n* − *p*) × smallest drive, then FR-9’s estimate | *p* | Every drive counts only up to the smallest drive’s size; the rest is hatched as unused. See the wide-group note below. |
| **Btrfs RAID1** | two copies | min(total ÷ 2, total − largest drive) | 1 | One very large drive can’t be fully mirrored, and its excess is hatched as unused. |

* **Synology, carried over from 1.4.0:**
  * **SHR** splits drives into layers at each distinct drive size and builds RAID across the drives that reach each layer. A layer reached by too few drives to protect is unused until a larger drive joins it. SHR keeps one drive’s worth of parity per layer (a mirror when only two drives reach it); SHR-2 keeps two.
  * A single drive is a basic volume: usable, unprotected.
  * Minimum drives: SHR 1, SHR-2 4, RAID 1 2, RAID 5 3, RAID 6 4.
  * The diagram draws parity on the largest drives of each layer, to keep it readable, though SHR spreads it.
* **Unraid and SnapRAID parity assignment:** a parity-count stepper. The largest drives become parity automatically, which is standard practice, so users never assign roles by hand.
  * Decided in plan 2: ties go to the lower bay number. “Parity smaller than a data drive” is therefore unreachable, and the rule surfaces in the footnote (“The largest drives are used as parity, so parity is always at least as large as every data drive.”), the info sheet, and the diagram, where a drive larger than parity becomes parity.
  * At least one data drive is required besides the parity drives.
* **Segments for the bay diagram:**
  * Unraid and SnapRAID: parity bays are fully parity, and data bays are fully data.
  * ZFS: each drive’s slice up to the smallest size is split into data and parity in proportion, and the remainder is unused.
  * Btrfs: each drive’s used portion is half data and half mirror, and any excess on the largest drive is unused.
  * No empty or negative slices are drawn.
* **SnapRAID parity hint** (advice, not a block): when the parity count is below [SnapRAID’s published recommendation](https://www.snapraid.it/faq), say so. For example: “SnapRAID recommends 2 parity drives for 5–14 data drives.”

| Data drives | Recommended parity |
|---|---|
| 2–4 | 1 |
| 5–14 | 2 |
| 15–21 | 3 |
| 22–28 | 4 |

  (SnapRAID’s table continues to 6 parity for 36–42 data drives, beyond the 30-bay limit.)
* **Wide ZFS group note** (advice, not a block): above 12 drives in one RAID-Z group, note that very wide groups take a long time to rebuild after a failure. This is in the spirit of the RAID 5 rebuild caution. It also applies to FR-8’s RAID-Z levels when a single group is wider than 12.
* **Validation**, inline, in the existing style, with no figures shown for an invalid setup:
  * Every system: “Add a drive to a bay to get started.” with no drives.
  * Unraid and SnapRAID: “%@ needs at least one data drive besides its parity drives.”, and for Unraid “Unraid arrays hold up to 28 data drives plus 2 parity drives.”
  * ZFS: “Each RAID-Z2 group needs at least 3 drives.” (the minimum widths of FR-8: Z1 2, Z2 3, Z3 4).
  * Btrfs RAID1: “Btrfs RAID1 needs at least 2 drives.”
  * Synology: the minimums above, for example “SHR-2 needs at least 4 drives.”
* **No ratings** for NAS systems (FR-17).

**FR-12: Biggest Upgrade per system** (1.6.0)

The 1.4.0 engine tried a largest-size drive in an empty bay, or in place of the smallest drive. It’s generalized to per-system candidate purchases, ranked by usable gain, and offered only when the setup is valid and the gain is positive:

* **Synology:** unchanged from 1.4.0.
* **Unraid and SnapRAID:** add a data drive the size of parity in an empty bay, or replace the smallest data drive with one.
  * Decided in plan 2: **the “new parity, old parity becomes data” move is not offered separately.** Data drives are capped at parity size, so it never adds more space right away than adding or replacing a data drive at parity size. Because parity is assigned automatically, a larger drive added later simply becomes parity in the diagram.
* **ZFS:** replace the uniquely smallest drive with the next size up already in the array, which is the cheapest drive that gains anything (decided in plan 2). It never suggests adding a drive: RAID-Z expansion needs OpenZFS 2.3 or later.
* **Btrfs RAID1:** add a drive the size of the largest in an empty bay, or replace the smallest drive with one.

**FR-13: Compare systems** (1.6.0)

* Show the current drives under every NAS system at once: usable capacity, failures tolerated and unused capacity.
* **iPad, two columns:** columns, side by side, beside the bay diagram, wrapping into rows of columns when they don’t fit. **iPhone and stacked layouts:** a sheet reached from the results card (“Compare Systems”), opening at the medium detent.
* Tapping a system switches the NAS tab to it. On iPhone the switch applies after the sheet dismisses, so the user sees the bays re-split (FR-20’s signature moment); on iPad it is immediate.
* Decided in plan 3:
  * Each system uses the user’s current setting for that system: Unraid’s and SnapRAID’s parity, the ZFS level, the Synology RAID type. These are the values switching to it would show.
  * **Sort order:** valid before invalid, then usable capacity (descending), then the picker’s order.
  * **Honesty rule:** a system that can’t use some of the drives says so. Synology reads at most 12 bays and states “Uses the first 12 bays”. Invalid setups show their warning, never a misleading number.

#### Both tabs (FR-14 to FR-20)

**FR-14: iPad layouts** (1.6.0)

* Size-class adaptive, never iPad-only.
* **Two columns** only when the horizontal size class is regular **and** the window is at least 800 points wide (`AdaptiveLayout.twoColumnMinWidth`). Everything else is stacked: iPhone, iPad mini in portrait (744 points), and iPad split view and Slide Over.
  * Decided in plan 3: the RAID tab did not already have a two-column layout (both tabs centered a 720-point column), so 1.6.0 built it for both tabs.
* **Reading order:** in two columns, results lead (left) and inputs follow (right), so VoiceOver and reading order match the stacked layout, where the answer comes first.
* **Bay diagram, more bays than fit one row:** at regular width, wrap into balanced rows (30 bays become 2 × 15); at compact width, scroll horizontally. The narrowest column is 24 points, scaled with Dynamic Type; bars never shrink below a readable size. Bay diagrams stay legible up to 30 bays on iPad.
* **At accessibility text sizes,** bay labels drop the unit (“16” rather than “16 TB”), and the legend says “Sizes in TB” once. VoiceOver labels keep full units. The rating and drive-size rows stack.
* **Drive strip:** at regular width, a grouped level draws each group as its own row, with no visible group labels. VoiceOver gets one element per group: “Group 2 of 3: 3 Data, 1 Parity”.
* iPad multitasking widths, where a compact width can occur on an iPad, are covered by the same rules.

**FR-15: Persistence**

* `UserDefaults` stores the last configuration on both tabs: RAID level, drive count, size, unit and groups; the NAS system, bays, per-system settings and the saved current setup.
* **The tab’s stored value is `"nas"`** in `@AppStorage("selectedTab")`, renamed from `"synology"`, decided 2026-10-02.
  * There is **no migration**. 1.4.0’s only tester is the developer, who clears the local store.
  * **Fallback:** any stored value that matches no tab opens the RAID tab, so an unexpected value never leaves `TabView` with nothing selected.
* Keys added in 1.5.0 and 1.6.0: the NAS system, Unraid/SnapRAID parity counts, the ZFS parity level, and RAID tab groups. Stored bays keep their key (`synology.bays`).
* `RaidLevel` raw values double as display labels and never change: `"R 0"`, `"R 1"`, `"R 5"`, `"R 6"`, `"R 10"`, `"JBOD"`, and since 1.5.0 `"R 50"`, `"R 60"`, `"Z1"`, `"Z2"`, `"Z3"`. An unknown stored value falls back to the default.

**FR-16: Copy, trademarks and the website** (1.6.0)

* **Not-affiliated lines** for **Synology**, **Unraid** (Lime Technology) and **ZFS** (Oracle). All three get factual, nominative mentions only, and no vendor logos, never in the app name, subtitle or icon. Exact wording:
  * “Not affiliated with or endorsed by Synology Inc. Synology and SHR are trademarks of Synology Inc.”
  * “Not affiliated with or endorsed by Lime Technology, Inc. Unraid is a trademark of Lime Technology, Inc.”
  * “ZFS is a trademark of Oracle and/or its affiliates. Not affiliated with or endorsed by Oracle.”
* **Placement,** decided 2026-10-02:
  * **In the app,** each system’s line lives in its **info sheet** (FR-17), not on the main view. Three brands in a main-view footer would grow into a legal paragraph. The line isn’t a legal requirement for nominative use; it guards against implied endorsement, and the sheet does that equally well. The RAID-Z level sheets on the RAID tab also carry the ZFS line (decided in plan 2). SnapRAID and Btrfs have no line.
  * Synology’s line moved from the bottom of the Synology view into the Synology sheet, along with the SHR explanation that sat beside it.
  * **The App Store description and the website footer** carry all three lines; that’s what a reviewer reads.
  * 1.4.0 was left as it was while in review.
* **Keywords** in the App Store listing contain no third-party trademarks (guideline 2.3.7).
* **Copy rules,** app and website: smart punctuation (curly “ ” ’) and American spelling; em dashes only where they earn it, at most one per sentence, closed up; en dashes in ranges stay. System names stay untranslated: Synology, SHR, SHR-2, Unraid, ZFS, RAID-Z1/Z2/Z3, SnapRAID, Btrfs RAID1.
* **Localization:** every string in English, Spanish, French, Italian and Japanese, through `scripts/strings.py`. On the NAS screen, Spanish says “disco” and Japanese counts drives with 台; the RAID tab and the info sheets keep Spanish “unidad” (ruled acceptable in plan 2).
* **Website (`www/`),** updated for 1.6.0:
  * The FAQ “What doesn’t it cover?” no longer lists RAID 50/60, ZFS or Unraid; expansion units, SSD cache, Unraid’s separate pools and cost/power/IOPS stay on it.
  * The model-presets paragraph is replaced by bay counts.
  * Screenshots refresh for the NAS tab and the iPad layout, including a Compare Systems shot (plan 4, Task 6), in light and dark.
  * Ships as a `www-v*` release once the app is live, which is the developer’s call.

**FR-17: Info sheets (the “i” button)**

* One shared info sheet for RAID levels and NAS systems, with these sections:
  * Overview
  * Pros
  * Cons
  * Typical uses
  * **Ratings** (optional)
  * **“How the app calculates this”** (optional)
* Copy is keyed by prefix in `Localizable.xcstrings` (`raid50_pros`, `unraid_cons` and so on).
* **RAID tab:** every level keeps its ratings section. The RAID-Z sheets add:
  * Pros: checksums and self-healing (integrity, not speed).
  * “How the app calculates this”: FR-9’s estimate, its default-settings assumption and its caveat.
  * For widths that pad badly, a note that this group width loses space to padding.
* **NAS tab:** the same “i” toolbar button opens the sheet for the selected system. These sheets have **no ratings**: NAS speed depends on implementation, such as Unraid’s cache and write mode, so stars would read as benchmark claims. “How the app calculates this” carries each system’s key rule:
  * **Synology:** how SHR builds layers from mixed drive sizes. The sheet covers SHR, SHR-2 and the classic levels.
  * **Unraid:** each parity drive must be at least as large as the largest data drive; parity is real-time.
  * **SnapRAID:** protection is only as current as the last sync, plus the parity-count recommendation.
  * **ZFS:** each drive counts only up to the smallest drive’s size, plus FR-9’s estimate and caveat.
  * **Btrfs RAID1:** two copies on different drives, so one very large drive can’t be fully mirrored.
* **Each trademarked system’s sheet ends with its not-affiliated line** (FR-16), as the last section’s footer.
* **VoiceOver** reads every section, including the caveats, in full.

**FR-18: One-line “Drive failures tolerated”** (1.6.0)

* Both tabs show the label and value on one line (“Drive failures tolerated … 1”) instead of stacking them.
* One shared row, built with `ViewThatFits`:
  * When it fits, use the single-line form.
  * When it doesn’t, fall back to the stacked form. This covers the conditional values (“Up to 4 (depends on which drives fail)”), the largest Dynamic Type sizes and Japanese.
* **The honesty rule:** the conditional wording is never shortened to make it fit.
* VoiceOver reads it as a single element.

**FR-19: The drive-size field** (cursor fix in 1.4.1; the rest in 1.6.0)

* **Bug in 1.4.0:** on the RAID tab, tapping the drive size and pressing backspace often deleted nothing, so the size couldn’t be replaced without fiddling the cursor to the right.
* **Root cause, reproduced in a UI test on 2026-10-02:**
  * The field is trailing-aligned in a frame up to 140 pt wide, but a size like “4” is one digit.
  * A tap anywhere left of the digits put the cursor *before* them. Backspace did nothing, and typing “8” produced “84”.
  * Clearing the field and typing decimals already worked, which ruled out the value binding.
* **Fix (`DriveSizeField` in `ContentView.swift`, 1.4.1):** on focus, the cursor moves to the end of the number, wherever the tap landed.
  * SwiftUI only offers `selection:` on text-bound fields, so the field edits its own text, pushing each value that parses.
  * Parsing is locale-aware, so the decimal comma works.
  * An empty field restores the last size when editing ends.
* **Added in 1.6.0:**
  * While the field is empty, or reads 0, the results card shows **“Enter a drive size.”** instead of the last result. Done restores the last size.
  * The NAS tab’s **Custom Size…** alert can’t be confirmed until it holds a positive number (its Done button is disabled), so an empty field no longer silently keeps the old size.
* **Tests:** UI tests cover:
  * tapping the middle, then replacing the size
  * clearing the field
  * a decimal
  * empty plus Done restoring the size
  * a Spanish decimal comma
  * the “Enter a drive size” prompt, including 0
  * the custom-size alert refusing an empty value

**FR-20: Motion**

Motion shows *what a change did to your drives*. The drive strip and bay diagram are the app’s subject, so they’re what moves.

* **The signature moment, on the NAS tab:** drives stay put when the system changes, so switching systems re-splits the same bays in place. Parity moves to its new drives, and unused space hatches in or out.
* **RAID tab:** changing Groups opens and closes visible gaps in the drive strip as the bars regroup. Applying a one-tap fix animates the configuration into its valid state.
* **Biggest Upgrade:** “Try it” grows the bay to its new size, and the gain counts up (`.numericText()`).
* **Defaults:** `.snappy` for layout changes, and `.numericText()` for every changing number.
* **Haptics:** `.selection` for steppers and pickers; `.success` only when a setup becomes valid.
* **Reduce Motion:** every animation falls back to a short (0.2 s) crossfade with no movement. Grouped drive rows crossfade rather than slide.
* **Restraint:** no decorative or entrance animations; one authored moment per tab.

---

### 1.6 Non-functional requirements

* **Performance:** Instant calculations; no noticeable lag. Comparing all five NAS systems at 30 bays recalculates instantly.
* **Time to answer stays under 10 seconds** on the RAID tab. The nested and ZFS levels sit behind the menu, so common levels are no slower to reach.
* **Offline:** Fully functional offline. No account, analytics, tracking, third-party services or network calls; the App Store privacy label reads “Data Not Collected”.
* **Accessibility:**
  * Dynamic Type at every size, including the largest accessibility sizes, and VoiceOver throughout.
  * VoiceOver reads group structure (one element per group, “Group 2 of 3: 3 Data, 1 Parity”), parity assignment and the ZFS caveat, and reads bay diagrams as full sentences (“Bay 1, 16 TB: 8 TB parity, 8 TB unused.”).
  * Ratings shown as stars also have text labels and spoken equivalents.
  * Every layout holds at the largest Dynamic Type sizes, in all five languages, in light and dark mode.
* **Localization:** English, Spanish, French, Italian and Japanese (FR-16).
* **Design:** System typography and SF Symbols; native controls with Liquid Glass styling on buttons and steppers.
* **Supported iOS version:** iOS 26.0 and later, iPhone and iPad. Native SwiftUI, MVVM-lite, no third-party dependencies.

---

### 1.7 Success metrics (soft, for you)

* You can answer “Which RAID should I choose?” rapidly while demoing.
* Friends / colleagues can understand RAID tradeoffs after playing with it for ~2 minutes.
* A NAS owner can see what their next drive buys before they buy it.
* The app feels “at home” next to Apple’s own utilities.

---

### 1.8 Out of scope

* Drobo, dRAID, Windows Storage Spaces and Ceph.
* ZFS mirror groups and mixed-size multi-group pools.
* SnapRAID split parity, Unraid cache pools and separate pools, and SSD caches of any kind.
* Synology expansion units and rack models.
* Settings for ZFS `ashift` or record size.
* Cost calculations, power, IOPS estimates.
* macOS layouts.
* Real disk management, sync and accounts.

---

### 1.9 Decisions

There are no open questions. These were resolved while specifying and building 1.5.0 and 1.6.0:

| Decision | Where |
|---|---|
| ZFS slop fraction and cap: 1/32, capped at 128 GiB (2026-10-02) | FR-9 |
| Bay-count limits per system (2026-10-02) | FR-10 |
| Ratings for the new levels, and none for NAS systems (2026-10-02) | FR-8, FR-17 |
| The tab’s stored value is `"nas"`, with no migration (2026-10-02) | FR-15 |
| Trademark lines in each system’s info sheet, all three in the App Store description and website footer (2026-10-02) | FR-16 |
| One bay-count stepper; no Synology model picker or presets (2026-10-03) | FR-10 |
| RAID 50/60 need 2+ groups; fixes never exceed 24 drives; the rebuild caution covers every single-parity layout at 8 TB+ (plan 1) | FR-3, FR-8 |
| Unraid/SnapRAID parity is assigned to the largest drives, ties to the lower bay (plan 2) | FR-11 |
| No separate “new parity, old parity becomes data” upgrade; ZFS upgrades replace the uniquely smallest drive (plan 2) | FR-12 |
| Switching system hides drives beyond a lower bay limit but never deletes them (plan 2) | FR-10 |
| Comparison settings, sort order and the iPhone switch-after-dismiss (plan 3) | FR-13 |
| Two columns at regular width and 800 pt or more; results lead (plan 3) | FR-14 |
| Phase 0 (a 1.4.1 rename to NAS if App Review objected to Synology’s name) was a contingency only; the rename shipped in 1.6.0 | FR-10 |

The plans: `docs/superpowers/plans/2026-10-03-raid-tab-nested-zfs.md` (1.5.0), `2026-10-04-nas-tab.md`, `2026-10-05-compare-and-ipad.md` and `2026-10-05-copy-site-and-rows.md` (1.6.0).

---

## 2. Technical Design Doc

**Note:** §2 and §3 are the original v1 design and build plan, kept as history. The code is authoritative where they differ. For example, `RaidLevel` raw values are `"R 0"` and so on (FR-15), the deployment target is iOS 26, and 1.5.0 and 1.6.0 added the grouped levels, `ZFSEstimate`, the NAS calculators (`SynologyCalculator`, `ParityArrayCalculator`, `ZFSMixedCalculator`, `BtrfsRaid1Calculator`), `NASViewModel`, the shared `InfoSheet` and `AdaptiveLayout`. Their plans are listed in §1.9.

### 2.1 Tech stack

* **Language:** Swift
* **UI framework:** SwiftUI (for modern, declarative UI and easy glassmorphism)
* **Architecture:** MVVM-lite
* **Project:** Single target iOS app (already initialized by you)

---

### 2.2 High-level architecture

**Layers:**

1. **Model Layer**

   * `RaidLevel` enum
   * `RaidConfiguration` struct
   * `RaidResult` struct
2. **Logic / Service Layer**

   * `RaidCalculator` for doing the math.
3. **ViewModel Layer**

   * `RaidCalculatorViewModel` – binds user input to computed results.
4. **View Layer**

   * SwiftUI screens: main calculator screen, info sheet.

---

### 2.3 Data model

```swift
enum RaidLevel: String, CaseIterable, Identifiable {
    case raid0 = "RAID 0"
    case raid1 = "RAID 1"
    case raid5 = "RAID 5"
    case raid6 = "RAID 6"
    case raid10 = "RAID 10"
    case jbod = "JBOD"

    var id: String { rawValue }
}

enum CapacityUnit: String, CaseIterable, Identifiable {
    case gb = "GB"
    case tb = "TB"
    var id: String { rawValue }
}

struct RaidConfiguration {
    var level: RaidLevel
    var driveCount: Int
    var driveSize: Double
    var unit: CapacityUnit
}

struct RaidResult {
    var usableCapacity: Double     // normalized to selected unit
    var failuresTolerated: String  // string to allow “up to 3”
    var speedRating: Int           // 1–5
    var availabilityRating: Int    // 1–5
    var warningMessage: String?    // for invalid configs
}
```

---

### 2.4 Calculation logic

**Normalization:**

* Internally pick one base unit (GB or TB).
* Example: store everything in TB, convert if user selects GB (or vice versa).

**Validation rules (pseudo):**

```swift
func validate(_ config: RaidConfiguration) -> String? {
    let n = config.driveCount

    switch config.level {
    case .raid0:
        if n < 1 { return "RAID 0 requires at least 1 drive." }
    case .raid1:
        if n < 2 { return "RAID 1 requires at least 2 drives." }
    case .raid5:
        if n < 3 { return "RAID 5 requires at least 3 drives." }
    case .raid6:
        if n < 4 { return "RAID 6 requires at least 4 drives." }
    case .raid10:
        if n < 4 || n % 2 != 0 { return "RAID 10 requires an even number of drives (4 or more)." }
    case .jbod:
        if n < 1 { return "JBOD requires at least 1 drive." }
    }
    return nil
}
```

**Capacity formulas (pseudo):**

```swift
func calculate(config: RaidConfiguration) -> RaidResult {
    let n = config.driveCount
    let size = config.driveSize  // assume already in chosen unit

    var usable: Double
    var failures: String

    switch config.level {
    case .raid0:
        usable = Double(n) * size
        failures = "0"
    case .raid1:
        usable = size
        failures = "\(max(0, n - 1))"
    case .raid5:
        usable = Double(max(0, n - 1)) * size
        failures = "1"
    case .raid6:
        usable = Double(max(0, n - 2)) * size
        failures = "2"
    case .raid10:
        usable = Double(n / 2) * size
        failures = "Up to \(n / 2) (depends on which drives fail)"
    case .jbod:
        usable = Double(n) * size
        failures = "0 (you lose data on any failed drive)"
    }

    let speed = speedRating(for: config.level)
    let availability = availabilityRating(for: config.level)

    return RaidResult(
        usableCapacity: usable,
        failuresTolerated: failures,
        speedRating: speed,
        availabilityRating: availability,
        warningMessage: validate(config)
    )
}
```

**Rating helpers:**

```swift
func speedRating(for level: RaidLevel) -> Int {
    switch level {
    case .raid0: return 5
    case .raid10: return 4
    case .raid5: return 3
    case .raid6, .raid1, .jbod: return 2
    }
}

func availabilityRating(for level: RaidLevel) -> Int {
    switch level {
    case .raid0, .jbod: return 1
    case .raid5: return 3
    case .raid6: return 4
    case .raid1, .raid10: return 5
    }
}
```

---

### 2.5 ViewModel

```swift
final class RaidCalculatorViewModel: ObservableObject {
    @Published var selectedLevel: RaidLevel = .raid5
    @Published var driveCount: Int = 4
    @Published var driveSize: Double = 4
    @Published var unit: CapacityUnit = .tb

    @Published private(set) var result: RaidResult?

    private let calculator = RaidCalculator()

    func recalculate() {
        let config = RaidConfiguration(
            level: selectedLevel,
            driveCount: driveCount,
            driveSize: driveSize,
            unit: unit
        )
        result = calculator.calculate(config: config)
    }
}
```

Use `onChange` or `didSet` to trigger `recalculate()` whenever inputs change.

---

### 2.6 UI / Screens

#### Screen 1: Main RAID Calculator

**Layout (SwiftUI):**

* Top: Title “RAID Calculator” + SF Symbol (`square.stack.3d.up` or similar).
* Section: RAID Level Selector

  * Segmented control or `Picker` with pill-style cards.
* Section: Drive Configuration

  * Stepper for **# of drives**.
  * TextField + Picker for **drive size & unit**.
* Section: Results Card

  * Glassmorphic rounded rectangle:

    * “Usable Capacity: 24 TB”
    * “Drive failures tolerated: 1”
    * Speed: `★★★★★` + “Very High”
    * Availability: `★★★☆☆` + “Medium”
* Optional: small footer text “Tap for RAID details” with chevron.

**Glass / liquid look:**

* Use blur materials on cards:

```swift
RoundedRectangle(cornerRadius: 24, style: .continuous)
    .fill(.thinMaterial)
    .overlay( /* subtle border with opacity */ )
    .shadow(radius: 10)
```

* Use system accent color; keep background a subtle gradient.

#### Screen 2: RAID Info Sheet

* Presented as `.sheet` when user taps an info button.
* Shows:

  * RAID level name.
  * Short description.
  * Pros/Cons (bullets).
  * Speed & availability stars again.

---

### 2.7 Navigation

* Single `NavigationStack` root for the calculator.
* Info sheet from main screen via `.sheet` or `.navigationDestination`.

---

### 2.8 Persistence

* Use `UserDefaults` to store:

  * Last selected RAID level.
  * Last drive count / size / unit.
  * Since 1.5.0 and 1.6.0, groups and every NAS-tab value too: FR-15.

---

### 2.9 Testing strategy

* **Unit tests:**

  * Verify capacity calculations for each RAID level with known inputs.
  * Verify invalid configs return appropriate warnings.
* **Snapshot or UI tests (optional):**

  * Simple check of main view loads without crash.
* **Manual testing:**

  * Edge cases: minimum drives, maximum drives, weird sizes (0.5 TB, etc.).

**Worked examples pinned in unit tests (1.5.0 and 1.6.0),** one suite per calculator:

| Case | Expected |
|---|---|
| RAID 50, 12 × 8 TB, 3 groups | 72 TB usable; tolerates 1, up to 3 |
| RAID 60, 12 × 8 TB, 2 groups | 64 TB usable; tolerates 2, up to 4 |
| RAID 60, 12 drives, 5 groups | invalid, with a fix offered |
| Unraid, parity 16; data 16, 8, 8, 4 TB | 36 TB usable; tolerates 1 |
| Unraid, a drive larger than parity | it becomes parity (the largest drives are always parity, so “parity smaller than the largest data drive” can’t occur) |
| Unraid, 29 data drives | invalid: “Unraid arrays hold up to 28 data drives plus 2 parity drives.” |
| SnapRAID, parity 20, 20; data 16, 12, 8 TB | 36 TB usable; tolerates 2 |
| SnapRAID, 1 parity, 6 data drives | valid, with the 2-parity hint |
| Btrfs RAID1, 16, 8, 8, 4 TB | 18 TB usable |
| Btrfs RAID1, 20, 4, 4 TB | 8 TB usable; 12 TB unused on the 20 TB |
| ZFS RAID-Z1, 16, 8, 8, 4 TB | 12 TB textbook; 20 TB unused; padding efficiency 32/44 |
| RAID-Z2 padding at widths 6 and 7 | 2/3 for both (width 7 loses capacity against its 5/7 textbook figure) |
| ZFS reported, RAID-Z2, 6 × 16 TB | ≈ 58.08 TiB (58.21 TiB minus the 128 GiB cap) |
| ZFS reported, RAID-Z1, 3 × 2 TB | ≈ 3.52 TiB (1/32 applies, under the cap) |
| Biggest Upgrade, Unraid 16, 16, 8, 8, 4 TB with an empty bay | add a 16 TB data drive: +16 TB (no separate parity move, FR-12) |
| Biggest Upgrade, ZFS 16, 8, 8, 4 TB | replace the 4 TB with an 8 TB: +12 TB |

Plus:

* **Persistence:** an unknown stored tab value, such as `"synology"`, opens the RAID tab; stored Synology bays open the NAS tab on Synology, with the same drives; switching to a system with fewer bays hides drives but keeps them.
* **Review-focus cases** from the plans: a drive-count change that leaves uneven groups offers fixes; zero groups is one group; standard levels ignore groups; the ZFS estimate in GB; fixes never exceed 24 drives; RAID-Z1 at width 2.
* **UI tests** for FR-19’s field and alert, FR-18’s row, the NAS system switch, compare systems, and the iPad two-column layouts. A Reduce Motion pass is manual, on iPhone and iPad, before tagging a release.

---

## 3. Task List (Implementation Plan)

You already initialized the app in Xcode, so we start just after that.

### Phase 1 – Project setup & architecture

1. **Set deployment target & basic settings**

   * Choose iOS version (e.g., iOS 17).
   * Set app name, bundle ID, accent color, etc.

2. **Create base SwiftUI structure**

   * Ensure `@main` `App` struct uses a root `ContentView`.
   * Wrap root view in `NavigationStack`.

3. **Define data models**

   * Create `RaidLevel`, `CapacityUnit`, `RaidConfiguration`, `RaidResult` as above.

4. **Implement RaidCalculator**

   * Create `RaidCalculator` struct or class.
   * Implement validation, capacity formulas, and rating mappings.
   * Add unit tests for calculator functions.

---

### Phase 2 – ViewModel & state wiring

5. **Create `RaidCalculatorViewModel`**

   * Implement published properties and `recalculate()` method.
   * Initialize a default configuration.
   * Call `recalculate()` in `init()`.

6. **Connect ViewModel to root view**

   * Use `@StateObject` in `ContentView` to hold `RaidCalculatorViewModel`.
   * Pass into child views as `@ObservedObject` if needed.

---

### Phase 3 – Core UI (Calculator screen)

7. **Build basic UI layout**

   * Header (title + icon).
   * Sections for RAID selector, drive config, and result.

8. **RAID level selector**

   * Implement segmented control-like UI (e.g., `Picker` with `.segmented` style).
   * Alternatively, horizontal scroll of pill buttons.
   * Bind selection to `viewModel.selectedLevel`.
   * Trigger `recalculate()` on change.

9. **Drive count input**

   * Implement `Stepper` for `driveCount`.
   * Show current value.
   * Trigger `recalculate()` on change.

10. **Drive size input**

    * TextField with numeric keyboard.
    * Simple validation (non-negative, non-zero).
    * Unit picker (GB/TB).
    * Trigger `recalculate()` on change.

11. **Result card**

    * Implement glassmorphic card with `.thinMaterial` background.
    * Show:

      * Usable capacity with units, formatted nicely.
      * Failures tolerated (consider pluralization).
      * Speed stars + label.
      * Availability stars + label.

12. **Error / warning display**

    * If `warningMessage != nil`, show a smaller warning card or banner.
    * Disable or dim some results if configuration invalid.

---

### Phase 4 – Styling, “liquid glass” & polish

13. **Background & theming**

    * Add gradient background (e.g., radial or angular gradient).
    * Ensure content sits on top with padding.

14. **Glass cards**

    * Add blur material backgrounds (.thinMaterial / .ultraThinMaterial).
    * Rounded corners (20–30).
    * Subtle inner strokes or overlays for depth.

15. **Stars component**

    * Create reusable `StarRatingView` (props: `rating: Int`, `max: Int = 5`).
    * Use SF Symbol `star.fill` / `star` with opacity.

16. **Typography & spacing**

    * Use system fonts with weights:

      * Title: `.title.bold()`
      * Section headers: `.headline`
      * Body: `.body`
    * Ensure good spacing, avoid clutter.

17. **Dark mode support**

    * Test in light & dark mode.
    * Adjust gradients / shadows if needed.

---

### Phase 5 – RAID Info sheet

18. **RAID info data**

    * Create a `RaidInfo` struct or compute from `RaidLevel`.
    * For each `RaidLevel`, define:

      * Short description.
      * Pros (strings).
      * Cons (strings).
      * Typical use cases.

19. **Info sheet UI**

    * Add info button near RAID selector.
    * On tap, present `.sheet` with details for the selected level.
    * Display description, pros/cons lists, ratings.

---

### Phase 6 – Persistence & Settings (lightweight)

20. **Persist last configuration**

    * Use `UserDefaults` to store/read last:

      * RAID level (rawValue)
      * driveCount, driveSize, unit.
    * Read at app launch, set ViewModel defaults.

21. **Optional mini Settings view**

    * Could be a simple toggle or default values screen (if you want).
    * Otherwise, keep this out of v1.

---

### Phase 7 – Testing & QA

22. **Unit tests for calculator**

    * For each RAID level, test capacity & failures with known scenarios.
    * Test invalid configs return warnings.

23. **Manual UI testing**

    * Try min/max drive counts.
    * Various drive sizes (1, 2, 3.5 TB, etc.).
    * Invalid combos (RAID 10 with 3 drives, etc.).
    * Light/dark mode; different Dynamic Type sizes.

24. **Performance sanity check**

    * Ensure recalculation is instant, no UI jank.

---

### Phase 8 – App Store readiness (if desired)

25. **App icon**

    * Design a simple icon (stacked drives / shield) and add to asset catalog.

26. **App metadata**

    * Name, description, keywords, screenshots if publishing.

