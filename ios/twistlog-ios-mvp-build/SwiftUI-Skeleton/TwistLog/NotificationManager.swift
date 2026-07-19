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

        let reminders = bottle.enabledReminders

        guard !reminders.isEmpty, !bottle.isArchived else {
            return
        }

        let granted = await requestAuthorization()
        guard granted else { return }

        for (index, reminder) in reminders.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "\(bottle.nickname) reminder"
            content.body = "Time to check your bottle."
            content.sound = .default

            if reminder.days == Set(Weekday.allCases) {
                var components = DateComponents()
                components.hour = reminder.hour
                components.minute = reminder.minute

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(
                    identifier: dailyReminderIdentifier(for: bottle.id, reminderIndex: index),
                    content: content,
                    trigger: trigger
                )

                try? await UNUserNotificationCenter.current().add(request)
            } else {
                for weekday in reminder.days {
                    var components = DateComponents()
                    components.weekday = weekday.rawValue
                    components.hour = reminder.hour
                    components.minute = reminder.minute

                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                    let request = UNNotificationRequest(
                        identifier: weeklyReminderIdentifier(for: bottle.id, reminderIndex: index, weekday: weekday),
                        content: content,
                        trigger: trigger
                    )

                    try? await UNUserNotificationCenter.current().add(request)
                }
            }
        }
    }

    static func cancelReminder(for bottleId: UUID) {
        guard canUseUserNotifications else { return }

        let legacyIdentifiers = Weekday.allCases.map { legacyReminderIdentifier(for: bottleId, weekday: $0) }
        let identifiers = (0..<12).flatMap { index in
            [dailyReminderIdentifier(for: bottleId, reminderIndex: index)] +
                Weekday.allCases.map { weeklyReminderIdentifier(for: bottleId, reminderIndex: index, weekday: $0) }
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: legacyIdentifiers)
    }

    static func scheduleTestReminder() async {
        guard canUseUserNotifications else { return }
        let granted = await requestAuthorization()
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to check your bottle."
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

    private static func dailyReminderIdentifier(for bottleId: UUID, reminderIndex: Int) -> String {
        "twistlog.reminder.\(bottleId.uuidString).\(reminderIndex).daily"
    }

    private static func weeklyReminderIdentifier(for bottleId: UUID, reminderIndex: Int, weekday: Weekday) -> String {
        "twistlog.reminder.\(bottleId.uuidString).\(reminderIndex).\(weekday.rawValue)"
    }

    private static func legacyReminderIdentifier(for bottleId: UUID, weekday: Weekday) -> String {
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
