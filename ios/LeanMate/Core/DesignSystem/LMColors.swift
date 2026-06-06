import SwiftUI

enum LMColors {
    static let background = Color(hex: 0xF7FBF6)
    static let card = Color.white
    static let textPrimary = Color(hex: 0x183326)
    static let textBody = Color(hex: 0x1F241F)
    static let textSecondary = Color(hex: 0x6F8074)
    static let textMuted = Color(hex: 0x9AA79D)
    static let primary = Color(hex: 0x48B878)
    static let primaryDeep = Color(hex: 0x23965B)
    static let primarySoft = Color(hex: 0xEAF8EF)
    static let primaryBorder = Color(hex: 0xBEE6CC)
    static let border = Color(hex: 0xDDEBDD)
    static let inputBorder = Color(hex: 0xE9E2D6)
    static let warmSurface = Color(hex: 0xFAF7F1)
    static let warmMuted = Color(hex: 0xF4F1EA)
    static let danger = Color(hex: 0xD94A36)
    static let dangerSoft = Color(hex: 0xFFF0EE)
    static let cameraSurface = Color(hex: 0x26342D)
    static let sheetHandle = Color(hex: 0xC9D8CD)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
