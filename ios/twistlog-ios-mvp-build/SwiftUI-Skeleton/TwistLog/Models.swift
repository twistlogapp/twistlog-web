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
    var isArchived = false
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
}
