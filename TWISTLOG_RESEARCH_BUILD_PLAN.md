# TwistLog Research + Build Plan

Last updated: 2026-07-03

Purpose: turn the early TwistLog idea into parallel workstreams that can validate the product quickly without overbuilding, overclaiming, or waiting for hardware to be perfect.

## Executive View

TwistLog should proceed in three parallel tracks:

1. Competitor research and feature selection.
2. Hardware prototype validation.
3. iOS MVP design/build.

These can run at the same time, but the make-or-break technical gate is hardware reliability:

```text
Can we reliably detect "bottle opened" across common prescription bottle/cap types?
```

Worst case, TwistLog can still launch as a strong manual/NFC medication logging and Apple Watch reminder app. Best case, hardware makes the app passive and meaningfully differentiated.

## Parallel Workstreams

### Track A: Competitor + Feature Research

Owner: Chandana / product research

Goal: decide what to copy, what to ignore, and where TwistLog is different.

Can run in parallel with hardware and app work.

Deliverables:

- Competitor matrix.
- Screenshots or notes from top iOS apps.
- Feature priority list.
- Pricing notes.
- User complaint themes from reviews.
- Safe language/compliance notes.

Key research targets:

- Medisafe
- Capsule
- Pillo
- Dosecast
- Hero
- MedMinder
- MedaCube
- TimeCap
- AdhereTech / smart pill bottle category
- Pillsy / smart cap category if still findable
- TimerCap / passive cap timers

### Track B: Hardware Prototype Validation

Owner: Dheeraj / hardware + BLE

Goal: prove the event detection mechanism before polishing hardware.

This is the highest-risk path and should start immediately.

Primary hypothesis:

```text
Bottle-mounted sensor + cap-mounted magnet can reliably detect cap open/close.
```

Prototype methods to test:

1. Hall sensor on bottle ring + small magnet on cap.
2. Reed switch on bottle ring + small magnet on cap.
3. NFC tap fallback.
4. MPU-6050 gyro/IMU as secondary experiment only.

Do not depend on gyro-only detection for V1 until proven. If the sensor sits on the bottle neck and the user only rotates/removes the cap, the bottle may not move enough for reliable detection.

### Track C: iOS MVP

Owner: Dheeraj / iOS

Goal: build a useful app even before hardware is reliable.

Can run in parallel with hardware.

MVP app should support:

- Add medication.
- Add simple schedule.
- Manual "Opened now" log.
- Today view.
- History timeline.
- Double-dose warning.
- Apple Watch notification/haptic.
- NFC tap fallback.
- Basic local storage first.

Supabase can come after local MVP unless cloud sync/caregiver is needed immediately.

## Competitor Matrix

### App-Only Competitors

#### Medisafe

Category: medication reminder and management app.

Observed features:

- iPhone and Apple Watch support.
- Medication reminders.
- Health app / HealthKit style integration.
- Drug-to-drug interaction warnings in the US.
- Medication import from Health Records where available.
- PDF report sharing.
- Family interaction / family pillboxes.
- Reminder sounds/tones.
- Timezone support.
- Refill reminders.
- Large review base and strong app ranking.

Sources:

- https://apps.apple.com/us/app/medisafe-medication-management/id573916946
- https://medisafe.com/

What TwistLog should copy:

- Simple medication setup.
- Today reminders.
- Refill reminders.
- Family/caregiver direction eventually.
- PDF/history export eventually.
- Apple Watch presence.

What TwistLog should avoid:

- Overclaiming adherence or safety outcomes.
- Trying to become a broad pharma engagement platform too early.

TwistLog differentiator:

Medisafe relies on self-reporting. TwistLog can add bottle-opening evidence.

#### Capsule

Category: iOS medication tracker app.

Known/expected feature themes to inspect manually in app:

- Manual dose logging.
- Minimum dose interval.
- NFC tag support.
- Shortcuts support.
- Per-medication reminders.
- Medication history.
- Tags/categories.

Research note:

Capsule's website may be barebones, so the app itself is the important source. Install and screen-record the onboarding/setup flows.

What TwistLog should copy:

- NFC fallback.
- Minimum dose interval.
- Fast manual logging.
- Clean per-medication history.
- iOS-native details.

TwistLog differentiator:

Capsule is still app/manual-first. TwistLog can make the physical bottle opening the primary event.

#### Pillo

Category: medication reminder app.

Observed/expected feature themes:

- Persistent/nagging reminders.
- Simple app-first medication reminders.
- Strong consumer positioning around not missing doses.

Source:

- https://pillo.care/

What TwistLog should copy:

- Escalating reminder concept.
- Simple non-clinical consumer language.

What TwistLog should avoid:

- Annoying reminders that become easy to uninstall.

#### Dosecast

Category: medication management / virtual care platform.

Observed features:

- Provider/payor/pharma orientation.
- Patient medication/care management.
- Caregiver real-time adherence visibility.
- Secure messaging.
- Broadcast notifications.
- Clinical care team positioning.
- AI/video-observed therapy claims in enterprise context.

Source:

- https://dosecast.com/

What TwistLog should copy:

- Caregiver visibility eventually.
- Enterprise/B2B future pattern only after consumer validation.

What TwistLog should avoid:

- Enterprise complexity in V1.
- Clinical claims.

### Hardware / Dispenser Competitors

#### Hero Health

Category: countertop automatic medication dispenser.

Observed features:

- Countertop dispenser.
- Push-button dispensing.
- Mobile app.
- Tracks pills in dispenser plus additional outside meds.
- Passcodes.
- Maximum dispense limits.
- Low-pill alerts.
- Family/loved-one peace of mind.
- Subscription model, around $39.99/mo with prepaid plans or $59.99/mo monthly at time reviewed.
- Claims HIPAA compliant and FDA registered.

Source:

- https://herohealth.com/

What TwistLog should copy:

- Family peace-of-mind framing.
- Low/refill alerts.
- Strong onboarding flow.

What TwistLog should attack:

- Hero is bulky.
- Hero changes the user's entire medication routine.
- Hero is expensive recurring hardware/service.

#### MedMinder

Category: automatic pill dispenser + pharmacy/provider platform.

Observed features:

- Hardware dispenser.
- Mobile app/cloud platform.
- Data services.
- Pharmacy services.
- Provider/caregiver workflows.
- Setup/support around medication management.

Source:

- https://medminder.com/

What TwistLog should copy:

- Caregiver support use case.
- Remote audit/history idea.

What TwistLog should avoid:

- Pharmacy operations in V1.
- Provider platform scope.

#### MedaCube

Category: automatic pill dispenser.

Observed features:

- Audio/visual dispense alerts.
- Caregiver notifications when a dose is late or missed.
- Refill alerts.
- Tamper alarm / lock/security.
- Holds up to 90-day supply of 16 medications.
- Large device.

Source:

- https://www.medacube.com/

What TwistLog should copy:

- Missed/late notification logic.
- Caregiver notification concept.
- Refill alerts.

What TwistLog should attack:

- Large 10x10x10 device class.
- More expensive/less portable than a bottle add-on.

### Smart Bottle / Smart Cap Category

#### AdhereTech-style smart bottles

Category: connected smart bottle, often pharma/program oriented.

Observed features:

- Bottle hardware with lights/speakers/sensors.
- Cellular connectivity.
- Cloud reminders.
- Provider/program alerting.
- Sensors to estimate pill quantity.

Source:

- https://www.wired.com/2013/03/adhere-tech-smart-pill-bottle

What TwistLog should copy:

- Passive container event concept.
- Cloud/event data model later.

What TwistLog should improve:

- Reusable add-on rather than replacement bottle.
- Consumer/iOS-first instead of pharma-program-first.

#### TimeCap / TimerCap-style caps

Category: passive cap timer/reminder.

Observed/expected features:

- Shows elapsed time since bottle was last opened.
- Low cost.
- No app/BLE/caregiver workflow.

What TwistLog should copy:

- Simple "when was this last opened?" value proposition.

What TwistLog should improve:

- App history.
- Alerts.
- Watch.
- Multi-bottle tracking.
- Caregiver/premium layer.

## Feature Selection

### Must-Have MVP

- Add medication.
- Schedule dose windows.
- Manual log: "Opened now."
- Today cards with status:
  - due later
  - due now
  - opened
  - missed/late
  - already opened
- Double-dose warning based on last opening/log.
- History by medication.
- Apple Watch notification/haptic.
- NFC fallback.
- Local storage.

### Hardware MVP

- Device ID.
- Bottle/medication assignment.
- Closed/open state.
- Open event timestamp.
- Basic debounce.
- BLE advertisement or BLE connection path.
- Manual fallback button on prototype board.

### Premium Later

- Caregiver dashboard.
- Cloud sync.
- Multi-user/family.
- PDF export for doctor visits.
- Refill estimate.
- Multiple ring bundle management.
- Shared alert contacts.
- App Store subscription.

### Avoid In V1

- Drug interaction engine.
- Doctor/pharmacy integrations.
- Health Records import.
- Clinical adherence claims.
- AI medical advice.
- B2B dashboards.
- FDA/clinical positioning.
- Fully custom hardware miniaturization before proof.

## Hardware Prototype Plan

### Prototype 1: Reed Switch + Magnet

Goal: simplest proof of open/closed state.

Parts:

- ESP32 dev board.
- Reed switch.
- Tiny neodymium magnet.
- Breadboard.
- Jumper wires.
- Prescription bottle.
- Tape or temporary 3D printed holder.

Test:

1. Attach reed switch to bottle neck or upper shoulder.
2. Attach magnet to cap.
3. Read digital state from ESP32.
4. Print `closed` or `open` over serial.
5. Open and close cap 50 times.
6. Record missed events and false events.

Pass condition:

- 95%+ open detection in normal use.
- No events when bottle is carried, moved, or gently bumped.

### Prototype 2: Hall Sensor + Magnet

Goal: better proximity sensing and more robust alignment.

Parts:

- ESP32 dev board.
- Hall effect sensor module or raw Hall sensor.
- Tiny neodymium magnets.
- Breadboard/wires.

Test:

1. Measure magnetic field/digital threshold while cap closed.
2. Measure when cap lifted/removed.
3. Test multiple magnet placements.
4. Test multiple bottle sizes.
5. Add threshold/debounce logic.

Pass condition:

- Reliable close/open separation.
- Tolerates imperfect cap alignment.

### Prototype 3: NFC Tag Fallback

Goal: useful app path even without sensor.

Parts:

- NTAG213/215/216 NFC stickers.
- iPhone.

Test:

1. Put NFC sticker on bottle or box.
2. Tap iPhone.
3. Open app/log event for assigned medication.

Pass condition:

- User can log in under 2 seconds.
- Works without opening a complicated screen.

### Prototype 4: Gyro/IMU Secondary

Goal: determine if twist/motion helps, not primary path.

Parts:

- MPU-6050.
- ESP32.

Test:

1. Attach sensor to bottle ring.
2. Open bottle in normal ways.
3. Detect rotation/movement.
4. Compare to magnet sensor.

Likely conclusion:

Useful for context, but unreliable if cap moves and bottle does not.

## Event Detection Rules

Use cautious event language:

```text
Bottle opened
Bottle closed
Possible duplicate opening
Manual log
NFC log
Device low battery
Device offline
```

Do not use:

```text
Dose taken
Dose confirmed
Medication consumed
Overdose prevented
```

Suggested open-event logic:

```text
If state changes closed -> open
and open state remains for >= 1.5 seconds
and last open event was more than 20 seconds ago
then emit bottle_opened
```

Suggested double-dose logic:

```text
If medication already has an opening/log inside configured minimum interval
show warning:
"This bottle was already opened at 8:14 AM."
```

## iOS MVP Spec

### Tabs

1. Today
2. History
3. Devices
4. Account/Settings

### Today Screen

Medication cards:

- Medication name.
- Next scheduled window.
- Last opened/logged time.
- Status pill.
- "Opened now" button.
- Optional NFC/device badge.

Status states:

- Not due yet.
- Due now.
- Opened today.
- Late.
- Already opened.
- Device not seen.
- Needs setup.

### Add Medication

Fields:

- Medication nickname/name.
- Dose schedule.
- Minimum interval.
- Optional bottle/device assignment.
- Refill count/supply optional later.
- Notification style.

### History

Views:

- By date.
- By medication.
- Event type:
  - device_opened
  - manual_log
  - nfc_log
  - edited
  - deleted

### Devices

Device states:

- Assigned.
- Unassigned.
- Last seen.
- Battery unknown/low.
- Open/closed state.
- Firmware/version later.

### Watch

MVP:

- Notification when due.
- Haptic.
- Action buttons:
  - Opened
  - Remind me later
  - View status

Later:

- Watch app/complication with next due med.

## Supabase Later

Start local on iOS for speed. Add Supabase when the app needs cloud sync/caregiver/dashboard.

Tables:

- `profiles`
- `medications`
- `bottle_devices`
- `dose_events`
- `reminder_schedules`
- `device_events_raw`
- `caregiver_links`
- `waitlist`
- `admin_audit_log`

Important event fields:

- `id`
- `user_id`
- `medication_id`
- `device_id`
- `event_type`
- `event_source`
- `occurred_at`
- `received_at`
- `payload`
- `confidence`
- `created_at`

Event sources:

- `device`
- `manual`
- `nfc`
- `watch`
- `import`

## Legal / FDA / Language Guardrails

FDA's mobile/device software guidance says FDA focuses oversight on software functions that meet the medical device definition and whose failure could pose patient safety risk. TwistLog should stay framed as a low-risk reminder/logging companion unless a healthcare attorney advises otherwise.

Source:

- https://www.fda.gov/regulatory-information/search-fda-guidance-documents/policy-device-software-functions-and-mobile-medical-applications

Approved language:

- Bottle opening log.
- Tracks bottle openings.
- Reminder companion.
- Helps reduce guessing.
- Possible duplicate opening alert.
- For personal reference.
- Not a substitute for professional medical advice.
- Does not verify ingestion.

Avoid:

- Ensures adherence.
- Prevents overdose.
- Confirms dose taken.
- Confirms medication consumed.
- Medical device.
- Clinically proven.
- Treatment outcome claims.

## Business Model Notes

Possible pricing:

- Hardware starter kit: $49-$79.
- Extra rings/devices: $29-$39.
- Free app: 1-2 medications/bottles, manual + basic reminders.
- Premium: $3.99-$5.99/month or $39.99/year.

Premium features:

- Caregiver alerts.
- Cloud sync.
- Family/multi-user.
- PDF export.
- Advanced refill reminders.
- Multi-device/bottle management.

Do not add payment before validation. First prove users care.

## Validation Questions

Ask 10-20 target users:

1. Have you ever forgotten whether you took/opened a medication?
2. Have you ever double-dosed because you were unsure?
3. What do you use now?
4. Do reminders work for you?
5. Would manual logging be too annoying?
6. Would tapping an NFC sticker be acceptable?
7. Would attaching a small ring + cap magnet be acceptable?
8. How many medication bottles would you track?
9. Would you pay $49 for hardware?
10. Would caregiver alerts be useful?
11. Would you pay $4.99/month for caregiver/cloud/PDF features?
12. What would make you not trust this?

## Immediate 7-Day Plan

### Day 1

- Order hardware parts.
- Install/test Capsule, Medisafe, Pillo, Dosecast apps.
- Capture screenshots/flows.
- Create first SwiftUI local prototype skeleton.

### Day 2

- Reed switch + magnet test.
- Hall sensor + magnet test.
- Decide primary detection approach.

### Day 3

- iOS Today screen.
- Manual "Opened now."
- Local history.

### Day 4

- NFC tap proof.
- Double-dose warning.
- Minimum interval.

### Day 5

- BLE event proof from ESP32 to iPhone.
- Map device event to medication.

### Day 6

- Apple Watch notification/haptic proof.
- Test with 2-3 bottles.

### Day 7

- Record demo video.
- Summarize hardware reliability.
- Decide whether to continue hardware-first or app/NFC-first.

## Decision Gates

### Continue Hardware-First If

- Magnet sensor detects 95%+ of opens.
- False positives are rare.
- Setup is explainable in under 60 seconds.
- Cap magnet is not annoying.

### Shift To App/NFC-First If

- Sensor is unreliable.
- Bottle/cap shapes vary too much.
- Battery/power is too hard early.
- Users accept NFC/manual logging.

### Kill Or Pivot If

- Users do not care enough to pay.
- Hardware attachment feels too awkward.
- Legal risk requires expensive medical device path.
- Competitors already solve the exact use case better.

## Core Product Thesis

TwistLog should not try to be "the app that makes people take medicine."

TwistLog should be:

```text
The fastest way to know whether this specific bottle was already opened.
```

That is narrow, honest, useful, and easier to validate.

