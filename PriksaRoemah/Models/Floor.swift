//
//  Floor.swift
//  PriksaRoemah
//
//  Created by Ignasius Holy Prasetya on 08/07/26.

import Foundation

/// Satu lantai hasil scan. 1 sesi scan RoomPlan (beberapa ruangan, StructureBuilder
/// digabung) menghasilkan 1 Floor. Satu House bisa punya banyak Floor.
struct Floor: Identifiable, Hashable {
    let id = UUID()

    /// "Floor 1", "Floor 2", dst — atau nama custom kalau user mau ganti nanti.
    var label: String

    var rooms: [Room]

    // Hasil RoomPlan (StructureBuilder) khusus lantai ini
    var usdzURL: URL?
    var wallSegments: [WallSegment2D] = []

    /// Pintu/jendela/opening lantai ini, buat digambar di denah 2D.
    var openings: [Opening2D] = []

    // Metrics khusus lantai ini
    var floorAreaSqM: Double
    var wallAreaSqM: Double
    var ceilingHeightM: Double

    /// Catatan bebas soal kondisi lantai ini (mis. "Bahan bangunan: bata merah").
    /// Foto dokumentasi TIDAK di sini lagi — pindah ke House.documentationPhotos,
    /// karena ditag per RoomType dan berlaku untuk seluruh rumah, bukan per lantai.
    var notes: String = ""

    var roomCount: Int { rooms.count }

    var bedrooms: [Room] { rooms.filter { $0.type == .bedroom } }
    var bathrooms: [Room] { rooms.filter { $0.type == .bathroom } }
    var otherRooms: [Room] { rooms.filter { $0.type != .bedroom && $0.type != .bathroom } }

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
