//
//  FloorPlanGeometry.swift
//  HVMAN
//
//  Proyeksi top-down (bidang X-Z) dari dinding hasil RoomPlan,
//  dipakai untuk menggambar denah 2D asli (bukan grid placeholder).
//

import Foundation
import RoomPlan
import simd
import CoreGraphics

struct WallSegment2D: Hashable {
    var start: CGPoint
    var end: CGPoint
}

enum FloorPlanGeometry {

    /// Dinding dari satu CapturedRoom (dipakai kalau StructureBuilder gagal / cuma 1 ruangan)
    static func wallSegments(from room: CapturedRoom) -> [WallSegment2D] {
        room.walls.map(segment(for:))
    }

    /// Dinding gabungan dari seluruh rumah (hasil StructureBuilder, sudah di-dedupe oleh RoomPlan)
    static func wallSegments(from structure: CapturedStructure) -> [WallSegment2D] {
        structure.walls.map(segment(for:))
    }

    /// Ubah satu Surface dinding jadi garis 2D: pusat dinding ± setengah lebar
    /// di sepanjang sumbu-X lokal dinding, diproyeksikan ke bidang (x, z).
    private static func segment(for wall: CapturedRoom.Surface) -> WallSegment2D {
        let t = wall.transform
        let center = SIMD3<Float>(t.columns.3.x, t.columns.3.y, t.columns.3.z)
        let xAxis  = SIMD3<Float>(t.columns.0.x, t.columns.0.y, t.columns.0.z)
        let halfWidth = wall.dimensions.x / 2
        let p1 = center - xAxis * halfWidth
        let p2 = center + xAxis * halfWidth
        return WallSegment2D(
            start: CGPoint(x: Double(p1.x), y: Double(p1.z)),
            end:   CGPoint(x: Double(p2.x), y: Double(p2.z))
        )
    }

    /// Bounding box semua segment — dipakai buat auto-fit scale saat digambar
    static func bounds(of segments: [WallSegment2D]) -> CGRect {
        guard !segments.isEmpty else { return .zero }
        var minX = CGFloat.greatestFiniteMagnitude, maxX = -CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude, maxY = -CGFloat.greatestFiniteMagnitude
        for s in segments {
            for p in [s.start, s.end] {
                minX = min(minX, p.x); maxX = max(maxX, p.x)
                minY = min(minY, p.y); maxY = max(maxY, p.y)
            }
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
