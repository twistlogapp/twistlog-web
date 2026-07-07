import SwiftUI

struct AddBottleView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    private let bottle: Bottle?

    @State private var nickname: String
    @State private var category: BottleCategory
    @State private var medicationName: String
    @State private var notes: String
    @State private var minimumIntervalEnabled: Bool
    @State private var minimumIntervalMinutes: Int
    @State private var minimumIntervalUnit: IntervalUnit
    @State private var minimumIntervalValue: Int
    @State private var reminderEnabled: Bool
    @State private var reminders: [BottleReminder]

    init(bottle: Bottle? = nil) {
        self.bottle = bottle
        _nickname = State(initialValue: bottle?.nickname ?? "")
        _category = State(initialValue: bottle?.category ?? .prescription)
        _medicationName = State(initialValue: bottle?.medicationName ?? "")
        _notes = State(initialValue: bottle?.notes ?? "")
        _minimumIntervalEnabled = State(initialValue: bottle?.minimumIntervalEnabled ?? false)
        _minimumIntervalMinutes = State(initialValue: bottle?.minimumIntervalMinutes ?? 240)
        _minimumIntervalUnit = State(initialValue: Self.intervalUnit(for: bottle?.minimumIntervalMinutes ?? 240))
        _minimumIntervalValue = State(initialValue: Self.intervalValue(for: bottle?.minimumIntervalMinutes ?? 240))
        _reminderEnabled = State(initialValue: !(bottle?.reminders ?? []).isEmpty)
        _reminders = State(initialValue: bottle?.reminders ?? [Self.defaultReminder()])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Bottle") {
                    TextField("Bottle nickname", text: $nickname)
                    Picker("Type", selection: $category) {
                        ForEach(BottleCategory.allCases) { category in
                            Text(category.pickerTitle).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
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

                        Text("Notification copy: Time to check your bottle.")
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
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Quick presets")
                                .font(.subheadline)
                                .foregroundStyle(TLTheme.gray)

                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 64), spacing: 8)
                            ], spacing: 8) {
                                ForEach(IntervalPreset.allCases) { preset in
                                    Button {
                                        setInterval(minutes: preset.minutes)
                                    } label: {
                                        Text(preset.title)
                                            .font(.caption.weight(.semibold))
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 9)
                                            .foregroundStyle(minimumIntervalMinutes == preset.minutes ? TLTheme.selectedChipText : TLTheme.green)
                                            .background(minimumIntervalMinutes == preset.minutes ? TLTheme.green : TLTheme.green.opacity(0.14))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Picker("Period frequency", selection: $minimumIntervalUnit) {
                                ForEach(IntervalUnit.allCases) { unit in
                                    Text(unit.title).tag(unit)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: minimumIntervalUnit) { _ in
                                minimumIntervalValue = min(max(minimumIntervalValue, 1), minimumIntervalUnit.maximumValue)
                                syncMinimumIntervalMinutes()
                            }

                            Stepper(value: $minimumIntervalValue, in: 1...minimumIntervalUnit.maximumValue, step: 1) {
                                Text(intervalLabel)
                            }
                            .onChange(of: minimumIntervalValue) { _ in
                                syncMinimumIntervalMinutes()
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
        minimumIntervalUnit.label(for: minimumIntervalValue)
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
                category: category,
                medicationName: medicationName,
                notes: notes,
                minimumIntervalEnabled: minimumIntervalEnabled,
                minimumIntervalMinutes: normalizedMinimumIntervalMinutes,
                reminders: normalizedReminders
            )
        } else {
            store.addBottle(
                nickname: trimmedNickname,
                category: category,
                medicationName: medicationName,
                notes: notes,
                minimumIntervalEnabled: minimumIntervalEnabled,
                minimumIntervalMinutes: normalizedMinimumIntervalMinutes,
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

    private var normalizedMinimumIntervalMinutes: Int? {
        minimumIntervalEnabled ? minimumIntervalMinutes : nil
    }

    private func setInterval(minutes: Int) {
        minimumIntervalMinutes = minutes
        minimumIntervalUnit = Self.intervalUnit(for: minutes)
        minimumIntervalValue = Self.intervalValue(for: minutes)
    }

    private func syncMinimumIntervalMinutes() {
        minimumIntervalMinutes = minimumIntervalValue * minimumIntervalUnit.minuteMultiplier
    }

    private static func intervalUnit(for minutes: Int) -> IntervalUnit {
        if minutes % IntervalUnit.weeks.minuteMultiplier == 0 {
            return .weeks
        }

        if minutes % IntervalUnit.days.minuteMultiplier == 0 {
            return .days
        }

        if minutes % IntervalUnit.hours.minuteMultiplier == 0 {
            return .hours
        }

        return .minutes
    }

    private static func intervalValue(for minutes: Int) -> Int {
        let unit = intervalUnit(for: minutes)
        return max(1, minutes / unit.minuteMultiplier)
    }
}

private enum IntervalUnit: String, CaseIterable, Identifiable {
    case minutes
    case hours
    case days
    case weeks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .minutes: return "Min"
        case .hours: return "Hours"
        case .days: return "Days"
        case .weeks: return "Weeks"
        }
    }

    var singularTitle: String {
        switch self {
        case .minutes: return "minute"
        case .hours: return "hour"
        case .days: return "day"
        case .weeks: return "week"
        }
    }

    func label(for value: Int) -> String {
        let suffix = value == 1 ? singularTitle : "\(singularTitle)s"
        return "\(value) \(suffix)"
    }

    var minuteMultiplier: Int {
        switch self {
        case .minutes: return 1
        case .hours: return 60
        case .days: return 1440
        case .weeks: return 10080
        }
    }

    var maximumValue: Int {
        switch self {
        case .minutes: return 180
        case .hours: return 72
        case .days: return 30
        case .weeks: return 12
        }
    }
}

private enum IntervalPreset: CaseIterable, Identifiable {
    case fourHours
    case eightHours
    case twelveHours
    case sixteenHours
    case twentyTwoHours
    case oneDay
    case oneWeek

    var id: String { title }

    var title: String {
        switch self {
        case .fourHours: return "4h"
        case .eightHours: return "8h"
        case .twelveHours: return "12h"
        case .sixteenHours: return "16h"
        case .twentyTwoHours: return "22h"
        case .oneDay: return "1d"
        case .oneWeek: return "1w"
        }
    }

    var minutes: Int {
        switch self {
        case .fourHours: return 240
        case .eightHours: return 480
        case .twelveHours: return 720
        case .sixteenHours: return 960
        case .twentyTwoHours: return 1320
        case .oneDay: return 1440
        case .oneWeek: return 10080
        }
    }
}

private struct ReminderEditorView: View {
    @Binding var reminder: BottleReminder
    @State private var reminderTime: Date
    var onDelete: () -> Void

    init(reminder: Binding<BottleReminder>, onDelete: @escaping () -> Void) {
        self._reminder = reminder
        self._reminderTime = State(initialValue: Self.reminderDate(
            hour: reminder.wrappedValue.hour,
            minute: reminder.wrappedValue.minute
        ))
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .onChange(of: reminderTime) { newValue in
                        updateReminderTime(newValue)
                    }

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
                            Text(weekday.twoLetterName)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(width: 38, height: 38)
                                .foregroundStyle(reminder.days.contains(weekday) ? TLTheme.selectedChipText : TLTheme.green)
                                .background(reminder.days.contains(weekday) ? TLTheme.green : TLTheme.green.opacity(0.14))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(weekday.shortName) reminder")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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

    private func updateReminderTime(_ date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        reminder.hour = components.hour ?? 8
        reminder.minute = components.minute ?? 0
    }

    private static func reminderDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
