# Xcode Setup Notes

This pack contains source files, not a compiled Xcode project. Build the first app project on a Mac.

## Create The Project

1. Open Xcode.
2. Create a new project.
3. Choose `iOS` > `App`.
4. Product Name: `TwistLog`
5. Interface: `SwiftUI`
6. Language: `Swift`
7. Storage: start without Core Data. SwiftData can be added after the first flow review.

## Add Source Files

Copy the Swift files from:

```text
SwiftUI-Skeleton/TwistLog
```

into the Xcode project.

If Xcode creates its own `TwistLogApp.swift`, replace it with the one in this pack or merge the `@StateObject private var store = AppStore.preview` environment setup.

## First Run Goal

The first run should show:

- Onboarding if `hasCompletedOnboarding` is false.
- Today, Opening History, and Settings tabs if true.
- Preview bottles from `AppStore.preview`.
- `Opened now` recording new local in-memory events.

## After Flow Approval

Replace the in-memory `AppStore` with SwiftData:

- `BottleEntity`
- `OpeningEventEntity`
- `ReminderScheduleEntity`
- `AppSettingsEntity`

Keep the UI language unchanged while replacing persistence.

