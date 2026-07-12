import Foundation

struct Room: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var type: RoomType

    /// Dimensi ruangan dari bounding box hasil RoomPlan (mis. "3 x 4 m").
    /// 0 kalau belum ke-compute (mis. data dummy).
    var widthM: Double = 0
    var lengthM: Double = 0

    /// Titik tengah ruangan (bounding box) di koordinat 2D yang SAMA dengan
    /// Floor.wallSegments — dipakai buat naruh label nama+ukuran di atas denah
    /// (FloorPlan2DView). 0,0 kalau belum ke-compute.
    var centerXM: Double = 0
    var centerYM: Double = 0

    var formattedDimensions: String {
        guard widthM > 0, lengthM > 0 else { return "– x – m" }
        return String(format: "%.0f x %.0f m", widthM, lengthM)
    }
}

enum RoomType: String, CaseIterable, Identifiable {
    case livingRoom  = "Living Room"
    case bedroom     = "Bedroom"
    case kitchen     = "Kitchen"
    case bathroom    = "Bathroom"
    case diningRoom  = "Dining Room"
    case garage      = "Garage"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .livingRoom:  return "sofa.fill"
        case .bedroom:     return "bed.double.fill"
        case .kitchen:     return "fork.knife"
        case .bathroom:    return "shower.fill"
        case .diningRoom:  return "table.furniture"
        case .garage:      return "car.fill"
        }
    }
}
