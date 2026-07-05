# TwistLog iOS MVP Flow Map

## App Structure

Tabs:

1. Today
2. Opening History
3. Settings

No account. No Supabase. No hardware requirement. No NFC requirement in v1.0.

## First Launch

### Screen 1: Promise

Title:

```text
Know when the bottle was opened.
```

Body:

```text
Manual log or NFC tap today. Sensor ring detection is in prototype.
```

Primary action:

```text
Continue
```

### Screen 2: Safety Boundary

Title:

```text
Opening events, not dose confirmation.
```

Body:

```text
TwistLog records bottle-opening events for personal reference and reminders. It does not verify that medicine was taken and is not medical advice.
```

Primary action:

```text
I understand
```

### Screen 3: Reminders

Title:

```text
Get reminder nudges.
```

Body:

```text
TwistLog can remind you to check a bottle and record an opening.
```

Actions:

```text
Enable reminders
Not now
```

Ask for iOS notification permission only after the user taps `Enable reminders`.

### Screen 4: First Bottle

Title:

```text
Add your first bottle.
```

Body:

```text
Give it a simple name like Morning bottle or Bedside bottle.
```

Actions:

```text
Add Bottle
Skip for now
```

## Today Tab

Primary job: record an opening in one tap.

### Header

The Today screen opens with a time-aware greeting and the current date:

```text
Good morning
Sunday, July 5
```

Do not hardcode a user name in v1. A personalized greeting can come later after the app has an explicit profile/name field.

### Empty State

```text
Add a bottle to get started.
TwistLog will show recent openings and reminder status here.
```

Primary action:

```text
Add Bottle
```

### Grouping

Today groups active bottles by type, not by separate tabs:

1. Prescription
2. Supplements
3. Other

Prescription stays first so important medications do not get pushed below vitamins or supplements. Sections stay on one screen so users do not have to switch tabs to see what needs attention.

### All-Done State

When every active bottle has an opening recorded for the current day, show a calm success banner above the bottle sections:

```text
All bottles opened today.
Great job. Your opening history is up to date.
```

Keep the bottle list visible below the banner so users can still open Details or record another opening if needed.

### Bottle Card

Recommended card order:

1. Bottle nickname.
2. Optional medication name.
3. Last opening.
4. Reminder summary.
5. Status pill.
6. `Opened now` button.
7. `Details` link.

Example:

```text
Morning bottle
Vitamin D
Last opening: Today at 8:14 AM
Next reminder: Tomorrow at 8:00 AM
Opened today
Opened now
```

### Opened Now Flow

1. User taps `Opened now`.
2. If no recent-opening warning applies, create opening event.
3. Show `Opening recorded.`
4. Use orange dot/pulse.
5. Trigger light haptic.
6. Update card immediately.

### Recent Opening Warning

Trigger when minimum interval is enabled and the last opening is inside that interval.

Sheet:

```text
Recent opening found.
This bottle was already opened at 8:14 AM.
```

Actions:

```text
Record anyway
Cancel
```

Use red warning styling. Do not use orange for warning states.

## Add/Edit Bottle

Fields:

- Bottle nickname, required.
- Type: Prescription, Supplement, or Other.
- Medication name, optional.
- Notes, optional.
- Reminder schedule toggle.
- Reminder time.
- Reminder days.
- Minimum time between openings toggle.
- Minimum interval duration.

Validation:

- Bottle nickname is required.
- Reminder schedule needs at least one day and one time.
- Minimum interval must be greater than zero.

Default stance:

- Keep the form short.
- Put minimum interval under an `Advanced` section if the first version feels crowded.
- Do not ask for dosage details in v1.0.

## Bottle Detail

Primary job: inspect one bottle.

Sections:

- Header with bottle nickname and optional medication name.
- Last opening.
- `Opened now`.
- Reminder schedule.
- Minimum interval.
- Recent openings.
- Notes.
- Edit bottle.

Recent opening row:

```text
Orange dot  Bottle opened  Today at 8:14 AM  Manual
```

## Opening History

Primary job: answer what happened recently.

Default:

- Reverse chronological.
- Grouped by day.
- Orange dot for each recorded opening.

Empty state:

```text
Opening history will appear here.
```

Rows:

```text
Morning bottle
Bottle opened
Today at 8:14 AM
Manual
```

## Settings

MVP:

- Notification settings.
- Safety/disclaimer.
- About TwistLog.
- Privacy Policy.
- Terms.

Later:

- Export data.
- Import data.
- iCloud/Supabase sync.
- NFC stickers.
- Prototype hardware.
