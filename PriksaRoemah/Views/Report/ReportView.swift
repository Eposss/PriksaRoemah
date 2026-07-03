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
                    placeholder3D
                } else {
                    FloorPlanGridView(rooms: house.rooms)
                        .padding(.horizontal)
                }

                metricsRow
                Divider().padding(.horizontal)
                roomsList
                orientationSection

                // Link ke AI Analysis
                NavigationLink {
                    AIAnalysisView()
                } label: {
                    Label("Analyze wall defects", systemImage: "magnifyingglass.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .foregroundStyle(.primary)
                .padding(.horizontal)

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
                    Image(systemName: room.type.icon)
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                    Text(room.name).font(.subheadline)
                    Spacer()
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

    // MARK: - 3D placeholder
    private var placeholder3D: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(.systemGray6))
            .frame(height: 260)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("3D View")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Powered by RealityKit")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            )
            .padding(.horizontal)
    }
}

// MARK: - Floor Plan Grid (fix: LazyVGrid, bukan GeometryReader)
// GeometryReader dalam ScrollView bisa dapat undefined height → view tidak muncul.
// LazyVGrid otomatis menghitung ukurannya sendiri berdasarkan konten.
struct FloorPlanGridView: View {
    let rooms: [Room]

    private let columns = [GridItem(.flexible(), spacing: 1), GridItem(.flexible(), spacing: 1)]

    var body: some View {
        Group {
            if rooms.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 1) {
                    ForEach(rooms) { room in
                        roomCell(room)
                    }
                }
                .background(Color(.systemGray4)) // Jadi "grid lines"
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray3), lineWidth: 2))
    }

    private func roomCell(_ room: Room) -> some View {
        VStack(spacing: 5) {
            Image(systemName: room.type.icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .padding(8)
                .background(Circle().fill(Color(.systemBackground)))
            Text(room.name)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text("Lt \(room.floor)")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Color(.systemBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("Belum ada ruangan terscan")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationStack {
        ReportView(house: House.dummyAll[0])
    }
}
