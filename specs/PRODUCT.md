# DriveByCurio Product Spec

## Product Summary

DriveByCurio is a **walking tour platform**. A user picks a tour from the catalog, hits play, and the app narrates the place around them — history, ecology, architecture, stories — triggering each stop automatically by GPS as they arrive. No screen-staring, no "you are 47 meters from the next point of interest." A knowledgeable local in your ear at the right moment; eyes and attention stay on the world in front of you.

DriveByCurio is for anyone walking somewhere they'd rather experience than just pass through: a neighborhood with a history, a park with layered ecology, a downtown with stories most passersby never hear.

## Two Kinds of Tours

### 1. Authored Tours (launch surface)

Pre-produced walking tours bundled with the app as local audio assets. Professionally scripted, narrated via ElevenLabs, and anchored to GPS waypoints. Launch catalog:

- **Huntington Terrace & Bradmoor** — neighborhood history in Bethesda, MD
- **McCrillis Gardens** — botanical walk
- **Rock Creek Trails** — "Where the City Disappears," a ~30 minute Rock Creek Park loop

These prove the authoring pipeline, the data model, and the playback loop end-to-end.

### 2. User-Created Tours (differentiator)

Any user can create a walking tour on-device:

1. Walk the route.
2. Drop waypoint pins at each stop.
3. Record audio at each stop (narration + optional nav instruction).
4. Save locally.
5. Share (future).

This is the product's long-term wedge: **anyone can be a tour guide for the place they love.** Locals know their neighborhoods better than any backend ever will.

## Experience Shape

**Glance-only, audio-first.** The phone is in a pocket or on a lanyard for most of the tour. The UI surfaces:

- **Playback** — play/pause/skip for the current story.
- **Compass / wayfinding** — heading arrow + distance to the next waypoint, for the moments a user glances down.
- **Nav instructions** — short pre-recorded audio between stops for tours where the path isn't obvious.

The user never searches for anything inside a tour. The tour is a sequence; narration is triggered by physical arrival.

## Out of Scope

DriveByCurio is explicitly **not**:

- **Not a navigation app.** No turn-by-turn routing. Optional nav audio between waypoints is pre-recorded by the tour author, not generated.
- **Not a location finder.** No "restaurants near me" surface. Ever.
- **Not a podcast player.** Audio is location-triggered, not linearly browsable.
- **Not a driving app.** The CarPlay prototype lives under `archive/`. Driving tours may return later — but as a second surface, not the primary one.

## Relationship to the Archived Driving Prototype

The repo previously shipped as a CarPlay driving-tour guide (see `archive/specs/PRODUCT.md` for the driving-era product spec). That prototype taught us the playback pipeline, the backend shape, and the CarPlay Audio-category constraints. The walking pivot carries forward the waypoint-triggered narration engine; everything else is reshaped around walking as the primary use.

The walking app is fully local in v1 — no backend required — which is a deliberate simplification: the driving prototype's Cloud Run service (`POST /nearby`, `GET /tours`) can be undeployed without blocking any launch work.
