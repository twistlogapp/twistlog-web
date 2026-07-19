# TwistLog V1.2 Phase 1 QA - UI Polish Freeze

Use this checklist to verify the Phase 1 UI polish before starting the larger V1.2 feature work.

Phase 1 goal: lock the daily-use UI so Today, Bottles, and History are readable, consistent, and clear about the difference between bottle category and opening status.

## Scope

- Today ring card UI.
- Ring tap and long-press logging behavior.
- Tile tap to Details.
- Category color system.
- Status color system.
- Larger readable fonts across Today, Bottles, and History.
- Same-calendar-day opening status.
- Dark mode and larger text sanity.

## Category Color System

Expected category colors:

- Prescription: green.
- Supplements: purple.
- Water: blue.
- Other: gray.

Verify:

- [ ] Prescription section header is green.
- [ ] Prescription card rail is green.
- [ ] Prescription History dot is green.
- [ ] Supplements section header is purple.
- [ ] Supplements card rail is purple.
- [ ] Supplements History dot is purple.
- [ ] Other section header is gray.
- [ ] Other card rail is gray.
- [ ] Other History dot is gray.
- [ ] Water section header is blue.
- [ ] Water card rail is blue.
- [ ] Water History dot is blue.

## Status Color System

Expected status colors:

- Done/opened today: green ring and green status label.
- Due/overdue: orange ring and orange status label.
- Upcoming/not due yet: gray ring and gray status label.
- Orange dot remains orange in every ring state.

Verify:

- [ ] A bottle opened today shows a green ring.
- [ ] A bottle opened today shows `Done` under the ring.
- [ ] A due bottle shows an orange ring.
- [ ] A due bottle shows `Due 8 PM` or equivalent under the ring.
- [ ] An upcoming bottle shows a gray ring.
- [ ] An upcoming bottle shows `Next 9 PM` or equivalent under the ring.
- [ ] A bottle with no opening and no reminder shows `Log` under the ring.
- [ ] The orange dot stays orange for green, orange, and gray ring states.
- [ ] The left card rail stays category-colored and does not change to due/opened status color.

## Today Ring Card Behavior

Create at least two bottles:

- One Prescription bottle with a reminder later today.
- One Supplement bottle with a reminder due now or earlier today.
- One Water bottle, such as `School water bottle`, with a reminder later today.

Verify:

- [ ] Today screen shows greeting and date.
- [ ] Today groups bottles by category.
- [ ] Section headers and bottle counts are readable.
- [ ] Bottle names are readable.
- [ ] Medication/details line is readable.
- [ ] Reminder line is readable and uses a bell icon.
- [ ] Status line is readable when shown.
- [ ] Upcoming bottles do not duplicate `Next due` on the left side when the ring already says `Next`.
- [ ] Tapping the main bottle tile opens the Details screen.
- [ ] Tapping the ring opens the logging options.
- [ ] Logging options include `Just now`, `Earlier today`, `Yesterday`, and `Cancel`.
- [ ] Long-pressing the ring records an opening immediately as `Just now`.
- [ ] After logging, the ring changes to green and shows `Done`.
- [ ] Undo appears after recording an opening.
- [ ] Undo removes the just-recorded opening and updates the Today card.
- [ ] Recent-opening warning still appears when minimum interval rules are triggered.

## Same-Calendar-Day Opening Logic

This protects against the confusing case where a user logs before a reminder time and the app later shows the bottle as due anyway.

Test case:

- Create a bottle with a daily reminder at 8:00 AM.
- Record an opening for the same calendar day at 7:00 AM.
- Move current time later than 8:00 AM, or test naturally after reminder time.

Verify:

- [ ] The bottle remains green/opened for the day.
- [ ] The ring shows `Done`.
- [ ] Today does not show orange `Due 8 AM` after the same-day opening exists.
- [ ] All Done banner respects same-calendar-day openings.
- [ ] Record Multiple does not preselect bottles already opened on the same calendar day.

## Bottles Tab Readability

Verify:

- [ ] Bottles tab section headers are readable.
- [ ] Bottle count text is readable.
- [ ] Bottle names are readable.
- [ ] Medication/details text remains readable.
- [ ] Reminder times show a bell icon.
- [ ] Reminder times are readable.
- [ ] Category chips such as `Rx` are readable.
- [ ] Search still filters by nickname, medication name, notes, and category.
- [ ] Tapping a bottle opens Details.
- [ ] Archived Bottles remains available if archived bottles exist.

## History Tab Readability

Verify:

- [ ] History header is readable.
- [ ] History subtitle says `Review when your bottles were opened.`
- [ ] History groups rows by `Today`, `Yesterday`, and older dates.
- [ ] Section headers use orange timeline accent color.
- [ ] History bottle names are readable.
- [ ] History event time is readable and uses primary text color.
- [ ] History date text is readable and gray.
- [ ] History dots use category colors.
- [ ] Manual events do not show redundant `Manual` text.
- [ ] Manual events do not show redundant `Bottle opened` text.
- [ ] Non-manual events still show their source when supported in the future.
- [ ] Swipe-to-delete works on History rows.
- [ ] Deleting a History row updates Today if it was the latest opening.

## Dark Mode

Verify:

- [ ] Today background and cards look clean in Dark Mode.
- [ ] Bottle names are clearly visible in Dark Mode.
- [ ] Ring states are distinguishable in Dark Mode.
- [ ] Category rails are visible in Dark Mode.
- [ ] Bottles tab text is readable in Dark Mode.
- [ ] History tab text is readable in Dark Mode.
- [ ] Delete confirmation remains readable in Dark Mode.

## Larger Text / Accessibility

Run a basic Dynamic Type pass.

Verify:

- [ ] Today bottle names do not disappear or become unreadable.
- [ ] Ring labels remain understandable.
- [ ] Reminder and status lines remain readable.
- [ ] Bottles tab rows remain usable.
- [ ] History rows remain usable.
- [ ] Logging options are still accessible.
- [ ] Important safety language is not truncated.

## Regression Checks

Verify:

- [ ] Add Bottle still works.
- [ ] Edit Bottle still works.
- [ ] Multiple reminders still display correctly.
- [ ] Reminder notifications still fire on a real iPhone.
- [ ] Opening history persists after force quit and relaunch.
- [ ] Bottle data persists after force quit and relaunch.
- [ ] Archive and restore still work.
- [ ] Website, Privacy, and Terms links still open.

## Sign-Off

- [ ] Simulator QA complete.
- [ ] Real iPhone QA complete.
- [ ] Dark Mode pass complete.
- [ ] Larger Text pass complete.
- [ ] No wording says TwistLog confirms medication was taken.
- [ ] No wording says water was consumed or medication was taken.
- [ ] Phase 1 UI polish is frozen.
