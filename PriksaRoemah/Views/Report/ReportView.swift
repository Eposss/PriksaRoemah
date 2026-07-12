import SwiftUI
import PhotosUI

/// Detail 1 lantai — sesuai layar "Review Scan" di mockup (tab Plan/Details).
/// Ambil session + id (bukan value langsung) supaya Notes/Gallery/Facing bisa
/// diedit dan ke-reflect balik ke SurveySession.savedHouses.
struct ReportView: View {

    @ObservedObject var session: SurveySession
    let houseID: UUID
    let floorID: UUID

    @State private var showIn3D        = false
    @State private var selectedTab     = 0   // 0 = Plan, 1 = Details
    @State private var showDownload    = false
    @State private var notesDraft      = ""

    private var house: House? { session.savedHouses.first { $0.id == houseID } }
    private var floor: Floor? { house?.floors.first { $0.id == floorID } }

    var body: some View {
        Group {
            if let house, let floor {
                content(house: house, floor: floor)
            } else {
                Text("Lantai tidak ditemukan.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func content(house: House, floor: Floor) -> some View {
        ScrollView {
            VStack(spacing: 20) {

                Picker("Tab", selection: $selectedTab) {
                    Text("Plan").tag(0)
                    Text("Details").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if selectedTab == 0 {
                    planSection(floor: floor)
                } else {
                    detailsSection(house: house, floor: floor)
                }

                Spacer(minLength: 32)
            }
            .padding(.top, 8)
        }
        .navigationTitle("Report")
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
        .onAppear { notesDraft = floor.notes }
    }

    // MARK: - Tab: Plan
    //
    // Sesuai mockup Figma "Report" — preview denah/model dengan toggle 2D/3D
    // mengambang (sama seperti ReviewScanView), dan stat pills Building Area /
    // Floor Area / Ceiling Height (bukan lagi segmented picker + divided row lama).

    private func planSection(floor: Floor) -> some View {
        VStack(spacing: 20) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if showIn3D {
                        // Lebih tinggi dari 2D — SCNView butuh lebih banyak
                        // ruang biar hasil pinch-zoom nggak keliatan pecah.
                        House3DView(usdzURL: floor.usdzURL)
                            .frame(height: 420)
                    } else {
                        FloorPlan2DView(wallSegments: floor.wallSegments, rooms: floor.rooms)
                            .frame(height: 300)
                            .padding(.horizontal, 30)
                    }
                }
                .frame(maxWidth: .infinity)

                viewModeToggle
                    .padding(.trailing, 16)
            }

            metricsRow(floor: floor)

            Divider().padding(.horizontal)

            roomsList(floor: floor)
        }
    }

    private var viewModeToggle: some View {
        VStack(spacing: 8) {
            toggleButton(title: "2D", systemImage: "square.on.square", isOn: !showIn3D) { showIn3D = false }
            Divider().frame(width: 28)
            toggleButton(title: "3D", systemImage: "cube", isOn: showIn3D) { showIn3D = true }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 4)
    }

    private func toggleButton(title: String, systemImage: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isOn ? Color.orange : Color.secondary)
        }
        .buttonStyle(.plain)
    }

    private func metricsRow(floor: Floor) -> some View {
        HStack(spacing: 12) {
            statCard(icon: "arrow.up.left.and.arrow.down.right", value: buildingDimensions(floor), label: "Building Area")
            statCard(icon: "square.split.bottomrightquarter", value: floor.formattedFloorArea, label: "Floor Area")
            statCard(icon: "arrow.up.and.down", value: floor.formattedCeiling, label: "Ceiling Height")
        }
        .padding(.horizontal)
    }

    private func buildingDimensions(_ floor: Floor) -> String {
        let bounds = FloorPlanGeometry.bounds(of: floor.wallSegments)
        guard bounds.width > 0, bounds.height > 0 else { return "– m" }
        return String(format: "%.0f×%.0f m", bounds.width, bounds.height)
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(Color.orange)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.primary.opacity(0.08)))
    }

    private func roomsList(floor: Floor) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Rooms (\(floor.rooms.count))")
                .font(.subheadline.bold())
                .padding(.horizontal)
                .padding(.bottom, 8)

            ForEach(floor.rooms, id: \.id) { (room: Room) in
                HStack(spacing: 12) {
                    Image(systemName: room.type.icon)
                        .foregroundStyle(.orange)
                        .frame(width: 24)
                    Text(room.name).font(.subheadline)
                    Spacer()
                    Text(room.formattedDimensions)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                Divider().padding(.leading, 52)
            }
        }
    }

    // MARK: - Tab: Details
    // Floor Area / Ceiling Height / Facing, Bedroom & Bathroom breakdown
    // (dengan dimensi), Gallery (dokumentasi foto biasa, TANPA AI), Notes.

    private func detailsSection(house: House, floor: Floor) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                detailCard(icon: "square.split.bottomrightquarter", value: floor.formattedFloorArea, label: "Floor Area")
                detailCard(icon: "arrow.up.and.down", value: floor.formattedCeiling, label: "Ceiling Height")
                facingCard(house.facing)
            }
            .padding(.horizontal)

            if !floor.bedrooms.isEmpty {
                roomGroupCard(title: "Bedroom", rooms: floor.bedrooms)
            }
            if !floor.bathrooms.isEmpty {
                roomGroupCard(title: "Bathroom", rooms: floor.bathrooms)
            }
            if !floor.otherRooms.isEmpty {
                roomGroupCard(title: "Other Rooms", rooms: floor.otherRooms)
            }

            documentationPreviewSection(house: house, floor: floor)
            notesSection(floor: floor)
        }
        .padding(.horizontal)
    }

    // MARK: - Documentation preview (ringkasan, "See All" ke DocumentationView penuh)

    private func documentationPreviewSection(house: House, floor: Floor) -> some View {
        let relevantTypes = Set(floor.rooms.map(\.type))
        let relevantPhotos = house.documentationPhotos.filter { relevantTypes.contains($0.roomType) }

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("DOCUMENTATION").font(.caption).foregroundStyle(.secondary)
                Spacer()
                NavigationLink {
                    DocumentationView(session: session, houseID: house.id)
                } label: {
                    Text("See All").font(.caption).foregroundStyle(.orange)
                }
            }

            if relevantPhotos.isEmpty {
                NavigationLink {
                    DocumentationView(session: session, houseID: house.id)
                } label: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(height: 90)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.08)))
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(relevantPhotos.prefix(6)) { photo in
                            if let uiImage = UIImage(data: photo.imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .clipped()
                            }
                        }
                    }
                }
            }
        }
    }

    private func detailCard(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundStyle(.orange)
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.08)))
    }

    private func facingCard(_ facing: HouseFacing?) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "location.north.fill")
                .foregroundStyle(.orange)
                .rotationEffect(.degrees(facingRotationDegrees(facing)))
            Text(facing?.rawValue ?? "–")
                .font(.subheadline.bold())
            Text("facing")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.08)))
    }

    private func facingRotationDegrees(_ facing: HouseFacing?) -> Double {
        switch facing {
        case .north: 0; case .northEast: 45; case .east: 90; case .southEast: 135
        case .south: 180; case .southWest: 225; case .west: 270; case .northWest: 315
        case .none: 0
        }
    }

    private func roomGroupCard(title: String, rooms: [Room]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title).font(.subheadline.bold())
                Spacer()
                Text("\(rooms.count)").font(.subheadline.bold())
            }
            .padding(.bottom, 8)

            ForEach(rooms) { room in
                HStack {
                    Image(systemName: room.type.icon)
                        .foregroundStyle(.orange)
                        .frame(width: 20)
                    Text(room.name).font(.subheadline)
                    Spacer()
                    Text(room.formattedDimensions)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.primary.opacity(0.08)))
    }

    // MARK: - Notes

    private func notesSection(floor: Floor) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTES").font(.caption).foregroundStyle(.secondary)
            TextField("Add note...", text: $notesDraft, axis: .vertical)
                .lineLimit(3...8)
                .padding(8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.08)))
                .onChange(of: notesDraft) { _, newValue in
                    session.updateFloor(houseID: houseID, floorID: floor.id) { f in
                        f.notes = newValue
                    }
                }
        }
    }
}
