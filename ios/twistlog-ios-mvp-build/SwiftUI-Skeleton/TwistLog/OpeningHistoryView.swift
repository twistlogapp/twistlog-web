import SwiftUI

struct OpeningHistoryView: View {
    @EnvironmentObject private var store: AppStore
    @State private var eventPendingDeletion: OpeningEvent?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HistoryHeader()
                        .listRowInsets(EdgeInsets(top: 18, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                    if store.openingEvents.isEmpty {
                        HistoryEmptyPrompt()
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }

                if !store.openingEvents.isEmpty {
                    ForEach(groupedEvents) { section in
                        Section {
                            ForEach(section.events) { event in
                                OpeningRow(
                                    event: event,
                                    bottleName: bottleName(for: event),
                                    style: .card,
                                    onDelete: {
                                        eventPendingDeletion = event
                                    }
                                )
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        } header: {
                            Text(section.title)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(TLTheme.green)
                                .textCase(nil)
                                .padding(.leading, 4)
                        }
                        .headerProminence(.increased)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(TLTheme.lightGray)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Delete opening record?", isPresented: deleteAlertBinding) {
                Button("Cancel", role: .cancel) {
                    eventPendingDeletion = nil
                }

                Button("Delete", role: .destructive) {
                    if let eventPendingDeletion {
                        store.deleteOpening(eventPendingDeletion)
                    }
                    eventPendingDeletion = nil
                }
            } message: {
                Text("This removes this opening from History and may update Today.")
            }
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { eventPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    eventPendingDeletion = nil
                }
            }
        )
    }

    private var sortedEvents: [OpeningEvent] {
        store.openingEvents.sorted { $0.openedAt > $1.openedAt }
    }

    private var groupedEvents: [OpeningHistorySection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sortedEvents) { event in
            calendar.startOfDay(for: event.openedAt)
        }

        return grouped.keys
            .sorted(by: >)
            .map { date in
                OpeningHistorySection(
                    date: date,
                    title: sectionTitle(for: date),
                    events: grouped[date] ?? []
                )
            }
    }

    private func sectionTitle(for date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        return date.formatted(date: .abbreviated, time: .omitted)
    }

    private func bottleName(for event: OpeningEvent) -> String? {
        store.bottles.first(where: { $0.id == event.bottleId })?.nickname
    }
}

private struct OpeningHistorySection: Identifiable {
    var date: Date
    var title: String
    var events: [OpeningEvent]

    var id: Date { date }
}

private struct HistoryHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Opening History")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(TLTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text("Review when your bottles were opened.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLTheme.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct HistoryEmptyPrompt: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(TLTheme.green)
                .accessibilityHidden(true)

            Text("No openings recorded yet")
                .font(.title3.weight(.bold))
                .foregroundStyle(TLTheme.text)

            Text("Tap Opened now from a bottle to start your opening history.")
                .font(.body)
                .foregroundStyle(TLTheme.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

enum OpeningRowStyle {
    case compact
    case card
}

struct OpeningRow: View {
    var event: OpeningEvent
    var bottleName: String?
    var style: OpeningRowStyle = .compact
    var onDelete: (() -> Void)?

    var body: some View {
        switch style {
        case .compact:
            compactRow
        case .card:
            cardRow
        }
    }

    private var compactRow: some View {
        HStack(alignment: .top, spacing: 12) {
            OrangeEventDot()
                .padding(.top, 6)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                if let bottleName {
                    Text(bottleName)
                        .font(.headline)
                }

                Text(event.openedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(TLTheme.gray)

                if event.source != .manual {
                    Text(event.source.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLTheme.green)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var cardRow: some View {
        HStack(alignment: .center, spacing: 12) {
            OrangeEventDot()
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(bottleName ?? "Bottle")
                    .font(.headline)
                    .foregroundStyle(TLTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if event.source != .manual {
                    Text(event.source.displayName)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .foregroundStyle(TLTheme.green)
                        .background(TLTheme.green.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text(event.openedAt.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLTheme.green)

                Text(event.openedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(TLTheme.gray)
            }

        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .contextMenu {
            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete opening", systemImage: "trash")
                }
            }
        }
    }
}
