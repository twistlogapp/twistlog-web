import SwiftUI

struct OpeningHistoryView: View {
    @EnvironmentObject private var store: AppStore
    @State private var eventPendingDeletion: OpeningEvent?
    @State private var eventPendingEdit: OpeningEvent?
    @State private var historyExportURL: URL?

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
                                    onEdit: {
                                        eventPendingEdit = event
                                    },
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !store.openingEvents.isEmpty, let historyExportURL {
                        ShareLink(item: historyExportURL) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Share opening history")
                    }
                }
            }
            .onAppear {
                refreshHistoryExportURL()
            }
            .alert("Delete opening record?", isPresented: deleteAlertBinding) {
                Button("Cancel", role: .cancel) {
                    eventPendingDeletion = nil
                }

                Button("Delete", role: .destructive) {
                    if let eventPendingDeletion {
                        store.deleteOpening(eventPendingDeletion)
                        refreshHistoryExportURL()
                    }
                    eventPendingDeletion = nil
                }
            } message: {
                Text("This removes this opening from History and may update Today.")
            }
            .sheet(item: $eventPendingEdit) { event in
                EditOpeningTimeSheet(event: event) { updatedDate in
                    store.updateOpening(event, openedAt: updatedDate)
                    refreshHistoryExportURL()
                    eventPendingEdit = nil
                }
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

    private func refreshHistoryExportURL() {
        historyExportURL = OpeningHistoryCSVExporter.makeFile(
            events: sortedEvents,
            bottles: store.bottles
        )
    }
}

private enum OpeningHistoryCSVExporter {
    static func makeFile(events: [OpeningEvent], bottles: [Bottle]) -> URL? {
        guard !events.isEmpty else { return nil }

        let csv = makeCSV(events: events, bottles: bottles)
        let filenameDateFormatter = DateFormatter()
        filenameDateFormatter.dateFormat = "yyyy-MM-dd-HHmm"
        let filenameDate = filenameDateFormatter.string(from: Date())

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("TwistLog-Opening-History-\(filenameDate)")
            .appendingPathExtension("csv")

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }

    private static func makeCSV(events: [OpeningEvent], bottles: [Bottle]) -> String {
        let bottleById = Dictionary(uniqueKeysWithValues: bottles.map { ($0.id, $0) })
        let rows = events.map { event in
            let bottle = bottleById[event.bottleId]
            return [
                bottle?.nickname ?? "Deleted bottle",
                bottle?.category.title ?? "Unknown",
                event.openedAt.formatted(date: .abbreviated, time: .shortened),
                event.source.displayName,
                event.note ?? ""
            ]
        }

        return ([["Bottle", "Category", "Opened At", "Source", "Note"]] + rows)
            .map { row in row.map { escapedField($0) }.joined(separator: ",") }
            .joined(separator: "\n")
    }

    private static func escapedField(_ field: String) -> String {
        "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
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

    @State private var selectedDate: Date?

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

    private var selectedDay: DailyOpeningCount {
        let calendar = Calendar.current
        let selectedStart = selectedDate.map { calendar.startOfDay(for: $0) }

        if let selectedStart,
           let selected = days.first(where: { calendar.isDate($0.date, inSameDayAs: selectedStart) }) {
            return selected
        }

        return days.last ?? DailyOpeningCount(date: calendar.startOfDay(for: Date()), count: 0)
    }

    private var selectedCategoryCounts: [CategoryOpeningCount] {
        categoryCounts(for: selectedDay.date)
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
                    let isSelected = Calendar.current.isDate(day.date, inSameDayAs: selectedDay.date)

                    VStack(spacing: 7) {
                        Text("\(day.count)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(isSelected ? TLTheme.orange : (day.count > 0 ? TLTheme.text : TLTheme.gray))
                            .monospacedDigit()

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(barColor(for: day, isSelected: isSelected))
                            .frame(height: barHeight(for: day.count))
                            .frame(maxWidth: .infinity)
                            .overlay {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(TLTheme.orange.opacity(0.55), lineWidth: 2)
                                }
                            }

                        Text(day.weekdayLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isSelected || day.isToday ? TLTheme.orange : TLTheme.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDate = day.date
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.accessibilityDate), \(day.count) opening records\(isSelected ? ", selected" : "")")
                }
            }
            .frame(height: 126, alignment: .bottom)

            SelectedDayOpeningSummary(day: selectedDay, categoryCounts: selectedCategoryCounts)

            VStack(alignment: .leading, spacing: 8) {
                Text("Last 7 days by category")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TLTheme.gray)

                HStack(spacing: 6) {
                    ForEach(categoryCounts) { item in
                        CategoryCountChip(item: item)
                    }
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

    private func barColor(for day: DailyOpeningCount, isSelected: Bool) -> Color {
        if day.count == 0 {
            return isSelected ? TLTheme.orange.opacity(0.2) : TLTheme.categoryGray.opacity(0.18)
        }

        return isSelected ? TLTheme.orange : TLTheme.orange.opacity(0.76)
    }

    private func categoryCounts(for date: Date) -> [CategoryOpeningCount] {
        let calendar = Calendar.current
        let bottleCategories = Dictionary(uniqueKeysWithValues: bottles.map { ($0.id, $0.category) })
        let eventsForDay = events.filter { event in
            calendar.isDate(event.openedAt, inSameDayAs: date)
        }
        let counts = Dictionary(grouping: eventsForDay) { event -> BottleCategory in
            bottleCategories[event.bottleId] ?? .other
        }

        return BottleCategory.allCases.map { category in
            CategoryOpeningCount(category: category, count: counts[category]?.count ?? 0)
        }
    }
}

private struct SelectedDayOpeningSummary: View {
    var day: DailyOpeningCount
    var categoryCounts: [CategoryOpeningCount]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.summaryTitle)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(TLTheme.text)

                    Text(day.summaryDate)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLTheme.gray)
                }

                Spacer()

                Text("\(day.count) \(day.count == 1 ? "opening" : "openings")")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TLTheme.orange)
                    .monospacedDigit()
            }

            HStack(spacing: 6) {
                ForEach(categoryCounts) { item in
                    CategoryCountChip(item: item)
                }
            }
        }
        .padding(12)
        .background(TLTheme.lightGray.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(day.summaryTitle), \(day.count) opening records")
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
        .padding(.horizontal, 7)
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

    var summaryTitle: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        return date.formatted(.dateTime.weekday(.wide))
    }

    var summaryDate: String {
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
    var onEdit: (() -> Void)?
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
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if let onEdit {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(TLTheme.green)
            }
        }
        .contextMenu {
            if let onEdit {
                Button {
                    onEdit()
                } label: {
                    Label("Edit opening time", systemImage: "pencil")
                }
            }
        }
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
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if let onEdit {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(TLTheme.green)
            }
        }
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
            if let onEdit {
                Button {
                    onEdit()
                } label: {
                    Label("Edit opening time", systemImage: "pencil")
                }
            }

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

struct EditOpeningTimeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var openedAt: Date

    var event: OpeningEvent
    var onUpdate: (Date) -> Void

    init(event: OpeningEvent, onUpdate: @escaping (Date) -> Void) {
        self.event = event
        self.onUpdate = onUpdate
        self._openedAt = State(initialValue: min(event.openedAt, Date()))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Opening time",
                        selection: $openedAt,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } footer: {
                    Text("Update the opening record if the original time was entered incorrectly. TwistLog records your correction based on your input.")
                }
            }
            .navigationTitle("Edit opening time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        onUpdate(openedAt)
                        dismiss()
                    }
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
