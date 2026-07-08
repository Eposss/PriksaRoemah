import Foundation

struct House: Identifiable, Hashable {
    let id = UUID()

    var name: String
    var developer: String
    var harga: String
    var luasTanah: String
    var catatan: String

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
