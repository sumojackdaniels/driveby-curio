# DriveByCurio — Workflow

## Session Start

1. Read: ARCHITECTURE.md, WORKFLOW.md
2. Check session defaults: `mcp__XcodeBuildMCP__session_show_defaults`
3. If resuming a branch: `git fetch origin main && git rebase origin/main`

## Build Rules

- `xcodegen generate` before every build — xcodeproj is gitignored
- Build to `/tmp/curio-build` — iCloud Drive paths cause codesign failures
- `project.yml` is source of truth for plist keys, build settings, everything

## Simulator Builds

1. `session_show_defaults` — verify project/scheme/simulator
2. `session_set_defaults` if needed:
   - projectPath: path to DriveByCurio.xcodeproj
   - scheme: DriveByCurio
   - derivedDataPath: /tmp/curio-build
3. `build_run_sim` — builds, boots simulator, installs, launches

### CarPlay Simulator

To test CarPlay: Simulator → I/O → External Displays → CarPlay

Enable extra options: `defaults write com.apple.iphonesimulator CarPlayExtraOptions -bool YES`

## Design Iteration (SwiftUI Previews)

Shared design-iteration workflow. Full docs are in the `infra` repo: [`docs/design-workflow/`](https://github.com/sumojackdaniels/infra/tree/main/docs/design-workflow). Clone `infra` next to this repo if you don't have it.

Read in this order:
1. [`README.md`](https://github.com/sumojackdaniels/infra/blob/main/docs/design-workflow/README.md) — three-tier workflow overview
2. [`previews-guide.md`](https://github.com/sumojackdaniels/infra/blob/main/docs/design-workflow/previews-guide.md) — **conventions every new screen and component must follow**
3. [`troubleshooting.md`](https://github.com/sumojackdaniels/infra/blob/main/docs/design-workflow/troubleshooting.md) — when the canvas spins, crashes, or reports phantom errors

Quick rules (full detail in `previews-guide.md`):
- **Every new screen** ships `#Preview`, `#Preview("States")`, `#Preview("Dark")`, `#Preview("A11y XL")` at minimum.
- **Split env-coupled views** into a container (reads `@Environment`) + a presentational `<Name>Content` struct that takes plain values. Preview the `Content`.
- **Component vs screen:** reusable components have variant previews in their own file; screens have state previews; never duplicate.
- **Don't reference singletons** (`Service.shared`, `UserDefaults`, `UUID()`, `Date()`) from preview closures — causes non-determinism.

## TDD Workflow

1. Write test for the component
2. Run tests — confirm failure
3. Implement component
4. Run tests — confirm pass
5. Build to simulator, screenshot, verify visually
6. Commit

## Git Conventions

- Branch: `feature/<name>` or `fix/<name>`
- Rebase before every PR: `git fetch origin main && git rebase origin/main`
- Include `[ci skip]` in commit message to skip CI
