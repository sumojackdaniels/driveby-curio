# Walking Tours — V1 Spec

> Status: in progress on `feature/walking-tours-v1`.
> Predecessor: [`CURATED-TOURS-MVP.md`](./CURATED-TOURS-MVP.md).

## Vision

DriveByCurio started as a driving tour guide. This milestone expands it into a
**community walking/biking tour platform**. Anyone can create a tour — historical,
botanical, poetic, architectural — by walking a route, dropping pins, and recording
audio at each stop. Consumers walk the tour and hear stories auto-triggered as they
approach each waypoint, with compass-based wayfinding between stops.

Think Detour (RIP) but user-generated. The creation tools are as important as the
playback experience.

## Deliverables

1. **Two pre-authored walking tours** (ElevenLabs-narrated, bundled as local assets):
   - Huntington Terrace & Bradmoor neighborhoods — neighborhood history
   - McCrillis Gardens — botanical/garden walk
2. **Walking tour playback** with three modes:
   - Listening mode (audio + controls)
   - Nav instruction mode (short direction audio between stops)
   - Compass/wayfinding mode (heading arrow + distance to next stop)
3. **Tour creation flow** — walk around, drop pins, record audio, save locally

## Architecture Decisions

### Location: "When In Use" + continuous polling (not geofences)

Geofences (`CLMonitor` / `CLCircularRegion`) require **Always** location permission,
which is a terrible first-run UX. For walking tours the app is foregrounded, so
"When In Use" is sufficient. We use continuous location polling at 1 Hz — same
pattern as the driving tours — with trigger circles around each waypoint.

Battery note: we set `activityType = .fitness` and `desiredAccuracy = kCLLocationAccuracyBest`
for walking. The app is foregrounded so background drain isn't a concern.

### Audio recording: AVAudioRecorder with AAC

- Format: AAC (`.m4a`), 64 kbps, 44.1 kHz mono
- 5 minutes of content audio ≈ 2.4 MB per waypoint
- 15 seconds of nav instruction ≈ 120 KB per waypoint
- Recordings saved to app's Documents directory under `tours/{tourId}/{waypointId}/`
- App must be foregrounded to record (AVAudioRecorder limitation) — fine for creation flow

### Compass heading: CLLocationManager.startUpdatingHeading()

No additional permissions beyond location. We calculate bearing from current position
to next waypoint, subtract device heading, and render an arrow showing which direction
to walk. Updates at ~5 Hz for smooth animation.

### Walking directions: MKDirections (in-app) + Apple Maps fallback

Between stops, we fetch walking directions via `MKDirections` and show a mini route
on an `MKMapView`. A "Navigate" button opens Apple Maps with walking directions to
the next waypoint for turn-by-turn.

### Storage: local JSON + audio files (v1)

No backend for user-created tours in v1. Everything is on-device:

```
Documents/
  tours/
    {tourId}/
      tour.json           # WalkingTour metadata + waypoints
      {waypointId}/
        content.m4a       # Main narration (up to 5 min)
        nav.m4a           # Nav instruction (up to 15 sec)
```

Pre-authored tours are bundled in the app bundle under `WalkingTours/`.

## Data Model

```swift
struct WalkingTour: Identifiable, Codable {
    let id: String                    // UUID
    var title: String
    var creatorName: String
    var creatorIsLocal: Bool          // "Local resident" tag
    var description: String
    var tags: [String]                // e.g. ["history", "neighborhood"]
    var mode: TourMode                // .walking, .biking, .driving
    var waypoints: [WalkingWaypoint]
    var createdAt: Date
    var updatedAt: Date
    var isAuthored: Bool              // true = pre-built with ElevenLabs
}

enum TourMode: String, Codable, CaseIterable {
    case walking, biking, driving
}

struct WalkingWaypoint: Identifiable, Codable {
    let id: String                    // UUID
    var order: Int
    var lat: Double
    var lng: Double
    var title: String
    var description: String           // Optional text description
    var triggerRadiusMeters: Double    // User-settable, default 30m for walking
    var contentAudioFile: String?     // Filename for main recording
    var navAudioFile: String?         // Filename for nav instruction
    var narrationText: String?        // For authored tours (ElevenLabs source)
    var navInstructionText: String?   // For authored tours
}
```

## Playback Modes

### Mode 1: Listening

Active when a waypoint's content audio is playing.

**UI:**
- Full-width card showing tour title, waypoint title, waypoint description
- Progress bar for current audio
- Play/pause button
- "Stop N of M" indicator
- "End Tour" button

### Mode 2: Nav Instruction

Fires automatically when content audio finishes. Plays the ≤15 second nav instruction
("Turn left at the corner and walk uphill to the stone bridge").

**UI:**
- Same card, but text changes to "Getting to the next stop..."
- Nav instruction audio plays automatically
- Transitions to compass mode when nav audio finishes (or immediately if no nav audio)

### Mode 3: Compass / Wayfinding

Active between stops — after nav instruction plays until the user enters the next
waypoint's trigger circle.

**UI:**
- Large compass arrow pointing toward next waypoint
- Distance to next stop (in feet/meters)
- Mini map showing current position, next waypoint pin, and walking route
- "Navigate in Maps" button → opens Apple Maps with walking directions
- Next stop title and description preview
- Auto-transitions to Listening mode when entering trigger circle

## Tour Creation Flow

### Step 1: Start a new tour

- Tap "Create Tour" from the main screen
- Enter: tour title, creator name, optional description
- Toggle: "I'm a local resident" tag
- Select mode: walking / biking
- Select tags from a predefined list + freeform

### Step 2: Add waypoints (map + walk)

- Full-screen map centered on current location
- "Add Stop" button drops a pin at current GPS position
- Each pin shows an order number
- Tap a pin to edit:
  - Title (required)
  - Description (optional text)
  - Trigger radius slider (10m–100m, default 30m)
  - "Record Story" button → recording screen (up to 5 min)
  - "Record Direction to Next Stop" button → recording screen (up to 15 sec)
  - Delete waypoint
- Can reorder waypoints by drag
- Recording is optional — user can add pins first, record later

### Step 3: Recording screen

- Large record button (red circle)
- Timer showing elapsed time
- Max duration indicator (5:00 for content, 0:15 for nav)
- Auto-stops at max duration
- Preview playback after recording
- "Re-record" to overwrite
- "Delete Recording" to remove
- Waveform visualization during recording

### Step 4: Save & preview

- "Save Tour" commits to local storage
- Tour appears in the tour browser alongside pre-authored tours
- "Preview Tour" lets you play through it starting from stop 1

## Pre-Authored Walking Tours

### Tour 1: Huntington Terrace & Bradmoor — "Postwar Dreams on Quiet Streets"

A 6-stop neighborhood history walk through two mid-century Bethesda subdivisions.
~45 minutes, ~1.5 miles.

**Stops:**
1. **Starting Point: Huntington Parkway & Bradmoor Dr** — Introduction to the
   postwar suburban boom that transformed Montgomery County farmland into the
   neighborhoods we're walking through.
2. **Huntington Terrace streetscape** — Colonial Revival and Cape Cod homes from
   the late 1940s. How the FHA and GI Bill created these neighborhoods. The visual
   contrast between original modest homes and modern renovations.
3. **Bradmoor Drive** — The naming convention (English moorland prestige branding),
   ranch-style and split-level architecture representing 1950s American optimism.
4. **Burning Tree Club vicinity** — The famously exclusive men-only golf club where
   Eisenhower and Nixon played. The club's name comes from a Native American
   practice of firing hollow trees to smoke out game.
5. **Mature canopy walk** — The 70+ year old tree canopy that defines these streets.
   Oaks, tulip poplars, beeches. Montgomery County's tree protection ordinances.
   How suburban trees have become an urban forest.
6. **Neighborhood evolution** — Standing at the boundary between original homes and
   teardown/rebuilds. What's gained and lost when modest postwar homes become
   5,000 sq ft houses. The changing economics of Bethesda.

### Tour 2: McCrillis Gardens — "A Garden for All Seasons"

A 6-stop botanical walk through a 5-acre shade garden on Inverness Drive.
~30 minutes, ~0.5 miles.

**Stops:**
1. **Garden entrance** — William McCrillis donated this property to Maryland-National
   Capital Park and Planning Commission. Why shade gardens exist — this is a woodland
   understory garden, not a sun-blasted rose garden.
2. **Azalea collection** — McCrillis is known for its exceptional azaleas. The
   difference between native and hybrid azaleas, and why this Piedmont soil is
   perfect for them.
3. **The specimen trees** — Old-growth canopy trees that predate the garden. How to
   read a tree's age from its trunk diameter. The relationship between canopy and
   understory.
4. **Shade perennials walk** — Hostas, ferns, astilbe, hellebores. The art of
   designing for texture and leaf shape when you can't rely on big blooms.
5. **The stream garden** — Water features and moisture-loving plants. How even a
   tiny water feature changes a garden's microclimate and the wildlife it attracts.
6. **Seasonal design philosophy** — A garden that's interesting in every season.
   Winter bark and structure, spring ephemerals, summer foliage, fall color.
   Why the best gardens are designed for 12 months, not 3.

## Assumptions

1. **"When In Use" location only** — no geofences, no Always permission. If the user
   backgrounds the app they'll miss triggers. This is fine for v1.
2. **Walking trigger radius defaults to 30m** (vs 200m for driving). Walking is slower
   and more precise. User can adjust per-waypoint during creation.
3. **No backend** for user-created tours in v1. All local. Sharing comes later.
4. **No social features** (upvoting, profiles, marketplace). Just create and consume.
5. **ElevenLabs audio for pre-authored tours** is bundled locally in the app, not
   streamed from the backend. Keeps v1 simple and offline-capable.
6. **Nav instructions are optional.** If a waypoint has no nav recording, we skip
   straight to compass mode after the content audio finishes.
7. **Compass mode requires magnetometer** — works on all iPhones. Heading accuracy
   is ±5° which is plenty for "walk that direction."
8. **MKDirections walking routes** may not always match the tour creator's intended
   path (e.g., through a park vs. around it). The nav instruction audio is the
   creator's chance to override with human directions.
9. **Audio format is AAC/m4a** — good compression, native iOS support, no transcoding.
10. **Tour creation requires being physically present** to drop pins at GPS coordinates.
    No remote tour authoring in v1.
11. **The existing CarPlay driving tour surface is untouched.** Walking tours are
    iPhone-only. The two systems coexist — the tour browser shows both.
12. **McCrillis Gardens coordinates** are approximate — I'm placing stops based on
    satellite imagery of the garden layout. JD will verify on his test walk and we
    can adjust.
