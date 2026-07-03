import Foundation

struct House: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String          // Nama Cluster
    var developer: String
    var harga: String         // "1.800.000.000"
    var luasTanah: String     // "90" (m²)
    var catatan: String
    var rooms: [Room]
    var floorAreaSqM: Double
    var wallAreaSqM: Double
    var ceilingHeightM: Double

    var formattedFloorArea: String {
        floorAreaSqM > 0 ? String(format: "%.2f m²", floorAreaSqM) : "– m²"
    }
    var formattedWallArea: String {
        wallAreaSqM > 0 ? String(format: "%.2f m²", wallAreaSqM) : "– m²"
    }
    var formattedCeiling: String {
        ceilingHeightM > 0 ? String(format: "%.1f m", ceilingHeightM) : "– m"
    }
    var roomCount: Int { rooms.count }
}
