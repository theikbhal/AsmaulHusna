# Install

## Build and install

```bash
scripts/build_app.sh
```

What it does:

1. `swift build -c release`
2. generates `Resources/AppIcon.png` if missing and turns it into an `.icns`
3. assembles `build/AsmaulHusna.app` with `Info.plist` (bundle id `com.ikbhal.asmaulhusna`)
4. copies it to `/Applications/AsmaulHusna.app`
5. creates the Desktop shortcut `~/Desktop/AsmaulHusna`

Build only (no install):

```bash
scripts/build_app.sh --build-only
open build/AsmaulHusna.app
```

Requirements: macOS 14+, Swift toolchain (`xcode-select --install`).

## Permissions

| Feature | Permission | Where |
| --- | --- | --- |
| Daily reminder | Notifications | System Settings → Notifications → AsmaulHusna |
| Start at login | Login item | approved automatically, or System Settings → General → Login Items |
| Record window (MP4) | Screen Recording | System Settings → Privacy & Security → Screen Recording |
| PNG screenshots, reel export | none | rendered in-process with `ImageRenderer` |

Notifications only schedule reliably from a real `.app` bundle — always test from
`/Applications/AsmaulHusna.app`, not from `swift run`.

## Where files go

- PNG posts / stories / squares / carousels / reels → `~/Desktop/AsmaulHusna-Exports/`
- Progress → UserDefaults (`ah.*` keys for progress, `asmaulhusna.settings.*` for preferences)

## Uninstall

```bash
rm -rf /Applications/AsmaulHusna.app ~/Desktop/AsmaulHusna
defaults delete com.ikbhal.asmaulhusna
```
