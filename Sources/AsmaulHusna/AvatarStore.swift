import SwiftUI

/// Simple, eye-free avatar parts (clothes, headwear, pet silhouette, tree) drawn with shapes.
enum DressKind: Int, CaseIterable, Identifiable {
    case thobe, kurti, abaya, bisht, jubba
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .thobe: return "Thobe"; case .kurti: return "Kurti"; case .abaya: return "Abaya"
        case .bisht: return "Bisht"; case .jubba: return "Jubba"
        }
    }
    var unlockAt: Int { [1, 1, 3, 6, 9][rawValue] }
    var colors: [Color] {
        switch self {
        case .thobe: return [Color(white: 0.97), Color(white: 0.90), Color(red: 0.95, green: 0.96, blue: 0.98)]
        case .kurti: return [Color(red: 0.20, green: 0.45, blue: 0.65), Color(red: 0.35, green: 0.30, blue: 0.60), Color(red: 0.15, green: 0.50, blue: 0.45)]
        case .abaya: return [Color(white: 0.15), Color(red: 0.18, green: 0.14, blue: 0.22), Color(red: 0.12, green: 0.20, blue: 0.24)]
        case .bisht: return [Color(red: 0.32, green: 0.22, blue: 0.14), Color(red: 0.25, green: 0.18, blue: 0.12), Color(red: 0.40, green: 0.30, blue: 0.18)]
        case .jubba: return [Color(red: 0.22, green: 0.38, blue: 0.30), Color(red: 0.30, green: 0.30, blue: 0.42), Color(red: 0.45, green: 0.36, blue: 0.20)]
        }
    }
}

enum CapKind: Int, CaseIterable, Identifiable {
    case none, kufi, imamah, scarf
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .none: return "Bare"; case .kufi: return "Kufi"; case .imamah: return "Imamah"; case .scarf: return "Scarf"
        }
    }
    var unlockAt: Int { [1, 2, 5, 7][rawValue] }
}

enum PetKind: Int, CaseIterable, Identifiable {
    case none, cat, deer, lamb, bird, camel
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .none: return "None"; case .cat: return "Cat"; case .deer: return "Deer"
        case .lamb: return "Lamb"; case .bird: return "Bird"; case .camel: return "Camel"
        }
    }
    var unlockAt: Int { [1, 2, 4, 6, 8, 12][rawValue] }
}

enum TreeKind: Int, CaseIterable, Identifiable {
    case none, palm, olive, sidr, garden
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .none: return "None"; case .palm: return "Palm"; case .olive: return "Olive"
        case .sidr: return "Sidr"; case .garden: return "Garden"
        }
    }
    var unlockAt: Int { [1, 3, 6, 9, 14][rawValue] }
}

/// Growth stages of the reward garden, driven by days passed.
enum GardenStage: Int, CaseIterable, Identifiable {
    case bare, soil, seed, sprout, sapling, tree, blossom, fruit, harvest
    var id: Int { rawValue }
    var name: String {
        ["Bare ground", "Soil", "Seed", "Sprout", "Sapling", "Tree", "Blossom", "Fruit", "Harvest"][rawValue]
    }
    var emoji: String {
        ["🟫", "🪨", "🌰", "🌱", "🌿", "🌳", "🌸", "🍎", "🎉"][rawValue]
    }
    static func stage(daysPassed: Int) -> GardenStage {
        switch daysPassed {
        case ..<1: return .bare
        case ..<2: return .soil
        case ..<4: return .seed
        case ..<7: return .sprout
        case ..<14: return .sapling
        case ..<25: return .tree
        case ..<40: return .blossom
        case ..<60: return .fruit
        default: return .harvest
        }
    }
    static let thresholds = [0, 1, 2, 4, 7, 14, 25, 40, 60]
}

@MainActor
final class AvatarStore: ObservableObject {
    static let shared = AvatarStore()

    @Published var dress = 0
    @Published var cap = 0
    @Published var pet = 1
    @Published var tree = 0
    @Published var tint = 0

    private enum K { static let all = "ah.avatar" }

    private init() {
        let d = UserDefaults.standard
        if let x = d.data(forKey: K.all), let v = try? JSONDecoder().decode([Int].self, from: x), v.count == 5 {
            dress = v[0]; cap = v[1]; pet = v[2]; tree = v[3]; tint = v[4]
        }
    }

    private func persist() {
        if let x = try? JSONEncoder().encode([dress, cap, pet, tree, tint]) {
            UserDefaults.standard.set(x, forKey: K.all)
        }
    }

    var level: Int { GameStore.shared.level }

    func isUnlocked(_ item: Int, for kind: String) -> Bool {
        switch kind {
        case "dress": return DressKind(rawValue: item)?.unlockAt ?? 1 <= level
        case "cap": return CapKind(rawValue: item)?.unlockAt ?? 1 <= level
        case "pet": return PetKind(rawValue: item)?.unlockAt ?? 1 <= level
        case "tree": return TreeKind(rawValue: item)?.unlockAt ?? 1 <= level
        default: return true
        }
    }

    func select(_ item: Int, kind: String) {
        guard isUnlocked(item, for: kind) else { return }
        switch kind {
        case "dress": dress = item; case "cap": cap = item; case "pet": pet = item
        case "tree": tree = item; case "tint": tint = item
        default: break
        }
        persist()
    }

    var stage: GardenStage { GardenStage.stage(daysPassed: ReadStore.shared.daysPassed) }
    var nextStageDays: Int? {
        let s = stage.rawValue + 1
        return GardenStage.thresholds.indices.contains(s) ? GardenStage.thresholds[s] : nil
    }

    static let tints: [Color] = [
        Color(red: 0.93, green: 0.80, blue: 0.62),
        Color(red: 0.80, green: 0.66, blue: 0.50),
        Color(red: 0.62, green: 0.48, blue: 0.36),
        Color(red: 0.45, green: 0.34, blue: 0.26)
    ]
}
