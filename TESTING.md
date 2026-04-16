# Testing the Curated Tours Milestone in the iOS Simulator

> Goal: pick the Connecticut Avenue tour, simulate a 15-minute drive from
> Bethesda Metro to Farragut Square, and hear ElevenLabs-narrated stories
> trigger as the simulated vehicle approaches each waypoint.
>
> You do **not** need a real car, the CarPlay window, or the
> `carplay-audio` entitlement to be granted by Apple. The iPhone scene works
> on its own. The CarPlay window works *if* the simulator surfaces it
> correctly, which is sometimes flaky depending on Xcode version and
> entitlement state.

## What's already done before you start

- ✅ Backend deployed to Cloud Run at `https://curio-api-1096302431561.us-central1.run.app` with the `/tours` endpoints. Catalog and audio files are live.
- ✅ ElevenLabs key is in Google Secret Manager and wired into the Cloud Run service.
- ✅ All 9 narration mp3s are pre-generated, committed to the repo under `backend/audio-cache/connecticut-avenue/`, and shipped in the docker image.
- ✅ GPX route file generated and committed at `sim/connecticut-avenue.gpx`.
- ✅ The iOS app code is on this branch (`feature/curated-tours-mvp`).

## Step 1 — Generate the Xcode project and open it

```bash
cd ~/Developer/driveby-curio
xcodegen generate
open DriveByCurio.xcodeproj
```

If `xcodegen` is missing, `brew install xcodegen`. The xcodeproj is `.gitignored`, so always regenerate after pulling.

## Step 2 — Pick a simulator and build

In Xcode, choose any iPhone simulator (iPhone 16 Pro is fine). Press ⌘B to build first to make sure the new files compile. If anything fails to compile, see the troubleshooting section at the bottom — a few of these files are brand new and I'm building blind without an Xcode here on the dev box.

## Step 3 — Run the app

Press ⌘R to run. The app launches into the **Tours** browser. You should see:

- A list with one tour: **"From Streetcar Suburb to Federal City"**
- A "CarPlay: Not connected" status row (expected — you haven't enabled the CarPlay window yet)
- A "Location" status row asking you to enable

**Grant location permission when prompted.** Pick "Allow While Using App" or "Always Allow." The tour playback works either way.

If the tour list is empty, see troubleshooting → "Catalog won't load."

## Step 4 — Load the GPX route into the simulator

This is the magic step. The simulator can replay a GPX file as if a real device were moving along it.

In **Xcode**, with the simulator running, go to:

`Debug → Simulate Location → Add GPX File to Workspace…`

Select `sim/connecticut-avenue.gpx` from the repo. After you add it, the GPX file shows up at the bottom of the same `Debug → Simulate Location` menu. **Click it to start playback.** The simulator will begin emitting location updates that walk through the GPX timestamps.

You can also do this from the iOS Simulator app itself: `Features → Location → Custom Location…` lets you drop a one-off coordinate, but for a moving drive you want the GPX path through Xcode.

## Step 5 — Start the tour

Tap the tour row in the iPhone app. The audio should start playing immediately — story 1, "Bethesda's Railroad Beginnings."

The Now Playing banner at the top of the screen will show:

- The tour title
- The current story title and subject
- A play/pause button
- A manual "next" button (a forward-arrow icon)
- An "End" button
- "Stop 1 of 9"

You should hear the ElevenLabs narrator immediately. **Audio plays through the Mac speakers**, no special routing required.

## Step 6 — Drive

Once the GPX is playing, the simulated location advances along Connecticut Avenue. As the vehicle enters each waypoint's trigger circle (~250m radius), the next story automatically starts. The Now Playing banner updates.

Expected pacing: each story is ~75 seconds of narration, and the GPX is timed so the next trigger fires ~110 seconds after the previous one. Most narrations finish before the next trigger; some longer ones may get clipped at the very end. That's a tunable in `backend/src/scripts/generate-gpx.ts` (`SEGMENT_DURATION_SEC`).

Total drive: ~15 minutes from start to "Arrival at the Federal City."

## Step 7 — (Optional) Try the CarPlay window

In the **iOS Simulator** app menu (not Xcode):

`I/O → External Displays → CarPlay`

A CarPlay-shaped window should appear next to the iPhone simulator. The CarPlay scene will connect, the Tours tab will populate, and tapping a tour pushes the system Now Playing template.

**Caveat:** CarPlay in the simulator is finicky when the entitlement hasn't been granted by Apple. If the window opens but stays blank, or if the templates render strangely, fall back to the iPhone scene. The iPhone path is the canonical milestone-1 test surface; CarPlay is a bonus.

If the CarPlay window does work, you should see:

- A tab bar with **Tours** and **Live**
- The Tours tab listing the Connecticut Avenue tour
- Tapping it starts playback and pushes the Now Playing template
- Tapping the "Playing Next" button pushes a list of upcoming waypoints
- The Now Playing artwork is a placeholder indigo card with the tour title

## Step 8 — Manually advancing or restarting

You don't have to wait for the GPX to drive you between waypoints. The forward button on the Now Playing banner (and the steering-wheel "next track" command, if you wire one up) calls `manualAdvance()` and immediately plays the next story. Useful for jumping to story 7 to verify the Taft Bridge narration.

To restart the tour, tap **End**, then tap the tour again.

## Troubleshooting

### "Catalog won't load"

- Verify the backend is up: `curl https://curio-api-1096302431561.us-central1.run.app/tours` should return JSON with one tour.
- Check the iPhone simulator's network — sometimes Mac firewalls block it.
- Look at the Xcode console for "TourCatalogStore: failed to load" messages.

### "Audio doesn't play when I tap a tour"

- Confirm the audio URL works: `curl -I https://curio-api-1096302431561.us-central1.run.app/tours/connecticut-avenue/audio/01-bethesda-metro.mp3` should return `200`.
- Mac volume on, speakers not muted, simulator not muted.
- Check the Xcode console for "TourPlayer: failed to activate audio session."

### "Location is stuck at the first GPX point"

- Make sure you actually clicked the GPX file in `Debug → Simulate Location` after adding it. Adding it to the workspace is not the same as activating it.
- The GPX timestamps start at 2026-04-15T15:00:00Z. The simulator's location pump uses *relative* time between consecutive `<time>` elements, not absolute clock time, so this is fine.

### "Stories advance too fast / cut each other off"

- Increase `SEGMENT_DURATION_SEC` in `backend/src/scripts/generate-gpx.ts` (try 130 or 150).
- Regenerate: `cd backend && npx tsx src/scripts/generate-gpx.ts connecticut-avenue > ../sim/connecticut-avenue.gpx`
- Re-add the GPX in Xcode (the previous one is cached; you may need to remove the old reference and add the new file).

### "Stories don't advance at all"

- The GPX may not be active. Look at the Location debug overlay or use `print` in `TourPlayer.onLocationUpdate`.
- Trigger radius might be too small for the GPX sample density. The radius is 200–250m per waypoint; the GPX samples are ~13 sec apart so at city speeds that's well within radius. If you've increased SEGMENT_DURATION_SEC dramatically, you may also need to densify the GPX (`POINTS_PER_SEGMENT` in the same file).

### "Build fails on a missing symbol or import"

A few of these files are brand new (TourPlayer, TourService, TourBrowserView, etc.) and I wrote them without an Xcode to compile-check against. If you hit a compile error, paste it into a Linear comment and I'll fix it on the next session. Likely culprits:

- `@Observable` on an `NSObject` subclass requires Swift 5.9+ — you're on 6.0, should be fine.
- `CPNowPlayingTemplate.shared` should be a property; if Xcode tells you it's a method, the call is `CPNowPlayingTemplate.shared` (no parens) in modern CarPlay SDK.
- `MPMediaItemArtwork(boundsSize:requestHandler:)` is the modern initializer.

## What you're testing

You are testing **the experience of the product**, not a unit. Specifically:

1. **Does this feel like a thing you'd want to drive with?** Is the narrator's voice OK? Is the pacing right? Are the stories interesting? Are 9 stops too many or too few?
2. **Does the trigger-on-approach feel right?** The story should start as you approach a waypoint, not after you've already driven past it. If it feels late, the trigger radius needs to be bigger or moved up-route.
3. **Are the topics any good?** Did I pick a topic worth telling, or is "streetcar suburbs" too dry? Should the next tour go a different direction (Cold War espionage? Architectural history? Something local-color rather than urban-history?).
4. **Is anything missing from the surface?** Pause/play/next is there. End tour is there. What else do you want as a button?

When you're done, dump thoughts into a Linear comment or a follow-up message and I'll iterate.
