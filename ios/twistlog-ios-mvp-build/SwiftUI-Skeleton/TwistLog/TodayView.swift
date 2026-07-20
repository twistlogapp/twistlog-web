import SwiftUI
import UIKit
import Combine

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingAddBottle = false
    @State private var showingMultiRecord = false
    @State private var currentDate = Date()

    private let clock = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    TodayHeader(currentDate: currentDate, displayName: store.displayName)

                    if store.activeBottles.isEmpty {
                        TodayEmptyPrompt {
                            showingAddBottle = true
                        }
                    } else {
                        if allBottlesOpenedToday {
                            AllDoneBanner()
                        }

                        ForEach(groupedSections) { section in
                            BottleCategorySection(
                                section: section,
                                currentDate: currentDate
                            )
                        }
                    }
                }
                .padding()
            }
            .background(TLTheme.lightGray)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                currentDate = Date()
            }
            .onReceive(clock) { now in
                currentDate = now
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if store.activeBottles.count > 1 {
                        Button {
                            showingMultiRecord = true
                        } label: {
                            Image(systemName: "checklist")
                        }
                        .accessibilityLabel("Record multiple openings")
                    }

                    Button {
                        showingAddBottle = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add bottle")
                }
            }
            .sheet(isPresented: $showingAddBottle) {
                AddBottleView()
            }
            .sheet(isPresented: $showingMultiRecord) {
                MultiRecordOpeningView(currentDate: currentDate)
            }
        }
    }

    private var allBottlesOpenedToday: Bool {
        let bottles = store.activeBottles.filter { bottle in
            bottle.enabledReminders.isEmpty
            || !store.reminderDatesForCalendarDay(containing: currentDate, for: bottle).isEmpty
        }
        guard !bottles.isEmpty else { return false }

        return bottles.allSatisfy { bottle in
            store.isBottleCompleteForCalendarDay(containing: currentDate, for: bottle)
        }
    }

    private var groupedSections: [BottleCategoryGroup] {
        BottleCategory.allCases.compactMap { category in
            let bottles = store.activeBottles
                .filter { $0.category == category }
                .sorted { lhs, rhs in
                    nextReminderDate(for: lhs) < nextReminderDate(for: rhs)
                }
            guard !bottles.isEmpty else { return nil }
            return BottleCategoryGroup(category: category, bottles: bottles)
        }
    }

    private func nextReminderDate(for bottle: Bottle) -> Date {
        let fallback = Date.distantFuture
        if let nextRequired = store.nextRequiredReminderDate(containing: currentDate, for: bottle) {
            return nextRequired
        }

        guard !bottle.enabledReminders.isEmpty else { return fallback }

        let calendar = Calendar.current
        return bottle.enabledReminders.compactMap { reminder in
            reminder.days.compactMap { weekday -> Date? in
                var components = DateComponents()
                components.weekday = weekday.rawValue
                components.hour = reminder.hour
                components.minute = reminder.minute
                return calendar.nextDate(
                    after: currentDate,
                    matching: components,
                    matchingPolicy: .nextTime,
                    direction: .forward
                )
            }
            .min()
        }
        .min() ?? fallback
    }
}

private struct TodayHeader: View {
    var currentDate: Date
    var displayName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(TLTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(formattedDate)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLTheme.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        let baseGreeting: String

        switch hour {
        case 5..<12:
            baseGreeting = "Good morning"
        case 12..<17:
            baseGreeting = "Good afternoon"
        default:
            baseGreeting = "Good evening"
        }

        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            return baseGreeting
        }

        return "\(baseGreeting), \(trimmedName)"
    }

    private var formattedDate: String {
        currentDate.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
}

private struct TodayEmptyPrompt: View {
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "pills")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(TLTheme.green)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("No bottles yet")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(TLTheme.text)

                Text("Add your first bottle to start recording openings and reminders.")
                    .font(.body)
                    .foregroundStyle(TLTheme.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: action) {
                Text("Add Bottle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(TLTheme.green)
            .controlSize(.large)
            .accessibilityLabel("Add bottle")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AllDoneBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(TLTheme.green)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Great job - all bottles opened today.")
                    .font(.headline)
                    .foregroundStyle(TLTheme.text)

                Text("Your opening history is up to date.")
                    .font(.subheadline)
                    .foregroundStyle(TLTheme.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TLTheme.green.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct BottleCategoryGroup: Identifiable {
    var category: BottleCategory
    var bottles: [Bottle]

    var id: BottleCategory { category }
}

private struct BottleCategorySection: View {
    var section: BottleCategoryGroup
    var currentDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(section.category.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(section.category.accentColor)

                Spacer()

                Text("\(section.bottles.count) \(section.bottles.count == 1 ? "bottle" : "bottles")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLTheme.gray)
            }
            .padding(.horizontal, 4)

            LazyVStack(spacing: 14) {
                ForEach(section.bottles) { bottle in
                    BottleCard(bottle: bottle, currentDate: currentDate)
                }
            }
        }
    }
}

struct BottleCard: View {
    @EnvironmentObject private var store: AppStore
    var bottle: Bottle
    var currentDate: Date

    @State private var showRecentWarning = false
    @State private var showSuccess = false
    @State private var showRecordOptions = false
    @State private var showingDetails = false
    @State private var pendingOpeningDate: Date?
    @State private var lateOpeningRequest: LateOpeningRequest?
    @State private var lastRecordedEvent: OpeningEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                Button {
                    showingDetails = true
                } label: {
                    cardDetails
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View details for \(bottle.nickname)")

                OpeningRingAction(
                    status: todayStatus,
                    bottleName: bottle.nickname,
                    onTap: {
                        showRecordOptions = true
                    },
                    onLongPress: {
                        requestOpening(at: Date())
                    }
                )
            }

            if showSuccess {
                HStack(spacing: 10) {
                    Text("Opening recorded.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TLTheme.green)

                    if lastRecordedEvent != nil {
                        Button("Undo") {
                            undoLastOpening()
                        }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.plain)
                        .foregroundStyle(TLTheme.green)
                        .accessibilityLabel("Undo last opening for \(bottle.nickname)")
                    }
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(bottle.category.accentColor)
                .frame(width: 5)
        }
        .alert("Recent opening found.", isPresented: $showRecentWarning) {
            Button("Cancel", role: .cancel) {
                pendingOpeningDate = nil
            }
            Button("Record anyway", role: .destructive) {
                recordOpening(at: pendingOpeningDate ?? Date())
                pendingOpeningDate = nil
            }
        } message: {
            Text(recentWarningMessage)
        }
        .confirmationDialog("Record opening", isPresented: $showRecordOptions, titleVisibility: .visible) {
            Button("Just now") {
                requestOpening(at: Date())
            }

            Button("Earlier today") {
                lateOpeningRequest = .earlierToday(referenceDate: currentDate)
            }

            Button("Yesterday") {
                lateOpeningRequest = .yesterday(referenceDate: currentDate)
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose when this bottle was opened.")
        }
        .sheet(item: $lateOpeningRequest) { request in
            LateOpeningSheet(request: request) { openedAt in
                lateOpeningRequest = nil
                requestOpening(at: openedAt)
            }
        }
        .navigationDestination(isPresented: $showingDetails) {
            BottleDetailView(bottleId: bottle.id)
        }
    }

    private var cardDetails: some View {
        VStack(alignment: .leading, spacing: 9) {
            VStack(alignment: .leading, spacing: 4) {
                Text(bottle.nickname)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(TLTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if let medicationName = bottle.medicationName {
                    Text(medicationName)
                        .font(.subheadline)
                        .foregroundStyle(TLTheme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                if let contextSummary {
                    Text(contextSummary)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TLTheme.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            Label(reminderSummary, systemImage: reminderSummaryIcon)
                .font(.subheadline)
                .foregroundStyle(TLTheme.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if shouldShowLeftStatusLine {
                Label(statusDetailText, systemImage: statusDetailIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(todayStatus.accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var shouldShowLeftStatusLine: Bool {
        switch todayStatus {
        case .due, .soon, .upcoming:
            return false
        case .opened, .yesterday, .lastOpened, .notOpened:
            return true
        }
    }

    private var statusDetailText: String {
        switch todayStatus {
        case let .opened(time):
            return "Last opened \(time)"
        case let .due(time):
            return "Due \(time)"
        case let .soon(time):
            return "Soon \(time)"
        case let .upcoming(time):
            return "Next due \(time)"
        case let .yesterday(time):
            return "Opened yesterday \(time)"
        case let .lastOpened(date):
            return "Last opened \(date)"
        case .notOpened:
            return "Not opened yet"
        }
    }

    private var statusDetailIcon: String {
        switch todayStatus {
        case .opened, .yesterday, .lastOpened:
            return "checkmark.circle"
        case .due:
            return "hourglass"
        case .soon, .upcoming, .notOpened:
            return "clock"
        }
    }

    private var recentWarningMessage: String {
        guard let last = store.lastOpening(for: bottle) else {
            return "This bottle was opened recently."
        }
        return "This bottle was already opened at \(last.openedAt.formatted(date: .omitted, time: .shortened))."
    }

    private var todayStatus: TodayBottleStatus {
        if let reminder = store.nextRequiredReminderDate(containing: currentDate, for: bottle) {
            let formattedTime = reminder.formatted(date: .omitted, time: .shortened)
            if reminder <= currentDate {
                return .due(time: formattedTime)
            }
            if reminder.timeIntervalSince(currentDate) <= Self.soonThreshold {
                return .soon(time: formattedTime)
            }
            return .upcoming(time: formattedTime)
        }

        if let openedToday = store.openingForCalendarDay(containing: currentDate, for: bottle) {
            return .opened(time: openedToday.openedAt.formatted(date: .omitted, time: .shortened))
        }

        if let reminder = reminderStatusDate {
            let formattedTime = reminder.formatted(date: .omitted, time: .shortened)
            if reminder.timeIntervalSince(currentDate) <= Self.soonThreshold {
                return .soon(time: formattedTime)
            }
            return .upcoming(time: formattedTime)
        }

        if let last = store.lastOpening(for: bottle) {
            if Calendar.current.isDateInYesterday(last.openedAt) {
                return .yesterday(time: last.openedAt.formatted(date: .omitted, time: .shortened))
            }

            return .lastOpened(date: last.openedAt.formatted(date: .abbreviated, time: .omitted))
        }

        return .notOpened
    }

    private var reminderStatusDate: Date? {
        let reminders = bottle.enabledReminders
        guard !reminders.isEmpty else { return nil }

        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: currentDate)
        let todaysReminders = reminders
            .filter { reminder in
                reminder.days.contains(Weekday(rawValue: todayWeekday) ?? .sunday)
            }
            .compactMap { reminder in
                calendar.date(
                    bySettingHour: reminder.hour,
                    minute: reminder.minute,
                    second: 0,
                    of: currentDate
                )
            }
            .sorted()

        if let latestPastDue = todaysReminders.last(where: { $0 <= currentDate }) {
            return latestPastDue
        }

        if let nextToday = todaysReminders.first(where: { $0 > currentDate }) {
            return nextToday
        }

        return reminders.compactMap { reminder in
            reminder.days.compactMap { weekday -> Date? in
                var components = DateComponents()
                components.weekday = weekday.rawValue
                components.hour = reminder.hour
                components.minute = reminder.minute
                return calendar.nextDate(
                    after: currentDate,
                    matching: components,
                    matchingPolicy: .nextTime,
                    direction: .forward
                )
            }
            .min()
        }
        .min()
    }

    private static let soonThreshold: TimeInterval = 2 * 60 * 60

    private var hasAnyOpening: Bool {
        store.lastOpening(for: bottle) != nil
    }

    private var hasOpenedToday: Bool {
        store.hasOpeningForCalendarDay(containing: currentDate, for: bottle)
    }

    private var cardBackground: Color {
        hasOpenedToday ? TLTheme.cardBackground : TLTheme.cardBackground.opacity(0.9)
    }

    private var reminderSummary: String {
        let reminders = bottle.enabledReminders
        guard !reminders.isEmpty else {
            return "No reminder set"
        }

        if reminders.count == 1, let reminder = reminders.first {
            return "\(reminderDaySummary(reminder)) at \(reminder.displayTime)"
        }

        let times = reminders
            .prefix(2)
            .map(\.displayTime)
            .joined(separator: ", ")

        if reminders.count > 2 {
            return "\(times) + \(reminders.count - 2) more"
        }

        return times
    }

    private var reminderSummaryIcon: String {
        bottle.enabledReminders.isEmpty ? "bell.slash" : "bell"
    }

    private var contextSummary: String? {
        let parts = [bottle.amountText, bottle.timingNote].compactMap { value -> String? in
            guard let value else { return nil }
            return value.nilIfBlank
        }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " • ")
    }

    private func reminderDaySummary(_ reminder: BottleReminder) -> String {
        if reminder.days.count == Weekday.allCases.count {
            return "daily"
        }

        return Weekday.allCases
            .filter { reminder.days.contains($0) }
            .map(\.shortName)
            .joined(separator: ", ")
    }

    private func requestOpening(at openedAt: Date) {
        if store.shouldWarnRecentOpening(for: bottle, now: openedAt) {
            pendingOpeningDate = openedAt
            showRecentWarning = true
        } else {
            recordOpening(at: openedAt)
        }
    }

    private func recordOpening(at openedAt: Date) {
        lastRecordedEvent = store.recordOpening(for: bottle, now: openedAt)
        showSuccess = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            await MainActor.run {
                showSuccess = false
                lastRecordedEvent = nil
            }
        }
    }

    private func undoLastOpening() {
        guard let lastRecordedEvent else { return }
        store.deleteOpening(lastRecordedEvent)
        self.lastRecordedEvent = nil
        showSuccess = false
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

struct EmptyStateView: View {
    var systemImage: String
    var title: String
    var message: String
    var buttonTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(TLTheme.green)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(TLTheme.text)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundStyle(TLTheme.gray)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let buttonTitle, let action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(TLTheme.green)
                .controlSize(.large)
                .accessibilityLabel(buttonTitle)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TLTheme.lightGray)
    }
}

struct OpeningRingAction: View {
    var status: TodayBottleStatus
    var bottleName: String
    var onTap: () -> Void
    var onLongPress: () -> Void

    @State private var didLongPress = false

    var body: some View {
        Button {
            if didLongPress {
                didLongPress = false
            } else {
                onTap()
            }
        } label: {
            VStack(spacing: 4) {
                OpeningRingMark(color: ringColor)

                Text(caption)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(captionColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 88)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Record opening for \(bottleName)")
        .accessibilityHint("Tap for logging options. Long press to record just now.")
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    didLongPress = true
                    onLongPress()
                }
        )
    }

    private var caption: String {
        switch status {
        case .opened:
            return "Done"
        case let .due(time):
            return "Due \(compactTime(time))"
        case let .soon(time):
            return "Soon \(compactTime(time))"
        case let .upcoming(time):
            return "Next \(compactTime(time))"
        case .yesterday, .lastOpened, .notOpened:
            return "Log"
        }
    }

    private func compactTime(_ time: String) -> String {
        time
            .replacingOccurrences(of: ":00", with: "")
            .replacingOccurrences(of: "\u{202F}", with: " ")
    }

    private var ringColor: Color {
        switch status {
        case .opened:
            return TLTheme.green
        case .due:
            return TLTheme.orange
        case .soon, .upcoming, .yesterday, .lastOpened, .notOpened:
            return Color(uiColor: .systemGray3)
        }
    }

    private var captionColor: Color {
        switch status {
        case .opened:
            return TLTheme.green
        case .due:
            return TLTheme.orange
        case .soon:
            return TLTheme.orange.opacity(0.9)
        case .upcoming, .yesterday, .lastOpened, .notOpened:
            return TLTheme.categoryGray
        }
    }
}

struct OpeningRingMark: View {
    var color: Color

    private let startAngle: Double = 10
    private let endAngle: Double = 340
    private let markDiameter: CGFloat = 64
    private let strokeWidth: CGFloat = 5
    private let dotDiameter: CGFloat = 12

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let dotClearance = (dotDiameter + 4) / 2
            let radius = min(size.width, size.height) / 2 - max(strokeWidth / 2, dotClearance)
            let start = Angle.degrees(startAngle)
            let end = Angle.degrees(endAngle)

            var arc = Path()
            arc.addArc(
                center: center,
                radius: radius,
                startAngle: start,
                endAngle: end,
                clockwise: false
            )
            context.stroke(
                arc,
                with: .color(color),
                style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
            )

            let dotCenter = point(on: center, radius: radius, angleDegrees: endAngle)
            let outerDotRect = CGRect(
                x: dotCenter.x - (dotDiameter + 4) / 2,
                y: dotCenter.y - (dotDiameter + 4) / 2,
                width: dotDiameter + 4,
                height: dotDiameter + 4
            )
            let innerDotRect = CGRect(
                x: dotCenter.x - dotDiameter / 2,
                y: dotCenter.y - dotDiameter / 2,
                width: dotDiameter,
                height: dotDiameter
            )

            context.fill(Path(ellipseIn: outerDotRect), with: .color(TLTheme.cardBackground))
            context.fill(Path(ellipseIn: innerDotRect), with: .color(TLTheme.orange))
        }
        .frame(width: markDiameter, height: markDiameter)
        .padding(6)
        .background(TLTheme.cardBackground)
        .clipShape(Circle())
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private func point(on center: CGPoint, radius: CGFloat, angleDegrees: Double) -> CGPoint {
        let radians = angleDegrees * .pi / 180
        return CGPoint(
            x: center.x + cos(radians) * radius,
            y: center.y + sin(radians) * radius
        )
    }
}

struct StatusPill: View {
    var status: TodayBottleStatus

    var body: some View {
        Text(status.text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(status.foregroundColor)
            .background(status.backgroundColor)
            .clipShape(Capsule())
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

enum TodayBottleStatus {
    case opened(time: String)
    case due(time: String)
    case soon(time: String)
    case upcoming(time: String)
    case yesterday(time: String)
    case lastOpened(date: String)
    case notOpened

    var text: String {
        switch self {
        case let .opened(time): return "Opened \(time)"
        case let .due(time): return "Due \(time)"
        case let .soon(time): return "Soon \(time)"
        case let .upcoming(time): return "Upcoming \(time)"
        case let .yesterday(time): return "Yesterday \(time)"
        case let .lastOpened(date): return "Last \(date)"
        case .notOpened: return "Not opened"
        }
    }

    var foregroundColor: Color {
        switch self {
        case .opened: return TLTheme.green
        case .due: return TLTheme.orange
        case .soon: return TLTheme.orange.opacity(0.9)
        case .upcoming, .yesterday, .lastOpened, .notOpened: return TLTheme.categoryGray
        }
    }

    var backgroundColor: Color {
        switch self {
        case .opened: return TLTheme.green.opacity(0.12)
        case .due: return TLTheme.orange.opacity(0.16)
        case .soon: return TLTheme.orange.opacity(0.1)
        case .upcoming, .yesterday, .lastOpened, .notOpened: return TLTheme.categoryGray.opacity(0.14)
        }
    }

    var accentColor: Color {
        switch self {
        case .opened: return TLTheme.green
        case .due: return TLTheme.orange
        case .soon: return TLTheme.orange.opacity(0.9)
        case .upcoming, .yesterday, .lastOpened, .notOpened: return TLTheme.categoryGray
        }
    }
}

struct MultiRecordOpeningView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBottleIds: Set<UUID>
    @State private var recordedEvents: [OpeningEvent] = []
    @State private var showSuccess = false

    var currentDate: Date

    init(currentDate: Date) {
        self.currentDate = currentDate
        self._selectedBottleIds = State(initialValue: [])
    }

    var body: some View {
        NavigationStack {
            List {
                if showSuccess {
                    Section {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("\(recordedEvents.count) \(recordedEvents.count == 1 ? "opening" : "openings") recorded.", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundStyle(TLTheme.green)

                            Text("Your opening history was updated for the selected bottles.")
                                .font(.subheadline)
                                .foregroundStyle(TLTheme.gray)

                            HStack {
                                Button("Undo") {
                                    undoRecordedEvents()
                                }
                                .buttonStyle(.bordered)
                                .tint(TLTheme.green)

                                Spacer()

                                Button("Done") {
                                    dismiss()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(TLTheme.green)
                            }
                        }
                    }
                } else {
                    Section {
                        ForEach(store.activeBottles) { bottle in
                            Button {
                                toggleSelection(for: bottle)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedBottleIds.contains(bottle.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedBottleIds.contains(bottle.id) ? TLTheme.green : TLTheme.gray)
                                        .accessibilityHidden(true)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(bottle.nickname)
                                            .font(.headline)
                                            .foregroundStyle(TLTheme.text)

                                        if let medicationName = bottle.medicationName {
                                            Text(medicationName)
                                                .font(.subheadline)
                                                .foregroundStyle(TLTheme.gray)
                                        }

                                        Text(multiRecordSubtitle(for: bottle))
                                            .font(.caption)
                                            .foregroundStyle(TLTheme.gray)
                                    }

                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    } footer: {
                        Text("Select the bottles you opened together. TwistLog records opening events based on your input; it does not confirm medication was taken.")
                    }
                }
            }
            .navigationTitle("Record multiple")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Record") {
                        recordSelected()
                    }
                    .disabled(selectedBottleIds.isEmpty || showSuccess)
                }
            }
            .onAppear {
                if selectedBottleIds.isEmpty {
                    selectedBottleIds = Set(
                        store.activeBottles
                            .filter { !store.isBottleCompleteForCalendarDay(containing: currentDate, for: $0) }
                            .map(\.id)
                    )
                }
            }
        }
    }

    private func toggleSelection(for bottle: Bottle) {
        if selectedBottleIds.contains(bottle.id) {
            selectedBottleIds.remove(bottle.id)
        } else {
            selectedBottleIds.insert(bottle.id)
        }
    }

    private func recordSelected() {
        let selectedBottles = store.activeBottles.filter { selectedBottleIds.contains($0.id) }
        recordedEvents = selectedBottles.map { store.recordOpening(for: $0, now: Date()) }
        selectedBottleIds.removeAll()
        showSuccess = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func undoRecordedEvents() {
        recordedEvents.forEach { store.deleteOpening($0) }
        recordedEvents.removeAll()
        showSuccess = false
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    private func multiRecordSubtitle(for bottle: Bottle) -> String {
        if store.isBottleCompleteForCalendarDay(containing: currentDate, for: bottle) {
            return "Opened for today"
        }

        if let nextRequired = store.nextRequiredReminderDate(containing: currentDate, for: bottle) {
            let time = nextRequired.formatted(date: .omitted, time: .shortened)
            return nextRequired <= currentDate ? "Due \(time)" : "Next \(time)"
        }

        let reminders = bottle.enabledReminders.map(\.displayTime)
        guard !reminders.isEmpty else { return "No reminder set" }
        return reminders.joined(separator: ", ")
    }
}

struct LateOpeningRequest: Identifiable {
    let id = UUID()
    var title: String
    var initialDate: Date
    var allowsDateSelection: Bool

    static func earlierToday(referenceDate: Date) -> LateOpeningRequest {
        LateOpeningRequest(
            title: "Earlier today",
            initialDate: Calendar.current.date(byAdding: .hour, value: -1, to: referenceDate) ?? referenceDate,
            allowsDateSelection: false
        )
    }

    static func yesterday(referenceDate: Date) -> LateOpeningRequest {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate) ?? referenceDate
        let initialDate = calendar.date(
            bySettingHour: calendar.component(.hour, from: referenceDate),
            minute: calendar.component(.minute, from: referenceDate),
            second: 0,
            of: yesterday
        ) ?? yesterday

        return LateOpeningRequest(
            title: "Yesterday",
            initialDate: initialDate,
            allowsDateSelection: true
        )
    }
}

struct LateOpeningSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var openedAt: Date

    var request: LateOpeningRequest
    var onRecord: (Date) -> Void

    init(request: LateOpeningRequest, onRecord: @escaping (Date) -> Void) {
        self.request = request
        self.onRecord = onRecord
        self._openedAt = State(initialValue: request.initialDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Opening time",
                        selection: $openedAt,
                        in: ...Date(),
                        displayedComponents: displayedComponents
                    )
                } footer: {
                    Text("Use this when the bottle was opened earlier, but you forgot to record it at the time.")
                }
            }
            .navigationTitle(request.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Record") {
                        onRecord(openedAt)
                        dismiss()
                    }
                }
            }
        }
    }

    private var displayedComponents: DatePickerComponents {
        request.allowsDateSelection ? [.date, .hourAndMinute] : [.hourAndMinute]
    }
}
