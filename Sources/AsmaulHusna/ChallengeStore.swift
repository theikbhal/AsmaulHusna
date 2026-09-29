import Foundation

enum ChallengeKind: String, CaseIterable, Identifiable {
    case daily, weekly, monthly, yearly, sunday, evening, family
    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "Daily Challenge"
        case .weekly: return "Weekly Challenge"
        case .monthly: return "Monthly Challenge"
        case .yearly: return "Yearly Challenge"
        case .sunday: return "Sunday Challenge"
        case .evening: return "Evening Challenge"
        case .family: return "Family Challenge"
        }
    }
    var symbol: String {
        switch self {
        case .daily: return "sun.max"
        case .weekly: return "calendar"
        case .monthly: return "calendar.badge.clock"
        case .yearly: return "sun.haze"
        case .sunday: return "sun.max.fill"
        case .evening: return "moon.stars"
        case .family: return "person.3"
        }
    }
    var defaultWhy: String {
        switch self {
        case .daily: return "Stay consistent — a small daily wird keeps the heart alive."
        case .weekly: return "A full week of readings builds rhythm."
        case .monthly: return "One month of the 99 Names is a complete heart-cleaning."
        case .yearly: return "Walk through every name with every season."
        case .sunday: return "Give Sunday a deeper, longer session."
        case .evening: return "Close the day with remembrance before Maghrib."
        case .family: return "Read together — the home that remembers Allah together stays together."
        }
    }
    var defaultWhen: String {
        switch self {
        case .daily: return "After Fajr"
        case .weekly: return "Any day of the week"
        case .monthly: return "First of every month"
        case .yearly: return "Ramadan + every day"
        case .sunday: return "Sunday, after Jumu'ah rest"
        case .evening: return "18:00 – 23:59"
        case .family: return "After Maghrib, together"
        }
    }
}

struct FamilyMember: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var dress: Int = 0
    var reads: [String: Int] = [:]   // dayKey -> reads
}

struct ChallengeConfig: Codable, Hashable {
    var why: String = ""
    var whenText: String = ""
    var howMuch: Int = 0             // target reads in the period (0 = auto)
    var minPass: Int = 0             // per-day minimum for a day to count (0 = app minimum)
    var family: [FamilyMember] = []
}

struct ChallengeProgress: Hashable {
    let value: Int
    let target: Int
    let passed: Bool
    let daysPassed: Int
    let daysTotal: Int
    var fraction: Double { target > 0 ? min(1, Double(value) / Double(target)) : 0 }
}

@MainActor
final class ChallengeStore: ObservableObject {
    static let shared = ChallengeStore()

    @Published var configs: [String: ChallengeConfig] = [:]
    @Published var eveningReads: [String: Int] = [:]     // dayKey -> reads done in the evening window
    @Published var passedPeriods: Set<String> = []

    private enum K { static let cfg = "ah.challenges.cfg"; static let eve = "ah.challenges.eve"
                     static let passed = "ah.challenges.passed" }

    private init() {
        let d = UserDefaults.standard
        if let x = d.data(forKey: K.cfg), let v = try? JSONDecoder().decode([String: ChallengeConfig].self, from: x) { configs = v }
        if let x = d.data(forKey: K.eve), let v = try? JSONDecoder().decode([String: Int].self, from: x) { eveningReads = v }
        if let x = d.data(forKey: K.passed), let v = try? JSONDecoder().decode(Set<String>.self, from: x) { passedPeriods = v }
        for k in ChallengeKind.allCases where configs[k.rawValue] == nil {
            configs[k.rawValue] = ChallengeConfig(why: k.defaultWhy, whenText: k.defaultWhen)
        }
    }

    private func persist() {
        let d = UserDefaults.standard
        if let x = try? JSONEncoder().encode(configs) { d.set(x, forKey: K.cfg) }
        if let x = try? JSONEncoder().encode(eveningReads) { d.set(x, forKey: K.eve) }
        if let x = try? JSONEncoder().encode(passedPeriods) { d.set(x, forKey: K.passed) }
    }

    func config(_ kind: ChallengeKind) -> ChallengeConfig {
        configs[kind.rawValue] ?? ChallengeConfig(why: kind.defaultWhy, whenText: kind.defaultWhen)
    }
    func binding(_ kind: ChallengeKind) -> ChallengeConfig {
        config(kind)
    }
    func update(_ kind: ChallengeKind, _ c: ChallengeConfig) {
        configs[kind.rawValue] = c
        persist()
    }

    var minPass: Int { max(1, AppSettings.shared.minPass) }
    var dailyUnit: Int { max(1, AppSettings.shared.dailyTarget * AppSettings.shared.namesPerDay) }

    // MARK: periods

    private var cal: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2 // Monday
        return c
    }
    private var today: Date { ReadStore.shared.today }
    private var todayKey: String { ReadStore.shared.todayKey }

    private func period(for kind: ChallengeKind) -> (start: Date, end: Date) {
        let c = cal
        switch kind {
        case .daily, .evening, .family:
            return (c.startOfDay(for: today), c.date(byAdding: .day, value: 1, to: c.startOfDay(for: today))!)
        case .weekly:
            let comps = c.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
            let s = c.date(from: comps)!
            return (s, c.date(byAdding: .day, value: 7, to: s)!)
        case .sunday:
            // the Sunday of the current week (week starts Monday → Sunday is day 6)
            let comps = c.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
            let s = c.date(from: comps)!
            let sun = c.date(byAdding: .day, value: 6, to: s)!
            return (c.startOfDay(for: sun), c.date(byAdding: .day, value: 1, to: sun)!)
        case .monthly:
            let s = c.date(from: c.dateComponents([.year, .month], from: today))!
            return (s, c.date(byAdding: .month, value: 1, to: s)!)
        case .yearly:
            let s = c.date(from: c.dateComponents([.year], from: today))!
            return (s, c.date(byAdding: .year, value: 1, to: s)!)
        }
    }

    func periodLabel(_ kind: ChallengeKind) -> String {
        let f = DateFormatter()
        let p = period(for: kind)
        switch kind {
        case .daily, .evening, .family:
            f.dateFormat = "EEE d MMM"; return f.string(from: p.start)
        case .weekly:
            f.dateFormat = "d MMM"; return "\(f.string(from: p.start)) – \(f.string(from: Calendar.current.date(byAdding: .day, value: -1, to: p.end)!))"
        case .sunday:
            f.dateFormat = "d MMM yyyy"; return f.string(from: p.start)
        case .monthly:
            f.dateFormat = "MMMM yyyy"; return f.string(from: p.start)
        case .yearly:
            f.dateFormat = "yyyy"; return f.string(from: p.start)
        }
    }

    // MARK: progress

    func progress(_ kind: ChallengeKind) -> ChallengeProgress {
        let cfg = config(kind)
        let target = cfg.howMuch > 0 ? cfg.howMuch : autoTarget(kind)
        let value = currentValue(kind)
        let (daysPassed, daysTotal) = dayStats(kind, perDay: cfg.minPass > 0 ? cfg.minPass : minPass)
        let passed = value >= target && daysPassed > 0
        let key = periodKey(kind)
        if passed && !passedPeriods.contains(key) {
            passedPeriods.insert(key)
            persist()
        }
        return ChallengeProgress(value: value, target: target, passed: passed,
                                 daysPassed: daysPassed, daysTotal: daysTotal)
    }

    func autoTarget(_ kind: ChallengeKind) -> Int {
        let unit = dailyUnit
        switch kind {
        case .daily: return unit
        case .evening: return max(1, unit - 1)
        case .family: return unit * 2
        case .weekly: return unit * 7
        case .monthly: return unit * 30
        case .yearly: return unit * 365
        case .sunday: return unit * 3
        }
    }

    private func currentValue(_ kind: ChallengeKind) -> Int {
        let store = ReadStore.shared
        let c = cal
        switch kind {
        case .daily, .weekly, .monthly, .yearly, .sunday:
            let p = period(for: kind)
            return store.counts.reduce(0) { acc, kv in
                guard let day = kv.key.split(separator: "#").first.map(String.init),
                      let date = ReadStore.parse(day), date >= p.start, date < p.end else { return acc }
                return acc + kv.value
            }
        case .evening:
            let p = period(for: kind)
            return eveningReads.filter { kv in
                guard let d = ReadStore.parse(kv.key) else { return false }
                return d >= p.start && d < p.end
            }.values.reduce(0, +)
        case .family:
            let p = period(for: kind)
            var sum = 0
            for m in config(.family).family {
                for (k, v) in m.reads {
                    guard let d = ReadStore.parse(k), d >= p.start, d < p.end else { continue }
                    sum += v
                }
            }
            // the user's own reads count too
            let mine = store.counts.reduce(0) { acc, kv in
                guard let day = kv.key.split(separator: "#").first.map(String.init),
                      let date = ReadStore.parse(day), date >= p.start, date < p.end else { return acc }
                return acc + kv.value
            }
            return sum + mine
        }
    }

    private func periodKey(_ kind: ChallengeKind) -> String { "\(kind.rawValue)#\(periodLabel(kind))" }

    private func dayStats(_ kind: ChallengeKind, perDay: Int) -> (Int, Int) {
        let store = ReadStore.shared
        let c = cal
        let p = period(for: kind)
        let start = c.startOfDay(for: p.start)
        let end = p.end
        var total = 0
        var passed = 0
        var d = start
        while d < end {
            total += 1
            let k = ReadStore.key(d)
            let dayReads = store.counts.filter { $0.key.hasPrefix(k) }.values.reduce(0, +)
            var ok = dayReads >= perDay
            if kind == .evening { ok = (eveningReads[k] ?? 0) >= perDay }
            if ok { passed += 1 }
            guard let n = c.date(byAdding: .day, value: 1, to: d) else { break }
            d = n
            if kind != .daily, kind != .evening, kind != .family, d > today { break }
        }
        return (passed, total)
    }

    // MARK: family

    func addFamilyMember(_ name: String) {
        var cfg = config(.family)
        cfg.family.append(FamilyMember(name: name))
        update(.family, cfg)
    }
    func removeFamilyMember(_ id: UUID) {
        var cfg = config(.family)
        cfg.family.removeAll { $0.id == id }
        update(.family, cfg)
    }
    func bumpMember(_ id: UUID, by amount: Int) {
        var cfg = config(.family)
        guard let i = cfg.family.firstIndex(where: { $0.id == id }) else { return }
        cfg.family[i].reads[todayKey] = max(0, (cfg.family[i].reads[todayKey] ?? 0) + amount)
        update(.family, cfg)
    }

    // MARK: evening

    /// Called for every read; counts it toward the evening window when local time is 18:00+.
    func noteReadTime() {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 18 || hour < 1 {
            eveningReads[todayKey] = (eveningReads[todayKey] ?? 0) + 1
            persist()
        }
    }

    var familyMembers: [FamilyMember] { config(.family).family }

    static func parse(_ key: String) -> Date? {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"
        return f.date(from: key)
    }
}
