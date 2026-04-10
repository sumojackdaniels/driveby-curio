# DriveByCurio

CarPlay contextual tour guide — learn about the land and history around you as you drive.

## Quick Reference

- XcodeGen: `xcodegen generate` (always before build)
- Build path: `/tmp/curio-build`
- CarPlay simulator: I/O > External Displays > CarPlay
- Backend: Cloud Run service `curio-api`
- Shared package: core-swift (SPM)

## Do

- Use TDD: write tests first, verify failure, implement, verify pass
- Screenshot verify after each UI milestone
- Keep CarPlay templates within depth limit (2 on iOS ≤26.3, 3 on 26.4+)
- Refresh POIs at most once per 60 seconds
- Frame everything as "tour guide" / "history guide" — NOT a location finder
- Use core-swift for any code reusable across apps

## Don't

- Don't use Search, Voice Control, or Map templates (not available for driving task apps)
- Don't refresh CarPlay data more than once per 10 seconds
- Don't show more than 12 POIs on CPPointOfInterestTemplate
- Don't instruct user to pick up iPhone while driving
- Don't embed API keys in the app — use backend proxy
