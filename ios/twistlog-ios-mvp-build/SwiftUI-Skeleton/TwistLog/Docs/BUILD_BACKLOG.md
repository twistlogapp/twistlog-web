# TwistLog iOS MVP Build Backlog

## Milestone 0: Project Setup

- Create Xcode project: `TwistLog`.
- SwiftUI app lifecycle.
- iOS 17+ target if possible.
- Add brand colors:
  - Deep Green `#0E6B4F`
  - Event Orange `#FF9F1C`
  - Text Dark `#11181C`
  - Neutral Gray `#6B7280`
  - Light Gray `#F2F4F7`
- Add app icon once final assets are exported.

Acceptance:

- App launches to onboarding or Today.
- Brand colors available through a central theme file.

## Milestone 1: App Shell

- Add tab view.
- Tabs: Today, Opening History, Settings.
- Build empty Today state.
- Build empty Opening History state.
- Build static Settings screen.

Acceptance:

- User can move between all three tabs.
- No placeholder text uses unsafe medication claims.

## Milestone 2: Onboarding

- Promise screen.
- Safety boundary screen.
- Reminder permission explainer.
- Add first bottle prompt.
- Persist onboarding completion.

Acceptance:

- Notification permission is only requested after explanation.
- Safety copy is shown before the main app.

## Milestone 3: Bottle CRUD

- Add bottle form.
- Edit bottle form.
- Archive bottle.
- Required nickname validation.
- Optional medication name.
- Optional notes.
- Minimum time between openings.
- Store bottle locally.

Acceptance:

- User can add a bottle in under 60 seconds.
- Bottle appears on Today immediately.

## Milestone 4: Opening Events

- Add `Opened now` action.
- Create opening event with source `manual`.
- Update last opening.
- Build bottle detail recent openings.
- Build global Opening History.
- Add orange dot event marker.
- Add success haptic.

Acceptance:

- User can record an opening in one tap from Today.
- Last opening and history update immediately.

## Milestone 5: Minimum Interval Warning

- Add minimum interval setting.
- Detect when a new opening is inside the interval.
- Show warning sheet.
- Allow `Record anyway`.
- Allow `Cancel`.

Acceptance:

- Warning uses red, not orange.
- App says recent opening, not duplicate dose.

## Milestone 6: Local Reminders

- Request notification permission.
- Save reminder schedule.
- Schedule local notification.
- Cancel/reschedule when bottle changes.
- Add notification settings entry.

Acceptance:

- At least one local reminder can fire.
- Notification copy says `Time to check your bottle.` or uses the bottle name, such as `Time to check your Turmeric.`

## Milestone 7: TestFlight Polish

- Empty states.
- Today greeting and date.
- All-done Today banner when every active bottle has an opening today.
- Accessibility labels.
- Dynamic Type checks.
- Dark mode pass.
- App icon.
- Privacy and terms links.
- Safety disclaimer in Settings.
- First TestFlight build.

Acceptance:

- App never claims medicine was taken.
- App works with no account, no cloud, no NFC, and no hardware.

## First Technical Shortcut

Start with a Codable/UserDefaults observable store. It keeps the app simple while making bottles and opening history survive app restarts. Replace persistence with SwiftData later if querying, sync, or migration needs become heavier.

## First Product Shortcut

Multiple reminder times are now part of the MVP because twice-daily use is common. Keep the scheduling UI simple and local-first until the core opening flow is validated in TestFlight.
