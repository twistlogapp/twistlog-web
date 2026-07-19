# TwistLog TestFlight QA Checklist

Run this checklist before sharing each TestFlight build.

## Simulator Pass

- Fresh install opens onboarding.
- Onboarding clearly says TwistLog records bottle openings, not medication taken.
- Today shows a time-aware greeting, such as `Good morning`, with the current date below it.
- Today empty state shows `No bottles yet` and the `Add Bottle` button.
- Add a bottle with only a nickname.
- Add a Prescription bottle with medication name, amount/label, timing note, notes, minimum opening interval, and one reminder.
- Add a Supplement bottle.
- Add a Water bottle, such as `School water bottle`.
- Confirm Today groups bottles as Prescription, Supplements, Water, and Other.
- Confirm bottles inside each Today section sort by the next reminder time.
- Confirm Prescription, Supplements, Water, and Other have distinct but subtle category accents.
- Confirm Today ring states can show `Done`, `Due`, `Soon`, `Next`, and `Log`.
- Confirm bottles without reminders show `No reminder set`.
- Edit the bottle and add a second reminder time, for example morning and evening.
- Edit an existing bottle's Type and confirm it moves to the correct Today section.
- Edit bottle context and confirm amount/timing appear on Today, Bottles, and Details.
- Confirm Today shows multiple reminder times.
- Open every active bottle for today and confirm the `All bottles opened today.` banner appears.
- Confirm the bottle list remains visible below the all-done banner.
- Confirm Details shows the bottle Type.
- Confirm Details lists each reminder time.
- Confirm unopened bottles show `Not opened today` or `Not opened yet`.
- Edit the bottle and confirm changes appear on Today and Details.
- Tap `Opened now` and confirm `Opening recorded.` appears.
- Confirm `Opening recorded.` fades away after about 2 seconds on Today and Details.
- Trigger a recent-opening alert and confirm `Record anyway` and `Cancel` both appear.
- Confirm History shows the new opening.
- Confirm History shows the subtitle `Review when your bottles were opened.`
- Confirm History is grouped by `Today`, `Yesterday`, and older date headers.
- Confirm History shows the `Daily openings` chart.
- Tap each Last 7 Days bar and confirm the selected day summary updates.
- Confirm `Last 7 days by category` totals are labeled clearly.
- Confirm History rows appear as rounded cards with bottle name, category dot, time, and date.
- Edit an opening time from History and confirm Today updates if needed.
- Delete an opening from History or Details and confirm it disappears.
- Archive a bottle and confirm it disappears from Today while existing history remains.
- Confirm the archive alert shows both `Archive Bottle` and `Cancel`.
- Open `Settings > Archived Bottles` and confirm the archived bottle appears.
- Open the archived bottle details and confirm its opening history is still visible.
- Restore the bottle and confirm it returns to Today.
- Force quit and relaunch; bottles, settings, reminders, and history persist.
- Increase Dynamic Type and confirm Today, History, Details, Settings, and onboarding remain usable.
- Verify Website, Privacy Policy, and Terms links open the correct pages.

## Real iPhone Pass

- Fresh install and complete onboarding.
- Allow reminder notifications from Settings.
- Set a real bottle reminder a few minutes ahead, background or lock the phone, and confirm the notification appears.
- Set multiple bottles to the same reminder time and confirm notifications are delivered or grouped.
- Confirm bottle reminders use safe copy: `Time to check your bottle.`
- Set two reminder times on one bottle and confirm both are saved after relaunch.
- Deny notifications on a fresh install and confirm the app still works without crashing.
- Tap Website, Privacy Policy, and Terms links and confirm they open in Safari.
- Confirm haptic feedback occurs after `Opened now`.
- Confirm Settings explains that MVP data is stored locally on this device.
- Install over an earlier build and confirm `What's New` appears once.
- Dismiss `What's New`, relaunch, and confirm it does not appear again for version 1.2.

## Safety Copy Check

- No screen says TwistLog confirms medication was taken.
- No screen gives medical advice.
- Notification copy remains cautious: `Time to check your bottle.`
- Orange is used for opening-recorded moments, not warnings or errors.

## Candidate Sign-Off

- Xcode build succeeds.
- Unit tests pass.
- Simulator pass complete.
- Real iPhone notification pass complete.
- App icon preview is correct in Xcode.
