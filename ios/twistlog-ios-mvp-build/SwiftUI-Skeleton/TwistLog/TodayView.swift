import SwiftUI
import UIKit

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingAddBottle = false

    var body: some View {
        NavigationStack {
            Group {
                if store.activeBottles.isEmpty {
                    ContentUnavailableView(
                        "Add a bottle to get started.",
                        systemImage: "pills",
                        description: Text("TwistLog will show recent openings and reminder status here.")
                    )
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
                Text(lastOpeningText)
                    .font(.subheadline)
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

                NavigationLink("Details") {
                    BottleDetailView(bottleId: bottle.id)
                }
                .buttonStyle(.bordered)
                .tint(TLTheme.green)
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

    private func recordOpening() {
        store.recordOpening(for: bottle)
        showSuccess = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
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
