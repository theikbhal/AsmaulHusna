import SwiftUI

@main
struct AsmaulHusnaApp: App {
    @StateObject private var state = AppState.shared
    @ObservedObject private var settings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if state.showOnboarding {
                    OnboardingView()
                } else {
                    RootView()
                }
            }
            .environmentObject(state)
            .environmentObject(AppSettings.shared)
            .environmentObject(ReadStore.shared)
            .environmentObject(GameStore.shared)
            .environmentObject(ChallengeStore.shared)
            .environmentObject(AvatarStore.shared)
            .environmentObject(MemoStore.shared)
            .environmentObject(state.recorder)
            .frame(minWidth: 780, minHeight: 560)
            .preferredColorScheme(settings.nightMode.scheme)
            .onAppear {
                NSWindow.allowsAutomaticWindowTabbing = false
                NotificationManager.shared.checkAuthorization()
                AppState.shared.launch.refresh()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    NotificationManager.shared.schedule()
                }
                AppState.shared.checkBadges()
            }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Read") { state.tab = .read }.keyboardShortcut("1", modifiers: .command)
                Button("Memorize") { state.tab = .memorize }.keyboardShortcut("2", modifiers: .command)
                Button("Challenges") { state.tab = .challenges }.keyboardShortcut("3", modifiers: .command)
                Button("Garden") { state.tab = .garden }.keyboardShortcut("4", modifiers: .command)
                Button("Stats") { state.tab = .stats }.keyboardShortcut("5", modifiers: .command)
                Button("Share") { state.tab = .share }.keyboardShortcut("6", modifiers: .command)
                Button("Settings") { state.tab = .settings }.keyboardShortcut("7", modifiers: .command)
            }
            CommandGroup(after: .help) {
                Button("Replay Onboarding") { state.replayOnboarding() }
                    .keyboardShortcut("o", modifiers: [.command, .shift])
            }
        }
        .defaultSize(width: 940, height: 660)
        .defaultPosition(.center)
        .windowResizability(.contentMinSize)
    }
}
