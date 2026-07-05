import SwiftUI
import UIKit
import Combine

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingAddBottle = false
    @State private var currentDate = Date()

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
            guard let last = store.lastOpening(for: bottle) else { return false }
            return Calendar.current.isDate(last.openedAt, inSameDayAs: currentDate)
        }
    }

    private var groupedSections: [BottleCategoryGroup] {
        BottleCategory.allCases.compactMap { category in
            let bottles = store.activeBottles
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
                Text("Opening recorded.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLTheme.green)
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
            Button("Cancel", role: .cancel) {}
            Button("Record anyway", role: .destructive) {
                recordOpening()
            }
        } message: {
            Text(recentWarningMessage)
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
            if store.shouldWarnRecentOpening(for: bottle) {
                showRecentWarning = true
            } else {
                recordOpening()
            }
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

        if Calendar.current.isDate(last.openedAt, inSameDayAs: currentDate) {
            return "Opened today"
        }

        return "Not opened today"
    }

    private var hasAnyOpening: Bool {
        store.lastOpening(for: bottle) != nil
    }

    private var hasOpenedToday: Bool {
        guard let last = store.lastOpening(for: bottle) else { return false }
        return Calendar.current.isDate(last.openedAt, inSameDayAs: currentDate)
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

    private func recordOpening() {
        store.recordOpening(for: bottle)
        showSuccess = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                showSuccess = false
            }
        }
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
