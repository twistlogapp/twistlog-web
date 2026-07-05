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
            Group {
                if store.activeBottles.isEmpty {
                    EmptyStateView(
                        systemImage: "pills",
                        title: "No bottles yet",
                        message: "Add your first bottle to start recording openings and reminders.",
                        buttonTitle: "Add Bottle"
                    ) {
                        showingAddBottle = true
                    }
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 18) {
                            ForEach(groupedSections) { section in
                                BottleCategorySection(
                                    section: section,
                                    currentDate: currentDate
                                )
                            }
                        }
                        .padding()
                    }
                    .background(TLTheme.lightGray)
                }
            }
            .navigationTitle("Today")
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

            HStack {
                Button {
                    if store.shouldWarnRecentOpening(for: bottle) {
                        showRecentWarning = true
                    } else {
                        recordOpening()
                    }
                } label: {
                    Text("Opened now")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(TLTheme.green)
                .accessibilityLabel("Record opening for \(bottle.nickname)")

                NavigationLink("Details") {
                    BottleDetailView(bottleId: bottle.id)
                }
                .font(.headline)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .foregroundStyle(TLTheme.text)
                .background(TLTheme.green.opacity(0.14))
                .clipShape(Capsule())
                .buttonStyle(.plain)
                .accessibilityLabel("View details for \(bottle.nickname)")
            }
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
