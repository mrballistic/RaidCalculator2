
## 1. Product Requirements Document (PRD)

### 1.1 Product overview

**Product name (working):** RAIDGauge (you can rename)
**Platform:** iOS, native (Swift / Xcode)
**Summary:**
A simple, visually polished iOS app that helps users understand RAID tradeoffs. The user selects:

* RAID level (0, 1, 5, 6, 10, JBOD)
* Number of drives
* Capacity per drive

The app calculates:

* **Usable storage capacity**
* **Number of drive failures tolerated**
* **Relative speed rating** (as stars)
* **Relative availability / resilience rating** (as stars)

The UI should feel like a modern iOS app: glassy cards, blur, SF Symbols, system typography.

---

### 1.2 Goals & non-goals

**Goals**

* Make RAID capacity and resiliency easy to understand for non-experts.
* Show a clear, immediate visual sense of tradeoffs: performance vs availability.
* Look and feel like a first-party iOS utility (glassmorphism, dynamic type, SF Symbols).
* Be usable in <10 seconds: open app → pick RAID → see answers.

**Non-goals (v1)**

* No actual disk / hardware management.
* No OS-level integration, no real RAID configuration.
* No complicated edge-case RAID modes (RAID 50, 60, etc.).
* No iCloud sync, multi-device state, or account system.

---

### 1.3 Target users & personas

**Persona 1 – Home Lab Tinkerer (“Alex”)**

* Self-hosts NAS, Plex, small clusters.
* Knows roughly what RAID is, but wants to sanity-check capacity and redundancy.

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

---

### 1.5 Functional requirements

**FR-1: RAID selection**

* The user can choose a RAID level from a set:
  `RAID 0, RAID 1, RAID 5, RAID 6, RAID 10, JBOD`.
* Selection control can be a segmented control or picker with icons.

**FR-2: Drive configuration input**

* User can select **number of drives**:

  * Integer, min 1, max (e.g.) 24 (configurable).
* User can input **drive size**:

  * Numeric value (e.g., 1, 2, 4, 8, 16).
  * Unit selection: GB / TB (simple Picker).
* Validation:

  * Show inline messaging if the RAID level requires a minimum drive count (e.g., RAID 5 ≥ 3 drives, RAID 6 ≥ 4, RAID 10 ≥ 4 and even).

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
  failures tolerated: up to `n / 2` in best case, but show something like
  “up to n/2 (depends on which drives fail)”.

**FR-4: Ratings (stars)**

Define fixed 1–5 ★ ratings, e.g.:

**Performance rating (example):**

* RAID 0: 5★
* RAID 10: 4★
* RAID 5: 3★
* RAID 6: 2★
* RAID 1: 2★
* JBOD: 2★ (sequential okay, but no striping)

**Availability rating (example):**

* RAID 0: 1★
* JBOD: 1★
* RAID 5: 3★
* RAID 6: 4★
* RAID 1: 5★
* RAID 10: 5★ (high redundancy)

**FR-5: Results presentation**

* A **“Results Card”** shows:

  * Usable capacity (e.g., “24 TB usable”).
  * Drive failures tolerated (e.g., “1 drive can fail safely”).
  * Speed rating (stars + label: “High”, “Medium”, etc.).
  * Availability rating (stars + label: “Very High”, etc.).
* If configuration is invalid for that RAID level:

  * Show an inline error card (e.g., “RAID 5 requires at least 3 drives”).

**FR-6: RAID info sheet**

* Tap on an “info” button (e.g., `i` icon) for the selected RAID:

  * Short description.
  * Pros & cons list.
  * Typical use cases.

**FR-7: Settings / defaults**

* Basic settings (optional for v1):

  * Default drive size (e.g., 4 TB).
  * Default units (GB/TB).
* Settings can be stored with `UserDefaults`.

---

### 1.6 Non-functional requirements

* **Performance:** Instant calculations; no noticeable lag.
* **Offline:** Fully functional offline.
* **Accessibility:** Support Dynamic Type & VoiceOver where possible.
* **Design:** Use system typography & SF Symbols; use native blur (`.thinMaterial`) for glass effects.
* **Supported iOS version:** e.g., iOS 17+ (can be adjusted).

---

### 1.7 Success metrics (soft, for you)

* You can answer “Which RAID should I choose?” rapidly while demoing.
* Friends / colleagues can understand RAID tradeoffs after playing with it for ~2 minutes.
* The app feels “at home” next to Apple’s own utilities.

---

### 1.8 Out of scope (v1)

* Multi-language support beyond English.
* Advanced RAID variants (50/60, ZFS RAID-Z, etc.).
* Cost calculations, power, IOPS estimates.
* iPad / macOS optimized layouts (could be later).

---

## 2. Technical Design Doc

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

---

### 2.9 Testing strategy

* **Unit tests:**

  * Verify capacity calculations for each RAID level with known inputs.
  * Verify invalid configs return appropriate warnings.
* **Snapshot or UI tests (optional):**

  * Simple check of main view loads without crash.
* **Manual testing:**

  * Edge cases: minimum drives, maximum drives, weird sizes (0.5 TB, etc.).

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

