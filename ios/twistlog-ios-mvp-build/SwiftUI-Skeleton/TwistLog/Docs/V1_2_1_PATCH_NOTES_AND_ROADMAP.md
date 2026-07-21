# TwistLog V1.2.1 Patch Notes and Roadmap

Last updated: July 20, 2026

## Context

V1.2 was approved by Apple and added a much stronger daily-use experience: redesigned Today cards, Water category, bottle context, history insights, editable opening times, and better readability.

After approval, real-device testing exposed several multi-reminder and clarity issues. The most important finding was that a bottle with multiple reminders needed clearer, more predictable completion logic.

## Fixed in Current Patch

### Multi-reminder completion logic

Previous behavior was too strict and time-window based. An opening near or before a later reminder could fail to satisfy that later reminder, leaving the bottle stuck in `Soon` or `Due`.

New behavior is count-based:

- 1 reminder today + 1 opening today = complete
- 2 reminders today + 1 opening today = one planned opening recorded; next reminder remains
- 2 reminders today + 2 openings today = complete
- 3 reminders today + 3 openings today = complete

Reminder times still guide the next ring status, but the number of recorded openings determines whether the bottle is complete for the day.

Example:

- Reminders: `7:11 AM`, `5:54 PM`
- Openings: `5:46 PM`, `5:47 PM`
- Result: `2 of 2` openings recorded, bottle is complete for today.

### Partial completion copy

Previous partial copy could produce confusing clock-time combinations, such as:

`Opened 8:41 PM - Due 8:00 PM`

New copy is count-based:

`1 of 2 openings recorded today`

This avoids stale or backward-sounding time labels and matches the count-based completion model.

### Stable Today list ordering

Today cards previously sorted by live next-reminder status. After logging an opening, a card could jump to a new position in the section.

New behavior:

- Sort by static configured reminder schedule.
- Earliest configured reminder time appears first.
- No-reminder bottles appear after reminder bottles.
- Logging updates the ring/status inside the card without moving the card.

### Water progress ring label

Water bottles with multiple reminders now use count-based ring labels:

- `4 left`
- `3 left`
- `2 left`
- `1 left`
- `Done`

This avoids stale labels like `Due 8 AM` late in the day for water bottles. Prescription, Supplements, and Other remain time-based.

### Recent-opening warning conflict

The app could show `Recent opening found` even when the next scheduled reminder slot was already due.

New behavior:

- If the next required reminder slot is due, recording can proceed without the recent-opening warning.
- The minimum interval warning still applies for extra or early openings when appropriate.

### No-reminder wording consistency

Bottles tab now matches Today:

- Text: `No reminder set`
- Icon: `bell.slash`

### Share opening history

History now includes a native iOS share action for opening records.

Behavior:

- Available from the History toolbar when opening records exist.
- Generates a local CSV file named like `TwistLog-Opening-History-2026-07-21-1842.csv`.
- Uses the native iOS share sheet for Files, AirDrop, Mail, Messages, and other system destinations.
- Does not add a backend, account, sync, email integration, or cloud dependency.
- Includes archived bottle history because opening history is preserved after archiving.
- Missing bottle fallback is `Deleted bottle` and `Unknown` category.

CSV columns:

- `Bottle`
- `Category`
- `Opened At`
- `Source`
- `Note`

Safe wording:

- Use `Share history`, `opening history`, and `opening records`.
- Avoid `adherence`, `compliance`, `missed`, `taken`, `dose taken`, and `medication report`.

## Product Decision: Count-Based Completion

TwistLog records bottle-opening events. It does not verify medication ingestion, dosage, or clinical adherence.

For that reason, V1.2.1 uses this simpler rule:

`Each opening recorded today counts toward one planned reminder for today.`

This model is easier to explain, safer for TwistLog's scope, and avoids the app judging whether an opening was medically valid based on exact time.

## Known Gaps / Not Urgent

### Ring label accuracy for out-of-order logging

The ring label still points to the next reminder by count. If openings are logged far out of order, the ring can show a stale scheduled time.

Example:

- Reminders: `8 AM`, `8 PM`
- User logs one opening at `8:41 PM`
- App may still point to the next reminder by count, not infer which exact reminder the opening was intended to satisfy.

Current safety property:

- The app does not falsely mark the bottle complete until enough openings are recorded.
- This is a display-accuracy gap, not a false-completion bug.

Future options:

- Keep count-based model but use more count-based labels for multi-reminder states.
- Add optional assignment of an opening to a reminder slot.
- Add a grace-window model, only if user feedback proves it is needed.

### Water progress behavior

Water now uses `N left`, which is clearer than stale time labels. Watch for feedback on whether Water should become more habit-focused in V1.3.

## V1.3 Candidates

### Reminder Control

- Pause reminders for today.
- Per-bottle pause first.
- Optional global pause later.
- Show `Paused today`.
- Automatically reset tomorrow.
- Cancel/suppress local notifications correctly.
- Requires real-device notification QA.

### Follow-up nudges

- Optional follow-up if no opening was recorded after the first reminder.
- Example delays: `30 min`, `1 hour`, `2 hours`.
- Cancel follow-up when opening is recorded.
- Limit follow-ups to avoid notification fatigue.
- Safe copy: `Still need to check [Bottle Name]?`
- Avoid: `missed dose`, `dose missed`, or similar medical claims.

### Multi-reminder display polish

- Improve ring labels for out-of-order logging.
- Explore count-based labels for multi-reminder bottles.
- Keep medication/supplement wording careful.

## Later Candidates

### Refill estimate

- Optional quantity estimate.
- Optional threshold.
- Safe copy:
  - `May be running low soon`
  - `Refill estimate`
- Avoid exact claims:
  - Do not say `You have exactly X pills left`.

### Camera / OCR

- Scan medication or bottle label text to prefill bottle name.
- Needs careful privacy and accuracy wording.

### Apple Watch / Widgets / Siri

- Faster logging surfaces.
- Good fit after reminder logic stabilizes.

### Caregiver / Family Sharing

- Much later.
- Requires account, sync, permissions, privacy, and safety design.

### NFC / Hardware

- Future path for tap or sensor-based opening records.
- Do not imply automatic detection until implemented and tested.

## Release Recommendation

If V1.2 is already live or approved, treat these changes as a small V1.2.1 maintenance update after real-device testing.

Suggested App Store wording:

`Improved multi-reminder tracking, Water bottle progress labels, and Today screen stability.`

Suggested reviewer note:

`This update improves multi-reminder bottle tracking, Today screen status labels, and Water bottle progress display. No account, payment, backend, or privacy changes were made.`
