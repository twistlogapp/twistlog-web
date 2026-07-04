import Combine
import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published var bottles: [Bottle]
    @Published var openingEvents: [OpeningEvent]
    @Published var hasCompletedOnboarding: Bool

    init(
        bottles: [Bottle] = [],
        openingEvents: [OpeningEvent] = [],
        hasCompletedOnboarding: Bool = false
    ) {
        self.bottles = bottles
        self.openingEvents = openingEvents
        self.hasCompletedOnboarding = hasCompletedOnboarding
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

    func addBottle(nickname: String, medicationName: String?, notes: String?) {
        bottles.append(
            Bottle(
                nickname: nickname,
                medicationName: medicationName?.nilIfBlank,
                notes: notes?.nilIfBlank
            )
        )
    }

    static let preview: AppStore = {
        let morning = Bottle(
            nickname: "Morning bottle",
            medicationName: "Vitamin D",
            minimumIntervalEnabled: true,
            minimumIntervalMinutes: 240
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
            hasCompletedOnboarding: true
        )
    }()
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

