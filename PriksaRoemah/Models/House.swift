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

    // Hasil RoomPlan (StructureBuilder) — dipakai untuk render 2D & 3D asli
    var usdzURL: URL?
    var wallSegments: [WallSegment2D] = []

    // AI Report gabungan dari semua ruangan (Property Dashboard / Survey Report)
    var overallReport: AIReport?

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

extension House {
    static let dummyAll: [House] = [
        House(
            name: "Cluster Magnolia",
            developer: "HVMAN Property",
            harga: "1.800.000.000",
            luasTanah: "90",
            catatan: "Rumah contoh untuk pratinjau survey.",
            rooms: [
                Room(name: "Living Room", type: .livingRoom, floor: "1", aiReport: nil),
                Room(name: "Bedroom", type: .bedroom, floor: "1", aiReport: nil),
                Room(name: "Kitchen", type: .kitchen, floor: "1", aiReport: nil)
            ],
            floorAreaSqM: 72,
            wallAreaSqM: 148,
            ceilingHeightM: 3,
            overallReport: AIReport(
                conditionScore: 86,
                priority: .low,
                summary: "Kondisi rumah terlihat baik dengan catatan minor pada beberapa area.",
                recommendation: ["Lakukan pengecekan ulang sebelum serah terima."],
                detections: []
            )
        ),
        House(
            name: "The Avani Residence",
            developer: "HVMAN Property",
            harga: "2.450.000.000",
            luasTanah: "120",
            catatan: "Unit dummy untuk dashboard dan report preview.",
            rooms: [
                Room(name: "Living Room", type: .livingRoom, floor: "1", aiReport: nil),
                Room(name: "Bedroom", type: .bedroom, floor: "2", aiReport: nil),
                Room(name: "Bathroom", type: .bathroom, floor: "2", aiReport: nil),
                Room(name: "Garage", type: .garage, floor: "1", aiReport: nil)
            ],
            floorAreaSqM: 96,
            wallAreaSqM: 184,
            ceilingHeightM: 3.2,
            overallReport: AIReport(
                conditionScore: 74,
                priority: .medium,
                summary: "Ada beberapa area yang perlu ditinjau sebelum finalisasi laporan.",
                recommendation: ["Prioritaskan inspeksi area basah dan sambungan dinding."],
                detections: []
            )
        )
    ]
}
