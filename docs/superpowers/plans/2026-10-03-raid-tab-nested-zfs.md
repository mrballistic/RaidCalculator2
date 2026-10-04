# RAID Tab: Nested and ZFS Levels Implementation Plan (1.5.0, plan 1 of 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add RAID 50, RAID 60 and RAID-Z1/Z2/Z3 to the RAID tab. They come with a Groups input, a sectioned level picker, a caveated ZFS “as ZFS reports it” estimate, motion that shows group structure, and info sheets in all five languages.

**Architecture:** `RaidLevel` gains the five cases and describes each level’s group rules. `RaidConfiguration` gains `groups`. `RaidCalculator` handles grouped capacity, validation, one-tap fixes and cautions as pure functions. A new pure `ZFSEstimate` models RAID-Z padding and slop space. The view model persists `groups`. `ContentView` gets the new picker, the Groups stepper, group gaps in the drive strip and the ZFS note. `RaidInfoSheet` gains an optional “How the app calculates this” section. All copy goes through `scripts/strings.py`.

**Tech Stack:** Swift 6, SwiftUI, iOS 26.0, Swift Testing (unit), XCTest (UI), Xcode 27, Python 3 (string tooling only).

**Spec:** `prd-update.md`. This plan implements FR-8, FR-9, the RAID-tab half of FR-17, and FR-20’s RAID-tab motion. The NAS tab (FR-10 to FR-13, FR-15), iPad layouts (FR-14), FR-16 and FR-18 come in later plans.

**Plan series:** 1, RAID tab (this plan). 2, NAS tab and systems. 3, compare systems and iPad layouts. 4, copy, trademarks, website and FR-18.

## Global Constraints

- Deployment target iOS 26.0. Native SwiftUI, with no third-party dependencies.
- Every user-facing string is a key in `RaidCalculator2/Localizable.xcstrings`, read with `"key".localized()`. Each key has `en`, `es`, `fr`, `it` and `ja`, all `"state" : "translated"`, with the same format specifiers in every language. `python3 scripts/strings.py check` must pass before every commit that touches strings.
- Copy uses smart punctuation: curly quotes “ ” and apostrophes ’. It uses American spelling. Em dashes are rare and always closed up (`word—word`). Use positional specifiers (`%1$d`, `%2$@`) whenever a string has more than one.
- Persisted `RaidLevel` raw values never change. The existing values are `"R 0"`, `"R 1"`, `"R 5"`, `"R 6"`, `"R 10"` and `"JBOD"`. The new ones are `"R 50"`, `"R 60"`, `"Z1"`, `"Z2"` and `"Z3"`.
- Drive count range stays `1...24`.
- Ratings are fixed (speed/availability):
  - RAID 50: 4/3
  - RAID 60: 3/4
  - RAID-Z1: 3/3
  - RAID-Z2: 2/4
  - RAID-Z3: 2/5
  - Existing levels are unchanged.
- Honesty rule:
  - Conditional fault tolerance uses “(depends on which drives fail)”.
  - The ZFS figure is always labeled an estimate.
  - Never shorten conditional wording to make it fit.
- **Motion** (FR-20): animate changes to the drive strip and results with `.snappy`, and use `.numericText()` for numbers.
  - With `@Environment(\.accessibilityReduceMotion)` true, use `.opacity` transitions and no movement.
  - Haptics: `.selection` when groups change, `.success` when a one-tap fix is applied.
- Spec gaps decided in this plan, so implementers don’t re-decide them:
  - RAID 50 and RAID 60 need at least 2 groups. With one group, they’re RAID 5 or RAID 6.
  - The rebuild caution covers every single-parity layout on drives of 8 TB or more. It suggests RAID 5 → RAID 6, RAID 50 → RAID 60 and RAID-Z1 → RAID-Z2.
  - One-tap fixes never suggest more than 24 drives.
- **Build churn:** Xcode’s build rewrites `Localizable.xcstrings` (it reorders keys and auto-adds extracted literals like `"TB"`). If, after a build, `git diff --stat RaidCalculator2/Localizable.xcstrings` shows changes and `scripts/strings.py check` still passes with the same key set your task intended, commit the file as is. Never hand-edit the JSON; use `scripts/strings.py`.
- Every commit message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

**Commands used throughout** (run from the repo root):

```bash
DEST='platform=iOS Simulator,name=iPhone 17'
# Unit tests (Swift Testing), whole target or one suite:
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" -destination "$DEST" -only-testing:"RAID CalcTests"
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" -destination "$DEST" -only-testing:"RAID CalcTests/GroupedLevelTests"
# One UI test:
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" -destination "$DEST" -only-testing:"RAID CalcUITests/RaidCalculator2UITests/testNestedLevelFromMenu"
```

A first build plus Simulator boot can take 5–10 minutes. Run `xcodebuild` in the background with a long timeout, and never run two `xcodebuild` processes at once: they share DerivedData and the Simulator.

## Review Focus

These are inputs the spec implies but no task’s main tests exercise. Each has its own test in the task that owns the code.

1. **Changing the drive count after choosing groups** (for example, 12 drives in 3 groups, then down to 10) shows the uneven-groups message and offers fixes. Groups of 0 can never divide by zero. Tests: `driveCountChangeLeavesUnevenGroupsWithFixes` and `zeroGroupsIsTreatedAsOne` (Task 3).
2. **A leftover `groups` value never affects the standard levels:** RAID 5 with `groups: 3` calculates exactly as RAID 5. Test: `standardLevelsIgnoreGroups` (Task 3).
3. **The ZFS estimate in GB:** bytes use 1e9, not 1e12. Test: `zfsEstimateInGigabytes` (Task 3).
4. **One-tap fixes at the 24-drive ceiling:** never “Use 28 drives”; offer a group count instead. Test: `fixesNeverExceedTwentyFourDrives` (Task 3).
5. **RAID-Z1 at its minimum width of 2:** 50% efficient, with no padding loss reported. Test: `raidZ1AtMinimumWidth` (Task 4).

## File map

| File | Change | Responsibility |
|---|---|---|
| `scripts/strings.py` | create | Add, remove and check catalog strings |
| `.github/workflows/ios.yml` | modify | Run `strings.py check` in CI |
| `RaidCalculator2/Models.swift` | modify | `RaidLevel` cases and group rules, `RaidFamily`, `RaidConfiguration.groups`, new `RaidResult` fields |
| `RaidCalculator2/ZFSEstimate.swift` | create | RAID-Z padding and slop maths |
| `RaidCalculator2/RaidCalculator.swift` | modify | Grouped capacity, validation, fixes, ratings, cautions |
| `RaidCalculator2/RaidCalculatorViewModel.swift` | modify | Persist `groups`; expose cautions and fixes |
| `RaidCalculator2/ContentView.swift` | modify | Picker, Groups stepper, strip gaps, ZFS note, cautions, motion |
| `RaidCalculator2/RaidInfoSheet.swift` | modify | Optional “How the app calculates this” section |
| `RaidCalculator2/Localizable.xcstrings` | modify via script | All new copy |
| `RaidCalculator2Tests/ModelTests.swift` | create | Level metadata |
| `RaidCalculator2Tests/ZFSEstimateTests.swift` | create | Estimate maths |
| `RaidCalculator2Tests/GroupedLevelTests.swift` | create | Grouped calculator behavior |
| `RaidCalculator2Tests/InfoSheetCopyTests.swift` | create | Every level has its sheet copy |
| `RaidCalculator2UITests/RaidCalculator2UITests.swift` | modify | Picker, groups and ZFS UI tests |

The project uses synchronized folders, so new `.swift` files in these folders are picked up without touching `project.pbxproj`.

## Execution order and models

Tasks run in order, because each `xcodebuild` needs the Simulator to itself. The one parallel lane is **Task 7a**: drafting copy and translations, with no build. It can start as soon as this plan is approved and run alongside Tasks 1–6.

| Task | Model | Depends on |
|---|---|---|
| 1. String tooling | sonnet | none |
| 2. Level metadata | sonnet | 1 |
| 3. Grouped calculator | sonnet | 2 |
| 4. ZFS estimate | sonnet | 2 (wired in by Task 3’s follow-up step) |
| 5. View model | sonnet | 3, 4 |
| 6. RAID tab UI and motion | opus | 5 |
| 7a. Draft info-sheet copy (en, es, fr, it, ja) | opus | none (parallel) |
| 7b. Apply copy and the sheet section | sonnet | 6, 7a |
| 8. Full verification | sonnet | all |

Reviews: opus for Tasks 6 and 7, sonnet for the rest, and an opus whole-branch review at the end.

> **Note on Task 3 and 4 order:** Task 4 creates `ZFSEstimate` and Task 3 uses it. Run **Task 4 before Task 3** (2 → 4 → 3). The numbering follows the spec’s order, not execution order.

---

### Task 1: String tooling and CI check

**Files:**
- Create: `scripts/strings.py`
- Modify: `.github/workflows/ios.yml` (add a step before “Build and test on the iOS simulator”)
- Modify (normalize only): `RaidCalculator2/Localizable.xcstrings`

**Interfaces:**
- Produces:
  - `python3 scripts/strings.py add <file.json>`, where the JSON is `{"key": {"en": "…", "es": "…", "fr": "…", "it": "…", "ja": "…"}}`.
  - `python3 scripts/strings.py remove <key>…`
  - `python3 scripts/strings.py check`: exit 0 when clean, exit 1 with one line per problem.
  - `STRINGS_CATALOG=<path>` overrides the catalog path, for testing.

- [ ] **Step 1: Write the script**

```python
#!/usr/bin/env python3
"""Add, remove and check strings in RaidCalculator2/Localizable.xcstrings.

  scripts/strings.py add new-strings.json   # {"key": {"en": "…", "es": "…", …}}
  scripts/strings.py remove key [key …]
  scripts/strings.py check                   # all five languages, matching specifiers

Never hand-edit the catalog JSON; Xcode and this script both rewrite it.
"""
import json
import os
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = pathlib.Path(os.environ.get("STRINGS_CATALOG", ROOT / "RaidCalculator2" / "Localizable.xcstrings"))
LANGS = ["en", "es", "fr", "it", "ja"]
# printf-style specifiers as Foundation uses them; %% is a literal percent.
SPEC = re.compile(r"%(?:(\d+)\$)?[-+ 0#]*\d*(?:\.\d+)?(ld|lu|lld|[dif@sucxX])")


def load():
    return json.loads(CATALOG.read_text(encoding="utf-8"))


def save(doc):
    text = json.dumps(doc, ensure_ascii=False, indent=2, sort_keys=True, separators=(",", " : "))
    CATALOG.write_text(text + "\n", encoding="utf-8")


def specifiers(value):
    """Specifier types in argument order, so %1$@ %2$d and %@ %d compare equal."""
    found = []
    for index, match in enumerate(SPEC.finditer(value.replace("%%", ""))):
        position = int(match.group(1)) if match.group(1) else index + 1
        found.append((position, match.group(2)))
    return sorted(found)


def add(path):
    new = json.loads(pathlib.Path(path).read_text(encoding="utf-8"))
    doc = load()
    for key, values in new.items():
        missing = [lang for lang in LANGS if not values.get(lang)]
        if missing:
            sys.exit(f"{key}: missing {', '.join(missing)}")
        doc["strings"][key] = {
            "extractionState": "manual",
            "localizations": {
                lang: {"stringUnit": {"state": "translated", "value": values[lang]}} for lang in LANGS
            },
        }
    save(doc)
    print(f"added {len(new)} key(s)")


def remove(keys):
    doc = load()
    for key in keys:
        if doc["strings"].pop(key, None) is None:
            sys.exit(f"{key}: not in catalog")
    save(doc)
    print(f"removed {len(keys)} key(s)")


def check():
    problems = []
    for key, entry in load()["strings"].items():
        localizations = entry.get("localizations")
        if not localizations or entry.get("shouldTranslate") is False:
            continue  # auto-extracted literals with no translations, such as "TB"
        english = localizations.get("en", {}).get("stringUnit", {}).get("value")
        if english is None:
            problems.append(f"{key}: no English value")
            continue
        for lang in LANGS:
            unit = localizations.get(lang, {}).get("stringUnit", {})
            if unit.get("state") != "translated" or not unit.get("value"):
                problems.append(f"{key}: {lang} missing or untranslated")
            elif specifiers(unit["value"]) != specifiers(english):
                problems.append(f"{key}: {lang} specifiers {specifiers(unit['value'])} ≠ en {specifiers(english)}")
    for line in problems:
        print(line)
    print(f"{len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    command, args = (sys.argv[1], sys.argv[2:]) if len(sys.argv) > 1 else ("", [])
    if command == "add" and len(args) == 1:
        add(args[0])
    elif command == "remove" and args:
        remove(args)
    elif command == "check" and not args:
        sys.exit(check())
    else:
        sys.exit(__doc__)
```

- [ ] **Step 2: Run the check against the real catalog**

Run: `python3 scripts/strings.py check`
Expected: `0 problem(s)`, exit 0. If it reports problems, they are real gaps in the shipped catalog. Report them in your task summary, and don’t fix them in this task.

- [ ] **Step 3: Prove the check fails on a broken catalog**

```bash
cp RaidCalculator2/Localizable.xcstrings /tmp/broken.xcstrings
python3 - <<'EOF'
import json
p = "/tmp/broken.xcstrings"; d = json.load(open(p))
d["strings"]["use_drive_count"]["localizations"]["ja"]["stringUnit"]["value"] = "ドライブを使用"  # drops %d
del d["strings"]["done"]["localizations"]["fr"]
json.dump(d, open(p, "w"), ensure_ascii=False)
EOF
STRINGS_CATALOG=/tmp/broken.xcstrings python3 scripts/strings.py check; echo "exit=$?"
```

Expected: two problem lines (`use_drive_count: ja specifiers …` and `done: fr missing or untranslated`), then `exit=1`.

- [ ] **Step 4: Add the CI step**

In `.github/workflows/ios.yml`, insert immediately before the step named `Build and test on the iOS simulator`:

```yaml
      - name: Check localized strings
        run: python3 scripts/strings.py check
```

Run: `actionlint .github/workflows/ios.yml`
Expected: no output.

- [ ] **Step 5: Normalize the catalog once**

Run a build so Xcode applies its own formatting, then check it:

```bash
xcodebuild build -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" -destination "$DEST" -quiet
python3 scripts/strings.py check
git diff --stat RaidCalculator2/Localizable.xcstrings
```

Expected: the check passes. The diff is reordering plus the auto-extracted keys, which have no translations. Committing that now keeps later diffs readable.

- [ ] **Step 6: Commit**

```bash
git add scripts/strings.py .github/workflows/ios.yml RaidCalculator2/Localizable.xcstrings
git commit -m "Add string catalog tooling and a CI check for all five languages" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Level metadata

**Files:**
- Modify: `RaidCalculator2/Models.swift`
- Test: `RaidCalculator2Tests/ModelTests.swift` (create)

**Interfaces:**
- Produces:
  - `enum RaidFamily: CaseIterable { case standard, nested, zfs }`
  - New `RaidLevel` cases: `.raid50 = "R 50"`, `.raid60 = "R 60"`, `.raidz1 = "Z1"`, `.raidz2 = "Z2"` and `.raidz3 = "Z3"`.
  - `RaidLevel.family: RaidFamily`
  - `static func levels(in: RaidFamily) -> [RaidLevel]`
  - `parityPerGroup: Int?`
  - `usesGroups: Bool`
  - `minimumGroupWidth: Int`
  - `minimumGroups: Int`
  - `isZFS: Bool`
  - `singleGroupEquivalent: RaidLevel?` (RAID 50 → RAID 5, RAID 60 → RAID 6)
  - `RaidConfiguration.groups: Int = 1`, the last stored property, so existing initializer calls still compile.
  - `RaidResult` is unchanged here. Task 4 adds `zfsEstimate`, and Task 3 adds `groupSize` and `suggestedGroups`.

- [ ] **Step 1: Write the failing tests**

```swift
//
//  ModelTests.swift
//  RaidCalculator2Tests
//

import Testing
@testable import RAID_Calc

struct ModelTests {

    @Test func persistedRawValuesNeverChange() {
        #expect(RaidLevel.raid0.rawValue == "R 0")
        #expect(RaidLevel.raid10.rawValue == "R 10")
        #expect(RaidLevel.jbod.rawValue == "JBOD")
        #expect(RaidLevel.raid50.rawValue == "R 50")
        #expect(RaidLevel.raid60.rawValue == "R 60")
        #expect(RaidLevel.raidz1.rawValue == "Z1")
        #expect(RaidLevel.raidz2.rawValue == "Z2")
        #expect(RaidLevel.raidz3.rawValue == "Z3")
    }

    @Test func familiesKeepTheSegmentedLevelsInOrder() {
        #expect(RaidLevel.levels(in: .standard) == [.raid0, .raid1, .raid5, .raid6, .raid10, .jbod])
        #expect(RaidLevel.levels(in: .nested) == [.raid50, .raid60])
        #expect(RaidLevel.levels(in: .zfs) == [.raidz1, .raidz2, .raidz3])
    }

    @Test func groupRules() {
        #expect(RaidLevel.raid50.parityPerGroup == 1)
        #expect(RaidLevel.raid60.parityPerGroup == 2)
        #expect(RaidLevel.raidz1.parityPerGroup == 1)
        #expect(RaidLevel.raidz2.parityPerGroup == 2)
        #expect(RaidLevel.raidz3.parityPerGroup == 3)
        #expect(RaidLevel.raid5.parityPerGroup == nil)
        #expect(RaidLevel.raid5.usesGroups == false)
        #expect(RaidLevel.raid60.usesGroups)

        #expect(RaidLevel.raid50.minimumGroupWidth == 3)
        #expect(RaidLevel.raid60.minimumGroupWidth == 4)
        #expect(RaidLevel.raidz1.minimumGroupWidth == 2)
        #expect(RaidLevel.raidz2.minimumGroupWidth == 3)
        #expect(RaidLevel.raidz3.minimumGroupWidth == 4)

        #expect(RaidLevel.raid50.minimumGroups == 2)
        #expect(RaidLevel.raid60.minimumGroups == 2)
        #expect(RaidLevel.raidz2.minimumGroups == 1)

        #expect(RaidLevel.raid50.singleGroupEquivalent == .raid5)
        #expect(RaidLevel.raid60.singleGroupEquivalent == .raid6)
        #expect(RaidLevel.raidz1.singleGroupEquivalent == nil)

        #expect(RaidLevel.raidz2.isZFS)
        #expect(!RaidLevel.raid60.isZFS)
    }

    @Test func namesAndKeys() {
        #expect(RaidLevel.raid50.displayName == "RAID 50")
        #expect(RaidLevel.raidz2.displayName == "RAID-Z2")
        #expect(RaidLevel.raidz3.shortLabel == "Z3")
        #expect(RaidLevel.raid60.stringKeyPrefix == "raid60")
        #expect(RaidLevel.raidz1.stringKeyPrefix == "raidz1")
    }

    @Test func configurationDefaultsToOneGroup() {
        let config = RaidConfiguration(level: .raid5, driveCount: 4, driveSize: 4, unit: .tb)
        #expect(config.groups == 1)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test … -only-testing:"RAID CalcTests/ModelTests"`
Expected: build FAILS (`type 'RaidLevel' has no member 'raid50'`).

- [ ] **Step 3: Implement**

Replace the `RaidLevel` enum and `RaidConfiguration` in `Models.swift` with the following. Leave `DriveRole`, `CapacityUnit` and `RaidResult` alone; Task 3 changes `RaidResult`.

```swift
/// Which part of the level picker a level lives in. The segmented control shows
/// the standard levels; the rest sit in a sectioned menu beside it.
enum RaidFamily: CaseIterable {
    case standard
    case nested
    case zfs
}

enum RaidLevel: String, CaseIterable, Identifiable {
    case raid0 = "R 0"
    case raid1 = "R 1"
    case raid5 = "R 5"
    case raid6 = "R 6"
    case raid10 = "R 10"
    case jbod = "JBOD"
    case raid50 = "R 50"
    case raid60 = "R 60"
    case raidz1 = "Z1"
    case raidz2 = "Z2"
    case raidz3 = "Z3"

    var id: String { rawValue }

    /// Full name for headings, VoiceOver and the info sheet. The raw value stays
    /// "R 5" etc. because it's what UserDefaults has persisted since 1.0.
    var displayName: String {
        switch self {
        case .raid0: "RAID 0"
        case .raid1: "RAID 1"
        case .raid5: "RAID 5"
        case .raid6: "RAID 6"
        case .raid10: "RAID 10"
        case .jbod: "JBOD"
        case .raid50: "RAID 50"
        case .raid60: "RAID 60"
        case .raidz1: "RAID-Z1"
        case .raidz2: "RAID-Z2"
        case .raidz3: "RAID-Z3"
        }
    }

    /// Segment label. The section header already says “RAID Level”, so the
    /// numerals alone are enough and six of them fit on the narrowest iPhone.
    var shortLabel: String {
        switch self {
        case .raid0: "0"
        case .raid1: "1"
        case .raid5: "5"
        case .raid6: "6"
        case .raid10: "10"
        case .jbod: "JBOD"
        case .raid50: "50"
        case .raid60: "60"
        case .raidz1: "Z1"
        case .raidz2: "Z2"
        case .raidz3: "Z3"
        }
    }

    /// Prefix for this level's keys in Localizable.xcstrings (raid5_description…).
    var stringKeyPrefix: String {
        switch self {
        case .raid0: "raid0"
        case .raid1: "raid1"
        case .raid5: "raid5"
        case .raid6: "raid6"
        case .raid10: "raid10"
        case .jbod: "jbod"
        case .raid50: "raid50"
        case .raid60: "raid60"
        case .raidz1: "raidz1"
        case .raidz2: "raidz2"
        case .raidz3: "raidz3"
        }
    }

    var family: RaidFamily {
        switch self {
        case .raid0, .raid1, .raid5, .raid6, .raid10, .jbod: .standard
        case .raid50, .raid60: .nested
        case .raidz1, .raidz2, .raidz3: .zfs
        }
    }

    /// Levels in a family, in picker order.
    static func levels(in family: RaidFamily) -> [RaidLevel] {
        allCases.filter { $0.family == family }
    }

    var isZFS: Bool { family == .zfs }

    /// Parity drives in each group, for the levels built from striped groups;
    /// nil for the standard levels, which have no Groups input.
    var parityPerGroup: Int? {
        switch self {
        case .raid50, .raidz1: 1
        case .raid60, .raidz2: 2
        case .raidz3: 3
        default: nil
        }
    }

    var usesGroups: Bool { parityPerGroup != nil }

    /// Fewest drives one group can have.
    var minimumGroupWidth: Int {
        switch self {
        case .raid50: 3
        case .raid60: 4
        case .raidz1: 2
        case .raidz2: 3
        case .raidz3: 4
        default: 1
        }
    }

    /// RAID 50 and 60 need two groups; with one they're just RAID 5 and 6.
    /// A single RAID-Z group is a normal pool.
    var minimumGroups: Int {
        switch self {
        case .raid50, .raid60: 2
        default: 1
        }
    }

    /// What a nested level is when it has only one group.
    var singleGroupEquivalent: RaidLevel? {
        switch self {
        case .raid50: .raid5
        case .raid60: .raid6
        default: nil
        }
    }
}
```

```swift
struct RaidConfiguration {
    var level: RaidLevel
    var driveCount: Int
    var driveSize: Double
    var unit: CapacityUnit
    /// Striped groups for RAID 50/60 and RAID-Z; ignored by the standard levels.
    var groups: Int = 1
}
```

Adding cases makes the `switch`es in `RaidCalculator.swift` non-exhaustive. To keep this task compiling, add a temporary branch to each of the four `switch config.level` / `switch level` statements in `RaidCalculator.swift`:
- `suggestedDriveCount`: `case .raid50, .raid60, .raidz1, .raidz2, .raidz3: return nil`
- `invalidDriveCountKey`: `case .raid50, .raid60, .raidz1, .raidz2, .raidz3: return nil`
- `calculate`: `case .raid50, .raid60, .raidz1, .raidz2, .raidz3: usable = 0; failures = "0"; roles = []`
- the ratings: `case .raid50, .raid60, .raidz1, .raidz2, .raidz3: return 3`

Task 3 replaces every one of them. Mark each with `// Task 3 replaces this.`

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test … -only-testing:"RAID CalcTests"`
Expected: PASS, including every existing `RaidCalculator2Tests` test.

- [ ] **Step 5: Commit**

```bash
git add RaidCalculator2/Models.swift RaidCalculator2/RaidCalculator.swift RaidCalculator2Tests/ModelTests.swift
git commit -m "Add RAID 50/60 and RAID-Z level metadata and a groups setting" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: ZFS estimate (run before Task 3)

**Files:**
- Create: `RaidCalculator2/ZFSEstimate.swift`
- Test: `RaidCalculator2Tests/ZFSEstimateTests.swift` (create)

**Interfaces:**
- Produces: `struct ZFSEstimate: Equatable` with:
  - `init(groups: Int, width: Int, parity: Int, driveBytes: Double)`
  - `let dataFraction: Double`
  - `let reportedBytes: Double`
  - `let paddingLoss: Double`
  - `static func allocatedSectors(width: Int, parity: Int) -> Int`

- [ ] **Step 1: Write the failing tests**

```swift
//
//  ZFSEstimateTests.swift
//  RaidCalculator2Tests
//

import Testing
@testable import RAID_Calc

struct ZFSEstimateTests {

    private let tebibyte = 1_099_511_627_776.0

    @Test func allocationPadding() {
        // 128K record = 32 data sectors; parity per row; round up to a multiple of parity + 1.
        #expect(ZFSEstimate.allocatedSectors(width: 6, parity: 2) == 48)  // 32 + 16, already a multiple of 3
        #expect(ZFSEstimate.allocatedSectors(width: 7, parity: 2) == 48)  // 32 + 14 = 46 → 48
        #expect(ZFSEstimate.allocatedSectors(width: 4, parity: 1) == 44)  // 32 + 11 = 43 → 44
        #expect(ZFSEstimate.allocatedSectors(width: 2, parity: 1) == 64)  // 32 + 32
    }

    @Test func widthSixRaidZ2HasNoPaddingLoss() {
        let estimate = ZFSEstimate(groups: 1, width: 6, parity: 2, driveBytes: 16e12)
        #expect(abs(estimate.dataFraction - 4.0 / 6.0) < 1e-12)
        #expect(estimate.paddingLoss < 1e-9)
    }

    @Test func widthSevenRaidZ2LosesSpaceToPadding() {
        let estimate = ZFSEstimate(groups: 1, width: 7, parity: 2, driveBytes: 16e12)
        #expect(abs(estimate.dataFraction - 2.0 / 3.0) < 1e-12)
        #expect(abs(estimate.paddingLoss - (1 - (2.0 / 3.0) / (5.0 / 7.0))) < 1e-9)  // ≈ 6.7%
    }

    @Test func largePoolSlopIsCappedAt128GiB() {
        // RAID-Z2, 6 × 16 TB: 64 TB of data = 58.21 TiB, minus 128 GiB.
        let estimate = ZFSEstimate(groups: 1, width: 6, parity: 2, driveBytes: 16e12)
        #expect(abs(estimate.reportedBytes / tebibyte - 58.0827) < 0.001)
    }

    @Test func smallPoolSlopIsOneThirtySecond() {
        // RAID-Z1, 3 × 2 TB: 4 TB of data; 1/32 of it is under the cap.
        let estimate = ZFSEstimate(groups: 1, width: 3, parity: 1, driveBytes: 2e12)
        #expect(abs(estimate.reportedBytes / tebibyte - 3.5243) < 0.001)
    }

    @Test func groupsMultiplyCapacity() {
        let one = ZFSEstimate(groups: 1, width: 6, parity: 2, driveBytes: 4e12)
        let two = ZFSEstimate(groups: 2, width: 6, parity: 2, driveBytes: 4e12)
        #expect(two.dataFraction == one.dataFraction)
        #expect(two.reportedBytes > one.reportedBytes * 1.9)
    }

    // Review Focus 5
    @Test func raidZ1AtMinimumWidth() {
        let estimate = ZFSEstimate(groups: 1, width: 2, parity: 1, driveBytes: 4e12)
        #expect(abs(estimate.dataFraction - 0.5) < 1e-12)
        #expect(estimate.paddingLoss < 1e-9)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test … -only-testing:"RAID CalcTests/ZFSEstimateTests"`
Expected: build FAILS (`cannot find 'ZFSEstimate' in scope`).

- [ ] **Step 3: Implement**

```swift
//
//  ZFSEstimate.swift
//  RaidCalculator2
//

import Foundation

/// What ZFS will report as usable for a RAID-Z pool, for OpenZFS defaults:
/// 4K sectors (ashift=12) and 128K records.
///
/// Two effects make it lower than the textbook (width − parity) × drives:
/// - RAID-Z rounds every allocation up to a multiple of parity + 1 sectors, so
///   some group widths waste a slice of each record (padding).
/// - ZFS holds back slop space: 1/32 of the pool, at most 128 GiB and at
///   least 128 MiB. Verified against `spa_get_slop_space()` in OpenZFS
///   2.1.0–2.4.4 (module/zfs/spa_misc.c) on 2026-10-02. The embedded-log
///   space it subtracts is also excluded from the pool's free space, so the two
///   cancel and aren't modeled.
struct ZFSEstimate: Equatable {
    /// Share of raw space that holds data once parity and padding are counted.
    let dataFraction: Double
    /// Bytes ZFS reports as usable: data space minus slop space.
    let reportedBytes: Double
    /// Space lost to padding, as a share of the textbook usable space; 0 when none.
    let paddingLoss: Double

    static let sectorsPerRecord = 32                       // 128K record ÷ 4K sectors
    static let maxSlopBytes = 128.0 * 1_073_741_824        // 128 GiB
    static let minSlopBytes = 128.0 * 1_048_576            // 128 MiB

    /// Sectors one 128K record occupies in a group of `width` drives.
    static func allocatedSectors(width: Int, parity: Int) -> Int {
        let dataPerRow = width - parity
        let rows = (sectorsPerRecord + dataPerRow - 1) / dataPerRow
        let total = sectorsPerRecord + parity * rows
        let multiple = parity + 1
        return (total + multiple - 1) / multiple * multiple
    }

    init(groups: Int, width: Int, parity: Int, driveBytes: Double) {
        let allocated = Self.allocatedSectors(width: width, parity: parity)
        dataFraction = Double(Self.sectorsPerRecord) / Double(allocated)

        let dataBytes = Double(groups * width) * driveBytes * dataFraction
        let slop = max(min(dataBytes / 32, Self.maxSlopBytes), min(dataBytes / 2, Self.minSlopBytes))
        reportedBytes = max(0, dataBytes - slop)

        let textbookFraction = Double(width - parity) / Double(width)
        paddingLoss = max(0, 1 - dataFraction / textbookFraction)
    }
}
```

Then add the field this task owns to `RaidResult` in `Models.swift`, after `driveRoles`:

```swift
    /// What ZFS will report, for the RAID-Z levels; nil otherwise or when invalid.
    var zfsEstimate: ZFSEstimate? = nil
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test … -only-testing:"RAID CalcTests"`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add RaidCalculator2/ZFSEstimate.swift RaidCalculator2/Models.swift RaidCalculator2Tests/ZFSEstimateTests.swift
git commit -m "Model what ZFS reports: RAID-Z padding and capped slop space" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Grouped calculator

**Files:**
- Modify: `RaidCalculator2/Models.swift` (`RaidResult` fields)
- Modify: `RaidCalculator2/RaidCalculator.swift`
- Modify via script: `RaidCalculator2/Localizable.xcstrings`
- Test: `RaidCalculator2Tests/GroupedLevelTests.swift` (create)

**Interfaces:**
- Consumes: Task 2’s `RaidLevel` group rules and `RaidConfiguration.groups`; Task 4’s `ZFSEstimate`.
- Produces:
  - `RaidResult.groupSize: Int?`: drives per group, set only when the level uses groups, has more than one group and is valid.
  - `RaidResult.suggestedGroups: Int?`
  - `RaidResult.zfsEstimate` filled for valid RAID-Z.
  - `static let driveCountRange = 1...24` on `RaidCalculator`.
  - `func rebuildCautionSuggestion(for: RaidConfiguration) -> RaidLevel?`
  - `func wideZFSGroupWidth(for: RaidConfiguration) -> Int?`: the group width when it’s over 12, else nil.
- New string keys:
  - `groups_uneven`
  - `group_too_narrow`
  - `nested_needs_two_groups`
  - `grouped_failures`

- [ ] **Step 1: Add the strings**

Create `/tmp/task3-strings.json` with real translations in all five languages. The English values are fixed. Translate the others in the tone of the existing catalog: check `raid10_failures` and `raid10_validation` in each language. Keep every positional specifier.

```json
{
  "groups_uneven": {
    "en": "%1$d drives don’t divide evenly into %2$d groups.",
    "es": "…", "fr": "…", "it": "…", "ja": "…"
  },
  "group_too_narrow": {
    "en": "Each %1$@ group needs at least %2$d drives.",
    "es": "…", "fr": "…", "it": "…", "ja": "…"
  },
  "nested_needs_two_groups": {
    "en": "%1$@ needs at least two groups. With one group, it’s %2$@.",
    "es": "…", "fr": "…", "it": "…", "ja": "…"
  },
  "grouped_failures": {
    "en": "%1$d, up to %2$d (depends on which drives fail)",
    "es": "…", "fr": "…", "it": "…", "ja": "…"
  }
}
```

The `…` above are for you to replace with the translation; `strings.py add` rejects an empty value but not a literal `…`, so check by eye. Then:

Run: `python3 scripts/strings.py add /tmp/task3-strings.json && python3 scripts/strings.py check`
Expected: `added 4 key(s)`, then `0 problem(s)`.

- [ ] **Step 2: Write the failing tests**

```swift
//
//  GroupedLevelTests.swift
//  RaidCalculator2Tests
//

import Testing
@testable import RAID_Calc

struct GroupedLevelTests {

    let calculator = RaidCalculator()

    private func result(_ level: RaidLevel, drives: Int, size: Double = 8, unit: CapacityUnit = .tb, groups: Int) -> RaidResult {
        calculator.calculate(config: RaidConfiguration(level: level, driveCount: drives, driveSize: size, unit: unit, groups: groups))
    }

    @Test func raid50ThreeGroups() {
        let r = result(.raid50, drives: 12, groups: 3)
        #expect(r.warningMessage == nil)
        #expect(r.usableCapacity == 72)
        #expect(r.failuresTolerated == "1, up to 3 (depends on which drives fail)")
        #expect(r.groupSize == 4)
        #expect(r.driveRoles == Array(repeating: [.data, .data, .data, .parity], count: 3).flatMap { $0 })
        #expect(r.speedRating == 4)
        #expect(r.availabilityRating == 3)
        #expect(r.zfsEstimate == nil)
    }

    @Test func raid60TwoGroups() {
        let r = result(.raid60, drives: 12, groups: 2)
        #expect(r.warningMessage == nil)
        #expect(r.usableCapacity == 64)
        #expect(r.failuresTolerated == "2, up to 4 (depends on which drives fail)")
        #expect(r.groupSize == 6)
        #expect(r.speedRating == 3)
        #expect(r.availabilityRating == 4)
    }

    @Test func unevenGroupsOfferBothFixes() {
        let r = result(.raid60, drives: 12, groups: 5)
        #expect(r.warningMessage == "12 drives don’t divide evenly into 5 groups.")
        #expect(r.suggestedDriveCount == 20)    // 5 groups × the 4-drive minimum
        #expect(r.suggestedGroups == 3)         // valid: 2 (width 6) or 3 (width 4); 3 is nearer 5
        #expect(r.driveRoles.count == 12)       // one bar per drive even when invalid
        #expect(r.groupSize == nil)
    }

    @Test func nestedLevelNeedsTwoGroups() {
        let r = result(.raid50, drives: 6, groups: 1)
        #expect(r.warningMessage == "RAID 50 needs at least two groups. With one group, it’s RAID 5.")
        #expect(r.suggestedGroups == 2)
        #expect(r.suggestedDriveCount == 6)     // already enough drives; the UI hides a no-op fix
    }

    @Test func groupTooNarrow() {
        let r = result(.raidz2, drives: 6, groups: 3)
        #expect(r.warningMessage == "Each RAID-Z2 group needs at least 3 drives.")
        #expect(r.suggestedGroups == 2)
        #expect(r.suggestedDriveCount == 9)
    }

    @Test func singleRaidZGroup() {
        let r = result(.raidz1, drives: 4, groups: 1)
        #expect(r.warningMessage == nil)
        #expect(r.usableCapacity == 24)
        #expect(r.failuresTolerated == "1")
        #expect(r.groupSize == nil)
        #expect(r.zfsEstimate != nil)
        #expect(r.speedRating == 3)
        #expect(r.availabilityRating == 3)
    }

    @Test func raidZ3Ratings() {
        let r = result(.raidz3, drives: 8, groups: 1)
        #expect(r.failuresTolerated == "3")
        #expect(r.usableCapacity == 40)
        #expect(r.speedRating == 2)
        #expect(r.availabilityRating == 5)
    }

    @Test func zfsEstimateMatchesWorkedExample() {
        let r = result(.raidz2, drives: 6, size: 16, groups: 1)
        let reported = try! #require(r.zfsEstimate).reportedBytes / 1_099_511_627_776
        #expect(abs(reported - 58.0827) < 0.001)
    }

    @Test func noEstimateWhenInvalid() {
        #expect(result(.raidz2, drives: 6, groups: 3).zfsEstimate == nil)
    }

    @Test func rebuildCautionSuggestsDualParity() {
        func caution(_ level: RaidLevel, size: Double, groups: Int = 1, drives: Int = 8) -> RaidLevel? {
            calculator.rebuildCautionSuggestion(for: RaidConfiguration(level: level, driveCount: drives, driveSize: size, unit: .tb, groups: groups))
        }
        #expect(caution(.raid5, size: 8) == .raid6)
        #expect(caution(.raid50, size: 8, groups: 2) == .raid60)
        #expect(caution(.raidz1, size: 10) == .raidz2)
        #expect(caution(.raid5, size: 4) == nil)
        #expect(caution(.raidz2, size: 20) == nil)
        #expect(caution(.raid50, size: 8, groups: 1) == nil)   // invalid configurations get no caution
    }

    @Test func wideRaidZGroup() {
        func width(_ drives: Int, groups: Int, level: RaidLevel = .raidz2) -> Int? {
            calculator.wideZFSGroupWidth(for: RaidConfiguration(level: level, driveCount: drives, driveSize: 8, unit: .tb, groups: groups))
        }
        #expect(width(14, groups: 1) == 14)
        #expect(width(12, groups: 1) == nil)
        #expect(width(24, groups: 2) == nil)
        #expect(width(14, groups: 1, level: .raid60) == nil)
    }

    // Review Focus 1
    @Test func driveCountChangeLeavesUnevenGroupsWithFixes() {
        let r = result(.raidz2, drives: 10, groups: 3)
        #expect(r.warningMessage == "10 drives don’t divide evenly into 3 groups.")
        #expect(r.suggestedDriveCount == 12)
        #expect(r.suggestedGroups == 2)
    }

    // Review Focus 1
    @Test func zeroGroupsIsTreatedAsOne() {
        let r = result(.raidz1, drives: 4, groups: 0)
        #expect(r.warningMessage == nil)
        #expect(r.usableCapacity == 24)
    }

    // Review Focus 2
    @Test func standardLevelsIgnoreGroups() {
        let grouped = result(.raid5, drives: 6, groups: 3)
        let plain = result(.raid5, drives: 6, groups: 1)
        #expect(grouped.usableCapacity == plain.usableCapacity)
        #expect(grouped.warningMessage == nil)
        #expect(grouped.groupSize == nil)
        #expect(grouped.suggestedGroups == nil)
    }

    // Review Focus 3
    @Test func zfsEstimateInGigabytes() {
        let tb = result(.raidz2, drives: 6, size: 16, unit: .tb, groups: 1)
        let gb = result(.raidz2, drives: 6, size: 16_000, unit: .gb, groups: 1)
        #expect(abs(try! #require(gb.zfsEstimate).reportedBytes - (try! #require(tb.zfsEstimate)).reportedBytes) < 1)
    }

    // Review Focus 4
    @Test func fixesNeverExceedTwentyFourDrives() {
        let r = result(.raidz3, drives: 24, groups: 7)
        #expect(r.suggestedDriveCount == nil)   // 7 × 4 = 28 is over the limit
        #expect(r.suggestedGroups == 6)         // divisors of 24 with 4+ drives each: 1, 2, 3, 4, 6
    }
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `xcodebuild test … -only-testing:"RAID CalcTests/GroupedLevelTests"`
Expected: build FAILS with `value of type 'RaidResult' has no member 'groupSize'` (and `suggestedGroups`). The `groups:` argument already compiles, since Task 2 added it.

- [ ] **Step 4: Add the result fields**

In `Models.swift`, add to `RaidResult` after `driveRoles` and before `zfsEstimate`:

```swift
    var groupSize: Int? = nil       // drives per group, for gaps in the strip; nil unless grouped and valid
    var suggestedGroups: Int? = nil // a group count that makes the current drive count valid
```

- [ ] **Step 5: Implement in `RaidCalculator.swift`**

Replace the whole `RaidCalculator` struct with this. It keeps every existing behavior and replaces Task 2’s placeholder branches.

```swift
struct RaidCalculator {

    static let driveCountRange = 1...24

    func validate(_ config: RaidConfiguration) -> String? {
        if let message = groupedValidationMessage(config) {
            return message
        }
        if let count = invalidDriveCountKey(config) {
            return count.localized()
        }
        if !(config.driveSize > 0) {
            return "drive_size_invalid".localized()
        }
        return nil
    }

    /// Smallest valid drive count at or above the current one, when the count is
    /// what makes the configuration invalid. Drives the one-tap fix.
    func suggestedDriveCount(for config: RaidConfiguration) -> Int? {
        let n = config.driveCount
        if config.level.usesGroups {
            guard groupedValidationMessage(config) != nil else { return nil }
            let groups = max(groupCount(config), config.level.minimumGroups)
            let perGroup = max(config.level.minimumGroupWidth, (n + groups - 1) / groups)
            let count = groups * perGroup
            return count <= Self.driveCountRange.upperBound ? count : nil
        }
        guard invalidDriveCountKey(config) != nil else { return nil }
        switch config.level {
        case .raid0, .jbod: return max(n, 1)
        case .raid1: return max(n, 2)
        case .raid5: return max(n, 3)
        case .raid6: return max(n, 4)
        case .raid10: return max(n + n % 2, 4)
        case .raid50, .raid60, .raidz1, .raidz2, .raidz3: return nil
        }
    }

    /// The valid group count for the current drive count nearest the current
    /// one (ties go to fewer, wider groups). Drives the “Use N groups” fix.
    func suggestedGroups(for config: RaidConfiguration) -> Int? {
        guard config.level.usesGroups, groupedValidationMessage(config) != nil else { return nil }
        let n = config.driveCount
        let current = groupCount(config)
        let candidates = (config.level.minimumGroups...max(config.level.minimumGroups, n)).filter {
            n % $0 == 0 && n / $0 >= config.level.minimumGroupWidth
        }
        let best = candidates.min { (abs($0 - current), $0) < (abs($1 - current), $1) }
        return best == current ? nil : best
    }

    /// Single-parity layouts on drives of 8 TB or more: a rebuild takes days,
    /// and a second failure during it loses the array. Returns the dual-parity
    /// level to suggest instead.
    func rebuildCautionSuggestion(for config: RaidConfiguration) -> RaidLevel? {
        guard validate(config) == nil else { return nil }
        let terabytes = config.unit == .tb ? config.driveSize : config.driveSize / 1000
        guard terabytes >= 8 else { return nil }
        switch config.level {
        case .raid5: return .raid6
        case .raid50: return .raid60
        case .raidz1: return .raidz2
        default: return nil
        }
    }

    /// Group width when a RAID-Z group is wider than 12 drives, which rebuilds slowly.
    func wideZFSGroupWidth(for config: RaidConfiguration) -> Int? {
        guard config.level.isZFS, validate(config) == nil else { return nil }
        let width = config.driveCount / groupCount(config)
        return width > 12 ? width : nil
    }

    private func groupCount(_ config: RaidConfiguration) -> Int { max(config.groups, 1) }

    private func groupedValidationMessage(_ config: RaidConfiguration) -> String? {
        let level = config.level
        guard level.usesGroups else { return nil }
        let n = config.driveCount
        let groups = groupCount(config)
        if groups < level.minimumGroups, let single = level.singleGroupEquivalent {
            return String(format: "nested_needs_two_groups".localized(), level.displayName, single.displayName)
        }
        if n % groups != 0 {
            return String(format: "groups_uneven".localized(), n, groups)
        }
        if n / groups < level.minimumGroupWidth {
            return String(format: "group_too_narrow".localized(), level.displayName, level.minimumGroupWidth)
        }
        return nil
    }

    private func invalidDriveCountKey(_ config: RaidConfiguration) -> String? {
        let n = config.driveCount
        switch config.level {
        case .raid0: return n < 1 ? "raid0_validation" : nil
        case .raid1: return n < 2 ? "raid1_validation" : nil
        case .raid5: return n < 3 ? "raid5_validation" : nil
        case .raid6: return n < 4 ? "raid6_validation" : nil
        case .raid10: return n < 4 || n % 2 != 0 ? "raid10_validation" : nil
        case .jbod: return n < 1 ? "jbod_validation" : nil
        case .raid50, .raid60, .raidz1, .raidz2, .raidz3: return nil
        }
    }

    func calculate(config: RaidConfiguration) -> RaidResult {
        let n = config.driveCount
        let size = config.driveSize  // assume already in chosen unit
        let warning = validate(config)

        var usable: Double
        var failures: String
        var roles: [DriveRole]
        var groupSize: Int?
        var zfsEstimate: ZFSEstimate?

        switch config.level {
        case .raid0:
            usable = Double(n) * size
            failures = "raid0_failures".localized()
            roles = Array(repeating: .data, count: n)
        case .raid1:
            usable = size
            failures = String(format: "raid1_failures".localized(), max(0, n - 1))
            roles = [.data] + Array(repeating: .mirror, count: max(0, n - 1))
        case .raid5:
            usable = Double(max(0, n - 1)) * size
            failures = "raid5_failures".localized()
            roles = Array(repeating: .data, count: max(0, n - 1)) + [.parity]
        case .raid6:
            usable = Double(max(0, n - 2)) * size
            failures = "raid6_failures".localized()
            roles = Array(repeating: .data, count: max(0, n - 2)) + Array(repeating: .parity, count: min(2, n))
        case .raid10:
            usable = Double(n / 2) * size
            failures = String(format: "raid10_failures".localized(), n / 2)
            // Mirrored pairs, striped: data, copy, data, copy…
            roles = (0..<n).map { $0.isMultiple(of: 2) ? .data : .mirror }
        case .jbod:
            usable = Double(n) * size
            failures = "jbod_failures".localized()
            roles = Array(repeating: .data, count: n)
        case .raid50, .raid60, .raidz1, .raidz2, .raidz3:
            let parity = config.level.parityPerGroup ?? 1
            let groups = groupCount(config)
            let width = n / groups
            usable = Double(groups * max(0, width - parity)) * size
            failures = groups > 1
                ? String(format: "grouped_failures".localized(), parity, groups * parity)
                : String(parity)
            // Each group's data drives, then its parity: data, data, parity | data, data, parity…
            roles = (0..<groups).flatMap { _ in
                Array(repeating: DriveRole.data, count: max(0, width - parity)) + Array(repeating: .parity, count: min(parity, width))
            }
            if warning == nil {
                if groups > 1 { groupSize = width }
                if config.level.isZFS {
                    let bytesPerUnit = config.unit == .tb ? 1e12 : 1e9
                    zfsEstimate = ZFSEstimate(groups: groups, width: width, parity: parity, driveBytes: size * bytesPerUnit)
                }
            }
        }

        // One bar per drive even when the drives don't divide into groups.
        if roles.count < n { roles += Array(repeating: .data, count: n - roles.count) }

        return RaidResult(
            usableCapacity: usable,
            rawCapacity: Double(n) * size,
            failuresTolerated: failures,
            speedRating: speedRating(for: config.level),
            availabilityRating: availabilityRating(for: config.level),
            warningMessage: warning,
            suggestedDriveCount: suggestedDriveCount(for: config),
            driveRoles: Array(roles.prefix(n)),
            groupSize: groupSize,
            suggestedGroups: suggestedGroups(for: config),
            zfsEstimate: zfsEstimate
        )
    }

    func speedRating(for level: RaidLevel) -> Int {
        switch level {
        case .raid0: return 5
        case .raid10, .raid50: return 4
        case .raid5, .raid60, .raidz1: return 3
        case .raid6, .raid1, .jbod, .raidz2, .raidz3: return 2
        }
    }

    func availabilityRating(for level: RaidLevel) -> Int {
        switch level {
        case .raid0, .jbod: return 1
        case .raid5, .raid50, .raidz1: return 3
        case .raid6, .raid60, .raidz2: return 4
        case .raid1, .raid10, .raidz3: return 5
        }
    }

    /// Word for a 1–5 rating, shared by the results and the info sheet.
    static func ratingLabel(_ rating: Int) -> String {
        switch rating {
        case 5: return "very_high".localized()
        case 4: return "high".localized()
        case 3: return "medium".localized()
        case 2: return "low".localized()
        case 1: return "very_low".localized()
        default: return ""
        }
    }
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `xcodebuild test … -only-testing:"RAID CalcTests"`
Expected: PASS: `GroupedLevelTests`, `ZFSEstimateTests`, `ModelTests` and every existing `RaidCalculator2Tests` test.

- [ ] **Step 7: Commit**

```bash
python3 scripts/strings.py check
git add RaidCalculator2/Models.swift RaidCalculator2/RaidCalculator.swift RaidCalculator2/Localizable.xcstrings RaidCalculator2Tests/GroupedLevelTests.swift
git commit -m "Calculate RAID 50/60 and RAID-Z groups, with fixes, cautions and the ZFS estimate" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: View model

**Files:**
- Modify: `RaidCalculator2/RaidCalculatorViewModel.swift`

**Interfaces:**
- Consumes: Task 3’s `RaidCalculator.driveCountRange`, `rebuildCautionSuggestion(for:)`, `wideZFSGroupWidth(for:)` and `RaidResult.suggestedGroups`.
- Produces, on `RaidCalculatorViewModel`:
  - `var groups: Int`: persisted under the key `"groups"`, clamped to `1...24`, and loaded as 1 when missing or 0.
  - `var rebuildCautionSuggestion: RaidLevel?`, replacing `showsRebuildCaution`.
  - `var wideZFSGroupWidth: Int?`
  - `func applySuggestedGroups()`
  - `static let driveCountRange` now aliases `RaidCalculator.driveCountRange`.

There are no unit tests for the view model: it writes to `UserDefaults.standard`. Task 6’s UI tests cover it, launching with `-groups`. The logic it exposes is Task 3’s, which is already tested.

- [ ] **Step 1: Implement**

In `RaidCalculatorViewModel.swift`:

1. Replace `static let driveCountRange = 1...24` with `static let driveCountRange = RaidCalculator.driveCountRange`.
2. After `var unit…`, add:

```swift
    /// Striped groups for RAID 50/60 and RAID-Z. Kept when switching to a
    /// standard level, which ignores it, so switching back restores the layout.
    var groups: Int = 1 {
        didSet {
            let clamped = min(max(groups, 1), Self.driveCountRange.upperBound)
            if clamped != groups { groups = clamped } else { saveConfiguration() }
        }
    }
```

3. In `result`, pass `groups: groups` to `RaidConfiguration`. Factor the configuration into a computed property so the cautions use the same one:

```swift
    private var configuration: RaidConfiguration {
        RaidConfiguration(level: selectedLevel, driveCount: driveCount, driveSize: driveSize, unit: unit, groups: groups)
    }

    /// Recomputed whenever an input changes; Observation tracks the reads.
    var result: RaidResult { calculator.calculate(config: configuration) }
```

4. Replace `showsRebuildCaution` with:

```swift
    /// Single parity on drives of 8 TB or more; the dual-parity level to suggest.
    var rebuildCautionSuggestion: RaidLevel? { calculator.rebuildCautionSuggestion(for: configuration) }

    /// Width of a RAID-Z group wider than 12 drives; nil otherwise.
    var wideZFSGroupWidth: Int? { calculator.wideZFSGroupWidth(for: configuration) }
```

5. Add `static let groups = "groups"` to `Keys`. In `saveConfiguration()`, add `userDefaults.set(groups, forKey: Keys.groups)`. In `loadConfiguration()`, after the unit:

```swift
        groups = userDefaults.integer(forKey: Keys.groups)
        if groups == 0 { groups = 1 }
```

6. After `applySuggestedDriveCount()`, add:

```swift
    func applySuggestedGroups() {
        if let suggested = result.suggestedGroups {
            groups = suggested
        }
    }
```

- [ ] **Step 2: Build and run the unit tests**

Run: `xcodebuild test … -only-testing:"RAID CalcTests"`
Expected: build FAILS only in `ContentView.swift` (`value of type 'RaidCalculatorViewModel' has no member 'showsRebuildCaution'`). Fix the one call site with the minimal change below, which Task 6 replaces. Then rerun and expect PASS.

```swift
            } else if let safer = viewModel.rebuildCautionSuggestion {
                Section {
                    Label {
                        Text(String(format: "rebuild_caution_level".localized(), viewModel.selectedLevel.displayName, safer.displayName))
                            .font(.subheadline)
```

`rebuild_caution_level` is added in Task 6, Step 1. Do that string step now, before this rerun: add the key using Task 6, Step 1’s JSON with only that key, so the build shows real text.

- [ ] **Step 3: Run the existing UI tests that touch the RAID tab**

Run: `xcodebuild test … -only-testing:"RAID CalcUITests"`
Expected: PASS. Persistence and the existing flows are unchanged.

- [ ] **Step 4: Commit**

```bash
python3 scripts/strings.py check
git add RaidCalculator2/RaidCalculatorViewModel.swift RaidCalculator2/ContentView.swift RaidCalculator2/Localizable.xcstrings
git commit -m "Persist groups and expose grouped fixes and cautions in the view model" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: RAID tab UI and motion

**Files:**
- Modify: `RaidCalculator2/ContentView.swift`
- Modify via script: `RaidCalculator2/Localizable.xcstrings`
- Test: `RaidCalculator2UITests/RaidCalculator2UITests.swift`

**Interfaces:**
- Consumes: Task 5’s view model API; `RaidResult.groupSize`, `suggestedGroups` and `zfsEstimate`.
- Produces:
  - `DriveStrip(roles:groupSize:)`
  - `CapacitySummary.binaryBytes(_:unit:) -> String`
  - Accessibility identifiers `moreLevels`, `groupCount`, `applySuggestedGroups`, `zfsReportedNote` and `wideGroupCaution`.

- [ ] **Step 1: Add the strings**

`/tmp/task6-strings.json`. English is fixed; translate the rest as in Task 3. Base `rebuild_caution_level` on each language’s existing `rebuild_caution`.

```json
{
  "more_levels": { "en": "More Levels" },
  "nested_levels": { "en": "Nested" },
  "zfs_levels": { "en": "ZFS" },
  "groups": { "en": "Groups" },
  "group_layout": { "en": "%1$d groups of %2$d drives" },
  "group_layout_single": { "en": "One group of %d drives" },
  "use_group_count": { "en": "Use %d groups" },
  "use_one_group": { "en": "Use one group" },
  "zfs_reported_note": { "en": "≈ %@ as ZFS reports it (estimate)" },
  "zfs_padding_note": { "en": "This group width loses about %@ more to RAID-Z padding." },
  "wide_zfs_group_caution": { "en": "Each RAID-Z group is %d drives wide. Very wide groups take a long time to rebuild after a failure; more, narrower groups rebuild faster." },
  "rebuild_caution_level": { "en": "Rebuilding %1$@ on drives this large can take days, and a second failure during the rebuild loses the array. Consider %2$@." },
  "drive_strip_groups_accessibility": { "en": "%1$d drives in %2$d groups: %3$@" }
}
```

Each entry needs `es`, `fr`, `it` and `ja` too: the script rejects missing ones. If Task 5 already added `rebuild_caution_level`, leave it out of this file. Then remove the old key, which nothing uses after this task:

Run: `python3 scripts/strings.py add /tmp/task6-strings.json && python3 scripts/strings.py remove rebuild_caution && python3 scripts/strings.py check`
Expected: keys added, 1 key removed, `0 problem(s)`.

- [ ] **Step 2: Write the failing UI tests**

In `RaidCalculator2UITests.swift`, give `launchApp` a groups argument, defaulting to 1, so existing tests are unchanged. Add `groups: Int = 1` to the parameter list, and `"-groups", "\(groups)",` after the `-driveSize` pair. Then add:

```swift
    /// Nested levels live in the More Levels menu; RAID 60 needs two groups,
    /// and the one-tap fix applies them.
    @MainActor
    func testNestedLevelFromMenu() throws {
        let app = launchApp(drives: 12)
        let menu = app.buttons["moreLevels"]
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        app.buttons["RAID 60"].tap()

        XCTAssertTrue(app.staticTexts["configurationWarning"].exists || app.otherElements["configurationWarning"].exists)
        let fix = app.buttons["applySuggestedGroups"]
        XCTAssertTrue(fix.waitForExistence(timeout: 2))
        fix.tap()

        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 32 TB,"), capacity(app))  // 2 groups of 6 × 4 TB, 2 parity each
        XCTAssertEqual(app.staticTexts["groupCount"].label.components(separatedBy: ", ").last, "2")
    }

    /// Choosing a standard level again from the segmented control clears the
    /// menu's selection and drops the Groups row.
    @MainActor
    func testStandardLevelHidesGroups() throws {
        let app = launchApp(level: "R 60", drives: 12, groups: 2)
        XCTAssertTrue(app.staticTexts["groupCount"].waitForExistence(timeout: 5))
        app.segmentedControls.firstMatch.buttons.element(boundBy: 2).tap()  // RAID 5
        XCTAssertFalse(app.staticTexts["groupCount"].exists)
        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 44 TB,"), capacity(app))
    }

    /// RAID-Z shows what ZFS will report, labeled as an estimate.
    @MainActor
    func testZFSEstimateShown() throws {
        let app = launchApp(level: "Z2", drives: 6)
        let note = app.staticTexts["zfsReportedNote"]
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        XCTAssertTrue(note.label.contains("as ZFS reports it (estimate)"), note.label)
    }

    /// A RAID-Z group wider than 12 drives gets the slow-rebuild caution.
    @MainActor
    func testWideRaidZGroupCaution() throws {
        let app = launchApp(level: "Z2", drives: 14)
        XCTAssertTrue(app.staticTexts["wideGroupCaution"].waitForExistence(timeout: 5))
    }
```

Run: `xcodebuild test … -only-testing:"RAID CalcUITests/RaidCalculator2UITests/testNestedLevelFromMenu"` (and the other three).
Expected: FAIL (`moreLevels`, `groupCount`, `zfsReportedNote` and `wideGroupCaution` don’t exist).

- [ ] **Step 3: Implement the picker, the Groups row and the fixes**

In `ContentView`:

1. Add `@Environment(\.accessibilityReduceMotion) private var reduceMotion` to the view’s properties.
2. Replace the `Section("raid_level"…)` block with:

```swift
            Section("raid_level".localized()) {
                Picker("raid_level".localized(), selection: standardLevelSelection) {
                    ForEach(RaidLevel.levels(in: .standard)) { level in
                        Text(level.shortLabel)
                            .accessibilityLabel(level.displayName)
                            .tag(Optional(level))
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Menu {
                    Section("nested_levels".localized()) {
                        ForEach(RaidLevel.levels(in: .nested)) { levelButton($0) }
                    }
                    Section("zfs_levels".localized()) {
                        ForEach(RaidLevel.levels(in: .zfs)) { levelButton($0) }
                    }
                } label: {
                    LabeledContent("more_levels".localized()) {
                        HStack(spacing: 6) {
                            if viewModel.selectedLevel.family != .standard {
                                Text(viewModel.selectedLevel.displayName)
                                    .foregroundStyle(.tint)
                            }
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .tint(.primary)
                .accessibilityIdentifier("moreLevels")
            }
```

3. Add these helpers to `ContentView`:

```swift
    /// The segmented control shows only the standard levels; with a nested or
    /// ZFS level chosen, nothing in it is highlighted.
    private var standardLevelSelection: Binding<RaidLevel?> {
        Binding(
            get: { viewModel.selectedLevel.family == .standard ? viewModel.selectedLevel : nil },
            set: { if let level = $0 { withAnimation(motion) { viewModel.selectedLevel = level } } }
        )
    }

    private func levelButton(_ level: RaidLevel) -> some View {
        Button {
            withAnimation(motion) { viewModel.selectedLevel = level }
        } label: {
            if viewModel.selectedLevel == level {
                Label(level.displayName, systemImage: "checkmark")
            } else {
                Text(level.displayName)
            }
        }
    }

    /// Movement for layout changes; a plain fade when Reduce Motion is on.
    private var motion: Animation { reduceMotion ? .easeInOut(duration: 0.2) : .snappy }
```

4. In `Section("drive_configuration"…)`, directly after the drive-count `Stepper`, add:

```swift
                if viewModel.selectedLevel.usesGroups {
                    Stepper(value: Binding(
                        get: { viewModel.groups },
                        set: { value in withAnimation(motion) { viewModel.groups = value } }
                    ), in: 1...max(1, viewModel.driveCount)) {
                        LabeledContent("groups".localized()) {
                            Text(viewModel.groups, format: .number)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .accessibilityIdentifier("groupCount")
                        }
                    }
                    .sensoryFeedback(.selection, trigger: viewModel.groups)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                }
```

5. Add a footer to that `Section` describing the layout when it’s valid. Change `Section("drive_configuration".localized()) {` to `Section {`. Then append, after the section’s content braces:

```swift
            } header: {
                Text("drive_configuration".localized())
            } footer: {
                if viewModel.selectedLevel.usesGroups, viewModel.result.warningMessage == nil {
                    let groups = max(viewModel.groups, 1)
                    let width = viewModel.driveCount / groups
                    Text(groups == 1
                         ? String(format: "group_layout_single".localized(), width)
                         : String(format: "group_layout".localized(), groups, width))
                }
            }
```

6. In the warning `Section`, after the existing `applySuggestedDriveCount` button, add:

```swift
                    if let suggested = result.suggestedGroups, suggested != viewModel.groups {
                        Button(suggested == 1 ? "use_one_group".localized() : String(format: "use_group_count".localized(), suggested)) {
                            withAnimation(motion) { viewModel.applySuggestedGroups() }
                        }
                        .accessibilityIdentifier("applySuggestedGroups")
                    }
```

Wrap the existing drive-count fix’s action in `withAnimation(motion)` too: replace `withAnimation {` with `withAnimation(motion) {`. Add `.sensoryFeedback(.success, trigger: result.warningMessage == nil) { wasValid, isValid in !wasValid && isValid }` to the `Form`, so the success haptic fires only when a setup becomes valid, never when it breaks.

7. Replace the `} else if let safer = viewModel.rebuildCautionSuggestion {` block from Task 5 with one that shows both cautions:

```swift
            } else if viewModel.rebuildCautionSuggestion != nil || viewModel.wideZFSGroupWidth != nil {
                Section {
                    if let safer = viewModel.rebuildCautionSuggestion {
                        caution(String(format: "rebuild_caution_level".localized(), viewModel.selectedLevel.displayName, safer.displayName))
                    }
                    if let width = viewModel.wideZFSGroupWidth {
                        caution(String(format: "wide_zfs_group_caution".localized(), width))
                            .accessibilityIdentifier("wideGroupCaution")
                    }
                }
                .transition(.opacity)
            }
```

Add this helper:

```swift
    private func caution(_ text: String) -> some View {
        Label {
            Text(text)
                .font(.subheadline)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .symbolRenderingMode(.multicolor)
        }
    }
```

The `accessibilityIdentifier` on a `Label` exposes it as a static text in XCUITest. If `app.staticTexts["wideGroupCaution"]` doesn’t match, apply the identifier to the inner `Text`. To do that, give `caution` an `identifier: String? = nil` parameter, set inside on the `Text`.

- [ ] **Step 4: Implement group gaps and the ZFS note**

1. In `CapacitySummary.body`, pass the group size: `DriveStrip(roles: result.driveRoles, groupSize: result.groupSize)`.
2. Replace the binary note block (`if isValid, result.usableCapacity > 0 { … }`) with:

```swift
            if isValid, result.usableCapacity > 0 {
                if let estimate = result.zfsEstimate {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "zfs_reported_note".localized(), Self.binaryBytes(estimate.reportedBytes, unit: unit)))
                            .accessibilityIdentifier("zfsReportedNote")
                        if estimate.paddingLoss > 0.01 {
                            Text(String(format: "zfs_padding_note".localized(), estimate.paddingLoss.formatted(.percent.precision(.fractionLength(0)))))
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                } else {
                    Text(String(format: "binary_capacity_note".localized(), Self.binaryCapacity(result.usableCapacity, unit: unit)))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
```

3. Add this next to `binaryCapacity`:

```swift
    /// A byte count in the binary unit matching the chosen decimal one.
    static func binaryBytes(_ bytes: Double, unit: CapacityUnit) -> String {
        switch unit {
        case .tb: capacity(bytes / 1_099_511_627_776, unit: "TiB", maxFractionDigits: 1)
        case .gb: capacity(bytes / 1_073_741_824, unit: "GiB", maxFractionDigits: 1)
        }
    }
```

4. Replace `DriveStrip` with the grouped version below. Bars sit in per-group stacks; the gaps open and close with `.snappy` when groups change, and as a fade under Reduce Motion.

```swift
/// One bar per physical drive, showing which hold data and which hold
/// redundancy. Mirrors are outlined rather than filled, so the distinction
/// doesn't rest on colour alone. Grouped levels show a wider gap between
/// groups, so a change of groups visibly regroups the same drives.
struct DriveStrip: View {
    let roles: [DriveRole]
    var groupSize: Int? = nil
    @ScaledMetric(relativeTo: .body) private var barHeight: CGFloat = 26
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var barSpacing: CGFloat { roles.count > 12 ? 3 : 5 }

    /// Drive indices per group; one group when the level isn't grouped.
    private var groups: [Range<Int>] {
        guard let size = groupSize, size > 0, roles.count > size else { return [roles.indices] }
        return stride(from: 0, to: roles.count, by: size).map { $0..<min($0 + size, roles.count) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: groups.count > 1 ? barSpacing * 3 : barSpacing) {
                ForEach(groups, id: \.lowerBound) { group in
                    HStack(spacing: barSpacing) {
                        ForEach(group, id: \.self) { index in
                            bar(for: roles[index])
                                .frame(maxWidth: 44)
                                .frame(height: barHeight)
                        }
                    }
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy, value: roles)
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy, value: groupSize)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) { legend }
                VStack(alignment: .leading, spacing: 4) { legend }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var presentRoles: [DriveRole] {
        [.data, .parity, .mirror].filter(roles.contains)
    }

    @ViewBuilder
    private var legend: some View {
        ForEach(presentRoles, id: \.self) { role in
            HStack(spacing: 5) {
                bar(for: role)
                    .frame(width: 10, height: 10)
                Text(Self.name(of: role))
            }
        }
    }

    @ViewBuilder
    private func bar(for role: DriveRole) -> some View {
        let shape = RoundedRectangle(cornerRadius: 4, style: .continuous)
        switch role {
        case .data:
            shape.fill(Color.accentColor)
        case .parity:
            shape.fill(Color.indigo)
        case .mirror:
            shape.fill(Color.accentColor.opacity(0.22))
                .overlay(shape.strokeBorder(Color.accentColor, lineWidth: 1.5))
        }
    }

    private var accessibilitySummary: String {
        let parts = presentRoles.map { role in
            String(format: "role_count".localized(), roles.filter { $0 == role }.count, Self.name(of: role))
        }.joined(separator: ", ")
        if groups.count > 1 {
            return String(format: "drive_strip_groups_accessibility".localized(), roles.count, groups.count, parts)
        }
        return String(format: "drive_strip_accessibility".localized(), roles.count, parts)
    }

    static func name(of role: DriveRole) -> String {
        switch role {
        case .data: "role_data".localized()
        case .parity: "role_parity".localized()
        case .mirror: "role_mirror".localized()
        }
    }
}
```

- [ ] **Step 5: Run the UI tests to verify they pass**

Run: `xcodebuild test … -only-testing:"RAID CalcUITests"`
Expected: PASS, including the four new tests and every existing one (`testRaidLevelSelection` still taps segments 0 and 1).

- [ ] **Step 6: Check it by eye in the Simulator**

Boot the iPhone 17 simulator with the app. For each check, capture `xcrun simctl io booted screenshot /tmp/raid-<name>.png`.
1. RAID 60, 12 drives, 2 groups.
2. RAID-Z2, 7 drives: the padding note is visible.
3. RAID-Z1, 6 × 10 TB: the rebuild caution names RAID-Z2.
4. Dark mode: `xcrun simctl ui booted appearance dark`.
5. Large text: `xcrun simctl ui booted content_size extra-extra-extra-large`. Nothing truncates; the More Levels row wraps.
6. Reduce Motion on (Settings → Accessibility → Motion). Changing groups fades instead of sliding.

Attach the six screenshot paths to the task report.

- [ ] **Step 7: Commit**

```bash
python3 scripts/strings.py check
git add RaidCalculator2/ContentView.swift RaidCalculator2/Localizable.xcstrings RaidCalculator2UITests/RaidCalculator2UITests.swift
git commit -m "Add the nested/ZFS level menu, Groups, grouped drive strip and ZFS estimate to the RAID tab" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7a: Draft info-sheet copy (parallel; no build)

**Files:**
- Create: `/tmp/task7-strings.json` (not committed; Task 7b applies it)

**Interfaces:**
- Produces: a `strings.py add` JSON covering these keys:
  - `raid50_`, `raid60_`, `raidz1_`, `raidz2_` and `raidz3_` + `description`, `pros`, `cons` and `use_cases` (20 keys)
  - `raidz1_calculation`, `raidz2_calculation` and `raidz3_calculation`
  - `how_calculated`

  Each key needs all five languages.

The English is fixed. Translate to Spanish, French, Italian and Japanese in the tone of the existing `raid5_*` and `raid6_*` copy for each language. Read those first with:

```bash
python3 -c "import json; d=json.load(open('RaidCalculator2/Localizable.xcstrings'))['strings']; [print(k, lang, repr(d[k]['localizations'][lang]['stringUnit']['value'])) for k in ['raid5_description','raid5_pros','raid6_cons','raid10_use_cases'] for lang in ['es','fr','it','ja']]"
```

Rules:
- `pros`, `cons` and `use_cases` are one item per line, joined with `\n`, with no trailing punctuation, matching the existing keys.
- Use smart punctuation in every language: French uses « » only if the existing French copy does, so check it.
- Keep “RAID-Z1”, “ZFS”, “TrueNAS”, “Proxmox”, “GiB” and “TB” untranslated.

- [ ] **Step 1: Write the JSON with these English values**

| Key | English |
|---|---|
| `how_calculated` | How the App Calculates This |
| `raid50_description` | RAID 50 stripes data across two or more RAID 5 groups. Each group keeps one drive’s worth of parity, so it’s faster than a single RAID 5 array, and a rebuild only touches one group. |
| `raid50_pros` | Faster than RAID 5, because writes spread across groups\nA rebuild only reads the drives in one group\nCan survive one failure in every group |
| `raid50_cons` | Two failures in the same group lose the whole array\nNeeds at least six drives\nGives up one drive per group to parity |
| `raid50_use_cases` | Large arrays that need more speed than RAID 5\nDatabases and virtual machines on many drives\nHardware RAID controllers that support nested levels |
| `raid60_description` | RAID 60 stripes data across two or more RAID 6 groups. Each group keeps two drives’ worth of parity, so any two drives can fail, and often more. |
| `raid60_pros` | Survives any two drive failures, and up to two per group\nFaster than a single RAID 6 array\nA rebuild only reads the drives in one group |
| `raid60_cons` | Gives up two drives per group to parity\nNeeds at least eight drives\nSlower writes than RAID 50 |
| `raid60_use_cases` | Large arrays where losing data isn’t an option\nBackup and archive servers with many big drives\nHardware RAID controllers that support nested levels |
| `raidz1_description` | RAID-Z1 is ZFS’s single-parity layout, similar to RAID 5. A pool can stripe several RAID-Z1 groups together. |
| `raidz1_pros` | Checksums detect and repair silent corruption\nNo RAID 5 write hole, because ZFS never overwrites data in place\nThe most usable space of the RAID-Z levels |
| `raidz1_cons` | Survives only one failure per group\nRisky with large drives, because rebuilds take a long time\nUses more memory than hardware RAID |
| `raidz1_use_cases` | Small home servers with a few drives\nMedia libraries that are backed up elsewhere\nTrueNAS, Proxmox and other ZFS systems |
| `raidz2_description` | RAID-Z2 is ZFS’s dual-parity layout, similar to RAID 6. Any two drives in a group can fail. |
| `raidz2_pros` | Survives any two failures per group\nChecksums detect and repair silent corruption\nThe common choice for large home pools |
| `raidz2_cons` | Gives up two drives per group to parity\nSome group widths lose extra space to padding\nUses more memory than hardware RAID |
| `raidz2_use_cases` | Home and small-office pools of 6 to 12 drives\nPhoto and document archives\nTrueNAS, Proxmox and other ZFS systems |
| `raidz3_description` | RAID-Z3 is ZFS’s triple-parity layout. Any three drives in a group can fail, which suits very wide groups of very large drives. |
| `raidz3_pros` | Survives any three failures per group\nThe safest choice for wide groups of large drives\nChecksums detect and repair silent corruption |
| `raidz3_cons` | Gives up three drives per group to parity\nThe slowest of the RAID-Z levels\nNeeds at least four drives per group |
| `raidz3_use_cases` | Very wide groups, where rebuilds take days\nLong-term archives\nLarge pools of 18 TB and bigger drives |
| `raidz1_calculation`, `raidz2_calculation`, `raidz3_calculation` (same text) | Usable space is shown two ways. The first figure is the simple formula: drives minus parity, in each group. The second estimates what ZFS will report for default settings (4K sectors and 128K records). It subtracts RAID-Z allocation padding, which makes some group widths less efficient than others, and the space ZFS holds back: 1/32 of the pool, at most 128 GiB. Compression, record size and sector size change the real number, and a little on-disk metadata isn’t counted. |

- [ ] **Step 2: Validate the draft without touching the catalog**

```bash
cp RaidCalculator2/Localizable.xcstrings /tmp/catalog-copy.xcstrings
STRINGS_CATALOG=/tmp/catalog-copy.xcstrings python3 scripts/strings.py add /tmp/task7-strings.json
STRINGS_CATALOG=/tmp/catalog-copy.xcstrings python3 scripts/strings.py check
```

Expected: `added 24 key(s)`, `0 problem(s)`. If Task 1 hasn’t landed yet, keep the JSON and validate once `scripts/strings.py` exists.

There’s no commit; hand `/tmp/task7-strings.json` to Task 7b.

---

### Task 7b: Apply the copy and the “How the app calculates this” section

**Files:**
- Modify via script: `RaidCalculator2/Localizable.xcstrings`
- Modify: `RaidCalculator2/RaidInfoSheet.swift`
- Test: `RaidCalculator2Tests/InfoSheetCopyTests.swift` (create)
- Test: `RaidCalculator2UITests/RaidCalculator2UITests.swift`

**Interfaces:**
- Consumes: `/tmp/task7-strings.json` from Task 7a.
- Produces: `RaidInfoSheet` shows a `how_calculated` section whenever `<prefix>_calculation` exists. Plan 2 generalizes this sheet for the NAS tab.

- [ ] **Step 1: Write the failing unit test**

```swift
//
//  InfoSheetCopyTests.swift
//  RaidCalculator2Tests
//

import Testing
@testable import RAID_Calc

struct InfoSheetCopyTests {

    @Test(arguments: RaidLevel.allCases)
    func everyLevelHasItsSheetCopy(level: RaidLevel) {
        for field in ["description", "pros", "cons", "use_cases"] {
            let key = "\(level.stringKeyPrefix)_\(field)"
            #expect(key.localized() != key, "missing \(key)")
        }
    }

    @Test(arguments: RaidLevel.levels(in: .zfs))
    func zfsLevelsExplainTheEstimate(level: RaidLevel) {
        let key = "\(level.stringKeyPrefix)_calculation"
        #expect(key.localized().contains("128 GiB"), "missing or wrong \(key)")
    }
}
```

Run: `xcodebuild test … -only-testing:"RAID CalcTests/InfoSheetCopyTests"`
Expected: FAIL for the five new levels.

- [ ] **Step 2: Apply the copy**

Run: `python3 scripts/strings.py add /tmp/task7-strings.json && python3 scripts/strings.py check`
Expected: `added 24 key(s)`, `0 problem(s)`.

Rerun the unit test. Expected: PASS.

- [ ] **Step 3: Add the optional section to `RaidInfoSheet`**

After the `typical_use_cases` section and before the ratings section, add:

```swift
                if let calculation = optionalText("calculation") {
                    Section("how_calculated".localized()) {
                        Text(calculation)
                            .accessibilityIdentifier("howCalculated")
                    }
                }
```

Then, after `lines(_:)`:

```swift
    /// Copy some levels have and others don't; nil when the key isn't in the catalog.
    private func optionalText(_ field: String) -> String? {
        let key = "\(level.stringKeyPrefix)_\(field)"
        let value = key.localized()
        return value == key ? nil : value
    }
```

- [ ] **Step 4: Write and run the UI test**

```swift
    /// RAID-Z's info sheet explains the estimate; RAID 5's has no such section.
    @MainActor
    func testRaidZInfoSheetExplainsEstimate() throws {
        let app = launchApp(level: "Z2", drives: 6)
        app.buttons["raidInfo"].tap()
        let section = app.staticTexts["howCalculated"]
        XCTAssertTrue(section.waitForExistence(timeout: 5))
        XCTAssertTrue(section.label.contains("128 GiB"), section.label)
    }
```

Run: `xcodebuild test … -only-testing:"RAID CalcUITests/RaidCalculator2UITests/testRaidZInfoSheetExplainsEstimate"`
Expected: PASS. If the text is below the fold, add `app.swipeUp()` before the assertion.

- [ ] **Step 5: Commit**

```bash
git add RaidCalculator2/Localizable.xcstrings RaidCalculator2/RaidInfoSheet.swift RaidCalculator2Tests/InfoSheetCopyTests.swift RaidCalculator2UITests/RaidCalculator2UITests.swift
git commit -m "Add info sheets for RAID 50/60 and RAID-Z, with how the ZFS estimate is calculated" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Full verification

**Files:** none changed unless a check fails.

- [ ] **Step 1: Strings**

Run: `python3 scripts/strings.py check`
Expected: `0 problem(s)`.

- [ ] **Step 2: The whole suite, as CI runs it**

Run: `xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" -destination "$DEST"`
Expected: `** TEST SUCCEEDED **`. Report the executed count from the `Executed N tests` line. Swift Testing counts each parameterized argument as its own case, so expect well over the previous 22.

- [ ] **Step 3: Japanese and Spanish by eye**

Launch with `-AppleLanguages (ja)`, then `(es)`, on RAID 60 with 12 drives and 2 groups, then on RAID-Z2 with 7 drives. Screenshot both. Check that nothing truncates and that specifiers render as numbers, never as `%1$d`.

- [ ] **Step 4: Report**

The summary lists:
- the screenshots from Task 6, Step 6 and this task
- the test count
- any catalog problems Task 1 found in the shipped strings

Don’t tag or release; plan 4 ships 1.5.0.
