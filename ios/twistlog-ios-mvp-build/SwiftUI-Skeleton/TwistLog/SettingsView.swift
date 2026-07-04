import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Safety") {
                    Text("TwistLog records bottle-opening events for personal reference and reminders. It does not verify that medicine was taken and is not medical advice.")
                        .foregroundStyle(TLTheme.gray)
                }

                Section("Notifications") {
                    Label("Reminder settings", systemImage: "bell")
                    Text("Local reminder scheduling comes in the next build step.")
                        .font(.footnote)
                        .foregroundStyle(TLTheme.gray)
                }

                Section("About") {
                    Link(destination: URL(string: "https://twistlog.com")!) {
                        Label("TwistLog", systemImage: "info.circle")
                    }

                    Link(destination: URL(string: "https://twistlog.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    Link(destination: URL(string: "https://twistlog.com/terms")!) {
                        Label("Terms", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
