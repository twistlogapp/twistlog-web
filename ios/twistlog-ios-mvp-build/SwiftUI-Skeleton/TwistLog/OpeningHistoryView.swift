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
                    } else {
                        LastSevenDaysOpeningChart(
                            events: store.openingEvents,
                            bottles: store.bottles
                        )
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 14, trailing: 16))
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
                                    category: bottleCategory(for: event),
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
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(TLTheme.orange)
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

    private func bottleCategory(for event: OpeningEvent) -> BottleCategory? {
        store.bottles.first(where: { $0.id == event.bottleId })?.category
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

private struct LastSevenDaysOpeningChart: View {
    var events: [OpeningEvent]
    var bottles: [Bottle]

    private var days: [DailyOpeningCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return nil
            }

            let count = events.filter { event in
                calendar.isDate(event.openedAt, inSameDayAs: date)
            }.count

            return DailyOpeningCount(date: date, count: count)
        }
    }

    private var totalOpenings: Int {
        days.reduce(0) { $0 + $1.count }
    }

    private var categoryCounts: [CategoryOpeningCount] {
        let recentDates = Set(days.map(\.date))
        let calendar = Calendar.current
        let bottleCategories = Dictionary(uniqueKeysWithValues: bottles.map { ($0.id, $0.category) })
        let counts = Dictionary(grouping: events) { event -> BottleCategory in
            bottleCategories[event.bottleId] ?? .other
        }

        return BottleCategory.allCases.map { category in
            let count = (counts[category] ?? []).filter { event in
                recentDates.contains(calendar.startOfDay(for: event.openedAt))
            }.count
            return CategoryOpeningCount(category: category, count: count)
        }
    }

    private var maxCount: Int {
        max(days.map(\.count).max() ?? 0, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily openings")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(TLTheme.text)

                    Text("Last 7 days")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TLTheme.gray)
                }

                Spacer()

                Text("\(totalOpenings) recorded")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLTheme.orange)
            }

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(days) { day in
                    VStack(spacing: 7) {
                        Text("\(day.count)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(day.count > 0 ? TLTheme.text : TLTheme.gray)
                            .monospacedDigit()

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(day.count > 0 ? TLTheme.orange : TLTheme.categoryGray.opacity(0.18))
                            .frame(height: barHeight(for: day.count))
                            .frame(maxWidth: .infinity)

                        Text(day.weekdayLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(day.isToday ? TLTheme.orange : TLTheme.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.accessibilityDate), \(day.count) opening records")
                }
            }
            .frame(height: 126, alignment: .bottom)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 74), spacing: 8)
            ], alignment: .leading, spacing: 8) {
                ForEach(categoryCounts) { item in
                    CategoryCountChip(item: item)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func barHeight(for count: Int) -> CGFloat {
        guard count > 0 else { return 8 }
        return 18 + CGFloat(count) / CGFloat(maxCount) * 54
    }
}

private struct CategoryOpeningCount: Identifiable {
    var category: BottleCategory
    var count: Int

    var id: BottleCategory { category }
}

private struct CategoryCountChip: View {
    var item: CategoryOpeningCount

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(item.category.accentColor)
                .frame(width: 7, height: 7)
                .accessibilityHidden(true)

            Text(item.category.pickerTitle)
                .font(.caption.weight(.bold))

            Text("\(item.count)")
                .font(.caption.weight(.bold))
                .monospacedDigit()
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .foregroundStyle(item.category.accentColor)
        .background(item.category.accentColor.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.category.title), \(item.count) opening records")
    }
}

private struct DailyOpeningCount: Identifiable {
    var date: Date
    var count: Int

    var id: Date { date }

    var weekdayLabel: String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var accessibilityDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}

enum OpeningRowStyle {
    case compact
    case card
}

struct OpeningRow: View {
    var event: OpeningEvent
    var bottleName: String?
    var category: BottleCategory? = nil
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
            CategoryEventDot(category: category)
                .padding(.top, 6)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                if let bottleName {
                    Text(bottleName)
                        .font(.title3.weight(.bold))
                }

                Text(event.openedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(TLTheme.gray)

                if event.source != .manual {
                    Text(event.source.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TLTheme.green)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var cardRow: some View {
        HStack(alignment: .center, spacing: 12) {
            CategoryEventDot(category: category)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(bottleName ?? "Bottle")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(TLTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if event.source != .manual {
                    Text(event.source.displayName)
                        .font(.subheadline.weight(.semibold))
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
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(TLTheme.text)

                Text(event.openedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
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

private struct CategoryEventDot: View {
    var category: BottleCategory?

    var body: some View {
        Circle()
            .fill(category?.accentColor ?? TLTheme.orange)
            .frame(width: 9, height: 9)
            .accessibilityLabel("Opening record")
            .accessibilityAddTraits(.isImage)
    }
}
