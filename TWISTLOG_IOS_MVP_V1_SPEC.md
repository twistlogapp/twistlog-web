# TwistLog iOS MVP v1.0 Product Spec

Last updated: 2026-07-04

Purpose: define the first iOS build clearly enough that it can be handed to Cursor/Xcode without waiting for hardware, Supabase, NFC, or Apple Watch app work.

## Product North Star

TwistLog helps a user answer one question quickly:

```text
When was this bottle last opened?
```

Brand promise:

```text
KNOW WHEN THE BOTTLE WAS OPENED.
```

MVP support copy:

```text
Manual log or NFC tap today. Sensor ring detection is in prototype.
```

## Scope

### In v1.0

- Local-first iPhone app.
- No account required.
- Add bottle.
- Manual `Opened now`.
- Last opening timestamp.
- Opening history.
- Simple local reminders.
- Minimum interval / recent-opening warning.
- Safety disclaimer.

### Not In v1.0

- Supabase sync.
- Sign in.
- Caregiver sharing.
- Medication interaction checks.
- Refill calculations.
- Widgets.
- Shortcuts.
- Full Watch app.
- NFC assignment flow.
- Sensor/ring pairing.
- Paid subscription.

## Product Principles

- Opening-first, not dose-first.
- One primary action: `Opened now`.
- Use orange only for recorded openings.
- Use red for warnings/problems.
- Avoid medical certainty language.
- Prefer `Bottle` over `Medication` in core flows, while allowing optional medication names.
- Prefer Apple-native patterns and calm, rounded UI.
- Keep each screen focused on one job.

## Capsule Learnings Applied

Capsule screenshots influenced the MVP, but TwistLog should stay narrower.

Borrow:

- Fast manual entry.
- Clear empty states.
- History tab.
- Schedule validation.
- Minimum interval / recent-opening warning.
- Per-item reminders later.
- Shortcuts/NFC later.

Do not copy into v1:

- Broad medication tracker complexity.
- Tags.
- Widgets.
- Import/export.
- Pro paywall.
- "Available/unavailable medication" status language.
- Heavy icon/color customization.

## App Structure

MVP tabs:

1. Today
2. Opening History
3. Settings

Later tabs or hidden sections:

- NFC
- Prototype Hardware
- Caregiver / Family

## Screen 1: Onboarding

Goal: explain the product promise and safety boundary before asking for permissions.

### Step 1: Promise

Title:

```text
Know when the bottle was opened.
```

Body:

```text
Manual log or NFC tap today. Sensor ring detection is in prototype.
```

Primary button:

```text
Continue
```

### Step 2: Safety Boundary

Title:

```text
Opening events, not dose confirmation.
```

Body:

```text
TwistLog records bottle-opening events for personal reference and reminders. It does not verify that medicine was taken and is not medical advice.
```

Primary button:

```text
I understand
```

### Step 3: Reminders

Title:

```text
Get reminder nudges.
```

Body:

```text
TwistLog can remind you to check a bottle and record an opening.
```

Primary button:

```text
Enable reminders
```

Secondary button:

```text
Not now
```

Only request iOS notification permission after this screen.

### Step 4: Add First Bottle

Primary button:

```text
Add Bottle
```

Secondary button:

```text
Skip for now
```

## Screen 2: Today

Goal: show current bottle status and make recording an opening one tap.

### Empty State

Title:

```text
Add a bottle to get started.
```

Body:

```text
TwistLog will show recent openings and reminder status here.
```

Primary button:

```text
Add Bottle
```

### Bottle Card

Fields:

- Bottle nickname.
- Optional medication name.
- Last opening.
- Next reminder, if configured.
- Status pill.
- Primary button: `Opened now`.
- Secondary link/button: `Details`.

Example:

```text
Morning bottle
Vitamin D
Last opening: Today at 8:14 AM
Next reminder: Tomorrow at 8:00 AM
Opened today
[Opened now]
```

### Status Pills

Use:

- `No opening yet`
- `Opened today`
- `Due soon`
- `Reminder due`
- `Recent opening`
- `Needs setup`

Avoid:

- `Taken`
- `Dose confirmed`
- `Available`
- `Unavailable`

### `Opened now` Behavior

When user taps `Opened now`:

1. Create `OpeningEvent`.
2. Source = `manual`.
3. Timestamp = current device time.
4. Show success copy:

```text
Opening recorded.
```

5. Use orange dot/pulse.
6. Trigger light success haptic.
7. Update Last opening immediately.

### Recent-Opening Warning

If the bottle has minimum interval enabled and the last opening is inside the interval, show a confirmation sheet.

Title:

```text
Recent opening found.
```

Body:

```text
This bottle was already opened at 8:14 AM.
```

Buttons:

```text
Record anyway
Cancel
```

Use red warning styling. Do not use orange for warning states.

## Screen 3: Add / Edit Bottle

Goal: add a bottle quickly without turning setup into a medical intake form.

Fields for v1:

- Bottle nickname, required.
- Medication name, optional.
- Notes, optional.
- Reminder schedule toggle.
- Reminder time(s).
- Reminder days.
- Minimum interval toggle.
- Minimum interval duration.

Defaults:

- Reminders off.
- Minimum interval off.
- No medication name required.
- Bottle nickname placeholder: `Morning bottle`.

Validation:

- Bottle nickname required.
- If reminders are enabled, at least one time and one day are required.
- If minimum interval is enabled, duration must be greater than zero.

Preferred labels:

- `Bottle nickname`
- `Medication name (optional)`
- `Reminder schedule`
- `Minimum time between openings`
- `Notes`

Avoid labels:

- `Dose confirmation`
- `Adherence`
- `Medication taken`

## Screen 4: Bottle Detail

Goal: inspect one bottle and its recent opening history.

Sections:

- Header: bottle nickname and optional medication name.
- Last opening card.
- `Opened now` button.
- Reminder schedule summary.
- Minimum interval summary.
- Recent openings list.
- Notes.
- Edit bottle.

Recent opening row:

```text
Orange dot  Bottle opened  Today at 8:14 AM  Manual
```

Event sources:

- Manual
- NFC
- Sensor
- Edited

## Screen 5: Opening History

Goal: answer "what happened recently?"

Default:

- Reverse chronological list.
- Group by day.
- Each opening uses the orange dot.

Empty state:

```text
Opening history will appear here.
```

Primary button:

```text
Record opening
```

Rows:

```text
Orange dot  Morning bottle  Bottle opened  Today at 8:14 AM
Orange dot  Evening bottle  Bottle opened  Yesterday at 9:02 PM
```

Later filters:

- By bottle.
- By source.
- By date range.

## Screen 6: Settings

MVP settings:

- Notification settings.
- Safety/disclaimer.
- About TwistLog.
- Privacy Policy.
- Terms.

Safety copy:

```text
TwistLog records bottle-opening events for personal reference and reminders. It does not verify that medicine was taken and is not medical advice.
```

Backlog settings:

- Export data.
- Import data.
- iCloud/Supabase sync.
- NFC stickers.
- Prototype hardware.

## Notifications

MVP:

- Local iOS notifications.
- Reminder due.
- Notification permission flow.

Notification copy:

```text
Reminder: check your bottle.
No opening recorded for this reminder yet.
Opening recorded.
```

Avoid:

```text
Time to take your dose.
Dose missed.
Medication confirmed.
```

Later notification actions:

- `Opened now`
- `Remind me later`

## Apple Watch

v1.0:

- Mirrored iPhone notifications only.
- Haptic arrives from iOS notification.

v1.1:

- Watch notification action: `Opened now`.
- Watch complication showing next reminder or last opening.

## NFC

v1.0:

- Plan model and copy.
- No required NFC flow if it slows launch.

v1.1:

- Assign NFC sticker to bottle.
- Tap sticker to open TwistLog and record opening.
- Success copy:

```text
Opening recorded by NFC.
```

## Prototype Hardware

v1.0:

- Mention in onboarding/marketing copy only.
- No required hardware screen.

v1.1:

- Test Lab / Prototype screen behind Settings.
- Pair test device.
- Show last sensor opening.
- Show last seen.
- Show battery if available.

## Data Model, Local First

Use local persistence first. SwiftData is preferred for modern iOS unless project constraints point to Core Data.

### Bottle

Fields:

- `id: UUID`
- `nickname: String`
- `medicationName: String?`
- `notes: String?`
- `createdAt: Date`
- `updatedAt: Date`
- `minimumIntervalEnabled: Bool`
- `minimumIntervalMinutes: Int?`
- `isArchived: Bool`

### OpeningEvent

Fields:

- `id: UUID`
- `bottleId: UUID`
- `openedAt: Date`
- `source: OpeningSource`
- `createdAt: Date`
- `editedAt: Date?`
- `note: String?`

Opening sources:

- `manual`
- `nfc`
- `sensor`
- `imported`
- `edited`

### ReminderSchedule

Fields:

- `id: UUID`
- `bottleId: UUID`
- `enabled: Bool`
- `timeOfDay: DateComponents`
- `daysOfWeek: Set<Weekday>`
- `repeatReminderEnabled: Bool`
- `createdAt: Date`
- `updatedAt: Date`

### AppSettings

Fields:

- `hasCompletedOnboarding: Bool`
- `hasAcceptedSafetyDisclaimer: Bool`
- `notificationsRequestedAt: Date?`
- `createdAt: Date`
- `updatedAt: Date`

## Visual Language

Color meanings:

- Green = TwistLog identity, device/ring identity, normal connected states.
- Orange = opening event recorded.
- Red = warning/problem.
- Gray = inactive, no recent event, or unknown state.

Orange usage:

- Opening history dots.
- `Opening recorded` success state.
- NFC success state.
- Sensor event state.
- Timeline markers.

Never use orange for:

- Possible repeat opening warning.
- Low battery.
- Device offline.
- Validation errors.

## User-Facing Language

Prefer:

- `Opening recorded`
- `Bottle opened`
- `Last opening`
- `Opening history`
- `Recent openings`
- `Opened now`

Avoid:

- `Log created`
- `Event logged`
- `Dose logged`
- `Medication taken`
- `Dose confirmed`
- `Adherence`

## Build Order

### Phase 1: App Shell

- SwiftUI app shell.
- Tabs: Today, Opening History, Settings.
- Brand colors.
- Static empty states.

### Phase 2: Local Data

- Add Bottle.
- Persist bottles locally.
- Today bottle cards.
- Bottle detail.

### Phase 3: Opening Events

- `Opened now`.
- Opening history.
- Recent openings list.
- Orange event markers.
- Success haptic.

### Phase 4: Reminders

- Local notification permission.
- Reminder schedule.
- Reminder due notification.
- Settings safety/disclaimer.

### Phase 5: Recent-Opening Warning

- Minimum interval setting.
- Warning sheet.
- `Record anyway` path.

### Phase 6: Polish

- Empty states.
- Accessibility labels.
- Error/validation copy.
- App icon.
- First TestFlight build.

## MVP Acceptance Criteria

- User can add a bottle in under 60 seconds.
- User can record `Opened now` in one tap from Today.
- User can see last opening for each bottle.
- User can view opening history grouped by day.
- App warns when recording inside the configured minimum interval.
- App can schedule at least one local reminder.
- App never claims medicine was taken.
- App works without account, cloud, NFC, or hardware.

## Open Questions

- Should the first release use "Bottle" everywhere, or "Bottle / Medication" in onboarding?
- Should minimum interval be visible in Add Bottle, or tucked into advanced settings?
- Should the Today screen sort bottles by reminder time, recent opening, or manual order?
- Should app data be local-only for TestFlight, or should iCloud sync come before public launch?
- Should notification actions wait for v1.1, or be included in the first TestFlight?
