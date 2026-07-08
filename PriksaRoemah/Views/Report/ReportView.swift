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
                    // ✅ Fix bug: sebelumnya di sini ada placeholder statis
                    // ("3D View / Powered by RealityKit") yang tidak pernah
                    // baca house.usdzURL sama sekali. House3DView yang benar
                    // ini pakai QuickLook untuk render USDZ hasil StructureBuilder,
                    // dan baru fallback ke empty state kalau usdzURL memang nil.
                    House3DView(usdzURL: house.usdzURL)
                        .frame(height: 320)
                } else {
                    FloorPlan2DView(wallSegments: house.wallSegments)
                        .frame(height: 260)
                        .padding(.horizontal)
                }

                metricsRow

                Divider().padding(.horizontal)

                roomsList

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

    // MARK: - Rooms list

    private var roomsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Rooms (\(house.rooms.count))")
                .font(.subheadline.bold())
                .padding(.horizontal)
                .padding(.bottom, 8)

            ForEach(house.rooms, id: \.id) { (room: Room) in
                HStack(spacing: 12) {
                    Image(systemName: room.type.icon)
                        .foregroundStyle(.blue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(room.name).font(.subheadline)
                        Text("Lantai \(room.floor)")
                            .font(.caption).foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                Divider().padding(.leading, 52)
            }
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
}

#Preview {
    NavigationStack { ReportView(house: House.dummyAll[0]) }
}
