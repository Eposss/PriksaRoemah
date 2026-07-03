//
//  FloorPlan2DView.swift
//  HVMAN
//
//  Denah 2D asli, digambar dari wall segments hasil RoomPlan (bukan grid ikon).
//

import SwiftUI

struct FloorPlan2DView: View {
    let wallSegments: [WallSegment2D]

    private let padding: CGFloat = 24

    var body: some View {
        Group {
            if wallSegments.isEmpty {
                emptyState
            } else {
                Canvas { context, size in
                    let bounds = FloorPlanGeometry.bounds(of: wallSegments)
                    guard bounds.width > 0, bounds.height > 0 else { return }

                    let availableW = size.width  - padding * 2
                    let availableH = size.height - padding * 2
                    let scale = min(availableW / bounds.width, availableH / bounds.height)

                    let offsetX = padding + (availableW - bounds.width  * scale) / 2
                    let offsetY = padding + (availableH - bounds.height * scale) / 2

                    func point(_ p: CGPoint) -> CGPoint {
                        CGPoint(
                            x: (p.x - bounds.minX) * scale + offsetX,
                            y: (p.y - bounds.minY) * scale + offsetY
                        )
                    }

                    var path = Path()
                    for wall in wallSegments {
                        path.move(to: point(wall.start))
                        path.addLine(to: point(wall.end))
                    }
                    context.stroke(path, with: .color(.primary), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                }
                .frame(height: 300)
                .background(Color(.systemGray6))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray3), lineWidth: 2))
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
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color(.systemGray6))
    }
}

#Preview {
    FloorPlan2DView(wallSegments: [
        WallSegment2D(start: .init(x: 0, y: 0), end: .init(x: 4, y: 0)),
        WallSegment2D(start: .init(x: 4, y: 0), end: .init(x: 4, y: 3)),
        WallSegment2D(start: .init(x: 4, y: 3), end: .init(x: 0, y: 3)),
        WallSegment2D(start: .init(x: 0, y: 3), end: .init(x: 0, y: 0)),
    ])
    .padding()
}
