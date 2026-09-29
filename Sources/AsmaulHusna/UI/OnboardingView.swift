import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var settings: AppSettings
    @ObservedObject private var notifications = NotificationManager.shared

    @State private var page = 0

    private var theme: AppTheme { state.activeTheme }

    var body: some View {
        ZStack {
            LinearGradient(colors: [theme.top, theme.bottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Group {
                    switch page {
                    case 0: welcome
                    case 1: whyPage
                    case 2: howPage
                    case 3: gamifyPage
                    default: remindPage
                    }
                }
                .id(page)
                .transition(.opacity)

                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(i == page ? theme.accent : Color.secondary.opacity(0.3))
                            .frame(width: 9, height: 9)
                    }
                }

                footer
            }
            .padding(40)
            .frame(maxWidth: 760, maxHeight: .infinity)
        }
        .frame(minWidth: 720, minHeight: 540)
    }

    // MARK: pages

    private var welcome: some View {
        VStack(spacing: 16) {
            Image(systemName: "hands.and.sparkles.fill")
                .font(.system(size: 74)).foregroundStyle(theme.accent)
            Text("Asmaul Husna").font(.largeTitle.weight(.bold))
            Text("Read one of the 99 Beautiful Names of Allah every day —")
                .font(.title3)
            Text("in Arabic, with the English transliteration, the Telugu transliteration, "
                 + "a short dua, its meaning and a hadith.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            Text("A tiny daily wird. Three reads. One passed day. A streak that grows.")
                .font(.callout).foregroundStyle(theme.accent)
        }
    }

    private var whyPage: some View {
        VStack(spacing: 14) {
            pageHeader("Why", "circle.hexagongrid.fill",
                       "The Prophet ﷺ said: “Allah has ninety-nine names, one hundred minus one; "
                       + "whoever ahısāhum (enumerates them) will enter Paradise.”")
            point("• Knowing the names of Allah is how you call on Him — and He answers.")
            point("• A fixed daily wird beats a burst of enthusiasm that fades in a week.")
            point("• Written intention (why) + fixed time (when) + target (how much) + "
                  + "pass mark (minimum) = a habit that survives busy days.")
            point("• Everything stays on your Mac — no account, no tracking.")
        }
    }

    private var howPage: some View {
        VStack(spacing: 14) {
            pageHeader("When · How much · Minimum pass", "clock.badge.checkmark.fill", "")
            point("WHEN — pick one fixed slot. Default reminder is 06:30; you can change it "
                  + "any time in Settings.")
            point("HOW MUCH — 1 name × 3 reads = 3 reads a day. Full cycle in 99 days.")
            point("MINIMUM PASS — reach the minimum to keep the streak. Miss a day, lose the streak; "
                  + "the Stats tab shows exactly where you stand.")
            point("Challenges: daily, weekly, monthly, yearly, an evening window, a Sunday "
                  + "deep-session and a family challenge you can run together.")
        }
    }

    private var gamifyPage: some View {
        VStack(spacing: 14) {
            pageHeader("Make it addictive (in a good way)", "sparkles", "")
            point("• XP and levels for every recitation — early reads earn bonus points.")
            point("• 23 badges, a growing garden, and an avatar with simple, eye-free clothes, "
                  + "pets and trees.")
            point("• Leitner-box memorisation: cover, recall, grade — today → 1 → 3 → 7 → 21 days.")
            point("• Share cards, carousels and reels straight to Instagram from the Share tab.")
            point("• 100 background themes, night mode, confetti when the day passes.")
        }
    }

    private var remindPage: some View {
        VStack(spacing: 14) {
            pageHeader("One reminder a day", "bell.badge.fill",
                       "A single local notification at the time you choose keeps the chain alive.")
            if notifications.isAuthorized {
                Label("Notifications allowed", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Allow notifications") { notifications.requestAuthorization() }
                    .buttonStyle(.borderedProminent).tint(theme.accent)
            }
            Toggle("Show this onboarding on next launch", isOn: $state.showOnboardingAgain)
                .toggleStyle(.checkbox)
                .padding(.top, 8)
        }
    }

    private func pageHeader(_ title: String, _ symbol: String, _ sub: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 46)).foregroundStyle(theme.accent)
            Text(title).font(.title.weight(.bold))
            if !sub.isEmpty {
                Text(sub).multilineTextAlignment(.center).foregroundStyle(.secondary)
            }
        }
    }

    private func point(_ t: String) -> some View {
        Text(t)
            .font(.callout)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: footer

    private var footer: some View {
        HStack {
            if page > 0 {
                Button("Back") { withAnimation { page -= 1 } }.buttonStyle(.bordered)
            } else {
                Button("Skip") { state.finishOnboarding() }.buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if page < 4 {
                Button("Next") { withAnimation { page += 1 } }
                    .buttonStyle(.borderedProminent).tint(theme.accent)
                    .keyboardShortcut(.defaultAction)
            } else {
                Button("Start reading") { state.finishOnboarding() }
                    .buttonStyle(.borderedProminent).tint(theme.accent)
                    .keyboardShortcut(.defaultAction)
            }
        }
    }
}
