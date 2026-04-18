# DriveByCurio — Technologies & Lessons

Patterns, gotchas, and workarounds discovered while building DriveByCurio. Lessons are tagged with the PR or context where they surfaced. Check here before implementing — these are the things that cost us time the first time around.

Modeled after `eno-ios/LIBRARIES.md`. Before adding a new section, use `context7` / `WebSearch` to verify against current docs.

---

## SwiftUI (iOS 26 / Swift 6)

### Navigation & presentation

- **`fullScreenCover(item:)` does NOT inherit `@Environment` from the presenter.** `fullScreenCover` creates a separate presentation tree, so any `@Environment(Service.self)` on the presented view will crash unless you re-inject on the cover. Pattern: `.fullScreenCover(item: $x) { item in PresentedView().environment(player) }`. [PR #7 — `TourOverviewView` → `SegmentPlayerView`]
- **Prefer `fullScreenCover(item:)` over `fullScreenCover(isPresented:) + if-let`.** The `isPresented + if-let` pattern has a race where SwiftUI can evaluate the body before `selectedItem` is set. Using `item:` guarantees a non-nil value at presentation time. [PR #7]
- **`NavigationStack` + `.navigationDestination(for:)`.** Value-based navigation (`NavigationLink(value:)` + `.navigationDestination(for: Type.self)`) is more reliable than `NavigationLink { DestinationView }` for destinations that might re-render mid-push. Use this pattern for any destination that uses `.ignoresSafeArea()` or has async-loaded content. [PR #7]

### Layout traps that cause blank screens on push

- **Don't apply `.ignoresSafeArea()` to a `ZStack` that contains a `ScrollView` + docked overlay.** It causes a layout-negotiation deadlock on `NavigationStack` push — the view collapses to zero height until a background/foreground cycle forces re-layout. Scope `.ignoresSafeArea()` to the specific background element (hero image, gradient) that needs edge-to-edge rendering. [PR #7 — `TourOverviewView`]
- **`GeometryReader` as a direct child of `ScrollView > VStack > ForEach` also causes layout deadlock / blank screen.** Fix: put the `GeometryReader` inside a `.background(alignment:)` on the row. That way the reader inherits an already-resolved size from the row's intrinsic content, instead of participating in the ForEach's layout negotiation. [PR #7 — `StopTimelineRow`]
- **Don't read `UIApplication.shared.connectedScenes` or `window.safeAreaInsets` during `body`.** Causes `AttributeGraph: cycle detected` when combined with `.ignoresSafeArea()`. Cache in `@State` from a UIKit callback. [eno-ios/lessons/ios26-layout, applies here too]

### Rendering & performance

- **Canvas stalls inside `fullScreenCover` on first presentation.** A `Canvas` view inside a `fullScreenCover` can Metal-stall during the cover's appear transition, leading to a blank sheet for 1–2 seconds. Replace with an `HStack` of `RoundedRectangle`s (or equivalent) when the canvas is decorative. The performance cost is negligible for <100 elements. [PR #7 — `WaveformView`]
- **Cache computed arrays in `init`, not as computed properties.** Computed `private var amplitudes: [Double]` on a SwiftUI `View` recomputes every body evaluation. For decorative per-item arrays that only change when inputs change, move the computation into `init(...)` and store in a `let` property. [PR #8 — `WaveformView`]
- **`@State` flag that forces a re-render after appear is a last resort.** If you're reaching for `.onAppear { refreshKey.toggle() }`, the underlying issue is usually layout-deadlock / stale GeometryReader. Fix the layout first.
- **`.overlay(alignment:)` hairline divider: use an explicit `frame(maxHeight: .infinity)`.** `Rectangle().fill(...).frame(width: 0.5)` on its own may not stretch vertically. Pattern: `.overlay(alignment: .leading) { Rectangle().fill(...).frame(width: 0.5).frame(maxHeight: .infinity) }`. [PR #8 — `TourFeedCard`]

### Observable state & concurrency

- **`@MainActor @Observable` services plus framework callbacks trigger `unsafeForcedSync` warnings at runtime.** AVPlayer time observers, CoreLocation delegates, and MKDirections completion handlers may fire on non-main queues. Wrap with `Task { @MainActor [weak self] in ... }` at the callback edge instead of relying on the Swift runtime's forced sync. The warning isn't fatal but it becomes a crash under stricter concurrency settings. [PR #7 — runtime warning investigation]
- **Guard Observable index-into-array reads.** `tour.sortedStops[player.currentStopIndex]` will crash if `sortedStops` is empty. Always `(0..<array.count).contains(index)` or `guard index < array.count` before subscripting, especially in SwiftUI computed properties where the input can race. [PR #8 — `DockedPlayerBanner`]

---

## MapKit

- **`MKMapSnapshotter` > embedded `MKMapView` for per-cell map inlays.** Embedding `MKMapView` in a feed cell (even via `UIViewRepresentable`) is expensive and can blank the list on scroll. Use `MKMapSnapshotter` to render a `UIImage` once, then overlay dots/polylines with `UIGraphicsImageRenderer` + `result.point(for:)`. Cache per stop-list signature. [PR #7 — `CompactStopMap`]
- **`MKMapSnapshotter.start()` returns `MKMapSnapshotter.Snapshot` (not a nested `.snapshot`).** The result *is* the snapshot — `result.image`, `result.point(for:)`. Don't access `result.snapshot.image`. [PR #7 — debugging the map inlay]
- **Hide map attribution on tiny inlays by clipping.** For decorative ≤200pt-tall map snapshots in feed cells, the Apple/legal attribution is visually distracting. Clip the bottom 20pt. This is fine for decorative use; if the map is interactive or primary, keep attribution. [PR #7]
- **`pointOfInterestFilter: .excludingAll`** on `MKMapSnapshotter.Options` for clean rendered maps without POI labels. [PR #7]

---

## Codable & data migration

- **Custom `Codable` conformance is the clean way to handle on-disk format migrations.** Our `WalkingTour.init(from:)` tries the new format first (decode `TourAuthor`), then falls back to the legacy flat-waypoint format (decode `creatorName` + `waypoints` array). Old user-saved tours keep loading without a schema-bump. Pattern: private `LegacyWaypoint` struct for the migration shape only. [PR #7 — `WalkingTour.swift`]
- **`decodeIfPresent` for optional new fields.** New fields on legacy records (e.g. `coverImageName`) should use `try container.decodeIfPresent(...)` so older JSON without the key still decodes.
- **Extract shared derivation logic into a static helper.** Our path-computation math lives in `WalkingTour.computePaths(from: [TourStop]) -> [TourPath]`; both the Codable migration and the tour-creation map editor call it. Avoids drift between duplicate implementations. [PR #8 — after review flagged duplication]

---

## XcodeGen / build

- **`xcodegen generate` before every build.** `DriveByCurio.xcodeproj` is gitignored and regenerated from `project.yml`. Any build setting change, target add, or source path change goes in `project.yml`.
- **Adding an XCTest target:** declare in `project.yml` with `type: bundle.unit-test`, `TEST_HOST: $(BUILT_PRODUCTS_DIR)/DriveByCurio.app/DriveByCurio`, and wire into the scheme via `schemes.DriveByCurio.test.targets`. `build.targets` must include the test target with `[test]` so it gets built for test runs. [PR #8]
- **Build to `/tmp/curio-build`.** iCloud Drive paths cause codesign failures during simulator builds (same issue as eno-ios). Never use the default `~/Library/Developer/Xcode/DerivedData`.
- **`UIRequiresFullScreen: true` in Info.plist is deprecated on iOS 26.** Xcode emits a build warning. The replacement is `UISceneSizeRestrictions` for UIKit or `.windowResizability(.contentSize)` for SwiftUI. See `eno-ios/lessons/ios26-layout.md`.

---

## Testing

- **XCTest target runs on a real simulator** (TEST_HOST points at the app), so test runs boot the simulator. For pure model tests, a ~30–60s boot cost is unavoidable but the tests themselves finish in <1s. No-TEST_HOST / logic-only bundles aren't supported on iOS in Xcode 16.
- **`@testable import DriveByCurio`** gives internal access to non-public types without marking everything `public`.
- **TDD for value-computing logic.** For each test, temporarily break the implementation to confirm the test actually exercises the behavior, then restore. Catches tests that accidentally pass because of an unrelated fallback. [PR #8]
- **Stale SourceKit diagnostics** ("Cannot find type X in scope") after edits are a frequent false-positive. Trust `xcodebuild`, not the inline diagnostics. Regenerating the project (`xcodegen generate`) usually clears them.

---

## AVFoundation / playback

- **`AVPlayer` time observers fire on the queue they were added to.** Store the observer token, remove it on cleanup, or you get zombie callbacks after the player is replaced.
- **`MPNowPlayingInfoCenter`** — set `MPMediaItemPropertyTitle`, `MPMediaItemPropertyArtist` (tour author name), `MPMediaItemPropertyAlbumTitle` (tour title), `MPNowPlayingInfoPropertyPlaybackRate`, `MPNowPlayingInfoPropertyElapsedPlaybackTime`, `MPMediaItemPropertyPlaybackDuration`. Update on play/pause/seek or the lock-screen controls go out of sync.
- **Background audio Info.plist key:** `UIBackgroundModes: [audio, location]`. Audio lets narration continue with the screen locked; location lets GPS keep triggering stops.

---

## Design tokens

- `TourTokens` (`Views/TourConsumption/TourTokens.swift`) holds the moss/ember/ink palette + spacing constants. Any new consumption-layer view should reuse these, not hardcode colors.
- iOS system greys (`.secondaryLabel`, `.tertiaryLabel`, `.separator`) remain the default for anything that isn't brand-colored — gives us free dark-mode and accessibility support.

---

## Cross-repo

When in doubt about SwiftUI / iOS 26 gotchas we've already solved, check:
- `eno-ios/LIBRARIES.md` — broader catalog of iOS 26 / SwiftUI / Swift 6 lessons from the sibling app
- `eno-ios/lessons/ios26-layout.md` — rotation, `onGeometryChange`, `UIRequiresFullScreen` deprecation
- `core-swift/docs/design-workflow/` — SwiftUI preview conventions every new screen must follow
