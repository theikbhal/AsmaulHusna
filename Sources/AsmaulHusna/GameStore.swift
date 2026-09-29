import Foundation

struct Badge: Identifiable, Hashable {
    let id: String
    let name: String
    let desc: String
    let icon: String
    let rarity: String
}

/// XP, levels, coins and badges.
@MainActor
final class GameStore: ObservableObject {
    static let shared = GameStore()

    @Published var xp: Int = 0
    @Published var coins: Int = 0
    @Published var unlocked: Set<String> = []

    private enum K { static let xp = "ah.game.xp"; static let coins = "ah.game.coins"
                     static let unlocked = "ah.game.badges" }

    private init() {
        let d = UserDefaults.standard
        xp = d.integer(forKey: K.xp)
        coins = d.integer(forKey: K.coins)
        if let x = d.data(forKey: K.unlocked), let v = try? JSONDecoder().decode(Set<String>.self, from: x) { unlocked = v }
    }

    private func persist() {
        let d = UserDefaults.standard
        d.set(xp, forKey: K.xp); d.set(coins, forKey: K.coins)
        if let x = try? JSONEncoder().encode(unlocked) { d.set(x, forKey: K.unlocked) }
    }

    var level: Int {
        var l = 1, rem = xp
        while rem >= xpForNext(l) { rem -= xpForNext(l); l += 1 }
        return l
    }
    func xpForNext(_ l: Int) -> Int { 80 + (l - 1) * 40 }
    /// 0...1 progress inside the current level.
    var levelProgress: Double {
        var before = 0, l = 1
        while l < level { before += xpForNext(l); l += 1 }
        let need = xpForNext(level)
        return need > 0 ? min(1, Double(xp - before) / Double(need)) : 0
    }

    @discardableResult
    func addXP(_ amount: Int) -> Int {
        xp += amount
        coins += max(1, amount / 5)
        persist()
        return xp
    }

    func grant(_ badgeId: String) -> Bool {
        guard !unlocked.contains(badgeId) else { return false }
        unlocked.insert(badgeId)
        coins += 25
        persist()
        return true
    }

    func reset() {
        xp = 0; coins = 0; unlocked = []
        persist()
    }

    // MARK: catalogue

    static let catalogue: [Badge] = [
        Badge(id: "first", name: "First Step", desc: "Read your first name", icon: "star.fill", rarity: "Common"),
        Badge(id: "pass1", name: "Daily Pass", desc: "Pass your first day", icon: "checkmark.seal.fill", rarity: "Common"),
        Badge(id: "streak3", name: "Three Days", desc: "3-day streak", icon: "flame.fill", rarity: "Common"),
        Badge(id: "streak7", name: "Week Warrior", desc: "7-day streak", icon: "flame.circle.fill", rarity: "Rare"),
        Badge(id: "streak30", name: "Month of Light", desc: "30-day streak", icon: "moon.stars.fill", rarity: "Epic"),
        Badge(id: "streak99", name: "Full Cycle", desc: "99-day streak", icon: "crown.fill", rarity: "Legendary"),
        Badge(id: "reads50", name: "50 Reads", desc: "50 total recitations", icon: "book.fill", rarity: "Common"),
        Badge(id: "reads500", name: "500 Reads", desc: "500 total recitations", icon: "books.vertical.fill", rarity: "Rare"),
        Badge(id: "reads1000", name: "1000 Reads", desc: "1000 total recitations", icon: "building.columns.fill", rarity: "Epic"),
        Badge(id: "names10", name: "Ten Names", desc: "Read 10 different names", icon: "sparkles", rarity: "Common"),
        Badge(id: "names33", name: "One Third", desc: "Read 33 different names", icon: "circle.grid.3x3.fill", rarity: "Rare"),
        Badge(id: "names99", name: "All Ninety-Nine", desc: "Read all 99 names", icon: "star.circle.fill", rarity: "Legendary"),
        Badge(id: "level5", name: "Level Five", desc: "Reach level 5", icon: "arrow.up.circle.fill", rarity: "Rare"),
        Badge(id: "level10", name: "Level Ten", desc: "Reach level 10", icon: "bolt.fill", rarity: "Epic"),
        Badge(id: "memo10", name: "Memoriser", desc: "10 names at Good or better", icon: "brain.head.profile", rarity: "Rare"),
        Badge(id: "memo99", name: "Hafiz of the Names", desc: "All 99 in the top box", icon: "graduationcap.fill", rarity: "Legendary"),
        Badge(id: "weekpass", name: "Perfect Week", desc: "Pass every day of a week", icon: "calendar.badge.checkmark", rarity: "Rare"),
        Badge(id: "sunday", name: "Sunday Challenge", desc: "Complete a Sunday challenge", icon: "sun.max.fill", rarity: "Rare"),
        Badge(id: "family", name: "Family Circle", desc: "Complete a family challenge", icon: "person.3.fill", rarity: "Rare"),
        Badge(id: "share1", name: "Shared Light", desc: "Export your first post", icon: "square.and.arrow.up.fill", rarity: "Common"),
        Badge(id: "reel1", name: "Reel Maker", desc: "Export your first reel", icon: "video.fill", rarity: "Rare"),
        Badge(id: "theme10", name: "Theme Collector", desc: "Try 10 themes", icon: "paintpalette.fill", rarity: "Common"),
        Badge(id: "early", name: "Early Bird", desc: "Read before 07:00", icon: "sunrise.fill", rarity: "Rare"),
        Badge(id: "streakFreeze", name: "Streak Keeper", desc: "Reach a 3-day streak twice", icon: "snowflake", rarity: "Common")
    ]

    static func badge(_ id: String) -> Badge? { catalogue.first { $0.id == id } }
}
