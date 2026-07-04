import Foundation
import UserNotifications

enum NotificationManager {
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    static func rescheduleReminder(for bottle: Bottle) async {
        cancelReminder(for: bottle.id)

        guard bottle.reminderEnabled, !bottle.isArchived, !bottle.reminderDays.isEmpty else {
            return
        }

        let granted = await requestAuthorization()
        guard granted else { return }

        for weekday in bottle.reminderDays {
            var components = DateComponents()
            components.weekday = weekday.rawValue
            components.hour = bottle.reminderHour
            components.minute = bottle.reminderMinute

            let content = UNMutableNotificationContent()
            content.title = "Reminder: check your bottle."
            content.body = "\(bottle.nickname): Open TwistLog to view recent openings."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: reminderIdentifier(for: bottle.id, weekday: weekday),
                content: content,
                trigger: trigger
            )

            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    static func cancelReminder(for bottleId: UUID) {
        let identifiers = Weekday.allCases.map { reminderIdentifier(for: bottleId, weekday: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func reminderIdentifier(for bottleId: UUID, weekday: Weekday) -> String {
        "twistlog.reminder.\(bottleId.uuidString).\(weekday.rawValue)"
    }
}
