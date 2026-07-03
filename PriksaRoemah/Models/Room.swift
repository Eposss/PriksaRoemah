import Foundation

struct Room: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var type: RoomType
    var floor: String          // "1", "2", dst
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
