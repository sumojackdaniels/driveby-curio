# Curated Tours — Milestone 1 Spec

> Status: implemented on `feature/curated-tours-mvp` (this branch).
> Predecessors: [`PRODUCT.md`](./PRODUCT.md), [`CARPLAY-CONSTRAINTS.md`](./CARPLAY-CONSTRAINTS.md).

## Goal

Get to the first end-to-end experience of DriveByCurio:

1. Open the app on the iOS Simulator.
2. Pick a curated tour from a list.
3. Drive that tour in the simulator via a GPX route.
4. Hear narrated stories trigger as the simulated vehicle approaches each waypoint.
5. Optionally see the same surface in the simulator's CarPlay window.

This is the milestone where DriveByCurio stops being a spec and starts being a thing JD can play with. It is intentionally narrow:

- **One tour**, hand-authored, real geography (Bethesda → Farragut Square down Connecticut Avenue).
- **Pre-synthesized audio** (ElevenLabs), committed to the repo and shipped in the docker image. No runtime TTS.
- **Mode 1 only** (curated tours). Live mode (Mode 2) is left in place as legacy code but is not surfaced and will be redesigned later.
- **No passenger QR**, **no Apple Maps handoff**, **no second tour**, **no on-demand tour generation**. All deferred.

## What was built

### Backend (`backend/`)

- `src/tours/types.ts` — `Tour`, `Waypoint`, `TourSummary` value types. JSON shape is the wire format.
- `src/tours/registry.ts` — single hand-curated array of tours. Adding tour #2 is a one-line change.
- `src/tours/connecticut-avenue.ts` — the launch tour content (route + narration).
- `src/tours/handlers.ts` — three Express handlers:
  - `GET /tours` → catalog summaries
  - `GET /tours/:id` → full manifest with narration text
  - `GET /tours/:id/audio/:waypointFile` → static mp3, served from disk
- `src/scripts/synthesize-tours.ts` — one-shot script that calls ElevenLabs for every waypoint and writes mp3s to `audio-cache/{tourId}/{waypointId}.mp3`. Idempotent. `npm run synthesize-tours`.
- `src/scripts/generate-gpx.ts` — emits a `.gpx` file for a tour by interpolating between waypoints. Used to regenerate `sim/connecticut-avenue.gpx`.
- `audio-cache/connecticut-avenue/*.mp3` — 9 pre-generated narration files (~8 MB total). Committed to the repo. Shipped as static assets in the docker image.
- `Dockerfile` — copies `audio-cache/` into the runtime image so the served files are co-located with the handler.

The deployed Cloud Run service is already serving these endpoints. Smoke tested with curl.

### iOS app (`DriveByCurio/`)

- `Models/Tour.swift` — Swift mirror of the backend types. Vendored in the app target rather than in `core-swift` because `core-swift` is a separate SPM repo and the contract is small. Promote later if a second consumer needs them.
- `Models/TourCatalogStore.swift` — `@Observable` store wrapping the catalog HTTP fetch.
- `Services/TourService.swift` — small URLSession-based client for `GET /tours`, `GET /tours/:id`, and the audio URL builder.
- `Services/TourPlayer.swift` — the heart of milestone 1:
  - Holds the active tour and current waypoint index.
  - Streams the current waypoint's mp3 via `AVPlayer`.
  - Pushes title/subject/album/artwork to `MPNowPlayingInfoCenter`.
  - Polls `LocationService` once per second; when the user enters the next waypoint's trigger circle, advances and plays the next narration.
  - Activates `AVAudioSession` only on `startTour`, never on app launch (audio-citizen rule from the CarPlay developer guide).
  - Wires `MPRemoteCommandCenter` play/pause/nextTrack so steering-wheel controls and the system Now Playing buttons work.
- `CarPlay/CarPlaySceneDelegate.swift` — completely rewritten for the Audio category template set:
  - `CPTabBarTemplate` (root) → Tours tab + Live tab placeholder.
  - Tours tab uses `CPListTemplate`, populated from `TourCatalogStore`.
  - Tapping a tour calls `TourPlayer.startTour`, then pushes `CPNowPlayingTemplate.shared` onto the stack.
  - "Playing Next" button on Now Playing pushes a `CPListTemplate` of upcoming waypoints.
  - The previous `CPPointOfInterestTemplate`-based code is gone — that template is not available to Audio-category apps.
- `Views/TourBrowserView.swift` — iPhone-side mirror of the CarPlay Tours surface. Lists the catalog, shows a Now Playing banner with tour cover, current story title, play/pause, manual "next stop" button, and "End tour." Exists so the iPhone simulator is testable on its own without enabling the CarPlay window.
- `Views/ContentView.swift` — replaced with a thin wrapper around `TourBrowserView`. The legacy POI/topics UI is no longer linked.
- `AppState.swift` — adds `tourService`, `tourCatalogStore`, `tourPlayer`. Legacy live-mode plumbing (POI store, topics, refresh controller, announcement service) is kept around so the codebase still compiles and the MVP tests still pass, but it is not wired into either UI surface.
- `project.yml` — location usage strings updated to the tour-based framing (no longer mentions "find interesting places nearby"). Background modes (`audio`, `location`) and entitlement (`com.apple.developer.carplay-audio`) were already correct from PR #2.

### Sim assets

- `sim/connecticut-avenue.gpx` — generated from the tour data. ~58 trkpts spanning a ~15-minute simulated drive (110 sec per waypoint segment). Suitable for `Features → Location → Custom Location` or `Edit Scheme → Run → Default Location` in Xcode.

## The launch tour: judgment calls

JD asked me to pick a topic. I went with:

**"From Streetcar Suburb to Federal City: A Drive Down Connecticut Avenue"** — Bethesda Metro to Farragut Square, 9 stops, ~12 km.

Why this topic:

- **Locally rooted to JD's actual area** (Bethesda).
- **A coherent single thesis** ("the streetcar made these neighborhoods exist") that links every stop into a chronological story rather than nine disconnected facts.
- **Real, rich, and non-political historical content** — Senator Newlands and the Chevy Chase Land Company, the Mount Vernon Seminary the Navy seized in WWII, Grover Cleveland's "Red Top," Olmsted Jr.'s zoo design, the Taft Bridge lions, Dupont Circle's Gilded Age mansions. None of this is invented; all of it is checkable.
- **Honest about uncomfortable history** — the narration explicitly mentions the racially restrictive covenants Newlands wrote into the original Chevy Chase deeds. That felt important. We can soften or remove if you'd rather, but I'd argue keeping it makes the tour feel like real history rather than a sanitized brochure.
- **Nine waypoints fit comfortably in a 15-minute simulated drive**, each with ~75 seconds of narration. Long enough to feel substantive; short enough that the whole tour is testable in one sim run.

The 9 waypoints (south on Connecticut Ave the whole way):

1. **Bethesda Metro** — B&O Railroad origins, where the town came from.
2. **Chevy Chase Circle** — Senator Newlands and the first streetcar suburb.
3. **Chevy Chase, DC** — How streetcar-era urban design differs from postwar.
4. **Van Ness / UDC** — Mount Vernon Seminary, the Navy WAVES, the Soviet embassy hill.
5. **Cleveland Park** — Grover Cleveland's "Red Top" summer escape.
6. **Woodley Park / National Zoo** — Olmsted Jr.'s zoo design.
7. **Taft Bridge** — The lions, the Cuban Friendship Urn.
8. **Dupont Circle** — Gilded Age mansions and the streetcar terminus.
9. **Farragut Square** — Arrival in the federal city.

Voice: ElevenLabs "Adam" (premade, deep American male). Easy to swap by editing one constant in `synthesize-tours.ts`.

## Assumptions logged

These are the calls I made without your sign-off. Flag any you want to change.

1. **Single voice (Adam) for all narration.** Could do per-tour voices later. For milestone 1 a single neutral narrator felt right.
2. **Audio is pre-synthesized at author time, committed to the repo, served as static files.** Not regenerated at request time. Pros: cheap, deterministic, fast, no runtime ElevenLabs dependency. Cons: tour edits require re-running the synthesis script and re-deploying. For 9 stories of ~150 KB each (~1.3 MB total per tour) this is fine.
3. **Audio assets are committed to git** rather than git-lfs or a GCS bucket. ~8 MB total for milestone 1. Will revisit if we get to 50+ tours.
4. **Tour models live in the app target, not `core-swift`.** Promoted later if a second consumer (watchOS, separate companion app) appears.
5. **Trigger radius is 200–250m per waypoint.** Sized for the simulator's GPX sample density. Real-world driving will probably want tighter radii (~100m); revisit during real-car testing.
6. **Waypoint progression is strictly ordered**, not "closest waypoint wins." For a curated tour the *intended sequence* is the product, so we play stop 1 then stop 2 then stop 3 even if you happen to drive by stop 5 first. If you skip out of order, you advance manually with the next button.
7. **GPX timing is 110 seconds per segment** — chosen so each ~75–90 second narration finishes before the next trigger fires. If you want a faster sim run, edit `SEGMENT_DURATION_SEC` in `generate-gpx.ts` and regenerate. Some narrations may get cut off at lower values.
8. **Now Playing artwork is a placeholder** — a solid indigo card with the tour title rendered in white. Real per-tour cover art is a follow-up. The constraint is that whatever ships there must be legitimate "album cover" art per CarPlay guideline 7, not a per-story photograph.
9. **No Apple Maps handoff yet.** Wiring `CPTemplateApplicationScene.open(_:)` is straightforward, but it's not testable in the simulator in any meaningful way (sim Maps doesn't actually drive a route), so I deferred it. Adding it is maybe a 20-minute job once you have a real car + the entitlement.
10. **No passenger QR.** Open design question per `CARPLAY-CONSTRAINTS.md`. Not in milestone 1 scope.
11. **No "End tour?" confirmation** via `CPActionSheetTemplate`. The iPhone "End" button just ends. The CarPlay surface doesn't currently expose an end button at all — you tab away. Add later.
12. **The legacy POI/live-mode code is still in the codebase** but no longer wired into either scene. Removing it would have ballooned this PR. Will be cleaned up as a separate small commit when Mode 2 is rebuilt for the Audio category.
13. **`com.apple.developer.carplay-audio` entitlement is enabled in `project.yml`** but Apple has not yet granted it to the team. The simulator may show a warning and the CarPlay window may not surface the templates correctly until it is granted. The iPhone path (`TourBrowserView`) does NOT depend on the entitlement and works regardless.

## What's next (post-milestone-1)

Roughly in order of value:

- Real tour cover art for the Now Playing artwork slot.
- A second tour (alternate Bethesda neighborhood loop, or NW DC corner you suggest).
- Apple Maps handoff (`CPTemplateApplicationScene.open`) for waypoint routing during a real-car drive.
- Strip the legacy live-mode code or rebuild it under the Audio category template set per `PRODUCT.md` step 3.
- "End tour?" confirmation via `CPActionSheetTemplate`.
- Passenger QR — the open design question in `CARPLAY-CONSTRAINTS.md`.
- Backend-generated tours — second audio tier from `PRODUCT.md`.
- Audio caching/streaming optimization for slow connections.
- Real-car testing once Apple grants the entitlement.
