# TwistLog Local Data Model

This is the app-first model. It supports manual logging now, NFC next, and sensor later.

## Bottle

```swift
struct Bottle: Identifiable, Hashable {
    var id: UUID
    var nickname: String
    var category: BottleCategory
    var medicationName: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var minimumIntervalEnabled: Bool
    var minimumIntervalMinutes: Int?
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var reminderDays: Set<Weekday>
    var reminders: [BottleReminder]
    var isArchived: Bool
}
```

`category` groups Today into Prescription, Supplements, and Other. Existing local bottles saved before this field existed decode as `prescription`; users can edit supplements once to move them into the Supplements section.

`reminderEnabled`, `reminderHour`, `reminderMinute`, and `reminderDays` remain for backward compatibility with early v1 builds. New UI and scheduling should use `reminders`.

## BottleCategory

```swift
enum BottleCategory: String, CaseIterable, Codable, Identifiable {
    case prescription
    case supplement
    case other
}
```

Today displays categories in this order: Prescription, Supplements, Other.

## BottleReminder

Each bottle can have multiple reminder times, such as 8:00 AM and 8:00 PM. Older one-reminder data is migrated into a one-item reminder array when decoded.

```swift
struct BottleReminder: Identifiable, Hashable, Codable {
    var id: UUID
    var isEnabled: Bool
    var hour: Int
    var minute: Int
    var days: Set<Weekday>
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

This is retained as a future sync/server concept. For the local MVP, reminder times live on `Bottle.reminders`.

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
