import SwiftUI

extension Color {
    /// Inisialisasi dari hex string "RRGGBB" (dipakai buat warna brand dari Figma
    /// yang nggak ada padanan system color-nya, mis. oranye Huni #E55616).
    init(hex: String) {
        var hexValue = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexValue.removeAll { $0 == "#" }
        var rgb: UInt64 = 0
        Scanner(string: hexValue).scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue:  Double(rgb & 0xFF) / 255
        )
    }
}
