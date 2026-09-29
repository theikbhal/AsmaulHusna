import SwiftUI

enum StepLog {
    static func write(_ m: String) {
        let line = "[\(Date().description(with: .none))] \(m)\n"
        let url = URL(fileURLWithPath: "/tmp/ah_export.log")
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: url.path) {
                if let h = try? FileHandle(forWritingTo: url) {
                    _ = try? h.seekToEnd()
                    try? h.write(contentsOf: data)
                    try? h.close()
                }
            } else { try? data.write(to: url) }
        }
    }
}

@main
struct AsmaulHusnaApp: App {
    init() {
        if CommandLine.arguments.contains("--export-test") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                Task { await Self.exportTest() }
            }
        }
    }

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
                Button("Names") { state.tab = .names }.keyboardShortcut("2", modifiers: .command)
                Button("Memorize") { state.tab = .memorize }.keyboardShortcut("3", modifiers: .command)
                Button("Challenges") { state.tab = .challenges }.keyboardShortcut("4", modifiers: .command)
                Button("Garden") { state.tab = .garden }.keyboardShortcut("5", modifiers: .command)
                Button("Stats") { state.tab = .stats }.keyboardShortcut("6", modifiers: .command)
                Button("Share") { state.tab = .share }.keyboardShortcut("7", modifiers: .command)
                Button("Settings") { state.tab = .settings }.keyboardShortcut("8", modifiers: .command)
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

    /// `AsmaulHusna --export-test` renders a post, a story, a carousel and a short reel,
    /// prints the paths and quits. Used to verify the Share pipeline without clicking.
    @MainActor
    static func exportTest() async {
        let s = AppSettings.shared
        StepLog.write("exportTest started")
        let list = Array(Names.all.prefix(3))
        let post = ShareExport.post(list[0], s)
        StepLog.write("post=\(post?.path ?? "FAIL")")
        let story = ShareExport.story(list[1], s)
        StepLog.write("story=\(story?.path ?? "FAIL")")
        let carousel = ShareExport.carousel(list, s)
        StepLog.write("carousel=\(carousel.count)")
        do {
            let reel = try await ShareExport.reel(list, audio: nil, secondsPerCard: 1.0, s)
            StepLog.write("reel=\(reel.path)")
            print("EXPORT-TEST post=\(post?.path ?? "FAIL") story=\(story?.path ?? "FAIL") "
                  + "carousel=\(carousel.count) reel=\(reel.path)")
        } catch {
            print("EXPORT-TEST post=\(post?.path ?? "FAIL") story=\(story?.path ?? "FAIL") "
                  + "carousel=\(carousel.count) reel-error=\(error)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { NSApp.terminate(nil) }
    }
}

