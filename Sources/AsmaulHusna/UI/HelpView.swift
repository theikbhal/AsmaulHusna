import SwiftUI

struct HelpView: View {
    @EnvironmentObject var state: AppState
    private var theme: AppTheme { state.activeTheme }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Help").font(.largeTitle.weight(.bold))

                qa("What is this app?",
                   "A daily reader for the 99 Beautiful Names (Asmaul Husna). Each day you get "
                   + "a name in Arabic, its transliteration in English letters, the same in Telugu "
                   + "letters, a short dua, a short meaning (English + Telugu) and a hadith or ayah "
                   + "about it.")

                qa("Why should I read daily?",
                   "Consistency is the point. The 99-day cycle means a full pass through every name "
                   + "three-and-a-half times a year, and the streak shows exactly how honest you have been.")

                qa("When should I read?",
                   "Pick one fixed slot — after Fajr is the classic choice. Set the reminder time in "
                   + "Settings → Daily reminder. There is also an evening challenge window (18:00–01:00) "
                   + "for reads done after Maghrib.")

                qa("How much should I read?",
                   "Default: 1 name × 3 reads = 3 reads a day (Settings → Daily study). You can raise "
                   + "names per day up to 5 and reads up to 33.")

                qa("What is the minimum pass?",
                   "The pass mark for a day. Hit it and the day counts, the streak grows and the garden "
                   + "grows. Miss it and the streak stops. Change the number in Settings → Daily study, "
                   + "or per-challenge in Challenges → Minimum pass / day.")

                qa("How do the challenges work?",
                   "Seven of them: daily, weekly, monthly, yearly, Sunday, evening and family. Each one "
                   + "carries four fields — WHY (your intention), WHEN (the slot), HOW MUCH (target reads) "
                   + "and MINIMUM PASS (per-day threshold). Edit them by expanding a challenge card.")

                qa("How does memorisation work?",
                   "Memorize tab: cover the Arabic, recall it, then reveal and grade yourself Again / Hard "
                   + "/ Good / Easy. Each grade moves the name through five Leitner boxes "
                   + "(today → 1 → 3 → 7 → 21 days).")

                qa("How do I share to Instagram?",
                   "Share tab: Post 4:5, Story/Reel 9:16, Square 1:1 or a multi-card carousel. "
                   + "“Export reel” renders an MP4 (optionally with an audio file you choose). "
                   + "Everything is written to ~/Desktop/AsmaulHusna.")

                qa("Is my data safe?",
                   "Everything is local — UserDefaults on this Mac. No account, no server, no analytics. "
                   + "Settings → Data can erase it all.")

                qa("Keyboard shortcuts",
                   "⌘1 Read · ⌘2 Memorize · ⌘3 Challenges · ⌘4 Garden · ⌘5 Stats · ⌘6 Share · "
                   + "⌘7 Settings · Space = read · Esc = undo · ← → = switch name · ⇧⌘O = replay onboarding.")

                qa("It does not remind me",
                   "Only a real .app bundle can schedule notifications reliably. Install with "
                   + "scripts/build_app.sh, then System Settings → Notifications → AsmaulHusna → allow.")

                Text("Support · github.com/theikbhal/AsmaulHusna")
                    .font(.caption).foregroundStyle(.secondary).padding(.top, 8)
            }
            .padding(26)
            .frame(maxWidth: 820, alignment: .leading)
        }
    }

    private func qa(_ q: String, _ a: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(q).font(.headline).foregroundStyle(theme.accent)
            Text(a).font(.callout).foregroundStyle(.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background.opacity(0.5)))
    }
}
