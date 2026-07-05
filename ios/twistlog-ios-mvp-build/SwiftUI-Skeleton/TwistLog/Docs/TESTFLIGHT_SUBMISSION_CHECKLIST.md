# TwistLog TestFlight Submission Checklist

Use this after the app builds cleanly and the QA checklist passes.

## 1. Git / Branch State

- Confirm Mac branch is `ios-mvp-v1`.
- Confirm working tree is clean before archive.
- Confirm latest commits are pushed to GitHub.
- Do not merge `ios-mvp-v1` into `main` yet.

Suggested commit message for the polish pass:

```text
Polish TestFlight readiness screens
```

## 2. Xcode Project Basics

- Open the TwistLog Xcode project on the Mac mini.
- Select the TwistLog app target.
- Confirm Bundle Identifier is final or close to final, for example:

```text
com.twistlog.app
```

- Confirm Display Name is:

```text
TwistLog
```

- Confirm Version is:

```text
1.0
```

- Confirm Build is incremented before every upload:

```text
1
```

- Confirm signing team is your Apple Developer account.
- Confirm automatic signing works.
- Confirm deployment target is reasonable for current iPhones.

## 3. App Icon / Assets

- Confirm AppIcon preview shows only the final TwistLog app icon.
- Confirm it is not the full brand board image.
- Confirm the icon has no transparent background.
- Confirm the icon does not have rounded corners baked in.

## 4. Required Website Links

Confirm these open correctly:

- https://twistlog.com
- https://twistlog.com/privacy
- https://twistlog.com/terms

Confirm the same links work inside the iOS app Settings/About screen.

## 5. Safety / Medical Wording

Before uploading, scan the app for unsafe claims.

Approved framing:

- TwistLog records bottle-opening events.
- TwistLog helps review opening history.
- TwistLog can send reminder nudges.
- TwistLog does not confirm medication was taken.
- TwistLog is not medical advice.

Avoid:

- Confirms medication was taken.
- Prevents missed doses.
- Prevents double dosing.
- Medical adherence guarantee.
- Treatment recommendation.
- FDA-style medical claims.

## 6. Local QA Before Archive

Run the companion checklist:

```text
TESTFLIGHT_QA_CHECKLIST.md
```

Minimum pass before archive:

- Fresh install onboarding works.
- Add bottle works.
- Opened now records an opening.
- History displays opening.
- Edit bottle works.
- Archive bottle works.
- Relaunch persistence works.
- Notification permission works.
- Test notification appears when app is backgrounded or phone is locked.
- Website, Privacy, and Terms links open.

## 7. Archive And Upload

- In Xcode, select a real device or `Any iOS Device`.
- Choose `Product > Archive`.
- Wait for archive to complete.
- In Organizer, select the archive.
- Choose `Distribute App`.
- Choose `App Store Connect`.
- Choose upload.
- Let Xcode handle signing unless it fails.
- Upload and wait for processing.

## 8. App Store Connect Setup

Create or open the TwistLog app record.

Suggested app name:

```text
TwistLog
```

Suggested subtitle:

```text
Bottle opening tracker
```

Suggested short description / beta description:

```text
TwistLog records bottle-opening events, reminders, and opening history for personal reference. It does not confirm medication was taken and is not medical advice.
```

Suggested keywords draft:

```text
bottle,reminder,medication,tracker,history,health,opening
```

## 9. TestFlight Beta Notes

Use clear tester instructions:

```text
Thanks for testing TwistLog. Please try adding a bottle, recording an opening, setting a reminder, checking opening history, and archiving a bottle. TwistLog records when a bottle is opened; it does not confirm medication was taken.
```

Suggested feedback questions:

- Did onboarding make the purpose clear?
- Was adding a bottle easy?
- Did `Opened now` feel obvious?
- Did reminder notifications appear as expected?
- Did any wording feel too medical or confusing?
- What felt missing from the first version?

## 10. Privacy Checklist

For the first TestFlight build, assume minimal data collection unless you added analytics or backend sync.

Confirm:

- No account login.
- No Supabase sync yet.
- No analytics SDK.
- No ad tracking.
- Data is stored locally on device.
- Notifications are local reminders.

If this changes later, update privacy policy and App Store privacy answers.

## 11. Internal Testers

- Add yourself first.
- Install from TestFlight.
- Run full QA on the TestFlight build, not just the Xcode build.
- Add one trusted tester only after your own TestFlight install passes.

## 12. Stop / Go Decision

Ready for first external tester when:

- Xcode archive/upload succeeds.
- TestFlight processing completes.
- You can install the build from TestFlight.
- Core flow passes on a real iPhone.
- Safety wording still looks clean.
- Privacy and Terms links work.

Hold the build if:

- Notifications do not work on a real iPhone.
- App crashes after relaunch.
- App icon is wrong.
- Any page says TwistLog confirms medication was taken.
- Privacy/Terms links fail.
