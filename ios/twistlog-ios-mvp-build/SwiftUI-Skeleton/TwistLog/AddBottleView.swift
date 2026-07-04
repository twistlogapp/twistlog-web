import SwiftUI

struct AddBottleView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    private let bottle: Bottle?

    @State private var nickname: String
    @State private var medicationName: String
    @State private var notes: String
    @State private var minimumIntervalEnabled: Bool
    @State private var minimumIntervalMinutes: Int

    init(bottle: Bottle? = nil) {
        self.bottle = bottle
        _nickname = State(initialValue: bottle?.nickname ?? "")
        _medicationName = State(initialValue: bottle?.medicationName ?? "")
        _notes = State(initialValue: bottle?.notes ?? "")
        _minimumIntervalEnabled = State(initialValue: bottle?.minimumIntervalEnabled ?? false)
        _minimumIntervalMinutes = State(initialValue: bottle?.minimumIntervalMinutes ?? 240)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Bottle") {
                    TextField("Bottle nickname", text: $nickname)
                    TextField("Medication name (optional)", text: $medicationName)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                Section {
                    Toggle("Minimum time between openings", isOn: $minimumIntervalEnabled)

                    if minimumIntervalEnabled {
                        Stepper(value: $minimumIntervalMinutes, in: 15...1440, step: 15) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Warn if opened again within")
                                Text(intervalLabel)
                                    .font(.caption)
                                    .foregroundStyle(TLTheme.gray)
                            }
                        }
                    }
                } footer: {
                    Text("This only warns about recent bottle openings. TwistLog does not verify that medicine was taken.")
                }
            }
            .navigationTitle(bottle == nil ? "Add Bottle" : "Edit Bottle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(trimmedNickname.isEmpty)
                }
            }
        }
    }

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var intervalLabel: String {
        if minimumIntervalMinutes < 60 {
            return "\(minimumIntervalMinutes) minutes"
        }

        let hours = minimumIntervalMinutes / 60
        let minutes = minimumIntervalMinutes % 60

        if minutes == 0 {
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }

        return "\(hours) hr \(minutes) min"
    }

    private func save() {
        if let bottle {
            store.updateBottle(
                id: bottle.id,
                nickname: trimmedNickname,
                medicationName: medicationName,
                notes: notes,
                minimumIntervalEnabled: minimumIntervalEnabled,
                minimumIntervalMinutes: minimumIntervalMinutes
            )
        } else {
            store.addBottle(
                nickname: trimmedNickname,
                medicationName: medicationName,
                notes: notes,
                minimumIntervalEnabled: minimumIntervalEnabled,
                minimumIntervalMinutes: minimumIntervalMinutes
            )
        }
    }
}

