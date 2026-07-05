import Foundation

struct Bottle: Identifiable, Hashable, Codable {
    var id = UUID()
    var nickname: String
    var medicationName: String? = nil
    var notes: String? = nil
    var createdAt = Date()
    var updatedAt = Date()
    var minimumIntervalEnabled = false
    var minimumIntervalMinutes: Int?
    var reminderEnabled = false
    var reminderHour = 8
    var reminderMinute = 0
    var reminderDays: Set<Weekday> = Set(Weekday.allCases)
    var reminders: [BottleReminder] = []
    var isArchived = false

    init(
        id: UUID = UUID(),
        nickname: String,
        medicationName: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        minimumIntervalEnabled: Bool = false,
        minimumIntervalMinutes: Int? = nil,
        reminderEnabled: Bool = false,
        reminderHour: Int = 8,
        reminderMinute: Int = 0,
        reminderDays: Set<Weekday> = Set(Weekday.allCases),
        reminders: [BottleReminder]? = nil,
        isArchived: Bool = false
    ) {
        self.id = id
        self.nickname = nickname
        self.medicationName = medicationName
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.minimumIntervalEnabled = minimumIntervalEnabled
        self.minimumIntervalMinutes = minimumIntervalMinutes
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.reminderDays = reminderDays
        self.reminders = reminders ?? Self.migratedReminders(
            enabled: reminderEnabled,
            hour: reminderHour,
            minute: reminderMinute,
            days: reminderDays
        )
        self.isArchived = isArchived
    }

    var enabledReminders: [BottleReminder] {
        reminders.filter { $0.isEnabled && !$0.days.isEmpty }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case medicationName
        case notes
        case createdAt
        case updatedAt
        case minimumIntervalEnabled
        case minimumIntervalMinutes
        case reminderEnabled
        case reminderHour
        case reminderMinute
        case reminderDays
        case reminders
        case isArchived
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        nickname = try container.decode(String.self, forKey: .nickname)
        medicationName = try container.decodeIfPresent(String.self, forKey: .medicationName)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        minimumIntervalEnabled = try container.decodeIfPresent(Bool.self, forKey: .minimumIntervalEnabled) ?? false
        minimumIntervalMinutes = try container.decodeIfPresent(Int.self, forKey: .minimumIntervalMinutes)
        reminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? false
        reminderHour = try container.decodeIfPresent(Int.self, forKey: .reminderHour) ?? 8
        reminderMinute = try container.decodeIfPresent(Int.self, forKey: .reminderMinute) ?? 0
        reminderDays = try container.decodeIfPresent(Set<Weekday>.self, forKey: .reminderDays) ?? Set(Weekday.allCases)
        reminders = try container.decodeIfPresent([BottleReminder].self, forKey: .reminders) ?? Self.migratedReminders(
            enabled: reminderEnabled,
            hour: reminderHour,
            minute: reminderMinute,
            days: reminderDays
        )
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(nickname, forKey: .nickname)
        try container.encodeIfPresent(medicationName, forKey: .medicationName)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(minimumIntervalEnabled, forKey: .minimumIntervalEnabled)
        try container.encodeIfPresent(minimumIntervalMinutes, forKey: .minimumIntervalMinutes)
        try container.encode(reminderEnabled, forKey: .reminderEnabled)
        try container.encode(reminderHour, forKey: .reminderHour)
        try container.encode(reminderMinute, forKey: .reminderMinute)
        try container.encode(reminderDays, forKey: .reminderDays)
        try container.encode(reminders, forKey: .reminders)
        try container.encode(isArchived, forKey: .isArchived)
    }

    private static func migratedReminders(
        enabled: Bool,
        hour: Int,
        minute: Int,
        days: Set<Weekday>
    ) -> [BottleReminder] {
        guard enabled else { return [] }
        return [
            BottleReminder(
                isEnabled: true,
                hour: hour,
                minute: minute,
                days: days
            )
        ]
    }
}

struct BottleReminder: Identifiable, Hashable, Codable {
    var id = UUID()
    var isEnabled = true
    var hour = 8
    var minute = 0
    var days: Set<Weekday> = Set(Weekday.allCases)

    var displayTime: String {
        let date = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}

struct OpeningEvent: Identifiable, Hashable, Codable {
    var id = UUID()
    var bottleId: UUID
    var openedAt: Date
    var source: OpeningSource
    var createdAt = Date()
    var editedAt: Date?
    var note: String?
}

enum OpeningSource: String, CaseIterable, Codable {
    case manual
    case nfc
    case sensor
    case imported
    case edited

    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .nfc: return "NFC"
        case .sensor: return "Sensor"
        case .imported: return "Imported"
        case .edited: return "Edited"
        }
    }
}

struct ReminderSchedule: Identifiable, Hashable, Codable {
    var id = UUID()
    var bottleId: UUID
    var enabled = false
    var hour = 8
    var minute = 0
    var daysOfWeek: Set<Weekday> = Set(Weekday.allCases)
    var repeatReminderEnabled = false
    var createdAt = Date()
    var updatedAt = Date()
}

enum Weekday: Int, CaseIterable, Codable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var twoLetterName: String {
        switch self {
        case .sunday: return "Su"
        case .monday: return "Mo"
        case .tuesday: return "Tu"
        case .wednesday: return "We"
        case .thursday: return "Th"
        case .friday: return "Fr"
        case .saturday: return "Sa"
        }
    }
}
