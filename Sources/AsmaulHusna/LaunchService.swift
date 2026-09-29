import ServiceManagement

/// "Start on computer start" — registers as a login item (only from a real .app bundle).
@MainActor
final class LaunchService: ObservableObject {
    static let shared = LaunchService()

    @Published private(set) var statusDescription: String?

    private var isAppBundle: Bool { Bundle.main.bundleURL.pathExtension == "app" }

    var isEnabled: Bool {
        guard isAppBundle else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    var supported: Bool { isAppBundle }

    func refresh() {
        guard isAppBundle else { statusDescription = nil; return }
        switch SMAppService.mainApp.status {
        case .notRegistered, .enabled: statusDescription = nil
        case .requiresApproval: statusDescription = "Approval required in System Settings"
        case .notFound: statusDescription = "Login item not found"
        @unknown default: statusDescription = nil
        }
    }

    func toggle(_ enabled: Bool) {
        guard isAppBundle else { return }
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            statusDescription = "Could not update login item: \(error.localizedDescription)"
        }
        refresh()
        AppSettings.shared.launchAtLogin = isEnabled
    }

    func openLoginItemsSettings() { SMAppService.openSystemSettingsLoginItems() }
}
