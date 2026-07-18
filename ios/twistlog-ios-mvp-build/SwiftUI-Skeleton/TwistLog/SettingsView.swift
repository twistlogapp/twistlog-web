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

                    Text("Your data is stored locally on this device. TwistLog does not sync bottle history to an account or cloud service.")
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
                        openAppSettings()
                    } label: {
                        Label("Open iPhone Settings", systemImage: "gearshape")
                    }

                    Text("Reminder copy: Time to check your bottle.")
                        .font(.footnote)
                        .foregroundStyle(TLTheme.gray)
                }

                Section("Support") {
                    Link(destination: feedbackURL) {
                        Label("Send feedback", systemImage: "envelope")
                    }

                    Link(destination: featureSuggestionURL) {
                        Label("Suggest a feature", systemImage: "lightbulb")
                    }

                    Text("Your notes go directly to the founder. Please do not include urgent medical information.")
                        .font(.footnote)
                        .foregroundStyle(TLTheme.gray)
                }

                Section("About") {
                    NavigationLink {
                        ArchivedBottlesView()
                    } label: {
                        Label("Archived Bottles", systemImage: "archivebox")
                    }

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

    private var feedbackURL: URL {
        mailtoURL(
            subject: "TwistLog Feedback",
            body: """
            Hi TwistLog team,


            ---
            App: TwistLog
            Version: \(appVersion)
            """
        )
    }

    private var featureSuggestionURL: URL {
        mailtoURL(
            subject: "TwistLog Feature Suggestion",
            body: """
            Hi TwistLog team,

            I have a feature idea:


            ---
            App: TwistLog
            Version: \(appVersion)
            """
        )
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        let cleanVersion = version?.isEmpty == false ? version : nil
        let cleanBuild = build?.isEmpty == false ? build : nil

        switch (cleanVersion, cleanBuild) {
        case let (version?, build?):
            return "\(version) (\(build))"
        case let (version?, nil):
            return version
        case let (nil, build?):
            return build
        default:
            return "1.0"
        }
    }

    private func mailtoURL(subject: String, body: String) -> URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "hello@twistlog.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url ?? URL(string: "mailto:hello@twistlog.com")!
    }
}

struct ArchivedBottlesView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if store.archivedBottles.isEmpty {
                EmptyStateView(
                    systemImage: "archivebox",
                    title: "No archived bottles",
                    message: "Archived bottles will appear here. Their opening history is kept for reference.",
                    buttonTitle: nil,
                    action: nil
                )
            } else {
                List {
                    ForEach(store.archivedBottles) { bottle in
                        NavigationLink {
                            BottleDetailView(bottleId: bottle.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(bottle.nickname)
                                    .font(.headline)

                                if let medicationName = bottle.medicationName {
                                    Text(medicationName)
                                        .font(.subheadline)
                                        .foregroundStyle(TLTheme.gray)
                                }

                                Text("Archived \(bottle.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(TLTheme.gray)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Archived Bottles")
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

                    Text("TwistLog records bottle-opening events, reminders, and opening history for personal reference. It does not confirm medication was taken and is not medical advice.")
                        .foregroundStyle(TLTheme.gray)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Your data is stored locally on this device.")
                        .font(.footnote)
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

            Section("App") {
                LabeledContent("Name", value: "TwistLog")
                LabeledContent("Version", value: appVersion)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        let cleanVersion = version?.isEmpty == false ? version : nil
        let cleanBuild = build?.isEmpty == false ? build : nil

        switch (cleanVersion, cleanBuild) {
        case let (version?, build?):
            return "\(version) (\(build))"
        case let (version?, nil):
            return version
        case let (nil, build?):
            return build
        default:
            return "1.0"
        }
    }
}
