import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var step = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            eyebrow: "Step 1",
            title: "Add a bottle.",
            body: "Create a simple record for each bottle you want to track.",
            buttonTitle: "Continue"
        ),
        OnboardingPage(
            eyebrow: "Step 2",
            title: "Record openings.",
            body: "Tap Opened now when the bottle is opened. TwistLog records opening events, not dose confirmation.",
            buttonTitle: "Continue"
        ),
        OnboardingPage(
            eyebrow: "Step 3",
            title: "Use reminders.",
            body: "Set reminder nudges to check a bottle and review recent openings.",
            buttonTitle: "Continue"
        ),
        OnboardingPage(
            eyebrow: "Step 4",
            title: "Review opening history.",
            body: "Use your history for personal reference. TwistLog does not confirm medication was taken and is not medical advice.",
            buttonTitle: "I understand"
        )
    ]

    var body: some View {
        let page = pages[step]

        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            OrangeEventDot(size: 16)
                .accessibilityHidden(true)

            Text(page.eyebrow)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TLTheme.green)

            Text(page.title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(TLTheme.text)
                .minimumScaleFactor(0.85)

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
            .accessibilityLabel(page.buttonTitle)
        }
        .padding(24)
    }
}

private struct OnboardingPage {
    var eyebrow: String
    var title: String
    var body: String
    var buttonTitle: String
}
