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
    private var isLoading = false

    init(
        bottles: [Bottle] = [],
        openingEvents: [OpeningEvent] = [],
        hasCompletedOnboarding: Bool = false,
        loadSavedState: Bool = true
    ) {
        self.bottles = bottles
        self.openingEvents = openingEvents
        self.hasCompletedOnboarding = hasCompletedOnboarding

        if loadSavedState {
            load()
        }
    }

    var activeBottles: [Bottle] {
        bottles
            .filter { !$0.isArchived }
            .sorted { $0.createdAt < $1.createdAt }
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

    func shouldWarnRecentOpening(for bottle: Bottle, now: Date = Date()) -> Bool {
        guard bottle.minimumIntervalEnabled,
              let minutes = bottle.minimumIntervalMinutes,
              let last = lastOpening(for: bottle)
        else { return false }

        let elapsed = now.timeIntervalSince(last.openedAt)
        return elapsed < Double(minutes * 60)
    }

    func recordOpening(for bottle: Bottle, source: OpeningSource = .manual, now: Date = Date()) {
        openingEvents.append(
            OpeningEvent(
                bottleId: bottle.id,
                openedAt: now,
                source: source
            )
        )
    }

    func addBottle(
        nickname: String,
        medicationName: String?,
        notes: String?,
        minimumIntervalEnabled: Bool,
        minimumIntervalMinutes: Int?,
        reminderEnabled: Bool,
        reminderHour: Int,
        reminderMinute: Int,
        reminderDays: Set<Weekday>
    ) {
        let bottle = Bottle(
            nickname: nickname,
            medicationName: medicationName?.nilIfBlank,
            notes: notes?.nilIfBlank,
            minimumIntervalEnabled: minimumIntervalEnabled,
            minimumIntervalMinutes: minimumIntervalEnabled ? minimumIntervalMinutes : nil,
            reminderEnabled: reminderEnabled,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute,
            reminderDays: reminderDays
        )

        bottles.append(bottle)
        scheduleReminderIfNeeded(for: bottle)
    }

    func updateBottle(
        id: UUID,
        nickname: String,
        medicationName: String?,
        notes: String?,
        minimumIntervalEnabled: Bool,
        minimumIntervalMinutes: Int?,
        reminderEnabled: Bool,
        reminderHour: Int,
        reminderMinute: Int,
        reminderDays: Set<Weekday>
    ) {
        guard let index = bottles.firstIndex(where: { $0.id == id }) else { return }

        bottles[index].nickname = nickname
        bottles[index].medicationName = medicationName?.nilIfBlank
        bottles[index].notes = notes?.nilIfBlank
        bottles[index].minimumIntervalEnabled = minimumIntervalEnabled
        bottles[index].minimumIntervalMinutes = minimumIntervalEnabled ? minimumIntervalMinutes : nil
        bottles[index].reminderEnabled = reminderEnabled
        bottles[index].reminderHour = reminderHour
        bottles[index].reminderMinute = reminderMinute
        bottles[index].reminderDays = reminderDays
        bottles[index].updatedAt = Date()

        scheduleReminderIfNeeded(for: bottles[index])
    }

    func archiveBottle(id: UUID) {
        guard let index = bottles.firstIndex(where: { $0.id == id }) else { return }
        bottles[index].isArchived = true
        bottles[index].updatedAt = Date()
        NotificationManager.cancelReminder(for: id)
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
            if bottle.reminderEnabled {
                await NotificationManager.rescheduleReminder(for: bottle)
            } else {
                NotificationManager.cancelReminder(for: bottle.id)
            }
        }
    }

    static let preview: AppStore = {
        let morning = Bottle(
            nickname: "Morning bottle",
            medicationName: "Vitamin D",
            minimumIntervalEnabled: true,
            minimumIntervalMinutes: 240,
            reminderEnabled: true,
            reminderHour: 8,
            reminderMinute: 0
        )
        let evening = Bottle(
            nickname: "Evening bottle",
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
            loadSavedState: false
        )
    }()
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
