import SwiftUI

struct BottleDetailView: View {
    @EnvironmentObject private var store: AppStore
    var bottle: Bottle

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(bottle.nickname)
                        .font(.title2.weight(.bold))
                    if let medicationName = bottle.medicationName {
                        Text(medicationName)
                            .foregroundStyle(TLTheme.gray)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Last opening") {
                if let last = store.lastOpening(for: bottle) {
                    OpeningRow(event: last, bottleName: nil)
                } else {
                    Text("No opening yet")
                        .foregroundStyle(TLTheme.gray)
                }
            }

            Section("Recent openings") {
                let events = store.recentOpenings(for: bottle, limit: 10)
                if events.isEmpty {
                    Text("Opening history will appear here.")
                        .foregroundStyle(TLTheme.gray)
                } else {
                    ForEach(events) { event in
                        OpeningRow(event: event, bottleName: nil)
                    }
                }
            }

            if let notes = bottle.notes {
                Section("Notes") {
                    Text(notes)
                }
            }
        }
        .navigationTitle("Details")
    }
}

