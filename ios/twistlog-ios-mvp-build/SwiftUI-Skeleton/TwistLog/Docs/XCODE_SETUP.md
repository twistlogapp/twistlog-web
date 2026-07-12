# Xcode Setup Notes

This pack contains source files, not a compiled Xcode project. Build the first app project on a Mac.

## Create The Project

1. Open Xcode.
2. Create a new project.
3. Choose `iOS` > `App`.
4. Product Name: `TwistLog`
5. Interface: `SwiftUI`
6. Language: `Swift`
7. Storage: start without Core Data. The included `AppStore` persists locally using Codable/UserDefaults. SwiftData can be added later.

## Add Source Files

Copy the Swift files from:

```text
SwiftUI-Skeleton/TwistLog
```

into the Xcode project.

If Xcode creates its own `TwistLogApp.swift`, replace it with the one in this pack or merge the `@StateObject private var store = AppStore()` environment setup.

## First Run Goal

The first run should show:

- Onboarding if `hasCompletedOnboarding` is false.
- Today, Opening History, and Settings tabs if true.
- Add/edit/archive bottle.
- `Opened now` recording local persisted events.
- Bottles and opening history still present after app restart.
- Bottle type, reminder on/off, multiple reminder times, and weekday selection in Add/Edit Bottle.
- Notification permission controls in Settings.
- Settings links opening `https://twistlog.com`, `/privacy`, and `/terms`.

## Later Persistence Upgrade

Replace the Codable/UserDefaults `AppStore` with SwiftData if needed:

- `BottleEntity`
- `OpeningEventEntity`
- `ReminderScheduleEntity`
- `AppSettingsEntity`

Keep the UI language unchanged while replacing persistence.
