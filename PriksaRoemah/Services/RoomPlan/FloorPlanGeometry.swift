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

/// Jenis bukaan di dinding — dipakai buat gambar simbol beda di denah 2D
/// (pintu = busur ayun, jendela = garis tipis). User TIDAK butuh ukuran
/// lebarnya, cukup tau ini pintu atau jendela.
enum OpeningKind: Hashable {
    case door
    case window
    case opening
}

/// Satu bukaan (pintu/jendela/opening) diproyeksikan jadi garis 2D di bidang
/// (x, z) — sama koordinat dengan WallSegment2D, jadi bisa digambar barengan.
struct Opening2D: Hashable {
    var segment: WallSegment2D
    var kind: OpeningKind
}

/// Rotasi buat "meluruskan" denah supaya dinding dominan sejajar sumbu layar
/// (bukan miring ngikutin orientasi ARSession waktu mulai scan). Diputar di
/// sekitar `pivot` (pusat denah) supaya posisinya nggak geser.
struct PlanTransform {
    var angle: CGFloat        // radian
    var pivot: CGPoint

    func apply(_ p: CGPoint) -> CGPoint {
        let c = cos(angle), s = sin(angle)
        let dx = p.x - pivot.x, dy = p.y - pivot.y
        return CGPoint(x: pivot.x + dx * c - dy * s,
                       y: pivot.y + dx * s + dy * c)
    }

    func apply(_ seg: WallSegment2D) -> WallSegment2D {
        WallSegment2D(start: apply(seg.start), end: apply(seg.end))
    }
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

    /// Bukaan (pintu/jendela/opening) dari satu CapturedRoom.
    static func openings(from room: CapturedRoom) -> [Opening2D] {
        room.doors.map   { Opening2D(segment: segment(for: $0), kind: .door) }
      + room.windows.map { Opening2D(segment: segment(for: $0), kind: .window) }
      + room.openings.map { Opening2D(segment: segment(for: $0), kind: .opening) }
    }

    /// Bukaan gabungan dari seluruh lantai (hasil StructureBuilder).
    static func openings(from structure: CapturedStructure) -> [Opening2D] {
        structure.doors.map   { Opening2D(segment: segment(for: $0), kind: .door) }
      + structure.windows.map { Opening2D(segment: segment(for: $0), kind: .window) }
      + structure.openings.map { Opening2D(segment: segment(for: $0), kind: .opening) }
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

    /// Hitung rotasi buat meluruskan denah: ambil dinding TERPANJANG, lipat
    /// sudutnya ke kelipatan 90° terdekat, lalu putar balik sebesar deviasinya
    /// — jadi dinding utama nempel ke sumbu horizontal/vertikal & denah nggak
    /// miring. Diputar di sekitar pusat bounding box biar posisi tetap.
    static func normalization(for segments: [WallSegment2D]) -> PlanTransform {
        let b = bounds(of: segments)
        let pivot = CGPoint(x: b.midX, y: b.midY)
        guard !segments.isEmpty else { return PlanTransform(angle: 0, pivot: pivot) }

        var longest: (len: CGFloat, angle: CGFloat) = (0, 0)
        for s in segments {
            let dx = s.end.x - s.start.x, dy = s.end.y - s.start.y
            let len = hypot(dx, dy)
            if len > longest.len { longest = (len, atan2(dy, dx)) }
        }
        let quarter = CGFloat.pi / 2
        let deviation = longest.angle - (longest.angle / quarter).rounded() * quarter
        return PlanTransform(angle: -deviation, pivot: pivot)
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
