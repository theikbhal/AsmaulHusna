import Foundation
import UserNotifications

/// One daily local reminder (and an optional evening reminder).
@MainActor
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    private enum K { static let id = "com.ikbhal.asmaulhusna.reminder" }

    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            let ok = s.authorizationStatus == .authorized || s.authorizationStatus == .provisional
            Task { @MainActor in self.isAuthorized = ok }
        }
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in
                self.isAuthorized = granted
                if granted { self.schedule() }
            }
        }
    }

    func schedule() {
        cancel()
        let s = AppSettings.shared
        guard s.reminderOn, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "🕌 Asmaul Husna — daily wird"
        content.body = "Read today's names — \(s.dailyTarget) times each keeps your streak alive."
        content.sound = .default

        var c = DateComponents()
        c.hour = s.reminderHour
        c.minute = s.reminderMinute
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: K.id, content: content,
                                  trigger: UNCalendarNotificationTrigger(dateMatching: c, repeats: true))
        ) { _ in }
    }

    func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [K.id])
    }

    func sendTest() {
        let content = UNMutableNotificationContent()
        content.title = "🕌 Test — Asmaul Husna"
        content.body = "Your daily reminder works. See you at \(String(format: "%02d:%02d", AppSettings.shared.reminderHour, AppSettings.shared.reminderMinute))."
        content.sound = .default
        let req = UNNotificationRequest(identifier: K.id + ".test", content: content,
                                        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false))
        UNUserNotificationCenter.current().add(req) { _ in }
    }
}
