//
//  AIAnalysisView.swift
//  PriksaRoemah
//
//  Created by Ignasius Holy Prasetya on 02/07/26.
//

import SwiftUI
import PhotosUI

struct AIAnalysisView: View {

    @State private var selectedImage: UIImage?
    @State private var photoItem:     PhotosPickerItem?
    @State private var showCamera  = false
    @State private var isAnalyzing = false
    @State private var detections: [Detection] = []
    @State private var report:     AIReport?

    private let detector = WallDetectorService.shared
    private let analyst  = AIAnalysisService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                imagePreview
                captureButtons
                if selectedImage != nil { analyzeButton }
                if isAnalyzing { ProgressView("Menganalisis...").padding() }
                if let r = report { reportSection(r) }
            }
            .padding()
        }
        .navigationTitle("AI Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: photoItem) { _, newItem in
            Task {
                guard
                    let data  = try? await newItem?.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                else { return }
                selectedImage = image
                detections    = []
                report        = nil
            }
        }
        .sheet(isPresented: $showCamera) {
            WallCameraPickerView(image: $selectedImage)
                .onDisappear {
                    detections = []
                    report     = nil
                }
        }
    }

    // MARK: - Image preview + bounding boxes
    @ViewBuilder
    private var imagePreview: some View {
        if let image = selectedImage {
            BoundingBoxOverlayView(image: image, detections: detections)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
                .frame(height: 240)
                .overlay(
                    VStack(spacing: 10) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                        Text("Foto dinding untuk dianalisis")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                )
        }
    }

    // MARK: - Capture buttons
    private var captureButtons: some View {
        HStack(spacing: 12) {
            Button {
                showCamera = true
            } label: {
                Label("Kamera", systemImage: "camera")
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .foregroundStyle(.primary)

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Galeri", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .foregroundStyle(.primary)
        }
    }

    // MARK: - Analyze button
    private var analyzeButton: some View {
        Button {
            runAnalysis()
        } label: {
            Label("Analyze", systemImage: "waveform.path.ecg")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isAnalyzing)
    }

    // MARK: - Report cards
    @ViewBuilder
    private func reportSection(_ r: AIReport) -> some View {
        // Score + Priority
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Condition Score")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(r.conditionScore)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                Text("out of 100")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(r.priority.rawValue.uppercased())
                .font(.caption.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(priorityColor(r.priority).opacity(0.15))
                .foregroundStyle(priorityColor(r.priority))
                .clipShape(Capsule())
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))

        // Summary
        infoCard(icon: "doc.text", title: "Summary", body: r.summary)

        // Deteksi per item
        if !r.detections.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("Deteksi (\(r.detections.count))", systemImage: "eye")
                    .font(.subheadline.bold())
                ForEach(r.detections) { d in
                    HStack {
                        Circle()
                            .fill(severityColor(d.severity))
                            .frame(width: 8, height: 8)
                        Text(d.label
                            .replacingOccurrences(of: "_", with: " ")
                            .capitalized)
                        .font(.subheadline)
                        Spacer()
                        Text("\(Int(d.confidence * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(d.severity.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(severityColor(d.severity).opacity(0.15))
                            .foregroundStyle(severityColor(d.severity))
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }

        // Rekomendasi
        if !r.recommendation.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("Rekomendasi", systemImage: "checkmark.seal")
                    .font(.subheadline.bold())
                ForEach(r.recommendation, id: \.self) { rec in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.subheadline)
                        Text(rec).font(.subheadline)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func infoCard(icon: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon).font(.subheadline.bold())
            Text(body).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Colors
    private func priorityColor(_ p: Priority) -> Color {
        switch p {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .green
        }
    }

    private func severityColor(_ s: Severity) -> Color {
        switch s {
        case .high:    return .red
        case .medium:  return .orange
        case .low:     return .yellow
        case .unknown: return .gray
        }
    }

    // MARK: - Run detection
    private func runAnalysis() {
        guard let image = selectedImage, let cg = image.cgImage else { return }
        isAnalyzing = true
        detector.detect(cgImage: cg) { results in
            self.detections = results
            self.report     = self.analyst.analyze(detections: results)
            self.isAnalyzing = false
        }
    }
}

// MARK: - Bounding box overlay
// Vision koordinat: origin bottom-left, Y naik ke atas, dinormalisasi 0...1.
// SwiftUI koordinat: origin top-left, Y turun. Perlu flip Y.
struct BoundingBoxOverlayView: View {

    let image:      UIImage
    let detections: [Detection]

    var body: some View {
        GeometryReader { geo in
            let scaled = scaledSize(containerSize: geo.size)
            let offset = imageOffset(containerSize: geo.size, scaledSize: scaled)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()

            ForEach(detections) { d in
                let rect = convertBox(d.boundingBox, scaledSize: scaled)
                let color = severityColor(d.severity)

                // Bounding box
                Rectangle()
                    .stroke(color, lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(
                        x: rect.midX + offset.x,
                        y: rect.midY + offset.y
                    )

                // Label
                Text(d.label.replacingOccurrences(of: "_", with: " "))
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 4).padding(.vertical, 2)
                    .background(color)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .position(
                        x: rect.minX + rect.width / 2 + offset.x,
                        y: max(10, rect.minY - 10 + offset.y)
                    )
            }
        }
        .aspectRatio(image.size.width / image.size.height, contentMode: .fit)
    }

    private func scaledSize(containerSize: CGSize) -> CGSize {
        let iAR = image.size.width  / image.size.height
        let cAR = containerSize.width / containerSize.height
        if iAR > cAR {
            return CGSize(width: containerSize.width,
                          height: containerSize.width / iAR)
        } else {
            return CGSize(width: containerSize.height * iAR,
                          height: containerSize.height)
        }
    }

    private func imageOffset(containerSize: CGSize, scaledSize: CGSize) -> CGPoint {
        CGPoint(
            x: (containerSize.width  - scaledSize.width)  / 2,
            y: (containerSize.height - scaledSize.height) / 2
        )
    }

    // Flip Y karena Vision origin = bottom-left, SwiftUI origin = top-left
    private func convertBox(_ box: CGRect, scaledSize: CGSize) -> CGRect {
        CGRect(
            x:      box.minX * scaledSize.width,
            y:      (1 - box.maxY) * scaledSize.height,
            width:  box.width  * scaledSize.width,
            height: box.height * scaledSize.height
        )
    }

    private func severityColor(_ s: Severity) -> Color {
        switch s {
        case .high:    return .red
        case .medium:  return .orange
        case .low:     return .yellow
        case .unknown: return .gray
        }
    }
}

// MARK: - Camera picker (native UIImagePickerController)
struct WallCameraPickerView: UIViewControllerRepresentable {

    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate   = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject,
                              UIImagePickerControllerDelegate,
                              UINavigationControllerDelegate {
        let parent: WallCameraPickerView
        init(_ p: WallCameraPickerView) { parent = p }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    NavigationStack { AIAnalysisView() }
}
