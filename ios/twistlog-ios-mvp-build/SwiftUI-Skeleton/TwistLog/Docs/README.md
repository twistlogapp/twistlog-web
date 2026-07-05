# TwistLog iOS MVP Build Pack

Last updated: 2026-07-04

This folder turns the TwistLog iOS MVP spec into a practical build handoff.

Primary source of truth:

- `../TWISTLOG_IOS_MVP_V1_SPEC.md`
- `../TWISTLOG_RESEARCH_BUILD_PLAN.md`

## What This Pack Contains

- `FLOW_MAP.md` - screen-by-screen MVP flow.
- `BUILD_BACKLOG.md` - implementation tasks in recommended order.
- `COPY_AND_LANGUAGE.md` - safe product language for the app.
- `DATA_MODEL.md` - local-first model shape.
- `SwiftUI-Skeleton/TwistLog` - starter SwiftUI source files for Cursor/Xcode.

## Recommended Build Approach

1. Create a new Xcode iOS app named `TwistLog`.
2. Use SwiftUI.
3. Target iOS 17+ if possible.
4. Add the Swift files from `SwiftUI-Skeleton/TwistLog` into the project.
5. Start with the Codable/UserDefaults `AppStore` included here.
6. Replace `AppStore` with SwiftData later if querying, sync, or migrations become heavier.

## MVP Rule

Ship the app even if hardware is not ready.

The app should answer one question clearly:

```text
When was this bottle last opened?
```

Brand promise:

```text
KNOW WHEN THE BOTTLE WAS OPENED.
```

Legal/safety boundary:

```text
TwistLog records bottle-opening events for personal reference and reminders. It does not verify that medicine was taken and is not medical advice.
```
