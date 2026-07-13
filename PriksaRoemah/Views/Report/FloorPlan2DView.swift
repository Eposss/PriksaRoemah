//
//  FloorPlan2DView.swift
//  HVMAN
//
//  Denah 2D asli, digambar dari wall segments hasil RoomPlan (bukan grid ikon).
//

import SwiftUI

struct FloorPlan2DView: View {
    let wallSegments: [WallSegment2D]

    /// Kalau diisi, tiap ruangan yang punya dimensi valid (widthM/lengthM > 0)
    /// dilabelin nama + ukurannya langsung di atas denah (bukan cuma garis
    /// outline polos) — dipakai di preview besar (Review Scan, Report). Default
    /// kosong buat thumbnail kecil (grid Floors) yang nggak muat teks.
    var rooms: [Room] = []

    /// Pintu/jendela buat digambar sebagai simbol beda di atas denah.
    var openings: [Opening2D] = []

    /// Tampilkan garis ukuran keseluruhan (lebar × panjang lantai, meter) di
    /// pinggir denah. Dimatikan buat thumbnail kecil.
    var showDimensions: Bool = false

    private let doorColor  = Color(red: 0.910, green: 0.349, blue: 0.090)
    private let windowColor = Color(red: 0, green: 0.478, blue: 1)
    private let backgroundGray = Color(.systemGray6)

    private var padding: CGFloat { showDimensions ? 44 : 24 }

    var body: some View {
        Group {
            if wallSegments.isEmpty {
                emptyState
            } else {
                GeometryReader { geo in
                    let bounds = FloorPlanGeometry.bounds(of: wallSegments)
                    let layout = projection(for: bounds, in: geo.size)

                    ZStack {
                        Canvas { context, _ in
                            guard let layout else { return }
                            drawWalls(in: &context, layout: layout)
                            drawOpenings(in: &context, layout: layout)
                            if showDimensions {
                                drawDimensions(in: &context, layout: layout, bounds: bounds)
                            }
                        }

                        if let layout {
                            ForEach(rooms.filter { $0.widthM > 0 && $0.lengthM > 0 }) { room in
                                VStack(spacing: 1) {
                                    Text(room.name.uppercased())
                                    Text(room.formattedDimensions)
                                }
                                .font(.system(size: 9, weight: .semibold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.primary)
                                .fixedSize()
                                .position(layout.project(CGPoint(x: CGFloat(room.centerXM), y: CGFloat(room.centerYM))))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(backgroundGray)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray3), lineWidth: 2))
    }

    // MARK: - Canvas drawing

    private func drawWalls(in context: inout GraphicsContext, layout: Projection) {
        var path = Path()
        for wall in wallSegments {
            path.move(to: layout.project(wall.start))
            path.addLine(to: layout.project(wall.end))
        }
        context.stroke(path, with: .color(.primary), style: StrokeStyle(lineWidth: 4, lineCap: .round))
    }

    /// Gambar tiap bukaan di atas dinding: dulu "hapus" dindingnya (garis warna
    /// background) biar keliatan bolong, terus tambahin simbol — pintu = busur
    /// ayun, jendela = garis tipis warna beda, opening = dibiarin bolong.
    private func drawOpenings(in context: inout GraphicsContext, layout: Projection) {
        let center = wallsCentroid(layout: layout)
        for opening in openings {
            let p1 = layout.project(opening.segment.start)
            let p2 = layout.project(opening.segment.end)

            // Hapus dinding di posisi bukaan (bikin gap).
            var gap = Path()
            gap.move(to: p1)
            gap.addLine(to: p2)
            context.stroke(gap, with: .color(backgroundGray), style: StrokeStyle(lineWidth: 7, lineCap: .butt))

            switch opening.kind {
            case .door:  drawDoor(in: &context, p1: p1, p2: p2, interior: center)
            case .window: drawWindow(in: &context, p1: p1, p2: p2)
            case .opening: break   // dibiarin bolong aja
            }
        }
    }

    private func drawDoor(in context: inout GraphicsContext, p1: CGPoint, p2: CGPoint, interior: CGPoint) {
        let dx = p2.x - p1.x, dy = p2.y - p1.y
        let w = max(1, hypot(dx, dy))
        // Perpendicular ke arah interior (centroid denah).
        var n = CGPoint(x: -dy / w, y: dx / w)
        let mid = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
        if (n.x * (interior.x - mid.x) + n.y * (interior.y - mid.y)) < 0 {
            n = CGPoint(x: -n.x, y: -n.y)
        }
        let leafEnd = CGPoint(x: p1.x + n.x * w, y: p1.y + n.y * w)

        // Daun pintu (garis dari engsel ke posisi terbuka) + busur ayun.
        var leaf = Path()
        leaf.move(to: p1)
        leaf.addLine(to: leafEnd)
        context.stroke(leaf, with: .color(doorColor), style: StrokeStyle(lineWidth: 2, lineCap: .round))

        let a1 = atan2(p2.y - p1.y, p2.x - p1.x)
        let a2 = atan2(leafEnd.y - p1.y, leafEnd.x - p1.x)
        var arc = Path()
        arc.addArc(center: p1, radius: w,
                   startAngle: .radians(a1), endAngle: .radians(a2),
                   clockwise: shouldDrawClockwise(from: a1, to: a2))
        context.stroke(arc, with: .color(doorColor.opacity(0.6)),
                       style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
    }

    /// Pilih arah busur yang sweep-nya minimal (90°), bukan yang muter jauh.
    private func shouldDrawClockwise(from a1: CGFloat, to a2: CGFloat) -> Bool {
        var diff = a2 - a1
        while diff <= -.pi { diff += 2 * .pi }
        while diff > .pi { diff -= 2 * .pi }
        return diff < 0
    }

    private func drawWindow(in context: inout GraphicsContext, p1: CGPoint, p2: CGPoint) {
        var line = Path()
        line.move(to: p1)
        line.addLine(to: p2)
        context.stroke(line, with: .color(windowColor), style: StrokeStyle(lineWidth: 3, lineCap: .butt))
    }

    private func wallsCentroid(layout: Projection) -> CGPoint {
        var sx: CGFloat = 0, sy: CGFloat = 0, n: CGFloat = 0
        for wall in wallSegments {
            for p in [layout.project(wall.start), layout.project(wall.end)] {
                sx += p.x; sy += p.y; n += 1
            }
        }
        guard n > 0 else { return .zero }
        return CGPoint(x: sx / n, y: sy / n)
    }

    /// Garis ukuran keseluruhan: lebar di atas denah, panjang di kiri denah.
    private func drawDimensions(in context: inout GraphicsContext, layout: Projection, bounds: CGRect) {
        let topLeft     = layout.project(CGPoint(x: bounds.minX, y: bounds.minY))
        let topRight    = layout.project(CGPoint(x: bounds.maxX, y: bounds.minY))
        let bottomLeft  = layout.project(CGPoint(x: bounds.minX, y: bounds.maxY))

        let gap: CGFloat = 22
        let tick: CGFloat = 5

        // --- Lebar (atas) ---
        let topY = min(topLeft.y, topRight.y) - gap
        var wLine = Path()
        wLine.move(to: CGPoint(x: topLeft.x, y: topY))
        wLine.addLine(to: CGPoint(x: topRight.x, y: topY))
        // Tick di ujung
        for x in [topLeft.x, topRight.x] {
            wLine.move(to: CGPoint(x: x, y: topY - tick))
            wLine.addLine(to: CGPoint(x: x, y: topY + tick))
        }
        context.stroke(wLine, with: .color(.secondary), style: StrokeStyle(lineWidth: 1))
        context.draw(
            Text(String(format: "%.2f m", bounds.width)).font(.system(size: 10, weight: .semibold)).foregroundColor(.secondary),
            at: CGPoint(x: (topLeft.x + topRight.x) / 2, y: topY - 8)
        )

        // --- Panjang (kiri) ---
        let leftX = min(topLeft.x, bottomLeft.x) - gap
        var hLine = Path()
        hLine.move(to: CGPoint(x: leftX, y: topLeft.y))
        hLine.addLine(to: CGPoint(x: leftX, y: bottomLeft.y))
        for y in [topLeft.y, bottomLeft.y] {
            hLine.move(to: CGPoint(x: leftX - tick, y: y))
            hLine.addLine(to: CGPoint(x: leftX + tick, y: y))
        }
        context.stroke(hLine, with: .color(.secondary), style: StrokeStyle(lineWidth: 1))
        context.draw(
            Text(String(format: "%.2f m", bounds.height)).font(.system(size: 10, weight: .semibold)).foregroundColor(.secondary),
            at: CGPoint(x: leftX - 4, y: (topLeft.y + bottomLeft.y) / 2),
            anchor: .center
        )
    }

    /// Transform dari koordinat dunia (meter) ke titik layar, sama-sama dipakai
    /// buat gambar garis dinding (Canvas) dan naruh label ruangan (Text overlay)
    /// supaya selalu selaras satu sama lain.
    private struct Projection {
        let scale: CGFloat
        let offsetX: CGFloat
        let offsetY: CGFloat
        let minX: CGFloat
        let minY: CGFloat

        func project(_ p: CGPoint) -> CGPoint {
            CGPoint(x: (p.x - minX) * scale + offsetX, y: (p.y - minY) * scale + offsetY)
        }
    }

    private func projection(for bounds: CGRect, in size: CGSize) -> Projection? {
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let availableW = size.width  - padding * 2
        let availableH = size.height - padding * 2
        let scale = min(availableW / bounds.width, availableH / bounds.height)
        let offsetX = padding + (availableW - bounds.width  * scale) / 2
        let offsetY = padding + (availableH - bounds.height * scale) / 2
        return Projection(scale: scale, offsetX: offsetX, offsetY: offsetY, minX: bounds.minX, minY: bounds.minY)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.dashed")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("Belum ada denah — scan minimal 1 ruangan.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
    }
}

private struct FloorPlan2DPreview: View {
    var body: some View {
        let walls: [WallSegment2D] = [
            WallSegment2D(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 6, y: 0)),
            WallSegment2D(start: CGPoint(x: 6, y: 0), end: CGPoint(x: 6, y: 4)),
            WallSegment2D(start: CGPoint(x: 6, y: 4), end: CGPoint(x: 0, y: 4)),
            WallSegment2D(start: CGPoint(x: 0, y: 4), end: CGPoint(x: 0, y: 0)),
            WallSegment2D(start: CGPoint(x: 3, y: 0), end: CGPoint(x: 3, y: 4)),
        ]
        let rooms: [Room] = [
            Room(name: "Bedroom", type: .bedroom, widthM: 3, lengthM: 4, centerXM: 1.5, centerYM: 2),
            Room(name: "Kitchen", type: .kitchen, widthM: 3, lengthM: 4, centerXM: 4.5, centerYM: 2),
        ]
        let openings: [Opening2D] = [
            Opening2D(segment: WallSegment2D(start: CGPoint(x: 3, y: 1.2), end: CGPoint(x: 3, y: 2.2)), kind: .door),
            Opening2D(segment: WallSegment2D(start: CGPoint(x: 1.5, y: 0), end: CGPoint(x: 2.6, y: 0)), kind: .window),
            Opening2D(segment: WallSegment2D(start: CGPoint(x: 6, y: 1.5), end: CGPoint(x: 6, y: 2.6)), kind: .window),
        ]
        FloorPlan2DView(wallSegments: walls, rooms: rooms, openings: openings, showDimensions: true)
            .frame(height: 320)
            .padding()
    }
}

#Preview { FloorPlan2DPreview() }
