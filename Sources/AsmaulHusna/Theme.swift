import SwiftUI

/// 100 simple background themes (a few hand-authored, the rest generated deterministically).
struct AppTheme: Identifiable, Hashable {
    let id: Int
    let name: String
    let top: Color
    let bottom: Color
    let accent: Color
    let card: Color

    static let total = 100
    private static var cache: [Int: AppTheme] = [:]

    private static let adjectives = [
        "Sage", "Amber", "Jade", "Indigo", "Ivory", "Coral", "Olive", "Plum",
        "Sand", "Ruby", "Teal", "Ash", "Mint", "Gold", "Sky", "Wine", "Rose", "Moss"
    ]
    private static let nouns = [
        "Dawn", "Dusk", "Oasis", "Lantern", "Garden", "Mosque", "Dune", "Moon",
        "Palm", "Star", "Dew", "Breeze", "Minaret", "Ridge", "Pearl", "Frost", "Hill", "River"
    ]

    static func make(_ id: Int) -> AppTheme {
        if let c = cache[id] { return c }
        let t = build(id); cache[id] = t; return t
    }

    private static func build(_ id: Int) -> AppTheme {
        if id < curated.count { return curated[id] }
        let hue = Double((id * 37) % 360) / 360.0
        let name = "\(adjectives[id % adjectives.count]) \(nouns[(id / adjectives.count) % nouns.count])"
        return AppTheme(
            id: id,
            name: name,
            top: Color(hue: hue, saturation: 0.28, brightness: 0.97),
            bottom: Color(hue: (hue + 0.07).truncatingRemainder(dividingBy: 1.0), saturation: 0.42, brightness: 0.88),
            accent: Color(hue: (hue + 0.45).truncatingRemainder(dividingBy: 1.0), saturation: 0.62, brightness: 0.78),
            card: Color(hue: hue, saturation: 0.12, brightness: 1.0)
        )
    }

    /// Darkened copy used by night mode.
    func night() -> AppTheme {
        AppTheme(id: id, name: name,
                 top: top.brightness(-0.62).saturation(+0.05),
                 bottom: bottom.brightness(-0.55),
                 accent: accent.brightness(+0.06),
                 card: card.brightness(-0.70))
    }

    static let curated: [AppTheme] = [
        AppTheme(id: 0, name: "Classic Green",
                 top: Color(red: 0.90, green: 0.96, blue: 0.92),
                 bottom: Color(red: 0.74, green: 0.90, blue: 0.81),
                 accent: Color(red: 0.10, green: 0.55, blue: 0.36),
                 card: .white),
        AppTheme(id: 1, name: "Midnight",
                 top: Color(red: 0.09, green: 0.11, blue: 0.18),
                 bottom: Color(red: 0.05, green: 0.06, blue: 0.11),
                 accent: Color(red: 0.55, green: 0.78, blue: 0.63),
                 card: Color(red: 0.13, green: 0.15, blue: 0.23)),
        AppTheme(id: 2, name: "Desert Sand",
                 top: Color(red: 0.99, green: 0.95, blue: 0.86),
                 bottom: Color(red: 0.95, green: 0.87, blue: 0.72),
                 accent: Color(red: 0.72, green: 0.45, blue: 0.16),
                 card: .white),
        AppTheme(id: 3, name: "Oasis Teal",
                 top: Color(red: 0.88, green: 0.97, blue: 0.97),
                 bottom: Color(red: 0.69, green: 0.90, blue: 0.91),
                 accent: Color(red: 0.06, green: 0.52, blue: 0.55),
                 card: .white),
        AppTheme(id: 4, name: "Makkah Night",
                 top: Color(red: 0.14, green: 0.10, blue: 0.20),
                 bottom: Color(red: 0.07, green: 0.05, blue: 0.12),
                 accent: Color(red: 0.85, green: 0.72, blue: 0.36),
                 card: Color(red: 0.18, green: 0.14, blue: 0.27)),
        AppTheme(id: 5, name: "Rose Mosque",
                 top: Color(red: 0.99, green: 0.93, blue: 0.94),
                 bottom: Color(red: 0.96, green: 0.83, blue: 0.86),
                 accent: Color(red: 0.78, green: 0.30, blue: 0.42),
                 card: .white),
        AppTheme(id: 6, name: "Palm Green",
                 top: Color(red: 0.93, green: 0.97, blue: 0.90),
                 bottom: Color(red: 0.78, green: 0.91, blue: 0.74),
                 accent: Color(red: 0.24, green: 0.52, blue: 0.20),
                 card: .white),
        AppTheme(id: 7, name: "Golden Hour",
                 top: Color(red: 1.00, green: 0.96, blue: 0.87),
                 bottom: Color(red: 0.99, green: 0.88, blue: 0.66),
                 accent: Color(red: 0.78, green: 0.52, blue: 0.06),
                 card: .white),
        AppTheme(id: 8, name: "Ocean Depth",
                 top: Color(red: 0.87, green: 0.94, blue: 0.99),
                 bottom: Color(red: 0.66, green: 0.83, blue: 0.95),
                 accent: Color(red: 0.09, green: 0.38, blue: 0.70),
                 card: .white),
        AppTheme(id: 9, name: "Slate Calm",
                 top: Color(red: 0.95, green: 0.96, blue: 0.97),
                 bottom: Color(red: 0.85, green: 0.87, blue: 0.90),
                 accent: Color(red: 0.30, green: 0.36, blue: 0.45),
                 card: .white)
    ]

    static func byId(_ id: Int) -> AppTheme { make(min(max(id, 0), AppTheme.total - 1)) }
}

extension Color {
    func brightness(_ delta: Double) -> Color {
        let c = nsColor
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h), saturation: Double(s),
                     brightness: max(0, min(1, Double(b) + delta)))
    }
    func saturation(_ delta: Double) -> Color {
        let c = nsColor
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h), saturation: max(0, min(1, Double(s) + delta)),
                     brightness: Double(b))
    }
    private var nsColor: NSColor { NSColor(self) }
}
