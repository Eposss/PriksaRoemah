import Foundation

struct House: Identifiable, Hashable {
    let id = UUID()

    var name: String
    var developer: String
    var harga: String
    var luasTanah: String
    var catatan: String
    var createdAt: Date = Date()

    var rooms: [Room]

    // RoomPlan Result
    var usdzURL: URL?
    var wallSegments: [WallSegment2D] = []

    // Metrics
    var floorAreaSqM: Double
    var wallAreaSqM: Double
    var ceilingHeightM: Double

    // MARK: - Computed Properties

    var roomCount: Int {
        rooms.count
    }

    var bedroomCount: Int {
        rooms.filter { $0.type == .bedroom }.count
    }

    var bathroomCount: Int {
        rooms.filter { $0.type == .bathroom }.count
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: createdAt)
    }

    /// Building/floor tags share this since the model doesn't distinguish
    /// building footprint from floor area yet.
    var formattedAreaTag: String {
        floorAreaSqM > 0 ? String(format: "%.0fm²", floorAreaSqM) : "–m²"
    }

    var formattedPriceShort: String {
        let digitsOnly = harga.filter(\.isNumber)
        guard let value = Double(digitsOnly), value > 0 else { return "Rp \(harga)" }
        if value >= 1_000_000_000 {
            return String(format: "Rp %.1f M", value / 1_000_000_000)
        }
        return String(format: "Rp %.1f Jt", value / 1_000_000)
    }

    var formattedFloorArea: String {
        floorAreaSqM > 0
        ? String(format: "%.2f m²", floorAreaSqM)
        : "– m²"
    }

    var formattedWallArea: String {
        wallAreaSqM > 0
        ? String(format: "%.2f m²", wallAreaSqM)
        : "– m²"
    }

    var formattedCeiling: String {
        ceilingHeightM > 0
        ? String(format: "%.1f m", ceilingHeightM)
        : "– m"
    }
}
