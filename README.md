# RAID Calculator

A native iOS and iPadOS app, for iPhone, iPad and iPhone Duo, that shows how much space a set of drives actually gives you, how many can fail, and which drive is worth buying next. It’s on the App Store as [RAID Calculator](https://apps.apple.com/app/id395601653), with a product page at [mrballistic.com/raid](https://mrballistic.com/raid/).

## Who it’s for

Mostly home-lab and NAS owners: people who self-host, know roughly what RAID is, and want to check usable space and redundancy before buying drives or building an array. It also suits people new to RAID who want to see what changes between levels, and IT generalists who need rough capacity numbers offline, in a meeting or at a whiteboard.

## What it does

**RAID tab: identical drives**
- RAID 0, 1, 5, 6, 10, 50, 60, JBOD, and ZFS RAID-Z1/Z2/Z3 (with groups), for 1–24 drives in GB or TB.
- Usable and raw capacity, efficiency, a drive strip showing data, parity and mirrors, and drive failures tolerated, including the conditional cases (“Up to 4 (depends on which drives fail)”).
- Invalid setups dim, VoiceOver says so, and they offer a one-tap fix (“Use 6 drives”).
- RAID 5, RAID 50 and RAID-Z1 on drives of 8 TB or more warn that a rebuild can take days and that a second failure during it loses the array, and offer a one-tap “Use RAID 6” (or RAID 60, or RAID-Z2) when the groups are wide enough to move up. Narrower groups get the warning without the button.
- Advice like this is marked as advice, with its own icon, so it doesn’t read as an error.
- RAID-Z shows an estimate of what ZFS will report, after padding and reserved space, always labeled as an estimate.

**NAS tab: mixed drives, bay by bay**
- One set of drives seen through five systems: Synology (SHR, SHR-2, classic RAID), Unraid, ZFS (one RAID-Z group), SnapRAID and Btrfs RAID1.
- A bay diagram drawn to scale, with unused capacity hatched.
- Biggest Upgrade: the single purchase that unlocks the most space.
- Save as Current Setup, and from then on every change reads as a difference from it, beside a line summarizing the saved setup. Until you save, there’s nothing to compare against. Revert asks before it restores the saved setup.
- Compare Systems: the same drives under every system, most usable first, saying when a system reads fewer bays than you set up, or more than the current one shows. A full-height sheet in one column, columns beside the bays in two.
- Advice with a one-tap fix, such as SnapRAID’s recommended parity count (“Use 2 parity drives”).

**Everywhere**
- An info sheet per RAID level and NAS system: overview, pros, cons, typical uses, ratings for RAID levels, and how the app calculates RAID-Z and each NAS system.
- Results beside inputs once the window is regular width, at least 800 points wide and at least 600 points tall, as on iPad and on iPhone Duo’s open inner display in landscape, where the fold falls in the gap between the columns. iPhone in landscape (the Pro Max included), iPhone Duo’s closed outer display (beside the system’s vertical bars) and its inner display in portrait, open or folded like a book, use one column. Bay diagrams stay legible up to 30 bays.
- Info sheets open as a sheet, except on iPhone Duo in two columns, where the info takes the place of the inputs so the results stay in view.
- iPhone rotates to landscape.
- At accessibility text sizes the level and unit pickers become menus.
- Light and dark mode, a tint dark enough for text contrast (darker still with Increase Contrast), Dynamic Type up to the largest accessibility sizes, VoiceOver (which reads each drive within a group), and Reduce Motion.

## Platforms

iPhone and iPad on iOS and iPadOS 26.0 or later, and iPhone Duo on iOS 27.1, in portrait and landscape. It works fully offline.

## Languages

English, Spanish, French, Italian, Japanese, German, Traditional Chinese, Simplified Chinese, Korean and Brazilian Portuguese.

## Privacy

No account, no analytics, no tracking and no network calls: the app collects no data. The [privacy policy](https://mrballistic.com/raid/privacy/) is on the product page.

## More

- [ARCHITECTURE.md](ARCHITECTURE.md): how the app is built, the calculation model, persistence, layout, accessibility, strings and testing.
- [DEPLOY.md](DEPLOY.md): CI, App Store uploads, the website deploy and the release checklist.
- [CHANGELOG.md](CHANGELOG.md): what changed in each version, from 1.3 to 1.7.0.
- [prd.md](prd.md): the product requirements and every decision behind them. [PRODUCT.md](PRODUCT.md): who the app is for and how it should feel.

## Trademarks

Not affiliated with or endorsed by Synology Inc. Synology and SHR are trademarks of Synology Inc. Not affiliated with or endorsed by Lime Technology, Inc. Unraid is a trademark of Lime Technology, Inc. ZFS is a trademark of Oracle and/or its affiliates. Not affiliated with or endorsed by Oracle.

## License

MIT. See [LICENSE](LICENSE).
