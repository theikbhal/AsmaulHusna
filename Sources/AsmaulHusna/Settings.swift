import SwiftUI

enum NightMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { self == .system ? "System" : (self == .light ? "Light" : "Night") }
    var scheme: ColorScheme? { self == .system ? nil : (self == .light ? .light : .dark) }
}

/// All user-facing preferences + feature switches + developer switches.
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    private let k = "asmaulhusna.settings."

    private init() {
        let d = UserDefaults.standard
        let prefix = "asmaulhusna.settings."
        func get<T>(_ key: String, _ def: T) -> T {
            d.object(forKey: prefix + key) == nil ? def : (d.object(forKey: prefix + key) as! T)
        }
        dailyTarget = get("dailyTarget", 3)
        minPass = get("minPass", 3)
        namesPerDay = get("namesPerDay", 1)
        reminderOn = get("reminderOn", true)
        reminderHour = get("reminderHour", 6)
        reminderMinute = get("reminderMinute", 30)
        themeId = get("themeId", 3)
        nightMode = NightMode(rawValue: get("nightMode", "system")) ?? .system
        // feature switches
        showTelugu = get("showTelugu", true)
        showMeaningTe = get("showMeaningTe", true)
        showHadith = get("showHadith", true)
        showDua = get("showDua", true)
        animationsOn = get("animationsOn", true)
        confettiOn = get("confettiOn", true)
        soundsOn = get("soundsOn", true)
        threeDOn = get("threeDOn", true)
        gardenOn = get("gardenOn", true)
        badgesOn = get("badgesOn", true)
        challengesOn = get("challengesOn", true)
        memorizeOn = get("memorizeOn", true)
        shareOn = get("shareOn", true)
        videoOn = get("videoOn", true)
        audioInReel = get("audioInReel", true)
        launchAtLogin = get("launchAtLogin", false)
        // developer
        devMode = get("devMode", false)
        dayOffset = get("dayOffset", 0)
        logEvents = get("logEvents", false)
    }

    private func set<T>(_ key: String, _ v: T) { UserDefaults.standard.set(v, forKey: k + key) }

    // MARK: study load
    @Published var dailyTarget: Int { didSet { set("dailyTarget", dailyTarget) } }
    @Published var minPass: Int { didSet { set("minPass", minPass) } }
    @Published var namesPerDay: Int { didSet { set("namesPerDay", namesPerDay) } }

    // MARK: reminder
    @Published var reminderOn: Bool { didSet { set("reminderOn", reminderOn) } }
    @Published var reminderHour: Int { didSet { set("reminderHour", reminderHour) } }
    @Published var reminderMinute: Int { didSet { set("reminderMinute", reminderMinute) } }

    // MARK: look
    @Published var themeId: Int { didSet { set("themeId", themeId) } }
    @Published var nightMode: NightMode { didSet { set("nightMode", nightMode.rawValue) } }

    // MARK: feature switches
    @Published var showTelugu: Bool { didSet { set("showTelugu", showTelugu) } }
    @Published var showMeaningTe: Bool { didSet { set("showMeaningTe", showMeaningTe) } }
    @Published var showHadith: Bool { didSet { set("showHadith", showHadith) } }
    @Published var showDua: Bool { didSet { set("showDua", showDua) } }
    @Published var animationsOn: Bool { didSet { set("animationsOn", animationsOn) } }
    @Published var confettiOn: Bool { didSet { set("confettiOn", confettiOn) } }
    @Published var soundsOn: Bool { didSet { set("soundsOn", soundsOn) } }
    @Published var threeDOn: Bool { didSet { set("threeDOn", threeDOn) } }
    @Published var gardenOn: Bool { didSet { set("gardenOn", gardenOn) } }
    @Published var badgesOn: Bool { didSet { set("badgesOn", badgesOn) } }
    @Published var challengesOn: Bool { didSet { set("challengesOn", challengesOn) } }
    @Published var memorizeOn: Bool { didSet { set("memorizeOn", memorizeOn) } }
    @Published var shareOn: Bool { didSet { set("shareOn", shareOn) } }
    @Published var videoOn: Bool { didSet { set("videoOn", videoOn) } }
    @Published var audioInReel: Bool { didSet { set("audioInReel", audioInReel) } }
    @Published var launchAtLogin: Bool { didSet { set("launchAtLogin", launchAtLogin) } }

    // MARK: developer switches
    @Published var devMode: Bool { didSet { set("devMode", devMode) } }
    @Published var dayOffset: Int { didSet { set("dayOffset", dayOffset) } }
    @Published var logEvents: Bool { didSet { set("logEvents", logEvents) } }

    func log(_ msg: String) {
        guard devMode, logEvents else { return }
        print("[AsmaulHusna] \(msg)")
    }

    func resetAll() {
        let d = UserDefaults.standard
        d.dictionaryRepresentation().keys.filter { $0.hasPrefix(k) }.forEach { d.removeObject(forKey: $0) }
        ["ah.counts", "ah.done", "ah.pername", "ah.game", "ah.avatar", "ah.memo",
         "ah.challenges", "ah.onboard.done", "ah.streak.best"].forEach { d.removeObject(forKey: $0) }
    }
}
