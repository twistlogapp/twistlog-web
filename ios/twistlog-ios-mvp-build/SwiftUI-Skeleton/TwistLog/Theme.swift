import SwiftUI

enum TLTheme {
    static let green = Color(red: 14 / 255, green: 107 / 255, blue: 79 / 255)
    static let orange = Color(red: 255 / 255, green: 159 / 255, blue: 28 / 255)
    static let text = Color(red: 17 / 255, green: 24 / 255, blue: 28 / 255)
    static let gray = Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255)
    static let lightGray = Color(red: 242 / 255, green: 244 / 255, blue: 247 / 255)
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
