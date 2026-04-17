# DriveByCurio Product Spec

> This document describes the broader product direction. The narrow first slice already under implementation is specified in [`MVP-spec.md`](./MVP-spec.md) — that remains the implementation record for the live-mode-only MVP and is not superseded by this document.

## Product Summary

DriveByCurio is a **contextual tour guide** for drivers. Pick a curated audio tour before you set off, or enable live contextual narration on a long drive, and the app tells you the history, geology, and culture of what you're passing — hands-free, eyes-on-the-road. Think of it as a knowledgeable passenger who points things out along the way.

DriveByCurio is for road trippers, daily commuters on long routes, and weekend drivers who want their drive to be enriched by what's around them. It is not a navigation app, not a place finder, and not a podcast player. Its purpose is activated by driving — there is no standalone parked-use experience you launch into. The product is **intrinsically tied to the act of driving**.

---

## CarPlay Framing Constraint (non-negotiable)

DriveByCurio ships as a **CarPlay Audio App** under the `com.apple.developer.carplay-audio` entitlement. The category choice and the resulting template / design constraints are documented in depth in [`CARPLAY-CONSTRAINTS.md`](./CARPLAY-CONSTRAINTS.md) — read that document before making any CarPlay-related design decision; everything in this section is a summary.

**What DriveByCurio is:**
- A curated audio tour player
- A contextual audio narration service about what the vehicle is currently driving past
- A learning / enrichment experience for time already spent driving
- Structurally an audiobook (curated tours) crossed with a radio service (live mode) — the two Audio-category exemplars that Apple lists by name in Entitlement Addendum §3.4

**What DriveByCurio is not, and what we will never describe it as:**
- A navigation app or turn-by-turn router (we hand off to Apple Maps via `CPTemplateApplicationScene.open(_:options:completionHandler:)`)
- A "find nearby places" / POI browser / destination picker
- A map-search experience
- A podcast player
- An experience the user launches while parked

Words we do not use anywhere in product copy, marketing, App Store metadata, or code-facing UI strings: *find*, *search*, *discover places*, *nearby locations*, *POI browser*, *destination finder*. We talk about **tours**, **stories**, **narration**, **what you're passing**, and **learning about what's around you**.

**Why not the Driving Task category** (important historical note — an earlier iteration of this spec targeted that category): the CarPlay Entitlement Addendum §3.10 contains two clauses that disqualify a contextual audio tour guide from shipping under Driving Task — *"may not combine driving tasks with media functions"* and *"may not be primarily designed to provide a list of Points of Interests (POIs) or locations."* Both hit us. Audio is the correct category and the one that matches the exemplars in Addendum §3.4. Full reasoning in `CARPLAY-CONSTRAINTS.md`.

---

## Two Modes

DriveByCurio has two modes. Both are audio-first. Both are framed as tour guides, not finders.

### 1. Curated Tours (PRIMARY)

The primary use case. The driver selects a pre-authored audio tour **before the drive begins**, from either their iPhone or a simple CarPlay list at a stop. A tour is a hand-curated or backend-generated sequence of narrated stories anchored to specific points along a driving route.

Initial launch tours (in scope as the first concrete designs):

- **Sunset Park, Brooklyn** — a short neighborhood drive covering the park itself and the surrounding blocks. Topics TBD.
- **Northwest D.C.** — a drive through NW Washington neighborhoods. Topics TBD.

These two are the first real tours we design end-to-end, informing the tour data model, the CarPlay experience, and the Apple Maps handoff. Additional tours in major cities follow once the first two are shipping.

Once the driver starts a tour and begins driving, the experience is **near-automatic**:
- Narration plays at the right moment based on GPS position and the next waypoint.
- The driver's only interaction while moving is a single-tap **"next"** control to advance to the next point of interest or skip the current story — functionally equivalent to the "next track" control in Apple Music's CarPlay interface. No menu dives, no multi-step selections, no typing.
- The CarPlay display shows only the current story title, upcoming story titles, the "next" control, and a passenger QR code (see below).
- If the driver needs routing to stay on the tour, DriveByCurio hands off to Apple Maps (see Navigation Handoff).

Tours are stored and served from the backend so we can author, update, and expand the catalog without App Store submissions.

### 2. Live Contextual Mode (SECONDARY)

For drives where no curated tour fits — random road trips, daily commutes through an unfamiliar region, an afternoon exploring a state you've never been to — the driver can enable a live contextual mode. In this mode the app generates short narrated segments about the historical, geological, and cultural aspects of whatever the vehicle is currently passing, based on location and heading.

Live mode has **no search, no browsing, no selection**. It is fully automatic. The driver configures their topical interests once on iPhone, enables live mode, and then drives.

This is the mode that the current MVP implements end-to-end against the `POST /nearby` backend endpoint. See `MVP-spec.md`.

---

## Navigation Handoff

**DriveByCurio never implements in-app or in-CarPlay turn-by-turn navigation.** This is both a product decision and a platform constraint.

**Platform constraint:** CarPlay Audio category apps cannot use `CPMapTemplate` at all — it is reserved for the Navigation category. Turn-by-turn in CarPlay belongs to Navigation-category apps, which have an entirely different product shape (the map *is* the app). Curio is an Audio app; the map is never our surface.

**How routing works for curated tours:**

Apple explicitly documents the hand-off pattern in the CarPlay Developer Guide (February 2026), p. 27: *"If your app launches other apps in CarPlay, such as to get directions or make a phone call, use the `CPTemplateApplicationScene open(_:options:completionHandler:)` method to launch the other app using a URL to ensure it launches on the CarPlay screen."* **"Get directions" is the example Apple itself uses** — our hand-off is a blessed pattern, not a workaround.

1. Tour is selected via CarPlay or iPhone (per CarPlay guideline 3, the CarPlay path must exist).
2. If the tour benefits from routing — e.g. the driver is not already on-route — DriveByCurio launches **Apple Maps** via `CPTemplateApplicationScene.open(_:options:completionHandler:)` with a standard Maps URL:
   ```
   http://maps.apple.com/?daddr=<lat>,<lng>&dirflg=d
   ```
3. Apple Maps takes over the CarPlay display and provides turn-by-turn to the next waypoint.
4. DriveByCurio **continues running in the background**, holding an audio session, and narrates each story as the driver approaches its anchor point. Apple Maps's voice prompts duck our narration via the standard `AVAudioSession` mixing/ducking rules. This requires `UIBackgroundModes` to include both `audio` and `location` (see [`CARPLAY-CONSTRAINTS.md`](./CARPLAY-CONSTRAINTS.md)).
5. At each waypoint, when Apple Maps has delivered the driver, DriveByCurio can re-invoke `open(_:)` with the next waypoint as destination.

---

## Passenger QR Handoff

One of the CarPlay templates displayed while a tour (or live mode) is running shows a **QR code**. Passengers scan it with their own iPhone and are taken to a **companion experience** — either a web view or a deep link into the DriveByCurio iPhone app — that shows rich media for the **current** and **recently played** stories:

- Photographs and historical images
- Long-form text and primary sources
- Maps showing the current story anchor
- Additional context that doesn't fit in a 20-second narration

**This is an explicit safety design choice, not a feature bolted on.** The driver's experience is deliberately, aggressively minimal: audio plus a story title. The rich visual experience is pushed to a **different device, in a different seat**, so the driver is never tempted to look at their own phone. A passenger who wants to dig deeper into "wait, what just happened at that battle?" has a device in their hands already showing it; the driver keeps their eyes on the road.

Beyond safety, the QR handoff is:
- A meaningful product differentiator (most CarPlay apps don't distinguish driver UX from passenger UX at all)
- A strong argument in the CarPlay Audio entitlement application — it demonstrates we've thought carefully about attention and distraction

The QR code encodes a short-lived session URL tied to the current drive so multiple passengers can follow along and the experience resumes where narration is.

---

## CarPlay UI Contract

The CarPlay surface is built from the fixed set of templates that the CarPlay Audio category permits — `CPNowPlayingTemplate`, `CPListTemplate`, `CPTabBarTemplate`, `CPGridTemplate`, `CPActionSheetTemplate`, `CPAlertTemplate`. Full inventory and rationale in [`CARPLAY-CONSTRAINTS.md`](./CARPLAY-CONSTRAINTS.md). The product shape below is what those templates can deliver.

### What the driver sees

**Tab bar** (`CPTabBarTemplate`, max 4 tabs for Audio apps): **Tours**, **Live**, plus the iOS-supplied Now Playing shortcut that auto-appears in the top-right when audio is active. A third tab — for passenger pairing via QR code — is a candidate pending the architectural sprint.

**Tour catalog** (`CPListTemplate`, reachable from the Tours tab): a scrollable list of curated tours with cover art (image row style), tour title, and a subtitle showing duration/distance/region. Tapping a tour starts it.

**Now Playing** (`CPNowPlayingTemplate`, the primary during-drive surface):
- **Album artwork slot:** the **tour's cover art**, fixed for the duration of the tour. Per Apple CarPlay guideline 7, the artwork slot must be used to show an album cover — it cannot be repurposed to show a photo of the currently-narrated point of interest. In live mode, the artwork is a single image representing live mode as a feature.
- **Title:** the current story's title (e.g. *"Sunset Park Industrial Waterfront"*). Updates via `MPNowPlayingInfoCenter` as each story begins.
- **Subtitle / "artist" slot:** the current subject (e.g. *"Bush Terminal, 1890"*) or the tour author's name — TBD in implementation.
- **"Album" slot:** the tour name (e.g. *"Sunset Park by Car"*).
- **Playback controls:** play/pause, next (advance to next story, the single during-drive interaction point), and optionally a **"Playing Next"** button that pushes a `CPListTemplate` showing upcoming stories in the tour.

**Upcoming stories queue** (`CPListTemplate`, pushed on top of Now Playing when the driver taps "Playing Next"): a read-only list of upcoming story titles in the current tour. This is the *only* template Apple permits on top of Now Playing — there is no way to surface an "information" screen or a richer detail view to the driver while a tour is playing.

**Alerts** (`CPAlertTemplate`): errors — no network, no location permission, tour unavailable — and confirmations like "End tour?" via `CPActionSheetTemplate`.

### What the driver never sees on CarPlay

- **Photographs of points of interest.** Audio category artwork must be album cover art, not per-story imagery. Photos live on the passenger device via the QR handoff.
- **Long-form text about a point of interest.** There is no `CPInformationTemplate` available to Audio apps. Any text beyond a story title + short subtitle lives on the passenger device.
- **Any map.** `CPMapTemplate` is Navigation-only.
- **Any POI browser, map pin, or destination picker.** None of these templates are available to Audio apps, and none would be permitted under guideline 7.
- **Search fields.**
- **Video of any kind.** No CarPlay template in any category supports video.

### What the passenger sees (via QR handoff, on their own device)

Everything the driver doesn't: images of each point of interest, long-form text, historical photographs, primary sources, deeper context for the current and recently-played stories. **The passenger device is the product's only rich visual surface.** The driver's CarPlay surface is deliberately spare; the rich experience is pushed to a different device in a different seat so the driver is never tempted to look at their own phone.

The surface the QR code appears on within CarPlay is an open design question — a candidate third tab or a surface reached from the Now Playing template. Tracked in `CARPLAY-CONSTRAINTS.md` → "Passenger QR handoff — open design questions."

### Where interaction happens

- **iPhone, before driving:** account setup, topical interest configuration for live mode, payment, tour downloads for offline use, long-form history — anything that is "outside the vehicle environment."
- **CarPlay, pre-drive or at a stop:** tour catalog browsing, tour selection, live mode toggle, passenger pairing. Per Apple CarPlay guideline 3, **every in-drive flow must be possible without touching iPhone** — iPhone-only gating is not permitted for these.
- **CarPlay, while driving:** a single "next" button on the Now Playing template. No other interaction is offered while the vehicle is in motion.

### Note on the "stationary enriched view" idea

An earlier iteration of this document proposed a richer display when the vehicle stops (photographs, longer text, an expanded passenger QR). **That is not implementable within the Audio category.** The rationale is documented in `CARPLAY-CONSTRAINTS.md` → "The 'stationary enriched view' idea — dropped." In short: the Information template isn't available, the artwork slot can't be repurposed, there's no CarPlay motion-state API for Audio apps to trigger view swaps on, and the whole concept relied on a mental model of the CarPlay display as a canvas we paint rather than a set of fixed-slot templates we fill.

This is not a loss — it forces the rich content cleanly onto the passenger device, which is a better product story anyway.

---

## Backend Architecture Sketch

The backend is the Cloud Run service already scoped in `MVP-spec.md`, extended with tour endpoints.

### Existing (MVP)

```
POST /nearby
  → live contextual mode
  → input:  { lat, lng, heading, radius_km, topics }
  → output: { pois: [ { name, topics, description, lat, lng } ] }
```

### New (curated tours) — pre-architectural-sprint sketch

> The endpoint shapes below are a first pass. A dedicated architectural sprint will settle the real data model, endpoint design, and audio pipeline before implementation begins. Treat this section as a placeholder for that sprint's output.

Rough shape:

```
GET  /tours
  → list of available curated tours (id, title, region, duration, distance, short description, preview image)

GET  /tours/:id
  → full tour manifest: ordered list of waypoints, each with
    { id, lat, lng, title, subject, narration_text, audio_url, trigger_radius_m }
  → plus tour-level metadata (author, sources, last updated)

GET  /tours/:id/waypoints/:waypoint_id/passenger
  → rich passenger payload: images, long-form text, citations, maps
  → accessed via the QR-encoded session URL (see Passenger QR Handoff)
```

### Audio strategy

Three tiers of audio, in order of expected rollout:

1. **Curated tours (launch):** pre-produced audio authored alongside the tour — either hand-recorded voice or generated via a specialized external TTS API (the specific vendor TBD in the architectural sprint). Audio is hosted server-side, streamed or cached on-device. These are the Sunset Park and NW D.C. tours and any other hand-curated launch catalog.
2. **On-demand generated tours (post-launch):** when the user requests a tour for a location or theme that isn't in the curated catalog, the backend generates narration text and produces audio via the same external TTS API. This lets the catalog grow without hand-authoring every tour.
3. **User-authored tours (future):** expert users curate their own tours and record their own audio — location experts, historians, local guides — publishing into the catalog for others to follow. This is the long-term creator surface.

`AVSpeechSynthesizer` is not expected to be the production path for curated-tour audio. (It remains in the current live-mode MVP but is not part of the curated-tours direction.)

Tours are stored server-side — never bundled in the app binary — so authoring, correction, and catalog expansion do not require App Store submissions.

---

## Out of Scope / Anti-Goals

DriveByCurio is explicitly **not**:

- **Not a navigation app.** We hand off to Apple Maps. We do not draw routes. We do not do turn-by-turn.
- **Not a POI finder / location search.** The driver never searches for anything. There is no "find me restaurants / gas / coffee" surface and we will reject any feature request framed that way.
- **Not a podcast player.** Audio content is tied to the driver's current location and heading. The driver cannot arbitrarily browse and pick stories off a shelf. There is no play queue, no skip-to-episode, no library management.
- **Not launched to use while parked.** The app's purpose is activated by driving. Users do not launch DriveByCurio to sit on their couch and browse tours as an end in itself — they launch it to drive a tour. When the vehicle comes to a stop during an active tour, the CarPlay display shows a genuinely richer view (photographs, longer text, an expanded passenger QR surface) — this is a **deliberate complementary experience** designed into the product, not a fallback. What it is not is a reason to open the app while parked in the first place. The iPhone app's only meaningful stationary-first function is pre-drive setup (interests, tour picking, account).

---

## Relationship to the Existing MVP

The currently-open MVP (see `MVP-spec.md` and the open PR on `feature/mvp-implementation`) implements **Live Contextual Mode only**, against the `POST /nearby` backend endpoint, using a `CPPointOfInterestTemplate`-based CarPlay interface. That MVP is the narrow first slice: it validates the end-to-end plumbing (location → backend → narration → CarPlay → audio) on the simplest possible mode.

**Curated Tours is post-MVP** and is the primary long-term product surface. It is a substantial piece of work — new backend, new CarPlay experience, Apple Maps handoff, new audio pipeline, passenger companion view — and it is intentionally out of scope for the current first slice.

**The CarPlay app built for the MVP needs to be redesigned around this spec**, not extended from the current POI-template layout. The curated-tours product, Apple Maps handoff, Audio-category template set (Now Playing + List + Tab Bar), "next" control, and passenger QR code are a materially different CarPlay experience from the live-mode-only MVP and should be designed fresh rather than grafted onto what exists. The MVP's `CPPointOfInterestTemplate`-based layout is not even available under the Audio category we're pursuing.

The critical path from here is roughly:

1. **Architectural sprint.** Settle the tour data model, backend endpoints, audio pipeline (external TTS vendor selection), waypoint/location state machine, and the redesigned CarPlay experience. This sprint explicitly covers what used to be called "waypoint triggering and narration" as part of the broader CarPlay redesign — it is not a standalone step.
2. **Backend + one real tour end-to-end.** Hand-author either the Sunset Park or the NW D.C. tour against the new data model, including pre-produced audio. Prove the authoring path works before building two.
3. **Redesigned CarPlay app.** New templates (Now Playing + Tab Bar + List + Alert/Action Sheet only — the Audio-category allow-list), new state machine, single-tap "next" control on Now Playing, "Playing Next" queue as a pushed List template, passenger QR surface (placement TBD in the architectural sprint). Built fresh against the PRODUCT spec. The MVP's `CPPointOfInterestTemplate` layout is discarded because that template is not available to Audio-category apps.
4. **Apple Maps handoff.** Integrate the URL-scheme handoff to Apple Maps for tour routing. This is the first point at which the experience can actually be tested end-to-end in a real car, so it is on the critical path for validating the product — not a deferrable polish item.
5. **iPhone pre-drive experience.** Tour browsing, selection, and setup on iPhone.
6. **Passenger QR handoff and companion view.** Short-lived per-session URL, rich passenger device experience.
7. **Second launch tour** (the other of Sunset Park / NW D.C.), then expand the catalog.
8. **On-demand generated tours.** Second audio tier — backend generates narration + audio for ad-hoc user requests.

The framing, UI contract, and anti-goals in this document apply to **both** modes and to **all** future work on the product. If a proposed feature would require us to describe DriveByCurio as something that "finds places" or "navigates," the feature is wrong, not the framing.
