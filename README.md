# Asmaul Husna — daily reader for the 99 Beautiful Names

A native macOS app that gives you **one of the 99 names of Allah every day** — in Arabic,
transliterated in English letters, transliterated in Telugu letters, with a short dua, a short
meaning (English + Telugu) and a hadith or ayah about it — then keeps your **streak, challenges,
badges, memorisation ladder and garden** honest.

> **اَلرَّحْمَٰنُ** · Ar-Rahman · అర్-రహ్మాన్ · *The Most Merciful* · అత్యంత కరుణగలవాడు
>
> Dua: **يَا رَحْمَٰنُ ٱغْفِرْ لِي وَٱرْحَمْنِي** — *Yā Raḥman, ighfir lī wa-rḥamnī*
> — “O The Most Merciful, forgive me and have mercy on me.”

## Features

- **Read tab** — Arabic (large, RTL) · English transliteration · Telugu transliteration ·
  meaning in English and Telugu · a short dua for that name · a hadith/ayah attached to it.
  `Space` = read once, `Esc` = undo, `←/→` switch names, drag the card to tilt it in 3D.
- **Streak & pass** — target reads per name (default 3), a **minimum pass** per day, current and
  best streak, automatic midnight rollover, 99-day name cycle.
- **Challenges** — daily · weekly · monthly · yearly · **Sunday** · **evening** · **family**,
  each with four fields: **why** (intention), **when** (slot), **how much** (target),
  **minimum pass** (per-day threshold). Family members get their own avatar and count.
- **Memorize** — cover → recall → grade (Again/Hard/Good/Easy) through 5 Leitner boxes
  (today → 1 → 3 → 7 → 21 days), plus six memorisation techniques.
- **Garden & avatar** — a garden that grows with days passed (bare → soil → seed → sprout →
  sapling → tree → blossom → fruit → harvest) and an avatar with simple, **eye-free** clothes
  (thobe, kurti, abaya, bisht, jubba), headwear (kufi, imamah, scarf), pet silhouettes and trees.
- **Stats / visualisation** — 84-day heatmap, reads-per-day bars, per-name mastery, badge wall.
- **Share tab (Instagram)** — export **Post 4:5 (1080×1350)**, **Story/Reel 9:16 (1080×1920)**,
  **Square 1:1** and **multi-card carousels** as PNGs; render a **reel MP4** (optionally with an
  audio file you choose); or **record the window live** with ScreenCaptureKit.
  Everything lands in `~/Desktop/AsmaulHusna`.
- **Gamified** — XP, levels, coins, **23 badges**, confetti when the day passes.
- **Settings** — 100 background themes, night mode, reminder time, **enable/disable almost every
  feature**, launch at login, and a hidden **Developer settings** pane (day offset, data dump,
  grant badges, reset).
- **Onboarding** — 5 pages explaining *why, when, how much and minimum pass* (replay with ⇧⌘O).
- **Local only** — nothing leaves your Mac. No account, no server, no analytics.

## Install

```bash
git clone https://github.com/theikbhal/AsmaulHusna.git
cd AsmaulHusna
scripts/build_app.sh
```

The script builds the Swift package, assembles `build/AsmaulHusna.app`, **moves it to
`/Applications/AsmaulHusna.app`** and **creates a Desktop shortcut** → `~/Desktop/AsmaulHusna`.

```bash
scripts/build_app.sh --build-only   # build without installing
open build/AsmaulHusna.app
```

Requires macOS 14+ and a Swift toolchain (`xcode-select --install`).

## Shortcuts

| Action | Shortcut |
| --- | --- |
| Read · Memorize · Challenges · Garden | `⌘1` · `⌘2` · `⌘3` · `⌘4` |
| Stats · Share · Settings | `⌘5` · `⌘6` · `⌘7` |
| Count one recitation | `Space` / `Return` |
| Undo | `Esc` |
| Previous / next name | `←` / `→` |
| Replay onboarding | `⇧⌘O` |

## Docs

- [docs/help.md](docs/help.md) — in-app help content
- [docs/INSTALL.md](docs/INSTALL.md) — install, permissions, uninstall
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) — build, layout, release flow

## Project layout

```
AsmaulHusna/
├── Package.swift                 Swift package (executable target)
├── Sources/AsmaulHusna/
│   ├── AsmaulHusnaApp.swift      entry point, window, menu shortcuts
│   ├── AppState.swift            tabs, onboarding, badge checks, recordRead()
│   ├── Names.swift               the 99 names + dua + hadith bank
│   ├── ReadStore.swift           daily counts, streak, heatmap, mastery
│   ├── ChallengeStore.swift      7 challenges, why/when/how much/min pass, family
│   ├── GameStore.swift           XP, levels, coins, 23 badges
│   ├── MemoStore.swift           Leitner boxes + techniques
│   ├── AvatarStore.swift         clothes / cap / pet / tree / garden stages
│   ├── Settings.swift            preferences + feature switches + dev switches
│   ├── Theme.swift               100 background themes + night mode
│   ├── Capture.swift             PNG export, reel encoder, window recorder
│   ├── NotificationManager.swift one daily local reminder
│   ├── LaunchService.swift       start at login (SMAppService)
│   └── UI/                       Read, Memorize, Challenges, Garden, Stats,
│                                 Share, ShareCard, Settings, Onboarding, Help, Avatar
├── Resources/AppIcon.png         generated icon
├── scripts/build_app.sh          build → .app → /Applications → Desktop shortcut
└── docs/                         help, install, development
```

## Uninstall

```bash
rm -rf /Applications/AsmaulHusna.app ~/Desktop/AsmaulHusna
defaults delete com.ikbhal.asmaulhusna   # optional: forget settings
# progress lives under UserDefaults keys starting with "ah."
```

## License

MIT © 2026 Ikbhal — theikbhal@gmail.com
