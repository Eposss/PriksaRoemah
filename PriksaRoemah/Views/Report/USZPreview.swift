//
//  USDZPreviewView.swift
//  HVMAN
//
//  3D view asli dari hasil scan RoomPlan, pakai QuickLook (support pinch/rotate gratis).
//

import SwiftUI
import QuickLook

struct USDZPreviewView: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator(url: url) }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as QLPreviewItem
        }
    }
}

/// Wrapper dengan empty state kalau USDZ belum ada (mis. belum ada ruangan yang di-scan)
struct House3DView: View {
    let usdzURL: URL?

    var body: some View {
        Group {
            if let usdzURL {
                USDZPreviewView(url: usdzURL)
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6))
                    .frame(height: 260)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "cube.transparent")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                            Text("Model 3D belum tersedia")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    )
            }
        }
        .padding(.horizontal)
    }
}
