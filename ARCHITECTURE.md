# DriveByCurio — Architecture

## What is DriveByCurio?

A CarPlay contextual tour guide. As you drive, DriveByCurio surfaces interesting facts about the land, history, and culture around you — tailored to your personal interests. Think of it as a knowledgeable passenger who points out fascinating things along the way.

## App Category

CarPlay **driving task** app (entitlement: `com.apple.developer.carplay-driving-task`).

This is NOT a location finder or navigation app. It's an educational companion that enriches the driving experience.

## Architecture

### Dual-Scene Design

The app runs two independent scenes:
1. **iPhone scene** (SwiftUI) — Topics configuration, location permissions
2. **CarPlay scene** (CarPlay framework) — Tour guide interface

Both scenes share state through @Observable stores.

### CarPlay Template Hierarchy

Root: CPTabBarTemplate
├── Tab 1 "Nearby": CPPointOfInterestTemplate (up to 12 POIs)
│   └── On select: push CPInformationTemplate (POI detail)
└── Tab 2 "Topics": CPListTemplate (active interest topics)

**Constraints** (from Apple CarPlay Developer Guide):
- Template depth: 2 (iOS ≤26.3) or 3 (iOS 26.4+)
- POI refresh: max once per 60 seconds
- Data refresh: max once per 10 seconds
- Max 12 POIs on CPPointOfInterestTemplate

### Data Flow

1. LocationService (core-swift) provides continuous location + heading
2. Every 60s (or on significant location change): POIService calls backend
3. Backend (Cloud Run) calls Claude API with location + topics → returns POIs
4. POIStore updated → CarPlay templates refreshed
5. AudioAnnouncementService speaks new closest POI via AVSpeechSynthesizer

### Project Structure

DriveByCurio/
├── DriveByCurioApp.swift          # @main entry, store initialization
├── PhoneSceneDelegate.swift       # iPhone UIWindowScene
├── CarPlay/
│   └── CarPlaySceneDelegate.swift # CPTemplateApplicationSceneDelegate
├── Models/
│   ├── TopicsStore.swift          # User interest topics (@Observable)
│   └── POIStore.swift             # POI data + refresh gating (@Observable)
├── Views/
│   ├── ContentView.swift          # iPhone main view
│   ├── LocationStatusView.swift   # Location permission UI
│   └── TopicsEditorView.swift     # Free-form topic entry
├── Services/
│   ├── POIService.swift           # Backend API client
│   └── AudioAnnouncementService.swift  # AVSpeechSynthesizer
└── Entitlements.plist             # CarPlay driving task entitlement

### Dependencies

- **core-swift** (SPM) — LocationService, HeadingCalculator, APIClient
- No other external dependencies for MVP

### Backend

Express/TypeScript service on Cloud Run.
- `POST /nearby` — takes location, heading, radius, topics → calls Claude → returns POI JSON
- Uses Claude to generate factual, location-appropriate content
