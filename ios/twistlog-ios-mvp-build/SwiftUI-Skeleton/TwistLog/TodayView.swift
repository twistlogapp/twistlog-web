import SwiftUI
import UIKit

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingAddBottle = false

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
                        LazyVStack(spacing: 14) {
                            ForEach(store.activeBottles) { bottle in
                                BottleCard(bottle: bottle)
                            }
                        }
                        .padding()
                    }
                    .background(TLTheme.lightGray.opacity(0.55))
                }
            }
            .navigationTitle("Today")
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
}

struct BottleCard: View {
    @EnvironmentObject private var store: AppStore
    var bottle: Bottle

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
                            .foregroundStyle(TLTheme.gray)
                    }
                }

                Spacer()

                StatusPill(text: statusText)
            }

            HStack(spacing: 8) {
                OrangeEventDot()
                    .accessibilityHidden(true)
                Text(lastOpeningText)
                    .font(.subheadline)
                    .foregroundStyle(TLTheme.gray)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(lastOpeningText)

            if bottle.reminderEnabled {
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
                .buttonStyle(.bordered)
                .tint(TLTheme.green)
                .accessibilityLabel("View details for \(bottle.nickname)")
            }
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .confirmationDialog(
            "Recent opening found.",
            isPresented: $showRecentWarning,
            titleVisibility: .visible
        ) {
            Button("Record anyway", role: .destructive) {
                recordOpening()
            }
            Button("Cancel", role: .cancel) {}
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
            return "No opening yet"
        }

        if Calendar.current.isDateInToday(last.openedAt) {
            return "Opened today"
        }

        return "Recent opening"
    }

    private var reminderSummary: String {
        let date = Calendar.current.date(from: DateComponents(hour: bottle.reminderHour, minute: bottle.reminderMinute)) ?? Date()
        let time = date.formatted(date: .omitted, time: .shortened)

        if bottle.reminderDays.count == Weekday.allCases.count {
            return "Reminder: daily at \(time)"
        }

        let days = Weekday.allCases
            .filter { bottle.reminderDays.contains($0) }
            .map(\.shortName)
            .joined(separator: ", ")

        return "Reminder: \(days) at \(time)"
    }

    private func recordOpening() {
        store.recordOpening(for: bottle)
        showSuccess = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
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
        .background(TLTheme.lightGray.opacity(0.45))
    }
}

struct StatusPill: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(TLTheme.green)
            .background(TLTheme.green.opacity(0.12))
            .clipShape(Capsule())
    }
}
