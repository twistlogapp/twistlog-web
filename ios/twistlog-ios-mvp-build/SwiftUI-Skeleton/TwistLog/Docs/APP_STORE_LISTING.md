# TwistLog App Store Listing (First Cut)

Last updated: 2026-07-05

Draft copy for the App Store Connect app record. Written to stay consistent
with `COPY_AND_LANGUAGE.md`: TwistLog records bottle-opening events based on
manual user input. It does not detect physical bottle openings, confirm
medication was taken, or verify dosage. Avoid words like "detect" or
"physically opened" anywhere in future copy revisions.

## App Name

```text
TwistLog
```

Matches the installed Display Name exactly.

## Subtitle (30 char max)

```text
Bottle Opening Tracker
```

Literal, searchable, safe. 23 characters.

## Promotional Text (170 char max, editable anytime without a new build)

```text
Know when a bottle was last opened. TwistLog records openings, sends reminder nudges, and keeps a private history on your device. No account needed.
```

## Description (4000 char max)

```text
KNOW WHEN THE BOTTLE WAS OPENED.

TwistLog is a simple bottle-opening tracker. It helps answer one practical question: when was this bottle last opened?

WHAT TWISTLOG DOES
• Record an opening in one tap with "Opened now"
• Set one or more daily reminders per bottle, such as morning and evening
• See a recent-opening alert if a bottle was opened sooner than your chosen interval
• Review opening history grouped by day
• Organize bottles as Prescription, Supplements, Water, or Other
• Archive bottles you are no longer tracking without losing their history
• Use the app with no account, login, or cloud setup

WHAT TWISTLOG DOES NOT DO
TwistLog does not confirm that medication was taken, verify dosage, or provide medical advice. It records bottle-opening events based on your own input. Always follow your prescriber's, pharmacist's, or care professional's instructions.

WHO IT'S FOR
TwistLog is built for personal reference. It can help anyone who wants a simple record of bottle-opening times, or a family member helping track a loved one's routine. It is not a substitute for professional care, medication supervision, or clinical monitoring.

PRIVACY, BY DESIGN
Your data stays on your device. TwistLog does not require an account, does not sync to a cloud service, and does not use analytics or ad tracking in this version. Reminders are scheduled locally on your iPhone.

TwistLog records bottle-opening events for personal reference and reminders. It does not verify that medicine was taken and is not medical advice.
```

## Keywords (100 char max, comma-separated, no spaces)

```text
medication,supplement,pill,vitamin,reminder,log,history,caregiver,senior,routine,daily,nudge
```

92 characters. Skips words already indexed from the App Name/Subtitle
("bottle", "opening", "tracker").

## Reviewer Notes (App Review Information — private, not public)

```text
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

Guideline 4.3 clarification: TwistLog is intentionally scoped as a personal bottle-opening log, not a medication ingestion, dosage, or clinical adherence app. Users record bottle-opening events manually, can review opening history, and can set local reminder nudges. The recent-opening alert is based on the user's own recorded openings and chosen interval. TwistLog does not verify medication was taken, does not manage dosage, and does not provide medical advice.
```

## App Store Connect Setup Notes

- **Age rating**: 4+. No medical claims, no user-generated content, no location data.
- **Category**: Health & Fitness (primary), Lifestyle (secondary). Do not select Medical — that category invites extra scrutiny this app doesn't need given it explicitly disclaims medical function.

## Open Items Before Submission

- Confirm subtitle/description against the final build once real-device QA (Pass 3B) passes.
- Take App Store screenshots from a clean build reflecting current Today/History/Settings UI.
- Re-check this copy after any future feature (NFC, sensor detection) ships — do not reuse "based on user input" language once automatic detection exists.
