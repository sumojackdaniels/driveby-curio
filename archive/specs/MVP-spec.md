# DriveByCurio MVP Spec

## Product Vision

DriveByCurio is a **contextual tour guide** for drivers. As you drive across the country, across town, or even through your own neighborhood, it surfaces fascinating facts about the land, history, and culture around you — tailored to your personal interests.

This is NOT a location finder or navigation app. It's an educational companion that enriches the driving experience. Think: a knowledgeable passenger who points things out along the way.

## Surfaces

### CarPlay Interface (primary)
The CarPlay screen is the main product surface. It uses Apple's CarPlay framework as a **driving task** app.

### iPhone Interface (companion)
The iPhone is used only for setup — entering topics of interest and granting location permissions. While driving, the user interacts only with CarPlay.

### Backend API (Cloud Run)
A lightweight service that takes the driver's location, heading, and topics, then uses Claude to generate relevant, factual POIs nearby.

---

## CarPlay Constraints (from Apple CarPlay Developer Guide)

**READ THESE CAREFULLY. Violating these will cause runtime crashes or App Store rejection.**

### Category & Entitlement
- Category: **Driving task app**
- Entitlement: `com.apple.developer.carplay-driving-task` (already in Entitlements.plist)
- Must apply to Apple at developer.apple.com/carplay to get the entitlement provisioned (we'll do this later — for now, test in simulator)

### Allowed Templates
Driving task apps may ONLY use: Action sheet, Alert, Grid, List, Tab bar, Information, Point of interest.

**NOT allowed**: Now playing, Contact, Map, Search, Voice control.

### Template Depth
- iOS ≤26.3: **maximum 2** templates deep (including root)
- iOS 26.4+: **maximum 3** templates deep (including root)
- Exceeding this causes a runtime exception

### Refresh Limits
- POI template: refresh at most once per **60 seconds**
- Other data items: refresh at most once per **10 seconds**

### POI Limits
- CPPointOfInterestTemplate shows at most **12 locations**
- Some cars limit lists to **12 items** dynamically

### Critical Guideline
> "Do not create POI apps that are focused on finding locations on a map. Driving task apps must be primarily designed to accomplish tasks and are not intended to be location finders."

This means: our primary value is the **knowledge/stories**, not the map pins. The CPInformationTemplate detail view should lead with the description/story, not the location. Everything should feel like a tour guide narrating, not a map app showing pins.

### Audio
- Only activate AVAudioSession the moment you are ready to play audio. Activating too early stops the car's FM radio.
- Check `promptStyle` before each announcement (`.none` = silence, `.short` = tone only, `.normal` = full spoken prompt)
- Recording is NOT supported for driving task apps

### Other Rules
- App may be launched ONLY on CarPlay (no iPhone scene) — handle this
- Don't instruct user to pick up iPhone
- Files with NSFileProtectionComplete won't be accessible when iPhone is locked
- Once entitlement is added, app icon appears on CarPlay home screen for ALL users

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│  iPhone App (SwiftUI)                           │
│  ┌─────────────────────────────────────────┐    │
│  │ ContentView                             │    │
│  │  • Location permission prompt           │    │
│  │  • Topics text editor (free-form)       │    │
│  │  • "Connected to CarPlay" status        │    │
│  └─────────────────────────────────────────┘    │
├─────────────────────────────────────────────────┤
│  CarPlay Scene (CPTemplateApplicationScene)      │
│  ┌─────────────────────────────────────────┐    │
│  │ CPTabBarTemplate (root)                 │    │
│  │  Tab 1: CPPointOfInterestTemplate       │    │
│  │    → up to 12 nearby POIs on map        │    │
│  │    → select → push CPInformationTemplate│    │
│  │  Tab 2: CPListTemplate                  │    │
│  │    → user's active topics               │    │
│  └─────────────────────────────────────────┘    │
├─────────────────────────────────────────────────┤
│  Shared Services                                │
│  ├── LocationService (from core-swift)          │
│  │   continuous location + heading updates      │
│  ├── POIService (backend API client)            │
│  │   fetches nearby POIs, ≤60s refresh cycle    │
│  ├── TopicsStore (@Observable, UserDefaults)     │
│  │   user's interest topics                     │
│  ├── POIStore (@Observable)                      │
│  │   current POIs, closest POI, audio queue     │
│  └── AudioAnnouncementService (AVSpeechSynth)   │
│      announces new closest POI via TTS          │
└─────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│  Backend API (Cloud Run)                        │
│  POST /nearby                                   │
│  {lat, lng, heading, radius_km, topics} →       │
│  Claude API → structured POI JSON               │
└─────────────────────────────────────────────────┘
```

### Info.plist Scene Configuration

The app declares two scenes in Info.plist (already configured in project.yml):
1. `UIWindowSceneSessionRoleApplication` → `PhoneSceneDelegate` (iPhone)
2. `CPTemplateApplicationSceneSessionRoleApplication` → `CarPlaySceneDelegate` (CarPlay)

Both scenes share state through @Observable stores injected via environment.

---

## Implementation Plan (TDD order)

Build each component test-first. After each milestone, build to simulator and take a screenshot for visual verification.

### Phase 1: core-swift enhancements

The core-swift package is already scaffolded with LocationService, HeadingCalculator, and APIClient. Verify the tests pass:

```bash
cd ~/Developer/core-swift
swift test
```

If tests pass, move on. If not, fix them first.

### Phase 2: Backend API

Build in `backend/` directory of this repo.

**Stack**: Express, TypeScript, @anthropic-ai/sdk, zod

**Files to create**:
- `backend/package.json`
- `backend/tsconfig.json`
- `backend/src/index.ts` — Express server with /health and /nearby routes
- `backend/src/nearby.ts` — Handler that calls Claude API
- `backend/Dockerfile` — Multi-stage build (node:22-slim)

**Endpoint: POST /nearby**

Request:
```json
{
  "lat": 39.8283,
  "lng": -98.5795,
  "heading": 180,
  "radius_km": 10,
  "topics": ["Civil War History", "Rock and Roll Landmarks"]
}
```

Response:
```json
{
  "pois": [
    {
      "name": "Gettysburg Battlefield",
      "topics": ["Civil War History"],
      "description": "Site of the pivotal 1863 battle that turned the tide of the Civil War. Over 50,000 soldiers were casualties across three days of intense fighting.",
      "lat": 39.8112,
      "lng": -77.2258
    }
  ]
}
```

**Claude prompt strategy**: Ask Claude to generate 5-12 real, factual POIs within the radius that match the topics. Each POI must be a real place. Response is structured JSON.

**Use model**: `claude-sonnet-4-20250514` (fast, cheap, good enough for POI generation)

**Validation**: Use zod to validate inbound request. Validate Claude's response structure before returning.

**Test the backend locally**:
```bash
cd backend && npm install && npm run dev
curl -X POST http://localhost:8080/nearby -H 'Content-Type: application/json' \
  -d '{"lat":39.8,"lng":-77.2,"heading":180,"radius_km":10,"topics":["Civil War History"]}'
```

**Deploy**: Build Docker image and provide gcloud deploy commands for the user to run manually (do NOT run gcloud commands yourself). The service should be called `curio-api`, use the existing `ANTHROPIC_API_KEY` from Secret Manager.

### Phase 3: iPhone UI

Enhance the existing ContentView with working location permissions and topics editor.

**LocationStatusView**: 
- Show current authorization status from LocationService (core-swift)
- Button to request always-on location if not yet authorized
- Green indicator when authorized, yellow for when-in-use, red for denied

**TopicsEditorView** (already scaffolded):
- Free-form TextEditor, one topic per line
- Show parsed topic count below

**CarPlay connection status**:
- Show whether CarPlay is currently connected (observe the CarPlaySceneDelegate state)

**Screenshot milestone**: Build to iPhone simulator, verify the UI shows location prompt and topics editor.

### Phase 4: CarPlay Scene — Tab Bar + POI Template

This is the core CarPlay implementation.

**CarPlaySceneDelegate.swift** — expand the existing stub:

1. On `didConnect`:
   - Create `CPTabBarTemplate` as root with 2 tabs
   - Tab 1: "Nearby" — `CPPointOfInterestTemplate`
   - Tab 2: "Topics" — `CPListTemplate`
   - Start location updates
   - Start POI refresh timer (60s interval)

2. **Nearby tab** (`CPPointOfInterestTemplate`):
   - Show up to 12 POIs from POIStore
   - Each POI gets a `CPPointOfInterest` with:
     - `location`: MKMapItem from lat/lng
     - `title`: POI name
     - `subtitle`: topic tags joined (e.g. "Civil War History")
     - `informativeText`: the 2-sentence description
     - `pinImage`: custom SF Symbol based on topic (or default pin)
   - `selectedHandler`: push CPInformationTemplate with POI details

3. **POI detail** (`CPInformationTemplate`):
   - Title: POI name
   - Labels (two-column layout):
     - "Topics": topic tags
     - "About": 2-sentence description  
     - "Distance": formatted distance + compass direction (e.g. "2.3 mi NE")
   - Footer button: "Open in Maps" — launches Apple Maps via URL scheme using `CPTemplateApplicationScene.open()`
   - This is depth 2 (root tab bar + pushed info template) — within the limit

4. **Topics tab** (`CPListTemplate`):
   - List the user's configured topics
   - Each topic is a `CPListItem` with the topic name
   - Read-only display (editing happens on iPhone)

**Screenshot milestone**: Build to simulator, open I/O > External Displays > CarPlay, verify tab bar with both tabs renders.

### Phase 5: POI Service Integration

Wire up the backend to the CarPlay scene.

**POIRefreshController** (new class, @Observable @MainActor):
- Owns the refresh logic
- On timer tick (60s) OR on significant location change (>500m):
  - Check `poiStore.canRefresh`
  - Call `poiService.fetchNearby()` with current location, heading, topics
  - Update `poiStore.pois`
  - Determine `closestPOI` (sort by distance to current location)
  - Refresh the CPPointOfInterestTemplate with new data

**Backend URL**: Configure via environment or hardcoded for MVP. The Cloud Run URL will be provided after deploy.

**Screenshot milestone**: With backend running locally (or deployed), verify POIs appear on CarPlay simulator map.

### Phase 6: Audio Announcements

**AudioAnnouncementService**:
- Uses `AVSpeechSynthesizer` for text-to-speech
- When `closestPOI` changes to a new POI:
  - Check AVAudioSession `promptStyle` — respect `.none` and `.short`
  - Activate AVAudioSession (category: `.playback`, mode: `.voicePrompt`)
  - Set options: `.interruptSpokenAudioAndMixWithOthers`, `.duckOthers`
  - Speak: "{POI name}. {description}"
  - Deactivate AVAudioSession immediately after utterance finishes
- Track announced POI IDs to avoid re-announcing the same POI
- Don't announce if the POI is more than 2km away

**Test**: Verify in simulator that changing the closest POI triggers speech output.

### Phase 7: Polish & Error States

- Empty state on CarPlay when no topics configured ("Open DriveByCurio on your iPhone to set your interests")
- Empty state when no POIs found ("No points of interest nearby for your topics")
- Loading state while backend request is in flight
- Error handling: backend timeout, network failure — show alert template briefly, then recover
- Handle case where app is launched only on CarPlay (no iPhone scene)

---

## TDD Strategy

For every component:

1. **Write the test file first** with tests that describe expected behavior
2. **Run tests — confirm they fail** (red)
3. **Implement the component**
4. **Run tests — confirm they pass** (green)
5. **Build to simulator and screenshot** to verify visually

### Test Files to Create

| Test File | What It Tests |
|-----------|--------------|
| `DriveByCurioTests/POIStoreTests.swift` | Already exists — refresh gating, closest POI selection |
| `DriveByCurioTests/TopicsStoreTests.swift` | Already exists — topic parsing |
| `DriveByCurioTests/POIRefreshControllerTests.swift` | Refresh timing, significant location change trigger |
| `DriveByCurioTests/AudioAnnouncementTests.swift` | Announcement dedup, distance threshold, promptStyle respect |
| `DriveByCurioTests/CarPlayTemplateTests.swift` | Template creation with POI data, depth limits, info template labels |
| `CoreSwiftTests/HeadingCalculatorTests.swift` | Already exists in core-swift |
| `CoreSwiftTests/APIClientTests.swift` | Already exists in core-swift |

### Screenshot Verification

After each phase, build to simulator and take a screenshot:

```bash
# iPhone
xcodegen generate
xcodebuild -project DriveByCurio.xcodeproj -scheme DriveByCurio \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /tmp/curio-build build

# Boot simulator + install + launch
xcrun simctl boot <UUID>
xcrun simctl install <UUID> /tmp/curio-build/Build/Products/Debug-iphonesimulator/DriveByCurio.app
xcrun simctl launch <UUID> com.sumojackdaniels.DriveByCurio

# Screenshot
xcrun simctl io <UUID> screenshot Screenshots/<name>.png
```

For CarPlay: After launching the app in simulator, enable the CarPlay external display (I/O > External Displays > CarPlay), then screenshot.

---

## File Structure (final state)

```
driveby-curio/
├── project.yml                          # XcodeGen (source of truth)
├── ARCHITECTURE.md
├── WORKFLOW.md
├── CLAUDE.md
├── specs/
│   └── MVP-spec.md                      # This file
├── Screenshots/                         # Visual verification screenshots
├── DriveByCurio/
│   ├── DriveByCurioApp.swift            # @main entry
│   ├── PhoneSceneDelegate.swift         # iPhone scene
│   ├── Entitlements.plist               # CarPlay driving task
│   ├── CarPlay/
│   │   ├── CarPlaySceneDelegate.swift   # CPTemplateApplicationSceneDelegate
│   │   └── POIRefreshController.swift   # 60s refresh, location-triggered updates
│   ├── Models/
│   │   ├── TopicsStore.swift            # User topics (@Observable)
│   │   └── POIStore.swift               # POI data + closest POI (@Observable)
│   ├── Views/
│   │   ├── ContentView.swift            # iPhone main view
│   │   ├── LocationStatusView.swift     # Permission UI
│   │   └── TopicsEditorView.swift       # Topic entry
│   └── Services/
│       ├── POIService.swift             # Backend API client
│       └── AudioAnnouncementService.swift
├── DriveByCurioTests/
│   ├── POIStoreTests.swift
│   ├── TopicsStoreTests.swift
│   ├── POIRefreshControllerTests.swift
│   ├── AudioAnnouncementTests.swift
│   └── CarPlayTemplateTests.swift
├── backend/
│   ├── package.json
│   ├── tsconfig.json
│   ├── Dockerfile
│   └── src/
│       ├── index.ts                     # Express server
│       └── nearby.ts                    # Claude API POI generation
└── .gitignore
```

---

## Backend Deploy Instructions

After Joni builds the backend, provide these commands for the user to run:

```bash
# Build the Docker image
cd ~/Developer/driveby-curio/backend
gcloud builds submit --tag us-central1-docker.pkg.dev/liberate-agent-infra/liberate/curio-api:latest

# Deploy to Cloud Run
gcloud run deploy curio-api \
  --image us-central1-docker.pkg.dev/liberate-agent-infra/liberate/curio-api:latest \
  --region us-central1 \
  --allow-unauthenticated \
  --set-secrets ANTHROPIC_API_KEY=ANTHROPIC_API_KEY:latest \
  --port 8080
```

Update POIService.swift `baseURL` with the deployed Cloud Run URL.

---

## Post-MVP

- Geofence-based POI caching (avoid sending real-time location to server)
- Google Maps/Directions API integration (low priority — this is a tour guide, not a navigator)
- Richer topic taxonomy (auto-extract subtopics from free-form text)
- Linear project setup for ticket management
- Xcode Cloud CI/CD
- Apple entitlement application for App Store distribution
