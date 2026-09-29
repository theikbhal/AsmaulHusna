import Foundation

/// Spaced-repetition memorisation for the names (Leitner boxes, 5 levels).
struct MemoCard: Codable, Hashable {
    var id: Int            // name id
    var box: Int = 1       // 1...5
    var due: Date = Date()
    var lapses: Int = 0
    var correct: Int = 0
}

@MainActor
final class MemoStore: ObservableObject {
    static let shared = MemoStore()

    @Published var cards: [Int: MemoCard] = [:]
    @Published var lastGrade: (id: Int, box: Int)? = nil

    private enum K { static let cards = "ah.memo.cards" }

    private init() {
        let d = UserDefaults.standard
        if let x = d.data(forKey: K.cards), let v = try? JSONDecoder().decode([Int: MemoCard].self, from: x) { cards = v }
    }

    private func persist() {
        let d = UserDefaults.standard
        if let x = try? JSONEncoder().encode(cards) { d.set(x, forKey: K.cards) }
    }

    func card(_ id: Int) -> MemoCard {
        cards[id] ?? MemoCard(id: id)
    }

    /// Names due for review today (never-seen names count as due).
    var dueToday: [Husna] {
        let now = Date()
        return Names.all.filter { cards[$0.id] == nil || cards[$0.id]!.due <= now }
    }

    /// Whether the next card has been introduced (step 0) or is a review.
    var newCount: Int { Names.all.filter { cards[$0.id] == nil }.count }
    var reviewCount: Int { let n = Date(); return cards.values.filter { $0.due <= n }.count }

    /// Interval in days for each box.
    private func interval(_ box: Int) -> Int {
        switch box {
        case 2: return 1
        case 3: return 3
        case 4: return 7
        case 5: return 21
        default: return 0
        }
    }

    /// Grading: 0 = Again, 1 = Hard, 2 = Good, 3 = Easy.
    @discardableResult
    func grade(_ id: Int, _ quality: Int) -> MemoCard {
        var c = card(id)
        let cal = Calendar.current
        let today = cal.startOfDay(for: ReadStore.shared.today)
        switch quality {
        case 0:                       // again — restart the ladder
            c.box = 1; c.lapses += 1; c.due = cal.date(byAdding: .day, value: 0, to: today)!
        case 1:                       // hard — stay, short delay
            c.box = max(1, c.box); c.due = cal.date(byAdding: .day, value: max(1, interval(c.box)), to: today)!
        case 2:                       // good — climb one box
            c.box = min(5, c.box + 1); c.correct += 1
            c.due = cal.date(byAdding: .day, value: max(1, interval(c.box)), to: today)!
        default:                      // easy — climb two boxes
            c.box = min(5, c.box + 2); c.correct += 1
            c.due = cal.date(byAdding: .day, value: max(2, interval(c.box)), to: today)!
        }
        cards[id] = c
        lastGrade = (id, c.box)
        persist()
        return c
    }

    var masteredCount: Int { cards.values.filter { $0.box >= 5 }.count }
    var knownCount: Int { cards.values.filter { $0.box >= 4 }.count }
    func averageBox() -> Double {
        guard !cards.isEmpty else { return 0 }
        return Double(cards.values.map(\.box).reduce(0, +)) / Double(cards.values.count)
    }

    func reset() { cards = [:]; persist() }

    // MARK: techniques shown in the memorise screen

    static let techniques: [(String, String, String)] = [
        ("Cover & Recite", "Cover the Arabic with your hand, say the name aloud, then uncover to check.",
         "Retrieval, not re-reading, is what fixes a name in memory."),
        ("Write it Three Times", "Write the Arabic once, the transliteration once, the meaning once.",
         "Handwriting engages motor memory alongside visual memory."),
        ("Pair with Meaning", "Say the name, then immediately say what it means in your language.",
         "Meaning gives the sound an anchor — you recall the idea, then the word."),
        ("Five-Box Rhythm", "Grade yourself honestly: Again / Hard / Good / Easy.",
         "Each box pushes the name further out: today → 1 → 3 → 7 → 21 days."),
        ("Hear & Repeat", "Read the name 3 times slowly, then 3 times at normal speed.",
         "Slow passes fix articulation; fast passes build automatic recall."),
        ("Link the Chain", "Link today's name to yesterday's in one sentence.",
         "Chaining names together turns a list into a story you can walk.")
    ]
}
