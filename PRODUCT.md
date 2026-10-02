# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

Primarily home-lab and NAS owners: people who self-host (Plex, file servers, small clusters), know roughly what RAID is, and want to sanity-check usable capacity and redundancy before buying drives or building an array. Secondary audiences named in `prd.md` are people new to RAID, who want to understand what changes between levels, and IT generalists who need rough capacity numbers offline, in a meeting or at a whiteboard.

## Product Purpose

RAID Calculator shows the tradeoffs between RAID levels instantly. The user picks a level (RAID 0, 1, 5, 6, 10, JBOD), a drive count and a per-drive size. The app returns usable capacity, how many drives can fail, and relative speed and availability ratings. Success means a user can answer “which RAID should I choose, and how much space will I actually have?” within seconds, and comes away understanding the tradeoff rather than just holding a number.

## Positioning

It is a focused, native, offline utility that does one calculation well and teaches as it goes. Each level has a short info sheet (description, pros, cons, use cases). There is no account, tracking or network dependency, and it is meant to feel at home next to Apple’s own utilities rather than like a web calculator wrapped in an app.

## Operating Context

- Used in quick bursts while planning a NAS build, comparing drive purchases, or explaining RAID to someone.
- Must work fully offline.
- Remembers the last configuration between launches (UserDefaults).

## Capabilities and Constraints

- Live on the App Store, published by mrBallistic. Current version 1.3.2.
- Native SwiftUI, MVVM-lite, no third-party dependencies. Deployment target iOS 18.6; iOS 26 Liquid Glass styling is applied to buttons and steppers where available.
- Runs on iPhone and iPad. A two-column iPad layout exists, but the user did not mark iPad as a binding design constraint.
- Localized into English, Spanish, French, Italian and Japanese. Layouts must survive longer translated strings and Japanese text.
- **Time to answer must stay under 10 seconds**: open the app, pick a level, read the result. No onboarding, account or required settings stand in front of the answer.
- Calculations use simplified standard formulas (see `prd.md` §FR-3). Speed and availability are fixed 1–5 ratings per level, not measured benchmarks. RAID 10’s fault tolerance is shown as “up to n/2, depending on which drives fail.”
- Inline validation covers minimum drive counts (RAID 5 ≥ 3, RAID 6 ≥ 4, RAID 10 ≥ 4 and even).
- **Synology mode** (second tab): per-bay drive sizes, SHR-1/SHR-2 alongside Synology's RAID 1/5/6, presets for current DiskStation models by bay count, unused-capacity explanation, upgrade suggestions and before/after comparison. Its job is upgrade and purchase planning for Synology owners with mixed drive sizes.
- "Synology" and "SHR" appear only as factual, nominative descriptions inside the app, with a not-affiliated notice; never in the app name, subtitle or icon, and never Synology's logo.
- Out of scope so far: RAID 50/60, ZFS RAID-Z, Unraid, expansion units, SSD cache, cost, power and IOPS estimates, real disk management, sync and accounts. The bay model is meant to take Unraid and RAID-Z later.

## Brand Commitments

- Name: **RAID Calculator** (RAID in capitals). “RAIDGauge” in the README and PRD was a working name and should not appear in product copy. The home-screen display name currently reads “Raid Calculator.”
- Must feel first-party iOS: system typography, SF Symbols, native controls and materials.
- Privacy is part of the product: no data collection, analytics, third-party services or network calls (`privacy.md`).

## Evidence on Hand

- `prd.md`: original requirements, personas, formulas, ratings.
- `privacy.md`: published privacy policy.
- `screenshot-1.png`, `screenshot-2.png`: current UI.
- App icon: `RaidCalculator2/AppIcon.icon` (with appearance variants).
- No testimonials, reviews, download figures or press exist in the repo; do not invent any.

## Product Principles

1. **The answer comes first.** Capacity and fault tolerance are visible the moment the inputs make sense; nothing comes between the user and the number.
2. **Show the tradeoff.** Speed and availability are presented side by side so choosing a level reads as a tradeoff, not a lookup.
3. **Be honest about simplifications.** Ratings are relative, RAID 10 tolerance is conditional, and invalid configurations explain themselves inline.
4. **Belong on iOS.** Platform conventions win over novelty, so the app sits naturally among Apple’s utilities.
5. **Private and offline by construction.**

## Accessibility & Inclusion

Supports Dynamic Type and VoiceOver (`prd.md` §1.6). Ratings shown as stars must also have text labels and spoken equivalents. Layouts must hold up at large Dynamic Type sizes and in all five localizations, and work in both light and dark mode.
