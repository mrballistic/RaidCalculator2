# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

Primarily home-lab and NAS owners: people who self-host (Plex, file servers, small clusters), know roughly what RAID is, and want to sanity-check usable capacity and redundancy before buying drives or building an array. Secondary audiences named in `prd.md` are people new to RAID, who want to understand what changes between levels, and IT generalists who need rough capacity numbers offline, in a meeting or at a whiteboard.

## Product Purpose

RAID Calculator shows the tradeoffs between RAID levels instantly. On the RAID tab the user picks a level (RAID 0, 1, 5, 6, 10, 50, 60, JBOD or RAID-Z1/Z2/Z3), a drive count and a per-drive size, and the app returns usable capacity, how many drives can fail, and relative speed and availability ratings. On the NAS tab the user sets each bay’s drive under Synology, Unraid, ZFS, SnapRAID or Btrfs RAID1, and sees usable and unused space, failures tolerated, the upgrade worth buying, and every system compared on the same drives. Success means a user can answer “which RAID should I choose, and how much space will I actually have?” within seconds, and comes away understanding the tradeoff rather than just holding a number.

## Positioning

It is a focused, native, offline utility that does one calculation well and teaches as it goes. Each level and NAS system has a short info sheet (description, pros, cons, use cases, and ratings for RAID levels); RAID-Z and every NAS system also explain how the app calculates them. There is no account, tracking or network dependency, and it is meant to feel at home next to Apple’s own utilities rather than like a web calculator wrapped in an app.

## Operating Context

- Used in quick bursts while planning a NAS build, comparing drive purchases, or explaining RAID to someone.
- Must work fully offline.
- Remembers the last configuration between launches (UserDefaults).

## Capabilities and Constraints

- Live on the App Store, published by mrBallistic. **1.4.0** (the iOS 26 rebuild, adding the Synology tab) went to App Review on 2026-10-02. **1.4.1** fixed the drive-size field’s cursor (`prd.md` FR-19). **1.5.0** added RAID 50/60 and RAID-Z to the RAID tab, with the ZFS estimate. **1.6.0** shipped (tag v1.6.0): the NAS tab, compare systems, iPad layouts, and the copy, trademark and website pass (`prd.md` FR-10 to FR-20). **1.7.0** is the release in progress: iPhone Duo support and iPhone landscape (`prd.md` FR-21), the review fixes (FR-22: tint contrast, the NAS baseline, invalid setups announced to VoiceOver, advice with one-tap fixes, menus at accessibility sizes, the narrow-group rebuild caution), and the 1.6.5 polish, which never shipped on its own: per-drive VoiceOver, ten languages, the full-height Compare sheet and more. The upload workflow sets each version from its `v*` tag.
- Native SwiftUI, MVVM-lite, no third-party dependencies. Deployment target iOS 26.0, with Liquid Glass styling on buttons and steppers.
- Runs on iPhone, iPad and iPhone Duo, in portrait and landscape. **iPad is a binding design target** (`prd.md` FR-14): two columns at regular width (results beside inputs), wrapped bay diagrams up to 30 bays, side-by-side system comparison and grouped drive strips. Layouts are size-class adaptive, never iPad-only.
- **iPhone Duo** (1.7.0, `prd.md` FR-21): the closed outer display uses the single column beside the system’s vertical bars; the open inner display in landscape uses the two columns, with the fold in the gap between them; portrait, open or folded like a book, is one column. In two columns on iPhone Duo, an info sheet opens in place of the inputs so the results stay visible; iPad keeps the sheet.
- Localized into English, Spanish, French, Italian, Japanese, German, Traditional Chinese, Simplified Chinese, Korean and Brazilian Portuguese. Layouts must survive longer translated strings, German compounds and CJK text.
- **Time to answer must stay under 10 seconds**: open the app, pick a level, read the result. No onboarding, account or required settings stand in front of the answer.
- Calculations use simplified standard formulas (see `prd.md` FR-3, FR-8 and FR-11); the ZFS figure is a labeled estimate (FR-9). Speed and availability are fixed 1–5 ratings per level, not measured benchmarks. RAID 10’s fault tolerance is shown as “up to n/2, depending on which drives fail.”
- Inline validation covers minimum drive counts (RAID 5 ≥ 3, RAID 6 ≥ 4, RAID 10 ≥ 4 and even) and group widths, with one-tap fixes. Errors and advice look different: advice (the rebuild caution, the SnapRAID parity hint, the wide RAID-Z note) has its own icon, and offers a one-tap fix where one exists.
- **The tabs split by question, not vendor.** The RAID tab is for identical drives; the NAS tab is for mixed drives, bay by bay. There is no third tab.
- **NAS tab** (second tab, 1.6.0): a system picker (Synology SHR/SHR-2/RAID 1/5/6, Unraid, ZFS with one RAID-Z group, SnapRAID, Btrfs RAID1) and one bay-count stepper (Synology 2–12, the rest 2–30; no model presets). Drives are shared across systems, so switching re-splits the same bays. Per-bay sizes, a bay diagram with unused space hatched, Biggest Upgrade, Save as Current Setup / Revert, a SnapRAID parity hint and a wide-RAID-Z note, and Compare Systems (a full-height sheet in one column, columns beside the bays in two). Its job is upgrade and purchase planning for owners with mixed drive sizes.
- **ZFS figures are labeled estimates** that model RAID-Z padding and slop space for default settings.
- Synology, SHR, Unraid (Lime Technology) and ZFS (Oracle) appear only as factual, nominative descriptions; never in the app name, subtitle, icon or App Store keywords, and never with a logo. Each system’s not-affiliated line sits in its info sheet; the App Store description and website footer carry all three (`prd.md` FR-16). The NAS tab name keeps Synology’s name out of the tab bar.
- Out of scope: Drobo, dRAID, Windows Storage Spaces, Ceph, ZFS mirror groups and mixed-size multi-group pools, SnapRAID split parity, expansion units, SSD cache, cost, power and IOPS estimates, real disk management, sync and accounts.

## Brand Commitments

- Name: **RAID Calculator** (RAID in capitals). “RAIDGauge” in the original README and PRD was a working name and should not appear in product copy. The home-screen display name currently reads “Raid Calculator.”
- Must feel first-party iOS: system typography, SF Symbols, native controls and materials.
- Privacy is part of the product: the app has no data collection, analytics, third-party services or network calls (`privacy.md`). The website (`www/`) is separate: it loads Google Analytics only after visitors consent, and the policy says so.

## Evidence on Hand

- `prd.md`: requirements, personas, formulas, ratings and decisions, current as of 1.7.0, in progress (the 1.5.0/1.6.0 delta from `prd-update.md` was merged in on 2026-10-05).
- `README.md`: the product overview. `CHANGELOG.md`: what changed in each version, 1.3 to 1.7.0.
- `ARCHITECTURE.md`: how the app is built. `DEPLOY.md`: CI, App Store uploads, the website deploy and the release checklist.
- `privacy.md`: published privacy policy, live at <https://mrballistic.com/raid/privacy/>.
- `www/`: the product page, live at <https://mrballistic.com/raid/>.
- `marketing/screenshots/`: App Store screenshots, iPhone and iPad (iPhone Duo sets are due with 1.7.0).
- `screenshot-1.png`, `screenshot-2.png`: current UI.
- App icon: `RaidCalculator2/AppIcon.icon` (with appearance variants).
- No testimonials, reviews, download figures or press exist in the repo; do not invent any.

## Product Principles

1. **The answer comes first.** Capacity and fault tolerance are visible the moment the inputs make sense; nothing comes between the user and the number.
2. **Show the tradeoff.** Speed and availability are presented side by side so choosing a level reads as a tradeoff, not a lookup.
3. **Be honest about simplifications.** Ratings are relative, conditional fault tolerance is never shortened, estimates are labeled as estimates, and invalid configurations explain themselves inline.
4. **Belong on iOS.** Platform conventions win over novelty, so the app sits naturally among Apple’s utilities.
5. **Private and offline by construction.**

## Accessibility & Inclusion

Supports Dynamic Type and VoiceOver (`prd.md` §1.6). The tint meets 4.5:1 text contrast in light and dark mode, with darker Increase Contrast variants, and data colors are separate from it (FR-22). Invalid setups are announced to VoiceOver, not only dimmed. Ratings shown as stars must also have text labels and spoken equivalents. Layouts must hold up at large Dynamic Type sizes and in all ten localizations, and work in both light and dark mode.
