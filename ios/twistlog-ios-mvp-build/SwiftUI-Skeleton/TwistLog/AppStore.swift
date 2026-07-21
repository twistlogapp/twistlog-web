import Combine
import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published var bottles: [Bottle] {
        didSet { save() }
    }
    @Published var openingEvents: [OpeningEvent] {
        didSet { save() }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { save() }
    }
    @Published var displayName: String {
        didSet { save() }
    }
    @Published var lastSeenWhatsNewVersion: String {
        didSet { save() }
    }

    private let storageKey = "twistlog.appState.v1"
    private let reminderScheduler: ReminderScheduling
    private var isLoading = false

    init(
        bottles: [Bottle] = [],
        openingEvents: [OpeningEvent] = [],
        hasCompletedOnboarding: Bool = false,
        displayName: String = "",
        lastSeenWhatsNewVersion: String = "",
        loadSavedState: Bool = true,
        reminderScheduler: ReminderScheduling = NotificationManager.liveScheduler
    ) {
        self.bottles = bottles
        self.openingEvents = openingEvents
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.displayName = displayName
        self.lastSeenWhatsNewVersion = lastSeenWhatsNewVersion
        self.reminderScheduler = reminderScheduler

        if loadSavedState {
            load()
            refreshScheduledReminders()
        }
    }

    var activeBottles: [Bottle] {
        bottles
            .filter { !$0.isArchived }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var archivedBottles: [Bottle] {
        bottles
            .filter(\.isArchived)
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func bottle(id: UUID) -> Bottle? {
        bottles.first { $0.id == id }
    }

    func lastOpening(for bottle: Bottle) -> OpeningEvent? {
        openingEvents
            .filter { $0.bottleId == bottle.id }
            .sorted { $0.openedAt > $1.openedAt }
            .first
    }

    func recentOpenings(for bottle: Bottle, limit: Int = 5) -> [OpeningEvent] {
        Array(
            openingEvents
                .filter { $0.bottleId == bottle.id }
                .sorted { $0.openedAt > $1.openedAt }
                .prefix(limit)
        )
    }

    func openingForMedicationDay(containing date: Date = Date(), for bottle: Bottle) -> OpeningEvent? {
        let interval = bottle.medicationDayInterval(containing: date)
        return openingEvents
            .filter { event in
                event.bottleId == bottle.id && interval.contains(event.openedAt)
            }
            .sorted { $0.openedAt > $1.openedAt }
            .first
    }

    func hasOpeningForMedicationDay(containing date: Date = Date(), for bottle: Bottle) -> Bool {
        openingForMedicationDay(containing: date, for: bottle) != nil
    }

    func openingForCalendarDay(containing date: Date = Date(), for bottle: Bottle) -> OpeningEvent? {
        openingEvents
            .filter { event in
                event.bottleId == bottle.id && Calendar.current.isDate(event.openedAt, inSameDayAs: date)
            }
            .sorted { $0.openedAt > $1.openedAt }
            .first
    }

    func hasOpeningForCalendarDay(containing date: Date = Date(), for bottle: Bottle) -> Bool {
        openingForCalendarDay(containing: date, for: bottle) != nil
    }

    func reminderDatesForCalendarDay(containing date: Date = Date(), for bottle: Bottle) -> [Date] {
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: date)
        guard let weekday = Weekday(rawValue: todayWeekday) else { return [] }

        return bottle.enabledReminders
            .filter { $0.days.contains(weekday) }
            .compactMap { reminder in
                calendar.date(
                    bySettingHour: reminder.hour,
                    minute: reminder.minute,
                    second: 0,
                    of: date
                )
            }
            .sorted()
    }

    func openingCountForCalendarDay(containing date: Date = Date(), for bottle: Bottle) -> Int {
        openingEvents
            .filter { event in
                event.bottleId == bottle.id && Calendar.current.isDate(event.openedAt, inSameDayAs: date)
            }
            .count
    }

    func nextRequiredReminderDate(containing date: Date = Date(), for bottle: Bottle) -> Date? {
        let todaysReminders = reminderDatesForCalendarDay(containing: date, for: bottle)
        guard !todaysReminders.isEmpty else { return nil }

        let satisfiedCount = min(openingCountForCalendarDay(containing: date, for: bottle), todaysReminders.count)
        guard satisfiedCount < todaysReminders.count else { return nil }
        return todaysReminders[satisfiedCount]
    }

    func isBottleCompleteForCalendarDay(containing date: Date = Date(), for bottle: Bottle) -> Bool {
        let todaysReminders = reminderDatesForCalendarDay(containing: date, for: bottle)

        if todaysReminders.isEmpty {
            if bottle.enabledReminders.isEmpty {
                return hasOpeningForCalendarDay(containing: date, for: bottle)
            }

            return true
        }

        return openingCountForCalendarDay(containing: date, for: bottle) >= todaysReminders.count
    }

    func shouldWarnRecentOpening(for bottle: Bottle, now: Date = Date()) -> Bool {
        if let nextRequired = nextRequiredReminderDate(containing: now, for: bottle),
           nextRequired <= now {
            return false
        }

        guard bottle.minimumIntervalEnabled,
              let minutes = bottle.minimumIntervalMinutes,
              let last = lastOpening(for: bottle)
        else { return false }

        let elapsed = now.timeIntervalSince(last.openedAt)
        return elapsed >= 0 && elapsed < Double(minutes * 60)
    }

    @discardableResult
    func recordOpening(for bottle: Bottle, source: OpeningSource = .manual, now: Date = Date()) -> OpeningEvent {
        let event = OpeningEvent(
            bottleId: bottle.id,
            openedAt: min(now, Date()),
            source: source
        )
        openingEvents.append(event)
        return event
    }

    func addBottle(
        nickname: String,
        category: BottleCategory = .prescription,
        medicationName: String?,
        amountText: String? = nil,
        timingNote: String? = nil,
        notes: String?,
        minimumIntervalEnabled: Bool,
        minimumIntervalMinutes: Int?,
        reminderEnabled: Bool,
        reminderHour: Int,
        reminderMinute: Int,
        reminderDays: Set<Weekday>
    ) {
        addBottle(
            nickname: nickname,
            category: category,
            medicationName: medicationName,
            amountText: amountText,
            timingNote: timingNote,
            notes: notes,
            minimumIntervalEnabled: minimumIntervalEnabled,
            minimumIntervalMinutes: minimumIntervalMinutes,
            reminders: Self.reminders(
                enabled: reminderEnabled,
                hour: reminderHour,
                minute: reminderMinute,
                days: reminderDays
            )
        )
    }

    func addBottle(
        nickname: String,
        category: BottleCategory = .prescription,
        medicationName: String?,
        amountText: String? = nil,
        timingNote: String? = nil,
        notes: String?,
        minimumIntervalEnabled: Bool,
        minimumIntervalMinutes: Int?,
        reminders: [BottleReminder]
    ) {
        let bottle = Bottle(
            nickname: nickname,
            category: category,
            medicationName: medicationName?.nilIfBlank,
            amountText: amountText?.nilIfBlank,
            timingNote: timingNote?.nilIfBlank,
            notes: notes?.nilIfBlank,
            minimumIntervalEnabled: minimumIntervalEnabled,
            minimumIntervalMinutes: minimumIntervalEnabled ? minimumIntervalMinutes : nil,
            reminderEnabled: Self.hasActiveReminder(reminders),
            reminderHour: reminders.first?.hour ?? 8,
            reminderMinute: reminders.first?.minute ?? 0,
            reminderDays: reminders.first?.days ?? Set(Weekday.allCases),
            reminders: reminders
        )

        bottles.append(bottle)
        scheduleReminderIfNeeded(for: bottle)
    }

    func updateBottle(
        id: UUID,
        nickname: String,
        category: BottleCategory = .prescription,
        medicationName: String?,
        amountText: String? = nil,
        timingNote: String? = nil,
        notes: String?,
        minimumIntervalEnabled: Bool,
        minimumIntervalMinutes: Int?,
        reminderEnabled: Bool,
        reminderHour: Int,
        reminderMinute: Int,
        reminderDays: Set<Weekday>
    ) {
        updateBottle(
            id: id,
            nickname: nickname,
            category: category,
            medicationName: medicationName,
            amountText: amountText,
            timingNote: timingNote,
            notes: notes,
            minimumIntervalEnabled: minimumIntervalEnabled,
            minimumIntervalMinutes: minimumIntervalMinutes,
            reminders: Self.reminders(
                enabled: reminderEnabled,
                hour: reminderHour,
                minute: reminderMinute,
                days: reminderDays
            )
        )
    }

    func updateBottle(
        id: UUID,
        nickname: String,
        category: BottleCategory = .prescription,
        medicationName: String?,
        amountText: String? = nil,
        timingNote: String? = nil,
        notes: String?,
        minimumIntervalEnabled: Bool,
        minimumIntervalMinutes: Int?,
        reminders: [BottleReminder]
    ) {
        guard let index = bottles.firstIndex(where: { $0.id == id }) else { return }

        var updatedBottle = bottles[index]
        updatedBottle.nickname = nickname
        updatedBottle.category = category
        updatedBottle.medicationName = medicationName?.nilIfBlank
        updatedBottle.amountText = amountText?.nilIfBlank
        updatedBottle.timingNote = timingNote?.nilIfBlank
        updatedBottle.notes = notes?.nilIfBlank
        updatedBottle.minimumIntervalEnabled = minimumIntervalEnabled
        updatedBottle.minimumIntervalMinutes = minimumIntervalEnabled ? minimumIntervalMinutes : nil
        updatedBottle.reminderEnabled = Self.hasActiveReminder(reminders)
        updatedBottle.reminderHour = reminders.first?.hour ?? 8
        updatedBottle.reminderMinute = reminders.first?.minute ?? 0
        updatedBottle.reminderDays = reminders.first?.days ?? Set(Weekday.allCases)
        updatedBottle.reminders = reminders
        updatedBottle.updatedAt = Date()

        var updatedBottles = bottles
        updatedBottles[index] = updatedBottle
        bottles = updatedBottles

        scheduleReminderIfNeeded(for: updatedBottle)
    }

    func archiveBottle(id: UUID) {
        guard let index = bottles.firstIndex(where: { $0.id == id }) else { return }

        var updatedBottle = bottles[index]
        updatedBottle.isArchived = true
        updatedBottle.updatedAt = Date()

        var updatedBottles = bottles
        updatedBottles[index] = updatedBottle
        bottles = updatedBottles

        reminderScheduler.cancelReminder(for: id)
    }

    func restoreBottle(id: UUID) {
        guard let index = bottles.firstIndex(where: { $0.id == id }) else { return }

        var updatedBottle = bottles[index]
        updatedBottle.isArchived = false
        updatedBottle.updatedAt = Date()

        var updatedBottles = bottles
        updatedBottles[index] = updatedBottle
        bottles = updatedBottles

        scheduleReminderIfNeeded(for: updatedBottle)
    }

    func deleteOpening(_ event: OpeningEvent) {
        openingEvents.removeAll { $0.id == event.id }
    }

    func updateOpening(_ event: OpeningEvent, openedAt: Date) {
        guard let index = openingEvents.firstIndex(where: { $0.id == event.id }) else { return }

        var updatedEvent = openingEvents[index]
        updatedEvent.openedAt = min(openedAt, Date())
        updatedEvent.editedAt = Date()

        var updatedEvents = openingEvents
        updatedEvents[index] = updatedEvent
        openingEvents = updatedEvents
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }

        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let state = try? JSONDecoder().decode(PersistedAppState.self, from: data)
        else { return }

        bottles = state.bottles
        openingEvents = state.openingEvents
        hasCompletedOnboarding = state.hasCompletedOnboarding
        displayName = state.displayName
        lastSeenWhatsNewVersion = state.lastSeenWhatsNewVersion
    }

    private func save() {
        guard !isLoading else { return }

        let state = PersistedAppState(
            bottles: bottles,
            openingEvents: openingEvents,
            hasCompletedOnboarding: hasCompletedOnboarding,
            displayName: displayName,
            lastSeenWhatsNewVersion: lastSeenWhatsNewVersion
        )

        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func scheduleReminderIfNeeded(for bottle: Bottle) {
        Task {
            if !bottle.isArchived, !bottle.enabledReminders.isEmpty {
                await reminderScheduler.rescheduleReminder(for: bottle)
            } else {
                reminderScheduler.cancelReminder(for: bottle.id)
            }
        }
    }

    private func refreshScheduledReminders() {
        let bottlesToRefresh = bottles.filter { !$0.isArchived && !$0.enabledReminders.isEmpty }
        guard !bottlesToRefresh.isEmpty else { return }

        Task {
            for bottle in bottlesToRefresh {
                await reminderScheduler.rescheduleReminder(for: bottle)
            }
        }
    }

    func shouldShowWhatsNew(version: String) -> Bool {
        hasCompletedOnboarding && lastSeenWhatsNewVersion != version
    }

    func markWhatsNewSeen(version: String) {
        lastSeenWhatsNewVersion = version
    }

    static let preview: AppStore = {
        let morning = Bottle(
            nickname: "Morning bottle",
            category: .prescription,
            medicationName: "Vitamin D",
            minimumIntervalEnabled: true,
            minimumIntervalMinutes: 240,
            reminders: [
                BottleReminder(hour: 8, minute: 0),
                BottleReminder(hour: 20, minute: 0)
            ]
        )
        let evening = Bottle(
            nickname: "Evening bottle",
            category: .supplement,
            medicationName: nil
        )
        let water = Bottle(
            nickname: "School water bottle",
            category: .water,
            medicationName: nil,
            reminders: [
                BottleReminder(hour: 15, minute: 30)
            ]
        )
        return AppStore(
            bottles: [morning, evening, water],
            openingEvents: [
                OpeningEvent(
                    bottleId: morning.id,
                    openedAt: Date().addingTimeInterval(-60 * 42),
                    source: .manual
                ),
                OpeningEvent(
                    bottleId: evening.id,
                    openedAt: Date().addingTimeInterval(-60 * 60 * 14),
                    source: .manual
                )
            ],
            hasCompletedOnboarding: true,
            lastSeenWhatsNewVersion: WhatsNewContent.version,
            loadSavedState: false,
            reminderScheduler: NoOpReminderScheduler()
        )
    }()

    private static func reminders(
        enabled: Bool,
        hour: Int,
        minute: Int,
        days: Set<Weekday>
    ) -> [BottleReminder] {
        guard enabled else { return [] }
        return [BottleReminder(isEnabled: true, hour: hour, minute: minute, days: days)]
    }

    private static func hasActiveReminder(_ reminders: [BottleReminder]) -> Bool {
        reminders.contains { $0.isEnabled && !$0.days.isEmpty }
    }
}

private struct PersistedAppState: Codable {
    var bottles: [Bottle]
    var openingEvents: [OpeningEvent]
    var hasCompletedOnboarding: Bool
    var displayName: String = ""
    var lastSeenWhatsNewVersion: String = ""

    enum CodingKeys: String, CodingKey {
        case bottles
        case openingEvents
        case hasCompletedOnboarding
        case displayName
        case lastSeenWhatsNewVersion
    }

    init(
        bottles: [Bottle],
        openingEvents: [OpeningEvent],
        hasCompletedOnboarding: Bool,
        displayName: String = "",
        lastSeenWhatsNewVersion: String = ""
    ) {
        self.bottles = bottles
        self.openingEvents = openingEvents
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.displayName = displayName
        self.lastSeenWhatsNewVersion = lastSeenWhatsNewVersion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bottles = try container.decode([Bottle].self, forKey: .bottles)
        openingEvents = try container.decode([OpeningEvent].self, forKey: .openingEvents)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        lastSeenWhatsNewVersion = try container.decodeIfPresent(String.self, forKey: .lastSeenWhatsNewVersion) ?? ""
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
