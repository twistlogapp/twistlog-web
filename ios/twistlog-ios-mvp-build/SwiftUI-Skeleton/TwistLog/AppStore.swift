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

    private let storageKey = "twistlog.appState.v1"
    private let reminderScheduler: ReminderScheduling
    private var isLoading = false

    init(
        bottles: [Bottle] = [],
        openingEvents: [OpeningEvent] = [],
        hasCompletedOnboarding: Bool = false,
        loadSavedState: Bool = true,
        reminderScheduler: ReminderScheduling = NotificationManager.liveScheduler
    ) {
        self.bottles = bottles
        self.openingEvents = openingEvents
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.reminderScheduler = reminderScheduler

        if loadSavedState {
            load()
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

    func shouldWarnRecentOpening(for bottle: Bottle, now: Date = Date()) -> Bool {
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
        notes: String?,
        minimumIntervalEnabled: Bool,
        minimumIntervalMinutes: Int?,
        reminders: [BottleReminder]
    ) {
        let bottle = Bottle(
            nickname: nickname,
            category: category,
            medicationName: medicationName?.nilIfBlank,
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

    private func load() {
        isLoading = true
        defer { isLoading = false }

        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let state = try? JSONDecoder().decode(PersistedAppState.self, from: data)
        else { return }

        bottles = state.bottles
        openingEvents = state.openingEvents
        hasCompletedOnboarding = state.hasCompletedOnboarding
    }

    private func save() {
        guard !isLoading else { return }

        let state = PersistedAppState(
            bottles: bottles,
            openingEvents: openingEvents,
            hasCompletedOnboarding: hasCompletedOnboarding
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
        return AppStore(
            bottles: [morning, evening],
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
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
