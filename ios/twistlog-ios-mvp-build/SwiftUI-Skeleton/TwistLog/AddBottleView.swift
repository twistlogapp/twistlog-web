import SwiftUI

struct AddBottleView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    private let bottle: Bottle?

    @State private var nickname: String
    @State private var medicationName: String
    @State private var notes: String
    @State private var minimumIntervalEnabled: Bool
    @State private var minimumIntervalMinutes: Int
    @State private var reminderEnabled: Bool
    @State private var reminders: [BottleReminder]

    init(bottle: Bottle? = nil) {
        self.bottle = bottle
        _nickname = State(initialValue: bottle?.nickname ?? "")
        _medicationName = State(initialValue: bottle?.medicationName ?? "")
        _notes = State(initialValue: bottle?.notes ?? "")
        _minimumIntervalEnabled = State(initialValue: bottle?.minimumIntervalEnabled ?? false)
        _minimumIntervalMinutes = State(initialValue: bottle?.minimumIntervalMinutes ?? 240)
        _reminderEnabled = State(initialValue: !(bottle?.reminders ?? []).isEmpty)
        _reminders = State(initialValue: bottle?.reminders ?? [Self.defaultReminder()])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Bottle") {
                    TextField("Bottle nickname", text: $nickname)
                    TextField("Medication name (optional)", text: $medicationName)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                Section {
                    Toggle("Reminder", isOn: $reminderEnabled)

                    if reminderEnabled {
                        ForEach($reminders) { $reminder in
                            ReminderEditorView(reminder: $reminder) {
                                removeReminder(reminder.id)
                            }
                        }

                        Button {
                            reminders.append(Self.defaultReminder(hour: nextReminderHour))
                        } label: {
                            Label("Add reminder time", systemImage: "plus.circle")
                        }
                        .disabled(reminders.count >= 6)

                        Text("Notification copy: Reminder: check your bottle.")
                            .font(.caption)
                            .foregroundStyle(TLTheme.gray)
                    }
                } header: {
                    Text("Reminder")
                } footer: {
                    Text("Reminders are local to this iPhone. TwistLog reminds you to check a bottle; it does not confirm medicine was taken.")
                }

                Section {
                    Toggle("Minimum time between openings", isOn: $minimumIntervalEnabled)

                    if minimumIntervalEnabled {
                        Stepper(value: $minimumIntervalMinutes, in: 15...1440, step: 15) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Warn if opened again within")
                                Text(intervalLabel)
                                    .font(.caption)
                                    .foregroundStyle(TLTheme.gray)
                            }
                        }
                    }
                } footer: {
                    Text("This only warns about recent bottle openings. TwistLog does not verify that medicine was taken.")
                }
            }
            .navigationTitle(bottle == nil ? "Add Bottle" : "Edit Bottle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(trimmedNickname.isEmpty || (reminderEnabled && reminderDays.isEmpty))
                }
            }
        }
    }

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var intervalLabel: String {
        if minimumIntervalMinutes < 60 {
            return "\(minimumIntervalMinutes) minutes"
        }

        let hours = minimumIntervalMinutes / 60
        let minutes = minimumIntervalMinutes % 60

        if minutes == 0 {
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }

        return "\(hours) hr \(minutes) min"
    }

    private var normalizedReminders: [BottleReminder] {
        guard reminderEnabled else { return [] }
        return reminders
            .map { reminder in
                var normalized = reminder
                normalized.isEnabled = true
                return normalized
            }
            .filter { !$0.days.isEmpty }
    }

    private var reminderDays: Set<Weekday> {
        Set(normalizedReminders.flatMap(\.days))
    }

    private var nextReminderHour: Int {
        min((reminders.last?.hour ?? 8) + 12, 23)
    }

    private func save() {
        if let bottle {
            store.updateBottle(
                id: bottle.id,
                nickname: trimmedNickname,
                medicationName: medicationName,
                notes: notes,
                minimumIntervalEnabled: minimumIntervalEnabled,
                minimumIntervalMinutes: minimumIntervalMinutes,
                reminders: normalizedReminders
            )
        } else {
            store.addBottle(
                nickname: trimmedNickname,
                medicationName: medicationName,
                notes: notes,
                minimumIntervalEnabled: minimumIntervalEnabled,
                minimumIntervalMinutes: minimumIntervalMinutes,
                reminders: normalizedReminders
            )
        }
    }

    private func removeReminder(_ id: UUID) {
        reminders.removeAll { $0.id == id }
        if reminders.isEmpty {
            reminders.append(Self.defaultReminder())
        }
    }

    private static func defaultReminder(hour: Int = 8) -> BottleReminder {
        BottleReminder(
            isEnabled: true,
            hour: hour,
            minute: 0,
            days: Set(Weekday.allCases)
        )
    }
}

private struct ReminderEditorView: View {
    @Binding var reminder: BottleReminder
    var onDelete: () -> Void

    private var reminderTime: Binding<Date> {
        Binding {
            Self.reminderDate(hour: reminder.hour, minute: reminder.minute)
        } set: { newValue in
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminder.hour = components.hour ?? 8
            reminder.minute = components.minute ?? 0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                DatePicker("Reminder time", selection: reminderTime, displayedComponents: .hourAndMinute)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "minus.circle.fill")
                }
                .accessibilityLabel("Remove reminder time")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Reminder days")
                    .font(.subheadline)
                    .foregroundStyle(TLTheme.gray)

                HStack(spacing: 6) {
                    ForEach(Weekday.allCases, id: \.self) { weekday in
                        Button {
                            toggleWeekday(weekday)
                        } label: {
                            Text(weekday.shortName)
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(reminder.days.contains(weekday) ? TLTheme.green : TLTheme.gray)
                        .accessibilityLabel("\(weekday.shortName) reminder")
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func toggleWeekday(_ weekday: Weekday) {
        if reminder.days.contains(weekday) {
            reminder.days.remove(weekday)
        } else {
            reminder.days.insert(weekday)
        }
    }

    private static func reminderDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
