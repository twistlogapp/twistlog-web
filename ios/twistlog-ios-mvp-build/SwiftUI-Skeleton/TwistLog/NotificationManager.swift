import Foundation
import UserNotifications

protocol ReminderScheduling {
    func requestAuthorization() async -> Bool
    func authorizationStatus() async -> UNAuthorizationStatus
    func rescheduleReminder(for bottle: Bottle) async
    func cancelReminder(for bottleId: UUID)
    func scheduleTestReminder() async
}

struct NoOpReminderScheduler: ReminderScheduling {
    func requestAuthorization() async -> Bool { false }
    func authorizationStatus() async -> UNAuthorizationStatus { .notDetermined }
    func rescheduleReminder(for bottle: Bottle) async {}
    func cancelReminder(for bottleId: UUID) {}
    func scheduleTestReminder() async {}
}

enum NotificationManager {
    static let liveScheduler: ReminderScheduling = LocalReminderScheduler()

    static func requestAuthorization() async -> Bool {
        guard canUseUserNotifications else { return false }

        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        guard canUseUserNotifications else { return .notDetermined }

        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    static func rescheduleReminder(for bottle: Bottle) async {
        guard canUseUserNotifications else { return }

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
        guard canUseUserNotifications else { return }

        let identifiers = Weekday.allCases.map { reminderIdentifier(for: bottleId, weekday: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    static func scheduleTestReminder() async {
        guard canUseUserNotifications else { return }
        let granted = await requestAuthorization()
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = "Reminder: check your bottle."
        content.body = "Test reminder: Open TwistLog to view recent openings."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(
            identifier: "twistlog.reminder.test",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    private static func reminderIdentifier(for bottleId: UUID, weekday: Weekday) -> String {
        "twistlog.reminder.\(bottleId.uuidString).\(weekday.rawValue)"
    }

    private static var canUseUserNotifications: Bool {
        Bundle.main.bundleIdentifier != nil
    }
}

private struct LocalReminderScheduler: ReminderScheduling {
    func requestAuthorization() async -> Bool {
        await NotificationManager.requestAuthorization()
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await NotificationManager.authorizationStatus()
    }

    func rescheduleReminder(for bottle: Bottle) async {
        await NotificationManager.rescheduleReminder(for: bottle)
    }

    func cancelReminder(for bottleId: UUID) {
        NotificationManager.cancelReminder(for: bottleId)
    }

    func scheduleTestReminder() async {
        await NotificationManager.scheduleTestReminder()
    }
}
