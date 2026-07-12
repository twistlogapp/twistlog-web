import SwiftUI
import UIKit
import Combine

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingAddBottle = false
    @State private var currentDate = Date()
    @State private var searchText = ""

    private let clock = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    TodayHeader(currentDate: currentDate)

                    if store.activeBottles.isEmpty {
                        TodayEmptyPrompt {
                            showingAddBottle = true
                        }
                    } else if filteredBottles.isEmpty {
                        EmptyStateView(
                            systemImage: "magnifyingglass",
                            title: "No bottles found",
                            message: "Try another bottle name, medication, or note.",
                            buttonTitle: nil,
                            action: nil
                        )
                    } else {
                        if allBottlesOpenedToday {
                            AllDoneBanner()
                        }

                        ForEach(groupedSections) { section in
                            BottleCategorySection(
                                section: section,
                                currentDate: currentDate
                            )
                        }
                    }
                }
                .padding()
            }
            .background(TLTheme.lightGray)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search bottles")
            .onAppear {
                currentDate = Date()
            }
            .onReceive(clock) { now in
                currentDate = now
            }
            .toolbar {
                Button {
                    showingAddBottle = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add bottle")
            }
            .sheet(isPresented: $showingAddBottle) {
                AddBottleView()
            }
        }
    }

    private var allBottlesOpenedToday: Bool {
        let bottles = store.activeBottles
        guard !bottles.isEmpty else { return false }

        return bottles.allSatisfy { bottle in
            store.hasOpeningForMedicationDay(containing: currentDate, for: bottle)
        }
    }

    private var filteredBottles: [Bottle] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return store.activeBottles }

        return store.activeBottles.filter { bottle in
            bottle.nickname.localizedCaseInsensitiveContains(trimmedSearch)
            || (bottle.medicationName?.localizedCaseInsensitiveContains(trimmedSearch) ?? false)
            || (bottle.notes?.localizedCaseInsensitiveContains(trimmedSearch) ?? false)
            || bottle.category.title.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    private var groupedSections: [BottleCategoryGroup] {
        BottleCategory.allCases.compactMap { category in
            let bottles = filteredBottles
                .filter { $0.category == category }
                .sorted { lhs, rhs in
                    nextReminderDate(for: lhs) < nextReminderDate(for: rhs)
                }
            guard !bottles.isEmpty else { return nil }
            return BottleCategoryGroup(category: category, bottles: bottles)
        }
    }

    private func nextReminderDate(for bottle: Bottle) -> Date {
        let fallback = Date.distantFuture
        guard !bottle.enabledReminders.isEmpty else { return fallback }

        let calendar = Calendar.current
        return bottle.enabledReminders.compactMap { reminder in
            reminder.days.compactMap { weekday -> Date? in
                var components = DateComponents()
                components.weekday = weekday.rawValue
                components.hour = reminder.hour
                components.minute = reminder.minute
                return calendar.nextDate(
                    after: currentDate,
                    matching: components,
                    matchingPolicy: .nextTime,
                    direction: .forward
                )
            }
            .min()
        }
        .min() ?? fallback
    }
}

private struct TodayHeader: View {
    var currentDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(TLTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(formattedDate)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLTheme.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentDate)

        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }

    private var formattedDate: String {
        currentDate.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
}

private struct TodayEmptyPrompt: View {
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "pills")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(TLTheme.green)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("No bottles yet")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(TLTheme.text)

                Text("Add your first bottle to start recording openings and reminders.")
                    .font(.body)
                    .foregroundStyle(TLTheme.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: action) {
                Text("Add Bottle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(TLTheme.green)
            .controlSize(.large)
            .accessibilityLabel("Add bottle")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AllDoneBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(TLTheme.green)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("All bottles opened today.")
                    .font(.headline)
                    .foregroundStyle(TLTheme.text)

                Text("Great job. Your opening history is up to date.")
                    .font(.subheadline)
                    .foregroundStyle(TLTheme.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLTheme.green.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct BottleCategoryGroup: Identifiable {
    var category: BottleCategory
    var bottles: [Bottle]

    var id: BottleCategory { category }
}

private struct BottleCategorySection: View {
    var section: BottleCategoryGroup
    var currentDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(section.category.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(section.category.accentColor)

                Spacer()

                Text("\(section.bottles.count) \(section.bottles.count == 1 ? "bottle" : "bottles")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TLTheme.gray)
            }
            .padding(.horizontal, 4)

            LazyVStack(spacing: 14) {
                ForEach(section.bottles) { bottle in
                    BottleCard(bottle: bottle, currentDate: currentDate)
                }
            }
        }
    }
}

struct BottleCard: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var bottle: Bottle
    var currentDate: Date

    @State private var showRecentWarning = false
    @State private var showSuccess = false
    @State private var showRecordOptions = false
    @State private var pendingOpeningDate: Date?
    @State private var lateOpeningRequest: LateOpeningRequest?
    @State private var lastRecordedEvent: OpeningEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bottle.nickname)
                        .font(.headline)
                        .foregroundStyle(TLTheme.text)

                    if let medicationName = bottle.medicationName {
                        Text(medicationName)
                            .font(.subheadline)
                            .foregroundStyle(TLTheme.text)
                    }
                }

                Spacer()

                StatusPill(
                    text: statusText,
                    foregroundColor: statusForegroundColor,
                    backgroundColor: statusBackgroundColor
                )
            }

            HStack(spacing: 8) {
                Circle()
                    .fill(hasAnyOpening ? TLTheme.orange : TLTheme.categoryGray.opacity(0.5))
                    .frame(width: 9, height: 9)
                    .accessibilityHidden(true)
                Text(lastOpeningText)
                    .font(.subheadline)
                    .foregroundStyle(TLTheme.gray)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(lastOpeningText)

            if !bottle.enabledReminders.isEmpty {
                Label(reminderSummary, systemImage: "bell")
                    .font(.caption)
                    .foregroundStyle(TLTheme.gray)
            }

            if showSuccess {
                HStack(spacing: 10) {
                    Text("Opening recorded.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TLTheme.green)

                    if lastRecordedEvent != nil {
                        Button("Undo") {
                            undoLastOpening()
                        }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.plain)
                        .foregroundStyle(TLTheme.green)
                        .accessibilityLabel("Undo last opening for \(bottle.nickname)")
                    }
                }
            }

            actionButtons
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(bottle.category.accentColor)
                .frame(width: 5)
        }
        .alert("Recent opening found.", isPresented: $showRecentWarning) {
            Button("Cancel", role: .cancel) {
                pendingOpeningDate = nil
            }
            Button("Record anyway", role: .destructive) {
                recordOpening(at: pendingOpeningDate ?? Date())
                pendingOpeningDate = nil
            }
        } message: {
            Text(recentWarningMessage)
        }
        .confirmationDialog("Record opening", isPresented: $showRecordOptions, titleVisibility: .visible) {
            Button("Just now") {
                requestOpening(at: Date())
            }

            Button("Earlier today") {
                lateOpeningRequest = .earlierToday(referenceDate: currentDate)
            }

            Button("Yesterday") {
                lateOpeningRequest = .yesterday(referenceDate: currentDate)
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose when this bottle was opened.")
        }
        .sheet(item: $lateOpeningRequest) { request in
            LateOpeningSheet(request: request) { openedAt in
                lateOpeningRequest = nil
                requestOpening(at: openedAt)
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 10) {
                openedNowButton
                detailsLink
            }
        } else {
            HStack {
                openedNowButton
                detailsLink
            }
        }
    }

    private var openedNowButton: some View {
        Button {
            showRecordOptions = true
        } label: {
            Text("Opened now")
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(TLTheme.green)
        .accessibilityLabel("Record opening for \(bottle.nickname)")
    }

    private var detailsLink: some View {
        NavigationLink {
            BottleDetailView(bottleId: bottle.id)
        } label: {
            detailsLabel
        }
        .foregroundStyle(TLTheme.text)
        .background(TLTheme.green.opacity(0.14))
        .clipShape(Capsule())
        .buttonStyle(.plain)
        .accessibilityLabel("View details for \(bottle.nickname)")
    }

    @ViewBuilder
    private var detailsLabel: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Text("Details")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
        } else {
            Text("Details")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
        }
    }

    private var lastOpeningText: String {
        guard let last = store.lastOpening(for: bottle) else {
            return "No opening yet"
        }
        return "Last opening: \(last.openedAt.formatted(date: .abbreviated, time: .shortened))"
    }

    private var recentWarningMessage: String {
        guard let last = store.lastOpening(for: bottle) else {
            return "This bottle was opened recently."
        }
        return "This bottle was already opened at \(last.openedAt.formatted(date: .omitted, time: .shortened))."
    }

    private var statusText: String {
        guard let last = store.lastOpening(for: bottle) else {
            return "Not opened yet"
        }

        if store.hasOpeningForMedicationDay(containing: currentDate, for: bottle) {
            return "Opened today"
        }

        return "Not opened today"
    }

    private var hasAnyOpening: Bool {
        store.lastOpening(for: bottle) != nil
    }

    private var hasOpenedToday: Bool {
        store.hasOpeningForMedicationDay(containing: currentDate, for: bottle)
    }

    private var cardBackground: Color {
        hasOpenedToday ? TLTheme.cardBackground : TLTheme.cardBackground.opacity(0.78)
    }

    private var statusForegroundColor: Color {
        hasOpenedToday ? TLTheme.green : TLTheme.categoryGray
    }

    private var statusBackgroundColor: Color {
        hasOpenedToday ? TLTheme.green.opacity(0.12) : TLTheme.categoryGray.opacity(0.14)
    }

    private var reminderSummary: String {
        let reminders = bottle.enabledReminders
        guard !reminders.isEmpty else {
            return "Reminder: off"
        }

        if reminders.count == 1, let reminder = reminders.first {
            return "Reminder: \(reminderDaySummary(reminder)) at \(reminder.displayTime)"
        }

        let times = reminders
            .prefix(2)
            .map(\.displayTime)
            .joined(separator: ", ")

        if reminders.count > 2 {
            return "Reminders: \(times) + \(reminders.count - 2) more"
        }

        return "Reminders: \(times)"
    }

    private func reminderDaySummary(_ reminder: BottleReminder) -> String {
        if reminder.days.count == Weekday.allCases.count {
            return "daily"
        }

        return Weekday.allCases
            .filter { reminder.days.contains($0) }
            .map(\.shortName)
            .joined(separator: ", ")
    }

    private func requestOpening(at openedAt: Date) {
        if store.shouldWarnRecentOpening(for: bottle, now: openedAt) {
            pendingOpeningDate = openedAt
            showRecentWarning = true
        } else {
            recordOpening(at: openedAt)
        }
    }

    private func recordOpening(at openedAt: Date) {
        lastRecordedEvent = store.recordOpening(for: bottle, now: openedAt)
        showSuccess = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            await MainActor.run {
                showSuccess = false
                lastRecordedEvent = nil
            }
        }
    }

    private func undoLastOpening() {
        guard let lastRecordedEvent else { return }
        store.deleteOpening(lastRecordedEvent)
        self.lastRecordedEvent = nil
        showSuccess = false
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

struct EmptyStateView: View {
    var systemImage: String
    var title: String
    var message: String
    var buttonTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(TLTheme.green)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(TLTheme.text)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundStyle(TLTheme.gray)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let buttonTitle, let action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(TLTheme.green)
                .controlSize(.large)
                .accessibilityLabel(buttonTitle)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TLTheme.lightGray)
    }
}

struct StatusPill: View {
    var text: String
    var foregroundColor: Color = TLTheme.green
    var backgroundColor: Color = TLTheme.green.opacity(0.12)

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
}

struct LateOpeningRequest: Identifiable {
    let id = UUID()
    var title: String
    var initialDate: Date
    var allowsDateSelection: Bool

    static func earlierToday(referenceDate: Date) -> LateOpeningRequest {
        LateOpeningRequest(
            title: "Earlier today",
            initialDate: Calendar.current.date(byAdding: .hour, value: -1, to: referenceDate) ?? referenceDate,
            allowsDateSelection: false
        )
    }

    static func yesterday(referenceDate: Date) -> LateOpeningRequest {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate) ?? referenceDate
        let initialDate = calendar.date(
            bySettingHour: calendar.component(.hour, from: referenceDate),
            minute: calendar.component(.minute, from: referenceDate),
            second: 0,
            of: yesterday
        ) ?? yesterday

        return LateOpeningRequest(
            title: "Yesterday",
            initialDate: initialDate,
            allowsDateSelection: true
        )
    }
}

struct LateOpeningSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var openedAt: Date

    var request: LateOpeningRequest
    var onRecord: (Date) -> Void

    init(request: LateOpeningRequest, onRecord: @escaping (Date) -> Void) {
        self.request = request
        self.onRecord = onRecord
        self._openedAt = State(initialValue: request.initialDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Opening time",
                        selection: $openedAt,
                        in: ...Date(),
                        displayedComponents: displayedComponents
                    )
                } footer: {
                    Text("Use this when the bottle was opened earlier, but you forgot to record it at the time.")
                }
            }
            .navigationTitle(request.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Record") {
                        onRecord(openedAt)
                        dismiss()
                    }
                }
            }
        }
    }

    private var displayedComponents: DatePickerComponents {
        request.allowsDateSelection ? [.date, .hourAndMinute] : [.hourAndMinute]
    }
}
