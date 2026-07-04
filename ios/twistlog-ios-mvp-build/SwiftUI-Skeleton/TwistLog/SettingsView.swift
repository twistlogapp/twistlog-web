import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            List {
                Section("Safety") {
                    Text("TwistLog records bottle-opening events for personal reference and reminders. It does not verify that medicine was taken and is not medical advice.")
                        .foregroundStyle(TLTheme.gray)
                }

                Section("Notifications") {
                    LabeledContent("Permission", value: notificationStatusLabel)

                    Button {
                        Task {
                            _ = await NotificationManager.requestAuthorization()
                            await refreshNotificationStatus()
                        }
                    } label: {
                        Label("Enable reminder notifications", systemImage: "bell.badge")
                    }

                    Button {
                        openAppSettings()
                    } label: {
                        Label("Open iPhone Settings", systemImage: "gearshape")
                    }

                    Text("Reminder copy: Reminder: check your bottle.")
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
            .task {
                await refreshNotificationStatus()
            }
        }
    }

    private var notificationStatusLabel: String {
        switch notificationStatus {
        case .authorized: return "Allowed"
        case .denied: return "Denied"
        case .notDetermined: return "Not asked"
        case .provisional: return "Provisional"
        case .ephemeral: return "Temporary"
        @unknown default: return "Unknown"
        }
    }

    private func refreshNotificationStatus() async {
        notificationStatus = await NotificationManager.authorizationStatus()
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

