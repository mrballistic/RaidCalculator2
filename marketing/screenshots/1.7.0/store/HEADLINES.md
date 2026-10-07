# RAID Calculator 1.7.0: App Store headline drafts

Phase 1 proposal, for Todd’s approval before the full set is rendered. Every image is one headline plus the device on a flat background. Orange `#FF9500` takes near-black `#1C1917` text (8:1); indigo `#5856D6` takes white text (5.6:1). SF Pro Display Bold, sentence case, no final period.

Approved. The iPhone set ships 1–5 and 8 (six images, renumbered 01–06); #6 and #7 are not shipped.

## iPhone 6.9″ (1320 × 2868), the main set

| # | Scene | Mode | Background | Headline |
|---|---|---|---|---|
| 1 | NAS tab, mixed drives (e.g. Synology SHR, 4 + 4 + 8 + 8 TB, bays drawn to scale) | Light | Orange (lead) | Know your real usable space |
| 2 | Compare Systems sheet, same drives across Synology, Unraid, ZFS, SnapRAID, Btrfs | Light | Indigo | Every system, same drives |
| 3 | NAS tab, saved current setup, bay 1 raised to 8 TB, “+4 TB usable” | Light | Orange | See what your next drive adds (**sample**) |
| 4 | RAID tab, RAID 5 with 8 × 20 TB, rebuild caution and “Use RAID 6” | Dark | Indigo | Warns you before a risky rebuild (**sample**) |
| 5 | RAID tab, invalid drive count with its one-tap fix | Light | Orange | One tap to a valid setup |
| 6 | Info sheet open on a RAID level | Light | Indigo | What each RAID level does |
| 7 | NAS or RAID tab in dark mode, a different setup from #4 | Dark | Orange | Light or dark, it fits in |
| 8 | NAS tab, Unraid or ZFS at 30 bays | Light | Indigo | Up to 30 bays, drawn to scale |

Changes from the starting points:
- #4 “Warned before a risky rebuild” became “Warns you before a risky rebuild”: active, says who benefits, still five words.
- #6 “Every RAID level, explained” became “What each RAID level does”: “every” overclaims (the info sheet covers the levels the app offers, not all RAID levels in existence).
- #8 is true only on the NAS tab for Unraid, ZFS, SnapRAID and Btrfs (Synology tops out at 12 bays; the RAID tab at 24 drives). Capture it on one of those systems.
- #7 is the weakest line. Alternative: “Looks at home in dark mode”.

Recommend shipping 6 of the 8 (1–5 plus 8) if Todd wants a tighter set; Apple’s guidance is that 4–6 is plenty.

## iPad 13″ (2064 × 2752)

| # | Scene | Mode | Background | Headline |
|---|---|---|---|---|
| 1 | Two-column NAS tab; at regular width the system comparison is inline | Light | Orange | Know your real usable space |
| 2 | Two-column RAID tab with the rebuild caution | Dark | Indigo | Warns you before a risky rebuild |
| 3 | Unraid at 30 bays; all 30 drawn at this width | Light | Orange | Up to 30 bays, drawn to scale |

iPad has no Compare Systems sheet (the comparison is inline in #1), so #3 is the 30-bay diagram instead.

## iPhone Duo

Lead with the inner display in landscape, the two-column layout, with the fold falling in the gap between columns. Inner portrait is a single column.

| Display | Size | # | Scene | Mode | Background | Headline |
|---|---|---|---|---|---|---|
| Inner, landscape | 2853 × 2007 | 1 | Two columns across the fold: NAS inputs left, results right | Light | Orange | Built for iPhone Duo |
| Inner, landscape | 2853 × 2007 | 2 | RAID tab, two columns, rebuild caution | Dark | Indigo | Warns you before a risky rebuild |
| Inner, portrait | 2007 × 2853 | 1 | NAS tab, single column | Light | Orange | Built for iPhone Duo |
| Inner, portrait | 2007 × 2853 | 2 | RAID tab, rebuild caution | Dark | Indigo | Warns you before a risky rebuild |
| Outer, portrait | 1398 × 2034 | 1 | NAS tab, mixed drives | Light | Orange | Know your real usable space |
| Outer, portrait | 1398 × 2034 | 2 | RAID tab, rebuild caution | Dark | Indigo | Warns you before a risky rebuild |
| Outer, landscape | 2034 × 1398 | 1 | NAS tab, mixed drives | Light | Orange | Know your real usable space |
| Outer, landscape | 2034 × 1398 | 2 | RAID tab, rebuild caution | Dark | Indigo | Warns you before a risky rebuild |

Every Duo scene is reachable by launch arguments alone, so `scripts/store-assets/capture_duo.sh` can drive it without a UI test. That is why Compare Systems (needs a tap) and the saved-setup comparison (needs a scroll) are not on the Duo. Outer landscape is included only if Device Hub can rotate the outer display.

Landscape layout: headline left-aligned, device on the right, the pair centred as one group inside the middle 80% width.

## Header and search images

All three use the same layout, each laid out natively, never scaled from one master: orange background, near-black headline on the left, device on the right, everything inside the middle 80% width and 75% height.

| Size | Ratio | Layout |
|---|---|---|
| 5244 × 2950 | about 16:9 | Headline “Know your real usable space” on one or two lines in the left 40%. Right side: the iPhone (NAS tab, light) at about 75% of the height. The extra width is empty orange, not filler. |
| 3840 × 2560 | 3:2 | Same, with the headline on two lines in the left 45%; device height about 72%. |
| 1920 × 1280 | 3:2 | Same as 3840 × 2560 at half scale, re-rendered natively so the type is hinted at its real size. |

Alternative for the 16:9 header if Todd wants the Duo story up front: the Duo inner display in landscape on the right, headline “Built for iPhone Duo”.

## Rationale

- **One idea per image.** Each headline names one thing the app does that a spreadsheet doesn’t: real usable space on mixed drives, comparing systems, seeing what an upgrade adds, catching a risky rebuild, fixing an invalid setup.
- **Lead with the NAS tab.** Mixed-drive NAS owners are the largest new audience for 1.7.0, and “real usable space” is the question they arrive with.
- **Alternating orange and indigo** uses the app’s own data and parity colors, so the set reads as RAID Calculator at thumbnail size. Orange carries the lead and the header, per Todd.
- **Plain and true.** Short, sentence case, no numbers that the screenshot doesn’t show, no prices, awards or URLs. Third-party names appear only in scene descriptions, spelled exactly, never in a headline except where a screen shows them.
