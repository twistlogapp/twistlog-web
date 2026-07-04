import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var step = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Know when the bottle was opened.",
            body: "Manual log or NFC tap today. Sensor ring detection is in prototype.",
            buttonTitle: "Continue"
        ),
        OnboardingPage(
            title: "Opening events, not dose confirmation.",
            body: "TwistLog records bottle-opening events for personal reference and reminders. It does not verify that medicine was taken and is not medical advice.",
            buttonTitle: "I understand"
        ),
        OnboardingPage(
            title: "Get reminder nudges.",
            body: "TwistLog can remind you to check a bottle and record an opening.",
            buttonTitle: "Continue"
        )
    ]

    var body: some View {
        let page = pages[step]

        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            OrangeEventDot(size: 16)

            Text(page.title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(TLTheme.text)

            Text(page.body)
                .font(.body)
                .foregroundStyle(TLTheme.gray)
                .lineSpacing(4)

            Spacer()

            Button {
                if step < pages.count - 1 {
                    step += 1
                } else {
                    store.hasCompletedOnboarding = true
                }
            } label: {
                Text(page.buttonTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(TLTheme.green)
            .controlSize(.large)
        }
        .padding(24)
    }
}

private struct OnboardingPage {
    var title: String
    var body: String
    var buttonTitle: String
}

