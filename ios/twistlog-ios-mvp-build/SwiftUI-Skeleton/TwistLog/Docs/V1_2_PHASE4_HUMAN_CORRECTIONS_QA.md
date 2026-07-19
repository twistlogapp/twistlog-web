# TwistLog V1.2 Phase 4 QA - Human Corrections

Use this checklist to verify editing an opening record.

Phase 4 goal: let users correct opening times without deleting and re-logging, while keeping wording safe and opening-based.

## Scope

- Edit opening time from History.
- Edit opening time from Bottle Details history.
- Prevent future opening times.
- Update Today status and History insight counts after edit.
- Keep delete opening available.

## History Edit Flow

- [ ] Open History with at least one opening record.
- [ ] Swipe right on a History row and confirm `Edit` appears.
- [ ] Tap `Edit`.
- [ ] Confirm sheet title says `Edit opening time`.
- [ ] Confirm DatePicker label says `Opening time`.
- [ ] Confirm footer says TwistLog records the correction based on user input.
- [ ] Change the opening time to another valid past time.
- [ ] Tap `Update`.
- [ ] Confirm the History row shows the updated time/date.
- [ ] Confirm the row remains under the correct date section if date changed.
- [ ] Long-press a History row and confirm `Edit opening time` appears in the context menu.

## Bottle Details Edit Flow

- [ ] Open a bottle Details screen.
- [ ] In `Last opening`, swipe right or long-press the opening row and edit the time.
- [ ] Confirm `Last opening` updates after saving.
- [ ] In `Recent openings`, swipe right or long-press an opening row and edit the time.
- [ ] Confirm the edited row updates after saving.
- [ ] Confirm delete still works from Recent openings.

## Future-Time Guard

- [ ] Open `Edit opening time`.
- [ ] Try to select a future date/time.
- [ ] Confirm the picker prevents future selection.
- [ ] If a future value somehow reaches save, confirm TwistLog clamps it to now.

## Today / Insight Updates

- [ ] Edit an opening from today to yesterday.
- [ ] Confirm Today status updates if that was the only opening today.
- [ ] Confirm History section grouping updates.
- [ ] Confirm Daily openings chart count updates.
- [ ] Confirm category chips still show correct counts.
- [ ] Edit an opening from yesterday to today.
- [ ] Confirm Today status updates to opened/done for that bottle.

## Safe Wording

Confirm the edit flow does not use:

- [ ] `taken`
- [ ] `dose taken`
- [ ] `missed`
- [ ] `adherence`

Acceptable wording:

- `Edit opening time`
- `Opening time`
- `Update`
- `opening record`
- `correction based on your input`

## Sign-Off

- [ ] Simulator edit QA complete.
- [ ] Real iPhone edit QA complete.
- [ ] Dark Mode edit sheet readable.
- [ ] Larger Text edit sheet usable.
- [ ] Delete opening still works.
