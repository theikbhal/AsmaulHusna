import Foundation

/// Daily reading counts, streaks and per-name mastery.
@MainActor
final class ReadStore: ObservableObject {
    static let shared = ReadStore()

    @Published var counts: [String: Int] = [:]     // "yyyy-MM-dd#nameId" -> reads
    @Published var doneDays: Set<String> = []      // days that reached the minimum pass
    @Published var perName: [Int: Int] = [:]       // all-time reads per name
    @Published var best: Int = 0                   // best streak ever
    private var loaded = false

    private enum K { static let counts = "ah.counts"; static let done = "ah.done"
                     static let per = "ah.pername"; static let best = "ah.best" }

    private init() { load() }

    private func load() {
        let d = UserDefaults.standard
        if let x = d.data(forKey: K.counts), let v = try? JSONDecoder().decode([String: Int].self, from: x) { counts = v }
        if let x = d.data(forKey: K.done), let v = try? JSONDecoder().decode(Set<String>.self, from: x) { doneDays = v }
        if let x = d.data(forKey: K.per), let v = try? JSONDecoder().decode([Int: Int].self, from: x) { perName = v }
        best = d.integer(forKey: K.best)
        loaded = true
    }

    private func persist() {
        let d = UserDefaults.standard
        if let x = try? JSONEncoder().encode(counts) { d.set(x, forKey: K.counts) }
        if let x = try? JSONEncoder().encode(doneDays) { d.set(x, forKey: K.done) }
        if let x = try? JSONEncoder().encode(perName) { d.set(x, forKey: K.per) }
        d.set(best, forKey: K.best)
    }

    // MARK: dates

    static func key(_ date: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    static func parse(_ key: String) -> Date? {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"
        return f.date(from: key)
    }

    var today: Date {
        Calendar.current.date(byAdding: .day, value: AppSettings.shared.dayOffset, to: Date()) ?? Date()
    }
    var todayKey: String { ReadStore.key(today) }

    /// 0-based index of today inside the 99-name cycle (deterministic, device local).
    var dayIndex: Int {
        let cal = Calendar.current
        let start = cal.date(from: DateComponents(year: 2024, month: 1, day: 1)) ?? Date.distantPast
        let days = cal.dateComponents([.day], from: start, to: cal.startOfDay(for: today)).day ?? 0
        return ((days % 99) + 99) % 99
    }

    var todayNames: [Husna] {
        let n = max(1, min(5, AppSettings.shared.namesPerDay))
        return (0..<n).map { Names.byId((dayIndex + $0) % 99 + 1) }
    }

    func reads(on key: String, name id: Int) -> Int { counts["\(key)#\(id)"] ?? 0 }
    var todayTotal: Int { todayNames.reduce(0) { $0 + reads(on: todayKey, name: $1.id) } }
    var targetForToday: Int { AppSettings.shared.dailyTarget * max(1, AppSettings.shared.namesPerDay) }
    var todayPassed: Bool { doneDays.contains(todayKey) }
    var todayProgress: Double {
        let t = targetForToday
        return t > 0 ? min(1, Double(todayTotal) / Double(t)) : 0
    }

    // MARK: reading

    @discardableResult
    func read(_ nameId: Int, by amount: Int = 1) -> Int {
        let key = "\(todayKey)#\(nameId)"
        counts[key] = (counts[key] ?? 0) + amount
        if amount > 0 { perName[nameId] = (perName[nameId] ?? 0) + amount }
        evaluateDay()
        persist()
        return counts[key] ?? 0
    }

    @discardableResult
    func undo(_ nameId: Int) -> Int {
        let key = "\(todayKey)#\(nameId)"
        counts[key] = max(0, (counts[key] ?? 0) - 1)
        if (counts[key] ?? 0) < AppSettings.shared.minPass { doneDays.remove(todayKey) }
        evaluateDay()
        persist()
        return counts[key] ?? 0
    }

    func resetToday() {
        todayNames.forEach { counts.removeValue(forKey: "\(todayKey)#\($0.id)") }
        doneDays.remove(todayKey)
        persist()
    }

    private func evaluateDay() {
        guard todayTotal >= AppSettings.shared.minPass else { return }
        if !doneDays.contains(todayKey) {
            doneDays.insert(todayKey)
            best = max(best, streak)
        }
    }

    // MARK: streaks

    var streak: Int {
        var n = 0
        var day = today
        if !doneDays.contains(ReadStore.key(day)) {
            guard let y = Calendar.current.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = y
        }
        while doneDays.contains(ReadStore.key(day)) {
            n += 1
            guard let p = Calendar.current.date(byAdding: .day, value: -1, to: day) else { break }
            day = p
        }
        return n
    }

    var daysPassed: Int { doneDays.count }
    var totalReads: Int { perName.values.reduce(0, +) }

    /// Mastery 0...1 for a name (30 reads = fully learnt).
    func mastery(_ id: Int) -> Double { min(1, Double(perName[id] ?? 0) / 30.0) }

    /// Last 84 days grid for the heatmap visualisation.
    func heatmap(_ days: Int = 84) -> [(key: String, date: Date, level: Int)] {
        let cal = Calendar.current
        return (0..<days).reversed().map { i in
            let d = cal.date(byAdding: .day, value: -i, to: today) ?? today
            let k = ReadStore.key(d)
            let total = counts.filter { $0.key.hasPrefix(k) }.values.reduce(0, +)
            return (k, d, total == 0 ? 0 : min(3, 1 + total / max(1, AppSettings.shared.minPass)))
        }
    }

    func readsLast(_ days: Int) -> [(label: String, value: Int)] {
        let cal = Calendar.current
        return (0..<days).reversed().map { i in
            let d = cal.date(byAdding: .day, value: -i, to: today) ?? today
            let k = ReadStore.key(d)
            let f = DateFormatter(); f.dateFormat = "EEE"
            return (f.string(from: d), counts.filter { $0.key.hasPrefix(k) }.values.reduce(0, +))
        }
    }

    func seriesTotal(_ days: Int) -> Int { readsLast(days).reduce(0) { $0 + $1.value } }
}
