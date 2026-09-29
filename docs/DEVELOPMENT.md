# Development

## Everyday commands

```bash
swift build                 # debug build
swift run                   # run from the terminal (no login item / notification id)
./scripts/build_app.sh --build-only   # assemble build/AsmaulHusna.app
./scripts/build_app.sh               # assemble + install + Desktop shortcut
```

## Project layout

| Path | Role |
| --- | --- |
| `Sources/AsmaulHusna/AsmaulHusnaApp.swift` | window, environment objects, `⌘1…⌘7` commands |
| `AppState.swift` | tabs, onboarding flags, `recordRead()`, badge checks, toast |
| `Names.swift` | the 99 entries (`ar/tr/te/en/ta`) + generated dua + hadith bank |
| `ReadStore.swift` | per-day counts, streak, heatmap, mastery, 99-day cycle |
| `ChallengeStore.swift` | 7 challenges, four fields each, family members, evening window |
| `GameStore.swift` | XP/level curve, coins, badge catalogue |
| `MemoStore.swift` | Leitner boxes (5) + technique copy |
| `AvatarStore.swift` | wardrobe parts, unlocks by level, garden stages |
| `Settings.swift` | every preference and feature switch (UserDefaults, prefix `asmaulhusna.settings.`) |
| `Theme.swift` | 100 themes (`AppTheme.make(id)`), night-mode darkening |
| `Capture.swift` | `ImageRenderer` PNGs, reel MP4 encoder (AVAssetWriter), ScreenCaptureKit recorder |
| `UI/` | one view per sidebar tab + `ShareCard` (offscreen Instagram render) |

## Data model (UserDefaults)

| Key prefix | Contents |
| --- | --- |
| `ah.counts` | `["2026-09-29#12": 4]` reads per name per day |
| `ah.done` | days that reached the minimum pass |
| `ah.pername` | all-time reads per name id |
| `ah.best` | best streak |
| `ah.game.*` | xp, coins, unlocked badges |
| `ah.memo.cards` | Leitner card per name |
| `ah.challenges.*` | challenge configs, evening counts, passed periods |
| `ah.avatar` | selected `[dress, cap, pet, tree, tint]` |
| `ah.onboard.*` | onboarding flags |
| `asmaulhusna.settings.*` | every preference / feature switch |

## Patterns used

- **Singleton stores** (`ReadStore.shared`, …) injected as environment objects; the UI stays declarative.
- **Single write path**: every recitation goes through `AppState.recordRead(_:)` so XP, challenges,
  confetti and badges can never drift apart.
- **`didSet → persist()`** on `@Published` settings.
- **Offscreen rendering**: `ImageRenderer` + fixed frame (`ShareCard`) for pixel-exact Instagram sizes.
- **Feature switches**: hide whole tabs in `RootView.visibleTabs` instead of dead buttons.

## Release flow

1. bump `VERSION` in `scripts/build_app.sh` and the About text in `SettingsPane.swift`
2. `./scripts/build_app.sh`
3. `git add -A && git commit && gh repo create theikbhal/AsmaulHusna --public --source --push`
4. `git tag v1.0.0 && git push --tags`
