import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if store.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "circle.grid.2x2")
                }

            BottlesView()
                .tabItem {
                    Label("Bottles", systemImage: "pills")
                }

            OpeningHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(TLTheme.green)
    }
}

struct BottlesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingAddBottle = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if store.activeBottles.isEmpty {
                    EmptyStateView(
                        systemImage: "pills",
                        title: "No bottles yet",
                        message: "Add your first bottle to start recording openings and reminders.",
                        buttonTitle: "Add Bottle",
                        action: {
                            showingAddBottle = true
                        }
                    )
                } else if filteredBottles.isEmpty {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        title: "No bottles found",
                        message: "Try another bottle name, medication, category, or note.",
                        buttonTitle: nil,
                        action: nil
                    )
                } else {
                    List {
                        Section {
                            BottlesSummaryRow(
                                activeCount: store.activeBottles.count,
                                archivedCount: store.archivedBottles.count
                            )
                        }
                        .listRowBackground(TLTheme.cardBackground)

                        ForEach(groupedSections) { section in
                            Section {
                                ForEach(section.bottles) { bottle in
                                    NavigationLink {
                                        BottleDetailView(bottleId: bottle.id)
                                    } label: {
                                        BottleManagementRow(bottle: bottle)
                                    }
                                }
                            } header: {
                                HStack {
                                    Text(section.category.title)
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(section.category.accentColor)
                                        .textCase(nil)

                                    Spacer()

                                    Text("\(section.bottles.count)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(TLTheme.gray)
                                }
                            }
                        }

                        if !store.archivedBottles.isEmpty {
                            Section("Archive") {
                                NavigationLink {
                                    ArchivedBottlesView()
                                } label: {
                                    Label("Archived Bottles", systemImage: "archivebox")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(TLTheme.lightGray)
                }
            }
            .navigationTitle("Bottles")
            .searchable(text: $searchText, prompt: "Search bottles")
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

    private var filteredBottles: [Bottle] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return store.activeBottles }

        return store.activeBottles.filter { bottle in
            bottle.nickname.localizedCaseInsensitiveContains(trimmedSearch)
            || (bottle.medicationName?.localizedCaseInsensitiveContains(trimmedSearch) ?? false)
            || (bottle.notes?.localizedCaseInsensitiveContains(trimmedSearch) ?? false)
            || bottle.category.title.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    private var groupedSections: [BottleManagementSection] {
        BottleCategory.allCases.compactMap { category in
            let bottles = filteredBottles
                .filter { $0.category == category }
                .sorted { $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending }
            guard !bottles.isEmpty else { return nil }
            return BottleManagementSection(category: category, bottles: bottles)
        }
    }
}

private struct BottleManagementSection: Identifiable {
    var category: BottleCategory
    var bottles: [Bottle]

    var id: BottleCategory { category }
}

private struct BottlesSummaryRow: View {
    var activeCount: Int
    var archivedCount: Int

    var body: some View {
        HStack(spacing: 16) {
            Label("\(activeCount) active", systemImage: "pills")
                .foregroundStyle(TLTheme.green)

            if archivedCount > 0 {
                Label("\(archivedCount) archived", systemImage: "archivebox")
                    .foregroundStyle(TLTheme.gray)
            }
        }
        .font(.subheadline.weight(.semibold))
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct BottleManagementRow: View {
    var bottle: Bottle

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(bottle.category.accentColor)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(bottle.nickname)
                    .font(.headline)
                    .foregroundStyle(TLTheme.text)

                if let medicationName = bottle.medicationName {
                    Text(medicationName)
                        .font(.subheadline)
                        .foregroundStyle(TLTheme.gray)
                }

                Text(reminderSummary)
                    .font(.caption)
                    .foregroundStyle(TLTheme.gray)
            }

            Spacer(minLength: 8)

            Text(bottle.category.pickerTitle)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .foregroundStyle(bottle.category.accentColor)
                .background(bottle.category.accentColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    private var reminderSummary: String {
        let reminders = bottle.enabledReminders
        guard !reminders.isEmpty else { return "No reminders" }

        let times = reminders
            .prefix(2)
            .map(\.displayTime)
            .joined(separator: ", ")

        if reminders.count > 2 {
            return "\(times) + \(reminders.count - 2) more"
        }

        return times
    }
}
