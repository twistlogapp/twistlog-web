import SwiftUI
import UIKit

enum TLTheme {
    static let green = Color(red: 14 / 255, green: 107 / 255, blue: 79 / 255)
    static let orange = Color(red: 255 / 255, green: 159 / 255, blue: 28 / 255)
    static let purple = Color(red: 139 / 255, green: 92 / 255, blue: 246 / 255)
    static let blue = Color(red: 37 / 255, green: 99 / 255, blue: 235 / 255)
    static let categoryGray = Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255)
    static let text = Color.primary
    static let gray = Color.secondary
    static let lightGray = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let selectedChipText = Color.white
}

extension BottleCategory {
    var accentColor: Color {
        switch self {
        case .prescription: return TLTheme.green
        case .supplement: return TLTheme.purple
        case .water: return TLTheme.blue
        case .other: return TLTheme.categoryGray
        }
    }
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
