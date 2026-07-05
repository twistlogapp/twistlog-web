import SwiftUI
import UIKit

enum TLTheme {
    static let green = Color(red: 14 / 255, green: 107 / 255, blue: 79 / 255)
    static let orange = Color(red: 255 / 255, green: 159 / 255, blue: 28 / 255)
    static let text = Color.primary
    static let gray = Color.secondary
    static let lightGray = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let selectedChipText = Color.white
}

struct OrangeEventDot: View {
    var size: CGFloat = 9

    var body: some View {
        Circle()
            .fill(TLTheme.orange)
            .frame(width: size, height: size)
            .accessibilityLabel("Opening recorded")
            .accessibilityAddTraits(.isImage)
    }
}
