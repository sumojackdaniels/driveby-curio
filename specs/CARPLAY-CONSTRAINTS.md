# CarPlay Constraints and Decisions for DriveByCurio

> This document records the CarPlay-related decisions that constrain DriveByCurio's architecture and product shape. It is derived from the *CarPlay Entitlement Addendum* (Rev. 2025-11-18) and the *CarPlay Developer Guide* (February 2026). Both sources are the authoritative Apple documentation; excerpts and the full Developer Guide PDF live under [`specs/reference/`](./reference/).
>
> If anything in this document conflicts with a feature proposal, the constraint wins — we either redesign the feature to fit, or we do not ship it. The CarPlay entitlement is the long-pole gating item for the whole product and we cannot afford a rejection for reasons that are avoidable at design time.

---

## Category decision: CarPlay Audio App

**DriveByCurio will be submitted to Apple under the CarPlay Audio App category** (Entitlement Addendum §3.4, Developer Guide pp. 4–5), not under the CarPlay Driving Task App category.

Entitlement key:

```xml
<key>com.apple.developer.carplay-audio</key>
<true/>
```

Minimum iOS: 14. (Developer Guide p. 12.)

### Why not Driving Task

An earlier iteration of this spec assumed Driving Task was the right category. It is not. Entitlement Addendum §3.10 disqualifies us on two grounds:

1. **"may not combine driving tasks with media functions"** — DriveByCurio's entire output is narrated audio content, which is a media function by any reasonable reading. A Driving Task app that plays narrated stories would be combining the two. This clause is a straight prohibition.
2. **"may not be primarily designed to provide a list of Points of Interests (POIs) or locations"** — reinforced on Developer Guide p. 5 guideline 6: *"Do not create POI (point of interest) apps that are focused on finding locations on a map. Driving tasks apps must be primarily designed to accomplish tasks and are not intended to be location finders (e.g. store finders)."* Our CarPlay surface is organized around points of interest, which reads empirically as a POI app whether we frame it as "tour guide" or not.

Apple's own examples of Driving Task apps in both the addendum and the Developer Guide are all vehicle-control / utility apps (car sharing, gate controls, trailer/towing accessory control, mileage trackers). Nothing in the Driving Task category resembles an experiential content app. The category is scoped to things the driver *does* to operate the vehicle or vehicle-adjacent accessories — not to things the driver *listens to* while driving.

### Why Audio

Addendum §3.4 defines CarPlay Audio apps as those "designed primarily to provide audio playback services to a user (e.g., music, podcasts, **audio books**, **radio services**, and **sports broadcast apps**)." Developer Guide p. 5 adds a single additional guideline: "Never show song lyrics on the CarPlay screen."

DriveByCurio maps cleanly onto two of Apple's Audio exemplars:

- **Curated tours** are structurally an audiobook. User picks a pre-authored sequence of narrated content from a catalog, audio plays, the user can advance stories. The only non-standard aspect is that transitions between "chapters" are triggered by GPS position rather than by linear playback time — a detail of *when* the next audio plays, not *whether* the app is primarily an audio playback service.
- **Live contextual mode** is structurally a radio service or a sports broadcast. Content is determined by an external signal (in our case, the vehicle's position in the world), played continuously, not user-selected from a track library. This is the same shape as a radio app (content determined by broadcast signal) or a sports broadcast app (content determined by the game in progress).

Both modes are **audio playback services** whose content is location-influenced. That's the correct category.

### Audio-category constraints we must respect

From Developer Guide p. 4 guidelines for all CarPlay apps, and p. 5 for Audio apps:

- **G1.** Primary purpose must be audio playback — every CarPlay surface must serve that.
- **G3.** All CarPlay flows must be possible without interacting with iPhone. Tour selection, live mode toggle, topic configuration — all must be reachable from CarPlay alone. iPhone-only pre-drive setup is not permitted as the *only* path.
- **G5.** No gaming or social networking.
- **G6.** Never show the content of messages, texts, or emails on CarPlay. (Not a concern for us — just noting.)
- **G7 (critical for us).** *"Use templates for their intended purpose, and only populate templates with the specified information types (e.g. a list template must be used to present a list for selection, album artwork in the now playing screen must be used to show an album cover, etc.)."* The Now Playing artwork slot **must be album cover art**, not a photo of the current point of interest. See the Artwork section below for how this shapes the design.
- **G8.** Voice interaction must be via SiriKit (Audio apps cannot use the Voice Control template).
- **Audio-specific.** Never show song lyrics on the CarPlay screen. (Not a concern.)

---

## Entitlement and Info.plist configuration

From Developer Guide pp. 11, 28–29.

### Entitlements.plist

```xml
<key>com.apple.developer.carplay-audio</key>
<true/>
```

This replaces the current (incorrect) `com.apple.developer.carplay-driving-task` entry in `DriveByCurio/Entitlements.plist` and `project.yml`.

### Info.plist scene manifest

CarPlay apps declare two scenes: one for the iPhone, one for CarPlay. Template from the Developer Guide (p. 28):

```xml
<key>UIApplicationSceneManifest</key>
<dict>
  <key>UISceneConfigurations</key>
  <dict>
    <key>UIWindowSceneSessionRoleApplication</key>
    <array>
      <dict>
        <key>UISceneClassName</key>
        <string>UIWindowScene</string>
        <key>UISceneConfigurationName</key>
        <string>PhoneSceneConfiguration</string>
        <key>UISceneDelegateClassName</key>
        <string>$(PRODUCT_MODULE_NAME).PhoneSceneDelegate</string>
      </dict>
    </array>
    <key>CPTemplateApplicationSceneSessionRoleApplication</key>
    <array>
      <dict>
        <key>UISceneClassName</key>
        <string>CPTemplateApplicationScene</string>
        <key>UISceneConfigurationName</key>
        <string>CarPlaySceneConfiguration</string>
        <key>UISceneDelegateClassName</key>
        <string>$(PRODUCT_MODULE_NAME).CarPlaySceneDelegate</string>
      </dict>
    </array>
  </dict>
</dict>
```

The current MVP scaffold already has `PhoneSceneConfiguration`. We need to audit what it currently does for CarPlay and align it with the `CPTemplateApplicationScene` pattern above.

### UIBackgroundModes

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
  <string>location</string>
</array>
```

- `audio` — required; allows narration to continue when another app (e.g. Apple Maps) takes the CarPlay screen.
- `location` — required for waypoint-triggered narration in curated tours, since the trigger signal must fire even when the app isn't foreground on CarPlay (e.g. during Apple Maps handoff).

### Scene delegate

The CarPlay scene delegate conforms to `CPTemplateApplicationSceneDelegate`. Key methods (Developer Guide p. 29):

- `templateApplicationScene(_:didConnect:)` — called when CarPlay connects. Hold on to the `CPInterfaceController` passed in; it manages all templates. Set an initial root template.
- `templateApplicationScene(_:didDisconnect:)` — release the interface controller.

> **Guide note:** "Your app may be launched *only* on the CarPlay screen so be sure to handle this use case." — Developer Guide p. 29. We cannot assume the iPhone scene has run first.

---

## Templates available to Audio apps

The Audio category supports a specific subset of CarPlay templates (Developer Guide p. 13 table). This is a hard constraint — using a template outside the allow-list raises a runtime exception.

| Template | Available to Audio? | Role in DriveByCurio |
|---|---|---|
| `CPNowPlayingTemplate` | ✅ | Primary surface. Shows current story title, tour cover art, playback controls, "next" button. |
| `CPListTemplate` | ✅ | Tour catalog browsing (pre-drive), upcoming stories queue (pushed on top of Now Playing), passenger QR surface (TBD — see open questions). |
| `CPTabBarTemplate` | ✅ | Top-level navigation. Audio apps get **4 tabs max** (vs. 5 for other categories). Planned tabs: **Tours**, **Live**, plus iOS-supplied Now Playing shortcut in the top-right corner when audio is active. |
| `CPGridTemplate` | ✅ | Possibly useful for a small fixed set of tour categories or "start live mode" entry points. Up to 8 icon+title items. |
| `CPActionSheetTemplate` | ✅ (iOS 17+) | Confirmations — e.g. "End tour?" when user taps back. |
| `CPAlertTemplate` | ✅ | Error states — no network, no location permission, tour unavailable. |
| `CPInformationTemplate` | ❌ | **Not available to Audio.** A prior version of this spec assumed it was — it isn't. Anything we thought of as "information screen" (longer text about a POI, tour metadata detail) must be re-imagined as a List template row or moved to the passenger device. |
| `CPPointOfInterestTemplate` | ❌ | Driving-task / location-category only. We cannot show POI pins on a map in our CarPlay surface. |
| `CPMapTemplate` | ❌ | Navigation-only. We never draw a map; we hand off to Apple Maps. |
| `CPContactTemplate` | ❌ | Communication-category only. |
| `CPSearchTemplate` | ❌ | Navigation-only. Fine — we explicitly do not want a search surface. |
| `CPVoiceControlTemplate` | ❌ | Navigation and voice-conversational categories only. Audio apps must route voice via SiriKit. |

### Depth limit

Audio apps can push templates to a depth of **5 templates** deep (Developer Guide p. 13). Ample headroom.

### Template usage rules worth restating

From Developer Guide p. 20 (Now Playing specifics):

- `CPNowPlayingTemplate` is a **shared instance**: `CPNowPlayingTemplate.shared()`.
- **"Only the list template may be pushed on top of the now playing template."** This is the mechanism for showing the upcoming-stories queue: enable a "Playing Next" button on Now Playing, respond by pushing a `CPListTemplate` containing the queue.
- The elapsed-time indicator can be configured for **fixed-length audio** (individual stories) or **open-ended live streams** (live mode). Both modes are supported natively.

---

## Now Playing template — what we can show

The Now Playing template is our primary driving-time surface. From the Developer Guide and Apple guideline 7, here is what we can and cannot put in it.

### Text metadata

Provided via `MPNowPlayingInfoCenter` (standard iOS now-playing integration, used by every audio app). Relevant fields for our use case:

- **Title** — the current story's title (e.g. *"The Freedom Trail: Boston Massacre Site"*). Updates dynamically as the tour advances.
- **Artist** — repurposed as the **current subject** (e.g. *"King Street, 1770"*), or as the tour author / brand. Decision TBD during implementation.
- **Album** — the **tour name** (e.g. *"The Freedom Trail by Car"*). Constant for the duration of a curated tour; set to *"Live Tour"* or similar for live mode.
- **Elapsed time / duration** — for curated stories, real elapsed/total; for live mode, configured as an open-ended live stream.

Dynamic updates to these fields during playback are supported and expected — standard audio-app behavior. Every track change on Spotify or Apple Music works this way.

### Artwork

Per guideline 7 (Developer Guide p. 4), the Now Playing artwork slot **must be used to show an album cover**. This means:

- **Curated tours:** the tour's cover art — a single image representing the tour as a whole — stays in the artwork slot for the entire duration of the tour. It does not change per story.
- **Live mode:** a single image representing live mode as a feature (a Curio logo, or an abstract "contextual listening" image). Does not change based on location.

**We cannot put a photo of the current point of interest in the Now Playing artwork slot.** The earlier product spec assumed we could; we cannot. Per-story imagery must live elsewhere (see the Passenger QR section for where).

### Playback buttons

Now Playing buttons are customizable (Developer Guide p. 20, 31). We can populate via `nowPlayingTemplate.updateNowPlayingButtons([...])`. For DriveByCurio, the relevant buttons are:

- **Play / pause** — standard transport control.
- **Next** — advance to the next story in the current tour or skip the current live-mode segment. Functionally equivalent to Apple Music's next-track button. This is the single "while driving" interaction point.
- **Playing Next** — pushes a `CPListTemplate` showing the upcoming stories queue. Tapped at a stop, not while moving.
- **Maybe: Open in Maps** — launches Apple Maps via the handoff pattern described below. May live as a button on Now Playing or as a list item in the "Playing Next" queue. TBD.

### Sports mode (iOS 18.4+)

Developer Guide pp. 20–21 describes a richer Now Playing variant for sports broadcast apps, with background artwork, event status text, team logos, scores, clocks, etc. It's tempting, but guideline 7 forbids using templates outside their intended purpose. **We do not use sports mode for tour narration.** It would almost certainly be flagged during review.

---

## Driver-visible surfaces and the rich-content problem

### What the driver sees on CarPlay, full inventory

1. **Tab bar** — Tours, Live. At-a-glance mode switching.
2. **Tour catalog** — `CPListTemplate` with `CPListImageRowItem` showing tour cover art, title, subtitle, duration/distance.
3. **Now Playing** — tour cover art in the artwork slot, current story title in the title field, current subject in the artist field, tour name in the album field, play/pause/next buttons, and (optionally) a "Playing Next" button and an "Open in Maps" button.
4. **Upcoming stories queue** (`CPListTemplate`, pushed on top of Now Playing) — list of upcoming story titles in the current tour, accessed by tapping "Playing Next."
5. **Alerts** — errors (no network, no location, tour unavailable) and confirmations ("End tour?").

### What the driver does NOT see

- Photographs of points of interest (forbidden by guideline 7 in the artwork slot; no Information template available elsewhere).
- Long-form text (no Information template, List template rows are constrained to title + subtitle + image).
- Maps (no `CPMapTemplate` available; no `CPPointOfInterestTemplate` available).
- Search fields or arbitrary POI browsing.
- Video of any kind (no template supports video in any CarPlay category).

### The "stationary enriched view" idea — dropped

An earlier version of this spec proposed that when the vehicle stops, the CarPlay display would swap to an enriched layout showing photographs of the current POI, longer text, and richer passenger content. **This cannot be implemented within the Audio category:**

1. There is no `CPInformationTemplate` or equivalent available to Audio apps.
2. The Now Playing artwork slot cannot be repurposed to show per-story photos (guideline 7).
3. There is no CarPlay API for vehicle motion state available to Audio apps — we cannot trigger a view swap on "vehicle is stopped." (`CLLocationManager.speed` gives us the signal, but there is no documented pattern for motion-driven template swaps.)
4. The concept relied on a mental model of the CarPlay display as a canvas we control. Audio category CarPlay surfaces are **fixed templates** with specific slots; we fill the slots, we don't paint the canvas.

**Where rich content goes instead:** all per-story photography, long-form text, historical context, and deep reference material lives on the **passenger device** via the QR handoff (see next section). The driver's CarPlay surface stays minimal and compliant; the rich experience is pushed to a different device in a different seat.

This is actually a cleaner product story. The passenger-device handoff is no longer a "differentiator on top of" a rich driver view; it is the **only** rich surface the product has, and the driver surface is deliberately, unambiguously spare.

---

## Passenger QR handoff — open design questions

The product vision calls for a QR code on the CarPlay display that passengers scan to open a companion experience on their own phone. Under Audio category templates, **there is no clean canonical slot for a QR code** on the driver-visible CarPlay surface. This is an open design problem.

Options, roughly in order of preference:

1. **QR as a dedicated tab.** A `CPListTemplate` or `CPGridTemplate` containing a single item whose image is the QR code. Accessed by the driver tapping the "Pair" or "Passenger" tab at a stop. Works within the template rules. Downside: not persistently visible while a tour is playing, which means a passenger who boards mid-drive has to wait for a stop to pair.
2. **QR as a list row in the upcoming-stories queue.** When the user taps "Playing Next" from Now Playing, the list that's pushed could include a pinned top row with the QR code as its image. Downside: conflates passenger pairing with the queue view; feels grafted on.
3. **QR on the iPhone app, not on CarPlay.** Passenger pairs by scanning from the driver's iPhone before the drive. Downside: violates the spirit of guideline 3 (CarPlay-only flows) for a safety-critical feature, and doesn't handle passengers who board mid-drive.
4. **No in-car QR pairing at all. Passenger joins via a link they get from the driver separately (text message, verbal instructions, etc.).** Technically simplest but removes a lot of the frictionless UX.

**Recommendation:** option 1 during the architectural sprint. Decision deferred to implementation.

Note: this is a product-surface question, not a category-compliance question. QR codes as images inside standard templates are not per se prohibited by anything in the guide — the constraint is only that we cannot dedicate the Now Playing artwork slot to them (guideline 7) and that we need them to be reachable from CarPlay alone (guideline 3).

---

## Audio session management

Developer Guide p. 27, plus standard iOS `AVAudioSession` patterns.

**Critical rule:** *"Only activate your audio session the moment you are ready to play audio. When you activate your audio session, other audio sources in the car will stop. For example, if someone is listening to the car's FM radio and you activate your audio session too soon, the FM radio will stop."*

Implications:

- **Do not activate the audio session on app launch.** The user might just be opening Curio to browse tours, not to play immediately; activating the session would kill whatever the driver was already listening to.
- **Activate the session only at the moment of "Start Tour" or "Start Live Mode."** The explicit user action that commits to playback.
- **Deactivate when playback truly ends** — user ends the tour, or tour completes with no continuation.
- **Handle interruptions correctly.** Phone calls, nav prompts, etc. The standard `AVAudioSession` interruption-handling pattern applies. During a phone call, we duck or pause; we resume cleanly after.
- **Mix with Apple Maps during handoff.** Our audio session must allow Apple Maps's turn-by-turn voice prompts to duck our narration cleanly. The standard audio session options (`.mixWithOthers` is *not* correct for our case — we are primary audio, not background; Maps should duck us temporarily during its prompts) handle this.

Session category: `.playback`. Standard for audio content apps.

---

## Apple Maps handoff — the blessed pattern

Developer Guide p. 27:

> "If your app launches other apps in CarPlay, such as to get directions or make a phone call, use the `CPTemplateApplicationScene open(_:options:completionHandler:)` method to launch the other app using a URL to ensure it launches on the CarPlay screen."

**Apple explicitly names "get directions" as the example use case for this API.** Our hand-off to Apple Maps is a documented, blessed pattern — not a clever workaround.

Implementation sketch:

```swift
let mapsURL = URL(string: "http://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=d")!
carPlayScene.open(mapsURL, options: nil) { success in
    // Audio session continues in background; Apple Maps takes over the CarPlay display.
}
```

Where `carPlayScene` is the `CPTemplateApplicationScene` held by our CarPlay scene delegate.

Apple Maps takes over the CarPlay display and provides turn-by-turn. DriveByCurio's audio session continues holding audio in the background, and narrates each waypoint's story as the driver approaches it. Apple Maps's own voice prompts duck our narration via the standard iOS audio session mixing rules. When the driver arrives at a waypoint and the story finishes, the next story queues up automatically; at waypoint boundaries where routing is needed, we can re-invoke `open(mapsURL)` with the next destination.

This pattern requires:

- Our `UIBackgroundModes` includes `audio` (required) and `location` (so waypoint triggers fire during handoff).
- Our audio session is set up to duck, not pause, on ephemeral interruptions (turn-by-turn voice).
- We do not try to draw anything on the CarPlay display during handoff — Apple Maps owns it.
- When Apple Maps completes route guidance or the user backs out of Maps into Curio, our CarPlay scene becomes visible again. We must handle scene activation / deactivation correctly.

---

## Location access

Nothing in the CarPlay Developer Guide or the Entitlement Addendum restricts Audio apps from accessing `CLLocationManager`. Standard iOS location authorization applies:

- Request `authorizedWhenInUse` on first use for tour selection and live mode toggle (iPhone or CarPlay).
- Request `authorizedAlways` for background waypoint triggering during curated tours (needed so narration fires when Apple Maps is foreground on CarPlay).
- `UIBackgroundModes` must include `location` for continued updates while backgrounded.
- `Info.plist` must include `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` with user-visible copy explaining *why* we need location.

**Framing for the usage descriptions** (important for App Store review independent of CarPlay review):

- `NSLocationWhenInUseUsageDescription`: "DriveByCurio uses your location to show you tours near where you are and to play audio stories about the places you're passing on your drive."
- `NSLocationAlwaysAndWhenInUseUsageDescription`: "DriveByCurio plays audio stories about nearby places even when the app is in the background — for example, while Apple Maps is showing directions on your CarPlay screen during a tour."

### Two legitimate uses of location

Location is used for two purposes in the app, both disclosed in the CarPlay entitlement submission to Apple (April 2026):

1. **Filtering / sorting the tour catalog by proximity.** When the user opens the Tours tab, the catalog is surfaced so that tours available in the user's current region appear first. This is a standard catalog-sort UX — the same way Audible sorts audiobooks by "Recently Added" or Apple Music sorts playlists by listening history. It is not a map, not a POI browser, not a "find places near me" surface. The items in the list are **tours** (curated, pre-authored audio content), not arbitrary locations, and selecting one starts audio playback — same as tapping an album.
2. **Triggering audio segment playback.** Once a tour is running, `CLLocationManager` updates fire the next narrated story as the vehicle approaches each waypoint. Audio-only trigger; no UI.

**Location is never surfaced as a map, a POI pin collection, or a browsable "places" catalog.** The tour list is a list of audio content items, not a list of locations. The distinction matters because it is what keeps us in the Audio category and not in Driving Task / POI territory.

The exact framing submitted to Apple, verbatim: *"Used for listing tours available locally, and as a trigger signal for which audio plays next — never surfaced as a map, POI list, or location browser."*

---

## Guideline 3 compliance: CarPlay flows without iPhone

Developer Guide p. 4 guideline 3 is a hard requirement: **all CarPlay flows must be possible without interacting with iPhone.**

For DriveByCurio this means every one of the following must be doable from the CarPlay display alone:

- Browse the curated tour catalog and select a tour to start.
- Toggle live mode on, and off.
- Advance to the next story; skip the current story.
- Open Apple Maps to route to the next tour waypoint.
- End the current tour / live mode.
- Pair a passenger device via the QR code (per the open design question above).

**Things that may still live iPhone-only** (because they are "outside the vehicle environment" and per Audio category practice are fine to put on iPhone):

- Account setup and sign-in.
- Topical interest configuration for live mode.
- Payment / subscription management.
- Tour downloads for offline use.
- Long-form account history, saved places, achievements, social features.

The distinction is: *in-drive flows must work from CarPlay; pre-drive configuration and administrative flows may be iPhone-only.*

---

## Notifications: not available to Audio apps

Developer Guide p. 25. CarPlay notifications are supported in communication, EV charging, parking, public safety, and (iOS 18.4+) driving task apps. **Audio apps cannot show CarPlay notifications.** This means:

- We cannot announce "Next story: Boston Tea Party Site" via a notification that briefly appears on the CarPlay screen.
- All driver-facing narration state lives in the Now Playing template, which updates when we push new `MPNowPlayingInfoCenter` info.

Fine for our design; just worth knowing.

---

## Testing

Developer Guide p. 7:

- **CarPlay Simulator** — a standalone Mac app in *Additional Tools for Xcode*. Closest to real CarPlay behavior. Connects to a real iPhone via USB.
- **Xcode Simulator CarPlay window** — iOS Simulator has a built-in CarPlay window via `I/O > External Displays > CarPlay`. Convenient for iteration but Apple recommends CarPlay Simulator for the final pass.
- **CarPlay Simulator is required** for scenarios that can't be tested in Xcode Simulator: locked-iPhone behavior, CarPlay connect/disconnect runtime, audio-citizen behavior (activating the audio session correctly without stopping the car's FM radio), SiriKit integration, and instrument cluster displays.

For DriveByCurio specifically, the **audio session citizen testing** is important: we need to verify we don't activate the session until the user explicitly starts a tour or live mode, and that we handle mixing with Apple Maps voice prompts correctly during handoff.

---

## Implementation checklist (derived from this document)

Once the CarPlay entitlement is granted, implementation tasks that are directly dictated by this document:

1. Replace `com.apple.developer.carplay-driving-task` with `com.apple.developer.carplay-audio` in `DriveByCurio/Entitlements.plist` (currently driven by `project.yml`).
2. Update `project.yml` entitlement property and regenerate the xcodeproj.
3. Add `location` to `UIBackgroundModes` alongside `audio`.
4. Add `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` to `Info.plist` with the usage framing above.
5. Audit / rebuild the CarPlay scene delegate as `CPTemplateApplicationSceneDelegate`, with the root template set in `didConnect`.
6. Redesign the CarPlay UI around the template allow-list above (Tab bar → Tours / Live, Tour catalog List, Now Playing, upcoming-stories List pushed on top of Now Playing).
7. Implement the audio session activation rule (only at "Start Tour" / "Start Live Mode", not on app launch).
8. Implement the Apple Maps handoff via `CPTemplateApplicationScene.open(_:options:completionHandler:)`.
9. Make sure every in-drive flow (listed in the guideline 3 section) is reachable from CarPlay alone.
10. Decide the QR code surface via the architectural sprint (see open questions).
11. Test audio-citizen behavior in CarPlay Simulator before submitting for review.

---

## References

- [`specs/reference/CarPlay-Developer-Guide-2026-02.pdf`](./reference/CarPlay-Developer-Guide-2026-02.pdf) — Apple, February 2026. Primary source for everything in this document.
- CarPlay Entitlement Addendum (Rev. 2025-11-18). Legal / category definitions; the "may not combine driving tasks with media functions" clause in §3.10 is the reason we pivoted away from Driving Task.
- [`specs/PRODUCT.md`](./PRODUCT.md) — product direction. Framing sections are kept in sync with the constraints here.
- [`specs/MVP-spec.md`](./MVP-spec.md) — the current MVP implementation record (live mode only). Pre-dates the category pivot; the CarPlay sections there should be treated as historical. The MVP's CarPlay implementation will be redesigned as part of the post-MVP Audio-category work.

---

## Appendix: CarPlay Audio entitlement submission to Apple (April 2026)

For the record, here is the verbatim text submitted to Apple in the *"What specific CarPlay features do you plan to implement?"* field of the CarPlay Audio entitlement request form. This is the pitch Apple is reviewing; any future submission or appeal should be consistent with it.

```
Templates (Audio allow-list):
- CPTabBarTemplate — Tours + Live tabs; system Now Playing shortcut auto-appears
- CPListTemplate — tour catalog (image-row style) and upcoming-stories queue pushed on top of Now Playing
- CPNowPlayingTemplate — primary driving surface; tour cover art in artwork slot, story title/subject/tour via MPNowPlayingInfoCenter, custom Play/Pause/Next/Playing-Next buttons
- CPAlertTemplate, CPActionSheetTemplate — errors and "End tour?" confirmations

Media/audio: MPNowPlayingInfoCenter for dynamic story updates; MPRemoteCommandCenter for steering-wheel controls; AVAudioSession .playback activated only when the user explicitly starts a tour, not on app launch.

Apple Maps hand-off: CPTemplateApplicationScene.open(_:options:completionHandler:) with a maps.apple.com URL — documented on p. 27 of Apple's February 2026 CarPlay Developer Guide. Maps takes the CarPlay display for turn-by-turn; we keep playing audio in the background (UIBackgroundModes includes audio + location), narrate each waypoint as the driver approaches, and Maps's voice prompts duck our narration via standard audio session mixing.

Location: CLLocationManager authorizedAlways for background waypoint triggering. Used for listing tours available locally, and as a trigger signal for which audio plays next — never surfaced as a map, POI list, or location browser.

Guideline 3: every in-drive flow (browse, start/end tour, toggle live mode, advance stories, invoke Maps) is reachable from CarPlay alone. iPhone is for out-of-vehicle concerns only.
```

### Notes on what was NOT in the submission

The submitted pitch deliberately omits content that is nonetheless binding on the implementation — it was cut for concision to fit the form field's length constraint, not because it's off the table:

- **The "Not implementing" enumeration** (no `CPMapTemplate`, `CPPointOfInterestTemplate`, `CPSearchTemplate`, `CPInformationTemplate`, `CPContactTemplate`, in-app turn-by-turn, video, CarPlay notifications, recording, or song lyrics on the CarPlay screen). These are still all off-limits — they're documented in the *Templates available to Audio apps* section above and in the *Driver-visible surfaces* section. Any implementation work that reaches for one of these templates is a spec violation regardless of whether Apple saw that list in the pitch.
- **The "Why not Driving Task" reasoning.** Not relevant to Apple's Audio-category reviewer, who is evaluating a fresh Audio request and doesn't need to hear the history of how we got there.
- **The scene / `CPTemplateApplicationScene` / `UIBackgroundModes` setup boilerplate.** Every CarPlay app does this exactly the same way; it's not a feature choice, and mentioning it would dilute the distinctive content. The `UIBackgroundModes = [audio, location]` combination is mentioned inline in the Apple Maps hand-off paragraph, where it's relevant to the behavior being described.
