---
target: main calculator screen
total_score: 23
max_score: 40
na_heuristics: 
p0_count: 1
p1_count: 3
target_identity: "file:/Users/todd.greco/current_work/RaidCalculator2/RaidCalculator2/ContentView.swift"
target_fingerprint: "sha256:20b8d27220b61fe400c9196da4ad82f7bcd8bde435b924542ddd18fb8086bd63"
target_path: /Users/todd.greco/current_work/RaidCalculator2/RaidCalculator2/ContentView.swift
timestamp: 2026-10-01T23-33-24Z
slug: raidcalculator2-contentview-swift
---
Method: dual-agent (A: design review · B: detector + simulator evidence). Native SwiftUI; the web detector does not scan Swift (returned [] / exit 0, false negative), so B substituted simulator renders on iPhone 17e and iPad Pro 11.

## Design Health Score
| # | Heuristic | Score | Key Issue |
|---|---|---|---|
| 1 | Visibility of System Status | 3 | Live recalculation; nothing marks what changed |
| 2 | Match System / Real World | 2 | "R 0/R 5" abbreviations; TB only, no TiB, won't match what a NAS reports |
| 3 | User Control and Freedom | 3 | Nothing destructive; no reset |
| 4 | Consistency and Standards | 2 | Hand-rolled cards and stepper instead of Form/Stepper; main screen localized, info sheet not |
| 5 | Error Prevention | 2 | Stepper allows odd RAID 10; size field accepts 0/negative/huge |
| 6 | Recognition Rather Than Recall | 2 | Comparing levels means flipping segments and remembering numbers |
| 7 | Flexibility and Efficiency | 2 | No compare view, no common drive sizes, decimal pad has no Done |
| 8 | Aesthetic and Minimalist Design | 2 | Title is the biggest text; usable capacity is body weight; decorative gradient |
| 9 | Error Recovery | 2 | Warning replaces results; no one-tap fix |
| 10 | Help and Documentation | 3 | Good info sheet; English-only; stars never explained as relative |
| **Total** | | **23/40** | **Acceptable** |

## Design Specificity Verdict
Category-interchangeable "glass card calculator": blue/purple radial gradient, four copies of a hand-rolled ultraThinMaterial card with white stroke and shadow, label/value list with stars. Nothing visual is about drives, parity or mirrors. Detector: no coverage for Swift.

## Priority Issues
1. [P0] Localization broken in the shipped build. A root-level Localizable.strings shadowed every .lproj, so fr/ja render entirely English (both agents, byte-identical renders). Even after that, the title (ContentView.swift:104), fault-tolerance values and validation messages (RaidCalculator.swift:17-27, 54, 57) and the whole info sheet are hardcoded English although translated keys exist. Capacity uses String(format:"%.1f"), not locale-aware. Fix: String Catalog (done on ios26-modernization branch), wire existing keys, FormatStyle. → /impeccable harden
2. [P1] Breaks at accessibility text sizes: title wraps huge, stepper glyphs overflow fixed 32x32 frames (:205,:222), 80pt size field truncates, results pushed below the fold. → /impeccable adapt
3. [P1] Answer has no hierarchy: usable capacity is .body.weight(.medium) while the title is .title.bold. Make capacity the hero with raw/efficiency beneath; drop gradient and hand-rolled glass; add a drive strip (N glyphs tinted data/parity/mirror). → /impeccable distill then /impeccable bolder
4. [P1] Invalid config is a dead end and controls invite it: warning replaces results; stepper allows odd RAID 10; size field unclamped. Keep results dimmed, offer the fix as a button, clamp input. → /impeccable clarify
5. [P2] VoiceOver: stars are literal "★★★☆☆" text with no label; stepper and info buttons unlabeled; low-contrast secondary captions on gradient (~3–3.5:1 est.); TB vs TiB. → /impeccable audit

## Persona Red Flags
- Home-lab NAS owner (8×16 TB, TrueNAS/Unraid): 12.0 TB vs ~10.9 TiB mismatch; no RAID-Z/SHR; can't compare RAID 5 vs 6 side by side; no rebuild-risk caution for RAID 5 on large drives.
- First-timer: "R 5" opaque; stars unexplained; results vanish at RAID 10 × 3.
- Japanese/French and AX5 users: English UI; answer off-screen at AX5.

## Minor Observations
Dark-mode text field is a black slab; accent colour doubles as warning colour; unreachable iPad placeholder card references missing keys; sheet duplicates ratings from RaidCalculator.swift; yellow SF stars in sheet vs black glyphs on main; JBOD copy contradicts itself between main screen and sheet; iPad leaves ~60% empty; three names in play (RAID Calc / Raid Calculator / RAID Calculator).

## Questions to Consider
- If it had to work without words, what shows "8 drives, 2 are parity"? Why isn't that the hero?
- Is the job "calculate one level" or "choose between levels"? A 6-row comparison at the current N could replace the segmented control.
- Would Sam trust it more if it looked like Settings?
