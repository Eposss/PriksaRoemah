//import SwiftUI
//
//struct DetectionResultView: View {
//
//    let detections: [Detection]
//
//    var body: some View {
//        List {
//            if detections.isEmpty {
//                ContentUnavailableView(
//                    "No Detections",
//                    systemImage: "checkmark.shield",
//                    description: Text("Tidak ada kerusakan terdeteksi.")
//                )
//            } else {
//                ForEach(detections, id: \.id) { (item: Detection) in
//                    HStack {
//                        Image(systemName: severityIcon(item.severity))
//                            .foregroundStyle(severityColor(item.severity))
//                        VStack(alignment: .leading, spacing: 2) {
//                            Text(item.label
//                                .replacingOccurrences(of: "_", with: " ")
//                                .capitalized)
//                                .font(.subheadline.bold())
//                            if !item.location.isEmpty {
//                                Text(item.location)
//                                    .font(.caption).foregroundStyle(.secondary)
//                            }
//                            Text("Confidence: \(Int(item.confidence * 100))%")
//                                .font(.caption).foregroundStyle(.secondary)
//                        }
//                        Spacer()
//                        Text(item.severity.rawValue.capitalized)
//                            .font(.caption)
//                            .padding(.horizontal, 8).padding(.vertical, 3)
//                            .background(severityColor(item.severity).opacity(0.12))
//                            .foregroundStyle(severityColor(item.severity))
//                            .clipShape(Capsule())
//                    }
//                }
//            }
//        }
//        .navigationTitle("Detection Results")
//    }
//
//    private func severityIcon(_ s: Severity) -> String {
//        switch s {
//        case .high:    return "exclamationmark.triangle.fill"
//        case .medium:  return "exclamationmark.circle.fill"
//        case .low:     return "info.circle.fill"
//        case .unknown: return "questionmark.circle"
//        }
//    }
//
//    private func severityColor(_ s: Severity) -> Color {
//        switch s {
//        case .high:    return .red
//        case .medium:  return .orange
//        case .low:     return .yellow
//        case .unknown: return .gray
//        }
//    }
//}
