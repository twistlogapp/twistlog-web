import SwiftUI

struct AddBottleView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    @State private var nickname = ""
    @State private var medicationName = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Bottle") {
                    TextField("Bottle nickname", text: $nickname)
                    TextField("Medication name (optional)", text: $medicationName)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                Section("Later") {
                    Text("Reminder schedule and minimum time between openings are planned for the next build step.")
                        .foregroundStyle(TLTheme.gray)
                }
            }
            .navigationTitle("Add Bottle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addBottle(
                            nickname: nickname,
                            medicationName: medicationName,
                            notes: notes
                        )
                        dismiss()
                    }
                    .disabled(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

