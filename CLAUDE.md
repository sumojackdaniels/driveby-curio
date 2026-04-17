# DriveByCurio

Walking tour platform — pre-authored and user-created audio tours, triggered by GPS as you walk. iPhone-only; CarPlay prototype archived under `archive/`.

## Quick Reference

- XcodeGen: `xcodegen generate` (always before build)
- Build path: `/tmp/curio-build`
- Shared package: core-swift (SPM) — `LocationService`, `HeadingCalculator`, `APIClient`
- Tour assets: `DriveByCurio/WalkingTours/{tour-id}/{waypoint-id}/` (audio bundled as folder reference)
- Archive: `archive/` holds the CarPlay prototype, driving-tour backend, and legacy specs. Not built by Xcode. Reference only.

## Do

- Use TDD: write tests first, verify failure, implement, verify pass
- Screenshot verify after each UI milestone
- Frame everything as "walking tour" / "story" — NOT a location finder or navigation app
- Use core-swift for any code reusable across apps
- Keep walking tours v1 fully local — no backend dependency

## Don't

- Don't re-introduce CarPlay code into the live target — the archive stays archived
- Don't instruct user to stare at the phone while walking; audio-first, glance-only UI
- Don't embed API keys in the app — if a backend returns, use a proxy
- Don't commit `archive/backend/node_modules/` (gitignored)
