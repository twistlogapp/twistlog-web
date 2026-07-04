import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    private let reminderScheduler: ReminderScheduling = NotificationManager.liveScheduler

    var body: some View {
        NavigationStack {
            List {
                Section("Safety") {
                    Text("TwistLog records bottle-opening events and reminders. It does not confirm medication was taken and is not medical advice.")
                        .foregroundStyle(TLTheme.gray)
                }

                Section("Notifications") {
                    LabeledContent("Permission", value: notificationStatusLabel)

                    Button {
                        Task {
                            _ = await reminderScheduler.requestAuthorization()
                            await refreshNotificationStatus()
                        }
                    } label: {
                        Label("Enable reminder notifications", systemImage: "bell.badge")
                    }

                    Button {
                        Task {
                            await reminderScheduler.scheduleTestReminder()
                            await refreshNotificationStatus()
                        }
                    } label: {
                        Label("Send test reminder in 10 seconds", systemImage: "bell.and.waves.left.and.right")
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
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About TwistLog", systemImage: "info.circle")
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
        notificationStatus = await reminderScheduler.authorizationStatus()
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    OrangeEventDot(size: 14)
                        .accessibilityHidden(true)

                    Text("KNOW WHEN THE BOTTLE WAS OPENED.")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(TLTheme.green)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("TwistLog records bottle-opening events and reminders. It does not confirm medication was taken and should not be used as medical advice.")
                        .foregroundStyle(TLTheme.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
            }

            Section("Links") {
                Link(destination: URL(string: "https://twistlog.com")!) {
                    Label("Website", systemImage: "safari")
                }

                Link(destination: URL(string: "https://twistlog.com/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }

                Link(destination: URL(string: "https://twistlog.com/terms")!) {
                    Label("Terms", systemImage: "doc.text")
                }
            }

            Section("Version") {
                LabeledContent("App", value: "TwistLog MVP")
                LabeledContent("Build", value: "TestFlight candidate")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
