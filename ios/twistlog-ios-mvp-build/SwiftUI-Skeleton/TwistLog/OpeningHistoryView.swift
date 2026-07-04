import SwiftUI

struct OpeningHistoryView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            Group {
                if store.openingEvents.isEmpty {
                    EmptyStateView(
                        systemImage: "clock",
                        title: "No openings recorded yet",
                        message: "Tap Opened now from a bottle to start your opening history.",
                        buttonTitle: nil,
                        action: nil
                    )
                } else {
                    List {
                        ForEach(sortedEvents) { event in
                            OpeningRow(
                                event: event,
                                bottleName: store.bottles.first(where: { $0.id == event.bottleId })?.nickname
                            )
                        }
                    }
                }
            }
            .navigationTitle("Opening History")
        }
    }

    private var sortedEvents: [OpeningEvent] {
        store.openingEvents.sorted { $0.openedAt > $1.openedAt }
    }
}

struct OpeningRow: View {
    var event: OpeningEvent
    var bottleName: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OrangeEventDot()
                .padding(.top, 6)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                if let bottleName {
                    Text(bottleName)
                        .font(.headline)
                }

                Text("Bottle opened")
                    .font(.subheadline)

                Text("\(event.openedAt.formatted(date: .abbreviated, time: .shortened)) · \(event.source.displayName)")
                    .font(.caption)
                    .foregroundStyle(TLTheme.gray)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
