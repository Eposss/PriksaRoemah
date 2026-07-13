import Foundation

/// Arah hadap rumah — 8 arah mata angin, sesuai mockup ("NE facing", dst).
enum HouseFacing: String, CaseIterable, Identifiable {
    case north     = "N"
    case northEast = "NE"
    case east      = "E"
    case southEast = "SE"
    case south     = "S"
    case southWest = "SW"
    case west      = "W"
    case northWest = "NW"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .north:     return "North"
        case .northEast: return "Northeast (NE)"
        case .east:      return "East"
        case .southEast: return "Southeast (SE)"
        case .south:     return "South"
        case .southWest: return "Southwest (SW)"
        case .west:      return "West"
        case .northWest: return "Northwest (NW)"
        }
    }

    /// Konversi heading compass (0-360°, 0 = True North) ke arah 8-mata-angin terdekat.
    /// Urutan `allCases` (N, NE, E, SE, S, SW, W, NW) sudah sesuai urutan compass.
    static func nearest(toDegrees degrees: Double) -> HouseFacing {
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        let index = Int((positive / 45).rounded()) % 8
        return allCases[index]
    }
}

struct House: Identifiable, Hashable {
    let id = UUID()

    var name: String
    var developer: String
    var harga: String
    var luasTanah: String
    var catatan: String
    var createdAt: Date = Date()

    /// Otomatis terdeteksi dari compass (heading device) saat lantai pertama selesai
    /// discan — lihat CompassService & SurveySession. Tidak ada input manual lagi.
    var facing: HouseFacing?

    /// Semua foto dokumentasi rumah ini, ditag per RoomType, gabungan seluruh lantai.
    /// Ini yang muncul di halaman "Documentation" (dikelompokkan per RoomType).
    var documentationPhotos: [DocumentationPhoto] = []

    /// Satu House = satu rumah, bisa punya banyak Floor (Floor 1, Floor 2, dst).
    /// Setiap Floor punya rooms + denah + 3D + metrics + catatan sendiri-sendiri —
    /// lihat Floor.swift.
    var floors: [Floor]

    /// Dikelompokkan per RoomType, hanya kategori yang punya minimal 1 foto,
    /// urutan mengikuti RoomType.allCases.
    var documentationByRoomType: [(type: RoomType, photos: [DocumentationPhoto])] {
        RoomType.allCases.compactMap { type in
            let photos = documentationPhotos.filter { $0.roomType == type }
            return photos.isEmpty ? nil : (type, photos)
        }
    }

    // MARK: - Aggregate computed properties
    // Dipakai di list card (HouseCard) & tempat lain yang butuh angka
    // ringkasan seluruh rumah, bukan per lantai.

    var roomCount: Int {
        floors.reduce(0) { $0 + $1.roomCount }
    }

    /// Jumlah kamar tidur & kamar mandi digabung dari semua lantai — dipakai
    /// di HouseCard (ikon bed / shower).
    var bedroomCount: Int {
        floors.reduce(0) { $0 + $1.rooms.filter { $0.type == .bedroom }.count }
    }
    var bathroomCount: Int {
        floors.reduce(0) { $0 + $1.rooms.filter { $0.type == .bathroom }.count }
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: createdAt)
    }

    /// Tag luas ringkas ("140m²") buat kartu koleksi.
    var formattedAreaTag: String {
        floorAreaSqM > 0 ? String(format: "%.0fm²", floorAreaSqM) : "–m²"
    }

    /// Harga ringkas: "Rp 1.8 M" / "Rp 999.9 Jt". Tahan input yang sudah
    /// mengandung pemisah ribuan ("1.800.000.000") karena hanya baca digit-nya.
    var formattedPriceShort: String {
        let digitsOnly = harga.filter(\.isNumber)
        guard let value = Double(digitsOnly), value > 0 else { return "Rp \(harga)" }
        if value >= 1_000_000_000 {
            return String(format: "Rp %.1f M", value / 1_000_000_000)
        }
        return String(format: "Rp %.1f Jt", value / 1_000_000)
    }

    var floorAreaSqM: Double {
        floors.reduce(0) { $0 + $1.floorAreaSqM }
    }

    var wallAreaSqM: Double {
        floors.reduce(0) { $0 + $1.wallAreaSqM }
    }

    /// Tinggi plafon dianggap sama tiap lantai secara umum — ambil yang tertinggi
    /// untuk representasi ringkas (bukan dijumlah, beda konteks dari area).
    var ceilingHeightM: Double {
        floors.map(\.ceilingHeightM).max() ?? 0
    }

    var floorCount: Int { floors.count }

    var formattedFloorArea: String {
        floorAreaSqM > 0 ? String(format: "%.2f m²", floorAreaSqM) : "– m²"
    }
    var formattedWallArea: String {
        wallAreaSqM > 0 ? String(format: "%.2f m²", wallAreaSqM) : "– m²"
    }
    var formattedCeiling: String {
        ceilingHeightM > 0 ? String(format: "%.1f m", ceilingHeightM) : "– m"
    }
}
