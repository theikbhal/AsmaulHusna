# Help

## What is this app?

A daily reader for the **99 Beautiful Names (Asmaul Husna)**. Each day you get a name in
**Arabic**, its **transliteration in English letters**, the **same in Telugu letters**, a
**short dua**, a **short meaning** (English + Telugu) and a **hadith or ayah** about it.

## Why should I read daily?

Consistency is the point. The **99-day cycle** walks through every name — three and a half full
passes a year — and the streak shows exactly how honest you have been.

## When should I read?

Pick one fixed slot; after Fajr is the classic choice. Set the reminder in
**Settings → Daily reminder** (default 06:30). There is also an **evening challenge window**
(18:00–01:00) for reads done after Maghrib.

## How much should I read?

Default: **1 name × 3 reads = 3 reads a day**. Raise it in **Settings → Daily study**
(up to 5 names a day, up to 33 reads each).

## What is the minimum pass?

The pass mark for a day. Reach it and the day counts, the streak grows and the garden grows.
Miss it and the streak stops. Change the number in **Settings → Daily study**, or per challenge
in **Challenges → Minimum pass / day**.

## How do the challenges work?

Seven: **daily · weekly · monthly · yearly · Sunday · evening · family**. Each carries four
fields:

| Field | Meaning |
| --- | --- |
| **Why** | your written intention |
| **When** | the fixed slot |
| **How much** | target reads in the period |
| **Minimum pass** | reads per day for a day to count |

Expand any challenge card to edit them. The family challenge adds members with their own
avatar and a shared target.

## How does memorisation work?

**Memorize** tab: cover the Arabic, recall it, reveal, then grade **Again / Hard / Good / Easy**.
The name moves through five Leitner boxes: **today → 1 → 3 → 7 → 21 days**. Six techniques are
listed at the bottom of the tab (cover & recite, write it three times, pair with meaning,
five-box rhythm, hear & repeat, link the chain).

## How do I share to Instagram?

**Share** tab:

- **Post 4:5** → 1080×1350 PNG (feed)
- **Story / Reel 9:16** → 1080×1920 PNG (story, reel cover)
- **Square** → 1080×1080 PNG
- **Carousel** → one PNG per card in its own folder, numbered in order
- **Export reel** → MP4 at 1080×1920, optionally with an audio file you choose
- **Record window** → live MP4 of the app window (Screen Recording permission)

All files land in `~/Desktop/AsmaulHusna`.

## Is my data safe?

Everything is local — UserDefaults on this Mac. No account, no server, no analytics.
**Settings → Data → Reset everything** erases it all.

## Keyboard shortcuts

| Action | Shortcut |
| --- | --- |
| Read · Memorize · Challenges · Garden | `⌘1` · `⌘2` · `⌘3` · `⌘4` |
| Stats · Share · Settings | `⌘5` · `⌘6` · `⌘7` |
| Count one recitation | `Space` / `Return` |
| Undo | `Esc` |
| Previous / next name | `←` / `→` |
| Replay onboarding | `⇧⌘O` |

## It does not remind me

Only a real `.app` bundle schedules notifications reliably. Install with `scripts/build_app.sh`,
then **System Settings → Notifications → AsmaulHusna → allow** alerts and sounds.

## Support

github.com/theikbhal/AsmaulHusna
