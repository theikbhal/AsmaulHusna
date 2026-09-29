import SwiftUI

struct SettingsPane: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var state: AppState
    @EnvironmentObject var read: ReadStore
    @EnvironmentObject var game: GameStore
    @EnvironmentObject var memo: MemoStore
    @ObservedObject private var notifications = NotificationManager.shared
    @ObservedObject private var launch = LaunchService.shared

    @State private var confirmReset = false
    @State private var showAllThemes = false

    private var theme: AppTheme { state.activeTheme }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                studySection
                reminderSection
                appearanceSection
                featuresSection
                captureSection
                startupSection
                dataSection
                devSection
                aboutSection
            }
            .padding(24)
            .frame(maxWidth: 860)
        }
        .onAppear { launch.refresh(); notifications.checkAuthorization() }
    }

    // MARK: study load

    private var studySection: some View {
        section("Daily study") {
            Stepper("Names per day: \(settings.namesPerDay)", value: $settings.namesPerDay, in: 1...5)
            Stepper("Reads target per name: \(settings.dailyTarget)", value: $settings.dailyTarget, in: 1...33)
            Stepper("Minimum pass per day: \(settings.minPass)", value: $settings.minPass, in: 1...99)
            Text("Why / When / How much / Minimum pass — all four live on the Challenges tab.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: reminder

    private var reminderSection: some View {
        section("Daily reminder") {
            Toggle("Remind me once a day", isOn: $settings.reminderOn)
                .onChange(of: settings.reminderOn) { _, on in
                    on ? notifications.schedule() : notifications.cancel()
                }
            DatePicker("Time", selection: timeBinding, displayedComponents: .hourAndMinute)
                .disabled(!settings.reminderOn)
            HStack {
                if notifications.isAuthorized {
                    Label("Notifications allowed", systemImage: "checkmark.circle.fill")
                        .font(.caption).foregroundStyle(.green)
                } else {
                    Button("Allow notifications") { notifications.requestAuthorization() }
                }
                Spacer()
                Button("Send test") { notifications.sendTest() }
            }
            .onChange(of: [settings.reminderHour, settings.reminderMinute]) { _, _ in
                notifications.schedule()
            }
        }
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                var c = DateComponents()
                c.hour = settings.reminderHour; c.minute = settings.reminderMinute
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { d in
                let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                settings.reminderHour = c.hour ?? 6
                settings.reminderMinute = c.minute ?? 30
                notifications.schedule()
            })
    }

    // MARK: appearance

    private var appearanceSection: some View {
        section("Background themes (100)") {
            HStack {
                Picker("Night mode", selection: $settings.nightMode) {
                    ForEach(NightMode.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
                Spacer()
                Button(showAllThemes ? "Show fewer" : "Show all 100") {
                    withAnimation { showAllThemes.toggle() }
                }
            }

            let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 10)
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(0..<(showAllThemes ? AppTheme.total : 20), id: \.self) { i in
                    let t = AppTheme.make(i)
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(colors: [t.top, t.bottom], startPoint: .top, endPoint: .bottom))
                            .frame(height: 34)
                            .overlay(RoundedRectangle(cornerRadius: 6)
                                .stroke(settings.themeId == i ? theme.accent : Color.primary.opacity(0.12),
                                        lineWidth: settings.themeId == i ? 3 : 1))
                        Text(t.name)
                            .font(.system(size: 8))
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }
                    .onTapGesture {
                        settings.themeId = i
                        state.noteTheme(i)
                    }
                    .help(t.name)
                }
            }
            Text("Tap a swatch to switch. Night mode darkens the same palette.")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: features

    private var featuresSection: some View {
        section("Enable / disable features") {
            gridToggles([
                ("Telugu transliteration", $settings.showTelugu),
                ("Telugu meaning", $settings.showMeaningTe),
                ("Hadith on each name", $settings.showHadith),
                ("Short dua on each name", $settings.showDua),
                ("Animations", $settings.animationsOn),
                ("Confetti celebration", $settings.confettiOn),
                ("3D card tilt", $settings.threeDOn),
                ("Names list tab", $settings.namesListOn),
                ("Memorize tab", $settings.memorizeOn),
                ("Challenges tab", $settings.challengesOn),
                ("Garden & avatar", $settings.gardenOn),
                ("Badges", $settings.badgesOn),
                ("Share tab", $settings.shareOn),
                ("Video export & recording", $settings.videoOn),
                ("Audio in reels", $settings.audioInReel)
            ])
        }
    }

    private func gridToggles(_ items: [(String, Binding<Bool>)]) -> some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
        return LazyVGrid(columns: cols, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack {
                    Text(item.0).font(.callout)
                    Spacer()
                    Toggle("", isOn: item.1).labelsHidden()
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: capture

    private var captureSection: some View {
        section("Screenshot & video") {
            Text("Screenshots: use the Share tab — PNG at 1080×1350 (post), 1080×1920 (story/reel), "
                 + "1080×1080 (square) or a multi-card carousel. No permission needed.")
                .font(.caption)
            Text("Video: “Export reel” renders an MP4 (optionally with your audio file). "
                 + "“Record window” uses Screen Recording — macOS will prompt for permission.")
                .font(.caption)
            Text("Files: ~/Desktop/AsmaulHusna-Exports").font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: startup

    private var startupSection: some View {
        section("Start with the computer") {
            Toggle("Open AsmaulHusna at login", isOn: Binding(
                get: { launch.isEnabled },
                set: { launch.toggle($0) }
            ))
            if let s = launch.statusDescription {
                Text(s).font(.caption).foregroundStyle(.orange)
                Button("Open System Settings") { launch.openLoginItemsSettings() }
            }
            if !launch.supported {
                Text("Login items only work when the app runs from /Applications "
                     + "(run scripts/build_app.sh to install).")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: data

    private var dataSection: some View {
        section("Data") {
            HStack {
                Text("\(read.totalReads) reads · \(read.daysPassed) days · \(game.unlocked.count) badges")
                    .font(.callout)
                Spacer()
                Button("Replay onboarding") { state.replayOnboarding() }
                Button("Reset everything", role: .destructive) { confirmReset = true }
            }
            .confirmationDialog("Erase all progress, badges, avatar and settings?",
                                isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) {
                    settings.resetAll()
                    game.reset()
                    memo.reset()
                    read.resetToday()
                    state.announce("All data erased")
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: developer

    private var devSection: some View {
        section("Developer settings") {
            Toggle("Developer mode", isOn: $settings.devMode)
            if settings.devMode {
                Toggle("Verbose log", isOn: $settings.logEvents)
                Stepper("Simulated day offset: \(settings.dayOffset)",
                        value: $settings.dayOffset, in: -365...365)
                Text("Offset shifts the 99-day cycle and all dates — for testing streaks and challenges.")
                    .font(.caption2).foregroundStyle(.secondary)
                HStack {
                    Button("Dump progress JSON") { dump() }
                    Button("Grant all badges") {
                        GameStore.catalogue.forEach { state.grantBadge($0.id) }
                    }
                    Button("Max level") { game.addXP(99999) }
                }
                Text("Export folder: \(Capture.shareFolder().path)")
                    .font(.caption2).foregroundStyle(.secondary).textSelection(.enabled)
            }
        }
    }

    private func dump() {
        var out: [String: Any] = [:]
        out["reads"] = read.counts
        out["doneDays"] = Array(read.doneDays)
        out["xp"] = game.xp
        out["badges"] = Array(game.unlocked)
        out["theme"] = settings.themeId
        if let data = try? JSONSerialization.data(withJSONObject: out, options: [.prettyPrinted]),
           let s = String(data: data, encoding: .utf8) {
            let url = Capture.shareFolder().appendingPathComponent("progress-\(Capture.stamp()).json")
            try? s.write(to: url, atomically: true, encoding: .utf8)
            state.announce("Dumped → \(url.path)")
        }
    }

    // MARK: about

    private var aboutSection: some View {
        section("About") {
            Text("Asmaul Husna 1.0.0 — a daily reader for the 99 Beautiful Names with "
                 + "streaks, challenges, spaced-repetition memorisation, a growing garden "
                 + "and Instagram-ready sharing.")
                .font(.callout)
            Text("Everything stays on this Mac. No account, no server, no analytics.")
                .font(.caption).foregroundStyle(.secondary)
            Text("github.com/theikbhal/AsmaulHusna").font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: section helper

    private func section<V: View>(_ title: String, @ViewBuilder content: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) { content() }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(.background.opacity(0.55)))
    }
}
