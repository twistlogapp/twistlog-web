# TwistLog V1.2 Release Readiness

Use this checklist before submitting the V1.2 build.

## What's New

- [ ] Install over the current App Store/TestFlight build.
- [ ] Launch TwistLog after update.
- [ ] Confirm the `What's New` sheet appears once.
- [ ] Confirm it lists Today card polish, Water/bottle context, and History insights.
- [ ] Tap `Done`.
- [ ] Force quit and relaunch.
- [ ] Confirm `What's New` does not appear again for version 1.2.
- [ ] Confirm copy says TwistLog records bottle-opening events and does not confirm medication was taken.

## Core Regression

- [ ] Add a Prescription bottle with medication name, amount/label, timing note, and reminder.
- [ ] Add a Supplement bottle.
- [ ] Add a Water bottle such as `School bottle`.
- [ ] Confirm Today groups Prescription, Supplements, Water, and Other.
- [ ] Confirm Today ring states: `Done`, `Due`, `Soon`, `Next`, and `Log`.
- [ ] Tap a ring and confirm logging options appear.
- [ ] Long-press a ring and confirm it records immediately.
- [ ] Tap a Today card and confirm Details opens.
- [ ] Confirm `No reminder set` appears for a bottle without reminders.

## History

- [ ] Record openings across multiple categories.
- [ ] Confirm `Daily openings` chart appears.
- [ ] Tap each bar and confirm selected day summary changes.
- [ ] Confirm selected day category counts are correct.
- [ ] Confirm `Last 7 days by category` total chips are clearly labeled.
- [ ] Edit an opening time from History.
- [ ] Delete an opening from History.

## Bottle Context

- [ ] Add `40mg` + `With food`.
- [ ] Add `16 oz bottle` + `After school` for Water.
- [ ] Add a custom timing note such as `After dinner`.
- [ ] Confirm context appears on Today, Bottles, and Details.
- [ ] Search in Bottles for amount/timing text.
- [ ] Confirm old bottles without context do not show blank rows.

## Real Device Reminders

- [ ] Allow notifications on a real iPhone.
- [ ] Set one bottle reminder a few minutes ahead.
- [ ] Background or lock the phone.
- [ ] Confirm notification appears.
- [ ] Set multiple bottles to the same reminder time and confirm notifications are delivered/grouped.
- [ ] Confirm reminder copy remains safe, e.g. `Time to check your bottle.`

## Accessibility And Appearance

- [ ] Test Light mode.
- [ ] Test Dark mode.
- [ ] Test larger Dynamic Type.
- [ ] Confirm Today, Bottles, History, Details, Settings, Add/Edit Bottle, and What's New remain readable.

## App Store Connect

- [ ] Bump build number before archive/upload.
- [ ] Keep version as `1.2` if this is the V1.2 release.
- [ ] Update screenshots if they still show the old Today or History UI.
- [ ] Paste the V1.2 reviewer notes below.

## Reviewer Notes - V1.2

TwistLog is already approved and live on the App Store. This V1.2 update is a feature polish release focused on clearer bottle-opening logs, better daily review, and safer display-only bottle context.

What changed in this build:
- Redesigned Today cards with tappable bottle tiles and ring-based logging.
- Added clearer ring states: Done, Due, Soon, Next, and Log.
- Added Water as a first-class bottle category for school, gym, bedside, or kids water bottles.
- Added optional display-only bottle context, such as amount/label and timing note.
- Added a Last 7 Days History chart with tap-to-inspect daily counts and category totals.
- Added edit opening time from History and Bottle Details.
- Improved notification scheduling reliability for daily reminders.
- Added a What's New card after update.
- Continued dark mode, larger text, and readability polish.

Reviewer testing steps:
1. Launch the app and complete onboarding if needed.
2. Add a bottle from the Bottles or Today screen.
3. Optionally enter display-only context such as `40mg`, `With food`, `16 oz bottle`, or `After school`.
4. Set one or more local reminder times.
5. Tap a Today card to open Details.
6. Tap a ring to record an opening, or long-press the ring to record immediately.
7. Open History and tap a Last 7 Days bar to inspect daily opening counts.
8. Edit an opening time from History or Bottle Details.
9. Add a Water bottle and confirm it appears under the Water section.

Important: TwistLog records bottle-opening events based on user input. It does not confirm medication was taken, verify dosage, measure water consumed, or provide medical advice. All data remains local to the device. No account, login, subscription, analytics, or third-party SDK is included in this build.
