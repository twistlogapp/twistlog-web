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
• Organize bottles as Prescription, Supplements, or Other
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
TwistLog is a local-first bottle-opening tracker. There is no account, login, or backend — all data (bottles, opening events, reminders) is stored on-device via UserDefaults. No test credentials are needed.

To test the core flow:
1. Complete onboarding (4 short screens explaining the app records bottle-opening events, not medication taken).
2. Tap the + button to add a bottle (nickname required; everything else optional).
3. Tap "Opened now" to record an opening — a brief "Opening recorded." confirmation appears and fades after ~2 seconds.
4. Optionally enable a reminder time in Add/Edit Bottle; local notification permission is requested only when a reminder is turned on, with a clear explanation beforehand.
5. Opening History (second tab) shows recorded openings grouped by day.
6. Bottles can be archived (Details > Archive Bottle) and restored from Settings > Archived Bottles; archiving preserves history.

Important: TwistLog does not confirm medication was taken, does not verify dosage, and does not give medical advice. Openings are recorded based on user input, not automatic or sensor-based detection. All in-app and notification copy is intentionally scoped to "bottle opened," not "dose taken." This is documented in-app under Settings > About and in the onboarding safety screen.

No analytics, ad tracking, or third-party SDKs are included in this build.

Guideline 4.3 clarification: TwistLog is intentionally scoped as a personal bottle-opening log, not a medication ingestion, dosage, or clinical adherence app. Users record bottle-opening events manually, can review opening history, and can set local reminder nudges. The recent-opening alert is based on the user's own recorded openings and chosen interval. TwistLog does not verify medication was taken, does not manage dosage, and does not provide medical advice.
```

## App Store Connect Setup Notes

- **Age rating**: 4+. No medical claims, no user-generated content, no location data.
- **Category**: Health & Fitness (primary), Lifestyle (secondary). Do not select Medical — that category invites extra scrutiny this app doesn't need given it explicitly disclaims medical function.

## Open Items Before Submission

- Confirm subtitle/description against the final build once real-device QA (Pass 3B) passes.
- Take App Store screenshots from a clean build reflecting current Today/History/Settings UI.
- Re-check this copy after any future feature (NFC, sensor detection) ships — do not reuse "based on user input" language once automatic detection exists.
