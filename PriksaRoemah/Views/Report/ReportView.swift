import SwiftUI

struct ReportView: View {
    let house: House

    @State private var showIn3D     = false
    @State private var showDownload = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                Picker("View mode", selection: $showIn3D) {
                    Text("2D").tag(false)
                    Text("3D").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if showIn3D {
                    House3DView(usdzURL: house.usdzURL)
                } else {
                    FloorPlan2DView(wallSegments: house.wallSegments)
                        .padding(.horizontal)
                }

                metricsRow
                Divider().padding(.horizontal)

                if let report = house.overallReport {
                    aiSummarySection(report)
                    Divider().padding(.horizontal)
                }

                roomsList
                orientationSection

                Spacer(minLength: 32)
            }
            .padding(.top, 8)
        }
        .navigationTitle(house.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showDownload = true } label: {
                    Image(systemName: "arrow.down.circle")
                }
            }
        }
        .sheet(isPresented: $showDownload) {
            DownloadReportSheet(house: house)
        }
    }

    // MARK: - Metrics
    private var metricsRow: some View {
        HStack(spacing: 0) {
            metricCell(value: house.formattedFloorArea, label: "Floor area")
            Divider().frame(height: 36)
            metricCell(value: house.formattedWallArea,  label: "Wall area")
            Divider().frame(height: 36)
            metricCell(value: house.formattedCeiling,   label: "Ceiling height")
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    private func metricCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Rooms
    private var roomsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Rooms (\(house.rooms.count))")
                .font(.subheadline.bold())
                .padding(.horizontal)
                .padding(.bottom, 8)
            ForEach(house.rooms) { room in
                HStack(spacing: 12) {
                    Circle()
                        .fill(statusColor(for: room.aiReport))
                        .frame(width: 8, height: 8)
                    Image(systemName: room.type.icon)
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                    Text(room.name).font(.subheadline)
                    Spacer()
                    if let score = room.aiReport?.conditionScore {
                        Text("\(score)%")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    Text("Lantai \(room.floor)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                Divider().padding(.leading, 52)
            }
        }
    }

    // MARK: - Orientation
    private var orientationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Orientation")
                .font(.subheadline.bold())
                .padding(.horizontal)
            HStack(spacing: 12) {
                orientationCard(direction: "N", label: "North-East (NE)", isActive: true)
                orientationCard(direction: "E", label: "East",            isActive: false)
            }
            .padding(.horizontal)
        }
    }

    private func orientationCard(direction: String, label: String, isActive: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.blue.opacity(0.12) : Color(.systemGray6))
                    .frame(width: 40, height: 40)
                Text(direction)
                    .font(.headline.bold())
                    .foregroundStyle(isActive ? .blue : .secondary)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - AI Summary (Property Health — step 7/11 di wireframe)
    private func aiSummarySection(_ report: AIReport) -> some View {
        VStack(spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Property Health").font(.caption).foregroundStyle(.secondary)
                    Text("\(report.conditionScore)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    + Text("/100").font(.headline).foregroundStyle(.secondary)
                }
                Spacer()
                Text(report.priority.rawValue.uppercased())
                    .font(.caption.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(priorityColor(report.priority).opacity(0.15))
                    .foregroundStyle(priorityColor(report.priority))
                    .clipShape(Capsule())
            }
            Text(report.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !report.recommendation.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(report.recommendation, id: \.self) { rec in
                        Label(rec, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    private func priorityColor(_ p: Priority) -> Color {
        switch p {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .green
        }
    }

    private func statusColor(for report: AIReport?) -> Color {
        guard let report else { return Color(.systemGray3) }
        switch report.priority {
        case .low:    return .green
        case .medium: return .orange
        case .high:   return .red
        }
    }
}

#Preview {
    NavigationStack {
        ReportView(house: House.dummyAll[0])
    }
}
