import SwiftUI
import UIKit

struct BottleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    var bottleId: UUID

    @State private var showingEditBottle = false
    @State private var showingArchiveConfirmation = false
    @State private var showRecentWarning = false
    @State private var showSuccess = false

    var body: some View {
        Group {
            if let bottle = store.bottle(id: bottleId) {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(bottle.nickname)
                                .font(.title2.weight(.bold))
                            if let medicationName = bottle.medicationName {
                                Text(medicationName)
                                    .foregroundStyle(TLTheme.text)
                            }
                        }
                        .padding(.vertical, 6)

                        if bottle.isArchived {
                            Label("Archived bottle", systemImage: "archivebox")
                                .foregroundStyle(TLTheme.gray)
                        } else {
                            Button {
                                if store.shouldWarnRecentOpening(for: bottle) {
                                    showRecentWarning = true
                                } else {
                                    recordOpening(for: bottle)
                                }
                            } label: {
                                Label("Opened now", systemImage: "plus.circle.fill")
                            }
                            .tint(TLTheme.green)
                            .accessibilityLabel("Record opening for \(bottle.nickname)")
                        }

                        if showSuccess {
                            Label("Opening recorded.", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(TLTheme.green)
                        }
                    }

                    Section("Bottle") {
                        LabeledContent("Type", value: bottle.category.title)
                    }

                    Section("Last opening") {
                        if let last = store.lastOpening(for: bottle) {
                            OpeningRow(event: last, bottleName: nil)
                        } else {
                            Text("No opening yet")
                                .foregroundStyle(TLTheme.gray)
                        }
                    }

                    Section("Opening settings") {
                        if bottle.minimumIntervalEnabled, let minutes = bottle.minimumIntervalMinutes {
                            LabeledContent("Minimum time between openings", value: intervalLabel(minutes: minutes))
                        } else {
                            LabeledContent("Minimum time between openings", value: "Off")
                        }
                    }

                    Section("Reminder") {
                        if bottle.enabledReminders.isEmpty {
                            LabeledContent("Reminder", value: "Off")
                        } else {
                            ForEach(bottle.enabledReminders) { reminder in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(reminder.displayTime)
                                        .font(.headline)
                                    Text(reminderDaySummary(reminder))
                                        .font(.caption)
                                        .foregroundStyle(TLTheme.gray)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    Section("Recent openings") {
                        let events = store.recentOpenings(for: bottle, limit: 10)
                        if events.isEmpty {
                            Text("No openings recorded yet. Tap Opened now to start this bottle's history.")
                                .foregroundStyle(TLTheme.gray)
                        } else {
                            ForEach(events) { event in
                                OpeningRow(event: event, bottleName: nil)
                            }
                            .onDelete { offsets in
                                deleteOpenings(at: offsets, for: events)
                            }
                        }
                    }

                    if let notes = bottle.notes {
                        Section("Notes") {
                            Text(notes)
                        }
                    }

                    Section {
                        if bottle.isArchived {
                            Button {
                                store.restoreBottle(id: bottle.id)
                                dismiss()
                            } label: {
                                Label("Restore Bottle", systemImage: "arrow.uturn.backward.circle")
                            }
                            .tint(TLTheme.green)
                        } else {
                            Button("Archive Bottle", role: .destructive) {
                                showingArchiveConfirmation = true
                            }
                        }
                    } footer: {
                        Text(bottle.isArchived ? "Restoring returns this bottle to Today and re-enables its reminders." : "Archiving hides this bottle from Today but keeps its opening history for reference.")
                    }
                }
                .navigationTitle("Details")
                .toolbar {
                    if !bottle.isArchived {
                        Button("Edit") {
                            showingEditBottle = true
                        }
                    }
                }
                .sheet(isPresented: $showingEditBottle) {
                    AddBottleView(bottle: bottle)
                }
                .confirmationDialog(
                    "Archive this bottle?",
                    isPresented: $showingArchiveConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Archive Bottle", role: .destructive) {
                        store.archiveBottle(id: bottle.id)
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("The bottle will be hidden from Today. Existing opening history will remain.")
                }
                .confirmationDialog(
                    "Recent opening found.",
                    isPresented: $showRecentWarning,
                    titleVisibility: .visible
                ) {
                    Button("Record anyway", role: .destructive) {
                        recordOpening(for: bottle)
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text(recentWarningMessage(for: bottle))
                }
            } else {
                ContentUnavailableView(
                    "Bottle not found",
                    systemImage: "archivebox",
                    description: Text("This bottle may have been archived.")
                )
            }
        }
    }

    private func recordOpening(for bottle: Bottle) {
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

    private func recentWarningMessage(for bottle: Bottle) -> String {
        guard let last = store.lastOpening(for: bottle) else {
            return "This bottle was opened recently."
        }
        return "This bottle was already opened at \(last.openedAt.formatted(date: .omitted, time: .shortened))."
    }

    private func deleteOpenings(at offsets: IndexSet, for events: [OpeningEvent]) {
        for offset in offsets {
            store.deleteOpening(events[offset])
        }
    }

    private func intervalLabel(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minutes"
        }

        if minutes % 10080 == 0 {
            let weeks = minutes / 10080
            return weeks == 1 ? "1 week" : "\(weeks) weeks"
        }

        if minutes % 1440 == 0 {
            let days = minutes / 1440
            return days == 1 ? "1 day" : "\(days) days"
        }

        let hours = minutes / 60
        let remainder = minutes % 60

        if remainder == 0 {
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }

        return "\(hours) hr \(remainder) min"
    }

    private func reminderDaySummary(_ reminder: BottleReminder) -> String {
        if reminder.days.count == Weekday.allCases.count {
            return "Daily"
        }

        return Weekday.allCases
            .filter { reminder.days.contains($0) }
            .map(\.shortName)
            .joined(separator: ", ")
    }
}
