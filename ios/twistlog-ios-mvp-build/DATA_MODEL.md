# TwistLog Local Data Model

This is the app-first model. It supports manual logging now, NFC next, and sensor later.

## Bottle

```swift
struct Bottle: Identifiable, Hashable {
    var id: UUID
    var nickname: String
    var medicationName: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var minimumIntervalEnabled: Bool
    var minimumIntervalMinutes: Int?
    var isArchived: Bool
}
```

## OpeningEvent

```swift
struct OpeningEvent: Identifiable, Hashable {
    var id: UUID
    var bottleId: UUID
    var openedAt: Date
    var source: OpeningSource
    var createdAt: Date
    var editedAt: Date?
    var note: String?
}
```

## OpeningSource

```swift
enum OpeningSource: String, CaseIterable, Codable {
    case manual
    case nfc
    case sensor
    case imported
    case edited
}
```

## ReminderSchedule

For the first build, keep one time per bottle. Expand later if users ask for multiple daily reminders.

```swift
struct ReminderSchedule: Identifiable, Hashable {
    var id: UUID
    var bottleId: UUID
    var enabled: Bool
    var hour: Int
    var minute: Int
    var daysOfWeek: Set<Weekday>
    var repeatReminderEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
}
```

## AppSettings

```swift
struct AppSettings {
    var hasCompletedOnboarding: Bool
    var hasAcceptedSafetyDisclaimer: Bool
    var notificationsRequestedAt: Date?
    var createdAt: Date
    var updatedAt: Date
}
```

