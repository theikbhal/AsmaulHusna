import SwiftUI

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    enum Tab: String, CaseIterable, Identifiable {
        case read, names, memorize, challenges, garden, stats, share, settings, help
        var id: String { rawValue }
        var title: String {
            switch self {
            case .read: return "Read"; case .names: return "Names"
            case .memorize: return "Memorize"
            case .challenges: return "Challenges"; case .garden: return "Garden"
            case .stats: return "Stats"; case .share: return "Share"
            case .settings: return "Settings"; case .help: return "Help"
            }
        }
        var symbol: String {
            switch self {
            case .read: return "book.closed.fill"; case .names: return "list.bullet.rectangle.fill"
            case .memorize: return "brain.head.profile"
            case .challenges: return "flag.checkered"; case .garden: return "leaf.fill"
            case .stats: return "chart.bar.fill"; case .share: return "camera.on.rectangle"
            case .settings: return "gearshape.fill"; case .help: return "questionmark.circle"
            }
        }
    }

    @Published var tab: Tab = .read
    @Published var showOnboarding = false
    @Published var showOnboardingAgain = false
    @Published var toast: String? = nil
    @Published var celebrate: Bool = false
    @Published var themesTried: Set<Int> = []
    var keyMonitor: Any?

    let read = ReadStore.shared
    let game = GameStore.shared
    let challenges = ChallengeStore.shared
    let avatar = AvatarStore.shared
    let memo = MemoStore.shared
    let settings = AppSettings.shared
    let notifications = NotificationManager.shared
    let launch = LaunchService.shared
    let recorder = Recorder()

    private enum K { static let done = "ah.onboard.done"; static let again = "ah.onboard.again"
                     static let themes = "ah.themes.tried" }

    private init() {
        let d = UserDefaults.standard
        showOnboardingAgain = d.bool(forKey: K.again)
        showOnboarding = !d.bool(forKey: K.done) || showOnboardingAgain
        if let x = d.data(forKey: K.themes), let v = try? JSONDecoder().decode(Set<Int>.self, from: x) {
            themesTried = v
        }
    }

    func finishOnboarding() {
        UserDefaults.standard.set(!showOnboardingAgain, forKey: K.done)
        withAnimation(.easeInOut(duration: 0.3)) { showOnboarding = false }
    }

    func replayOnboarding() {
        showOnboardingAgain = true
        withAnimation { showOnboarding = true }
    }

    // MARK: single entry point for a recitation

    func recordRead(_ id: Int) {
        let s = settings
        read.read(id)
        challenges.noteReadTime()

        var xp = 5 + min(10, read.streak)
        if Calendar.current.component(.hour, from: Date()) < 7 { xp += 3 }
        game.addXP(xp)

        let before = read.todayPassed
        _ = before
        if read.todayPassed {
            celebrate = s.confettiOn
            announce("Day passed — streak \(read.streak) 🔥")
        } else {
            announce("\(read.todayTotal)/\(read.targetForToday) · +\(xp) XP")
        }
        checkBadges()
    }

    func undoRead(_ id: Int) {
        read.undo(id)
        checkBadges()
    }

    func announce(_ text: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
            withAnimation { self?.toast = nil }
        }
    }

    func noteTheme(_ id: Int) {
        themesTried.insert(id)
        if let x = try? JSONEncoder().encode(themesTried) {
            UserDefaults.standard.set(x, forKey: K.themes)
        }
        if themesTried.count >= 10 { grantBadge("theme10") }
    }

    // MARK: badges

    func grantBadge(_ id: String) {
        guard game.grant(id) else { return }
        let b = GameStore.badge(id)
        announce("Badge unlocked: \(b?.name ?? id) 🎉")
    }

    func checkBadges() {
        let r = read, g = game, m = memo
        if r.totalReads >= 1 { grantBadge("first") }
        if r.doneDays.count >= 1 { grantBadge("pass1") }
        if r.streak >= 3 { grantBadge("streak3") }
        if r.streak >= 7 { grantBadge("streak7") }
        if r.streak >= 30 { grantBadge("streak30") }
        if r.streak >= 99 { grantBadge("streak99") }
        if r.totalReads >= 50 { grantBadge("reads50") }
        if r.totalReads >= 500 { grantBadge("reads500") }
        if r.totalReads >= 1000 { grantBadge("reads1000") }
        let seen = r.perName.keys.count
        if seen >= 10 { grantBadge("names10") }
        if seen >= 33 { grantBadge("names33") }
        if seen >= 99 { grantBadge("names99") }
        if g.level >= 5 { grantBadge("level5") }
        if g.level >= 10 { grantBadge("level10") }
        if m.knownCount >= 10 { grantBadge("memo10") }
        if m.masteredCount >= 99 { grantBadge("memo99") }
        if perfectWeek { grantBadge("weekpass") }
        if let sunday = tryPass(.sunday) { if sunday { grantBadge("sunday") } }
        if let fam = tryPass(.family) { if fam { grantBadge("family") } }
    }

    private var perfectWeek: Bool {
        let cal = Calendar.current
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: read.today)
        guard let start = cal.date(from: comps) else { return false }
        return (0..<7).allSatisfy { i in
            guard let d = cal.date(byAdding: .day, value: i, to: start) else { return false }
            return d > read.today || read.doneDays.contains(ReadStore.key(d))
        }
    }

    private func tryPass(_ kind: ChallengeKind) -> Bool? {
        guard settings.challengesOn else { return nil }
        return challenges.progress(kind).passed
    }

    // MARK: theme

    var theme: AppTheme {
        let base = AppTheme.byId(settings.themeId)
        return settings.nightMode == .dark ? base.night() : base
    }
    var nightActive: Bool {
        settings.nightMode == .dark
            || (settings.nightMode == .system && NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua)
    }
    var activeTheme: AppTheme {
        let base = AppTheme.byId(settings.themeId)
        return nightActive ? base.night() : base
    }
}
