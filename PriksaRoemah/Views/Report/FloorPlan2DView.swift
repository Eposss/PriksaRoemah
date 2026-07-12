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

    private let padding: CGFloat = 24

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
                            var path = Path()
                            for wall in wallSegments {
                                path.move(to: layout.project(wall.start))
                                path.addLine(to: layout.project(wall.end))
                            }
                            context.stroke(path, with: .color(.primary), style: StrokeStyle(lineWidth: 4, lineCap: .round))
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
                .background(Color(.systemGray6))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray3), lineWidth: 2))
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

#Preview {
    FloorPlan2DView(
        wallSegments: [
            WallSegment2D(start: .init(x: 0, y: 0), end: .init(x: 4, y: 0)),
            WallSegment2D(start: .init(x: 4, y: 0), end: .init(x: 4, y: 3)),
            WallSegment2D(start: .init(x: 4, y: 3), end: .init(x: 0, y: 3)),
            WallSegment2D(start: .init(x: 0, y: 3), end: .init(x: 0, y: 0)),
        ],
        rooms: [
            Room(name: "Bedroom", type: .bedroom, widthM: 4, lengthM: 3, centerXM: 2, centerYM: 1.5)
        ]
    )
    .frame(height: 300)
    .padding()
}
