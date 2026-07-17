import SwiftUI

/// Muncul begitu 1 lantai selesai discan. Sesuai mockup Figma "Review Scan" —
/// toggle 2D/3D mengambang, preview denah/model, dan SATU sheet native yang
/// bisa di-drag: peek (grabber + 3 stat cards, sesuai "finish scanning - report")
/// sampai full screen (nama unit/harga + breakdown ruangan + notes, sesuai
/// "new home sheet").
///
/// Drag halus & native: sheet-nya SATU `NavigationStack { Form { ... } }` yang
/// konstan — nggak pernah ditukar strukturnya waktu detent berubah, cuma toolbar
/// (nav bar) yang di-toggle visible/hidden. Section urutannya stats-dulu, jadi
/// pas peek (tinggi kecil) yang kelihatan otomatis cuma stat cards-nya — sisanya
/// kebuka begitu di-drag ke atas. Ini persis cara sheet native Apple sendiri
/// (Maps, dll) nge-reveal konten lebih banyak tanpa nge-swap view tree.
///
/// X (toolbar luar) = discard lantai ini & kembali scan ulang (pop 1 level).
/// Checkmark (toolbar luar) = expand sheet ke full screen (sama seperti drag ke atas).
/// Checkmark (di dalam sheet, full screen) = save. Kalau `houseID` nil (lantai
/// pertama survey baru), minta nama unit/harga dulu lalu buat House baru. Kalau
/// `houseID` ada (Add Floor ke House existing), langsung append. Setelah save,
/// sheet di-dismiss DULU (onDismiss) baru `path` di-reset ke [.floorsList(id)] —
/// itu artinya balik ke Home lalu push FloorsList dalam 1 langkah, jadi stack-nya
/// cuma 1 level dalam & tombol back di FloorsList balik pas ke koleksi survey.
struct ReviewScanView: View {

    @ObservedObject var session: SurveySession
    var houseID: UUID?
    @Binding var path: [SurveyRoute]

    @State private var showIn3D = false
    @State private var showDiscardAlert = false
    @State private var sheetPresented = true
    @State private var sheetDetent: PresentationDetent = Self.peekDetent
    @State private var notesDraft = ""
    @State private var pendingSaveHouseID: UUID?

    private static let peekDetent: PresentationDetent = .height(190)

    private var floor: Floor? { session.pendingFloor }
    private var isNewHouse: Bool { houseID == nil }

    private var canSave: Bool {
        isNewHouse ? !session.houseName.trimmingCharacters(in: .whitespaces).isEmpty : true
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            previewContent

            VStack {
                topToolbar
                Spacer()
            }

            HStack {
                Spacer()
                viewModeToggle
                    .padding(.trailing, 16)
            }
            .padding(.top, 120)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .alert("Discard This Floor?", isPresented: $showDiscardAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Discard", role: .destructive) {
                session.discardPendingFloor()
                if !path.isEmpty { path.removeLast() }
            }
        } message: {
            Text("Your 2D and 3D results for this floor won't be saved.")
        }
        .sheet(isPresented: $sheetPresented, onDismiss: handleSheetDismiss) {
            reviewSheetContent
                .presentationDetents([Self.peekDetent, .large], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: Self.peekDetent))
                .interactiveDismissDisabled(true)
        }
    }

    /// Sheet di-dismiss dulu (sheetPresented = false di confirmTapped), BARU reset
    /// path di sini — kalau dua-duanya dipicu bersamaan, sheet yang masih nempel
    /// tetap nutupin FloorsListView yang baru di-push.
    private func handleSheetDismiss() {
        guard let id = pendingSaveHouseID else { return }
        path = [.floorsList(houseID: id)]
    }

    private func confirmTapped() {
        session.catatan = notesDraft
        if let houseID {
            session.appendPendingFloorToHouse(houseID: houseID, notes: notesDraft)
            pendingSaveHouseID = houseID
        } else {
            let house = session.createHouse()
            pendingSaveHouseID = house.id
        }
        sheetPresented = false
    }

    // MARK: - Preview (2D denah / 3D model)

    @ViewBuilder
    private var previewContent: some View {
        if let floor {
            if showIn3D {
                // Full-bleed (bukan dipusatin kayak 2D) — kotak kecil bikin
                // hasil pinch-zoom keliatan pecah karena SCNView-nya sendiri
                // sempit. Padding atas/bawah cuma buat ngasih ruang toolbar &
                // sheet peek di bawahnya, bukan buat ngecilin model.
                House3DView(usdzURL: floor.usdzURL)
                    .padding(.top, 110)
                    .padding(.bottom, 210)
            } else {
                VStack {
                    Spacer()
                    FloorPlan2DView(wallSegments: floor.wallSegments, rooms: floor.rooms, openings: floor.openings, showDimensions: true)
                        .frame(height: 300)
                        .padding(.horizontal, 30)
                    Spacer()
                    Spacer()
                }
            }
        }
    }

    // MARK: - Top toolbar (X close, title, checkmark = expand sheet)

    private var topToolbar: some View {
        HStack {
            Button {
                showDiscardAlert = true
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Review Scan")
                .font(.headline)

            Spacer()

            Button {
                withAnimation { sheetDetent = .large }
            } label: {
                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.orange, in: Circle())
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Floating 2D/3D toggle

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

    // MARK: - Draggable review sheet
    //
    // SATU NavigationStack+Form yang konstan — tidak pernah ditukar struktur view-nya
    // biar drag-nya mulus. Section "stats" ditaruh PALING ATAS supaya itu yang
    // kelihatan pas sheet masih peek (pendek); section lain kebuka pas di-drag naik.

    private var reviewSheetContent: some View {
        NavigationStack {
            Form {
                if let floor {
                    Section {
                        metricsRow(floor: floor)
                    }
                }

                if isNewHouse {
                    Section {
                        TextField("Listing Name", text: $session.houseName)
                        TextField("Price (Rp)", text: $session.harga)
                            .keyboardType(.numberPad)
                    }

                    Section("House Facing") {
                        CompassLockView(compass: session.compass, locked: $session.lockedFacing)
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    }
                }

                if let floor {
                    if !floor.bedrooms.isEmpty {
                        roomSection(title: "Bedroom", rooms: floor.bedrooms)
                    }
                    if !floor.bathrooms.isEmpty {
                        roomSection(title: "Bathroom", rooms: floor.bathrooms)
                    }
                    if !floor.otherRooms.isEmpty {
                        roomSection(title: "Other Rooms", rooms: floor.otherRooms)
                    }
                }

                Section("Notes") {
                    TextField("Add note...", text: $notesDraft, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(isNewHouse ? "New Survey" : "New Floor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(sheetDetent == .large ? .visible : .hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation { sheetDetent = Self.peekDetent }
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if session.isBuildingHouse {
                        ProgressView()
                    } else {
                        Button {
                            confirmTapped()
                        } label: {
                            Image(systemName: "checkmark")
                                .foregroundStyle(canSave ? Color.orange : Color.secondary)
                        }
                        .disabled(!canSave)
                    }
                }
            }
        }
    }

    // MARK: - Stats (Building Area / Floor Area / Ceiling Height)

    private func metricsRow(floor: Floor) -> some View {
        HStack(spacing: 12) {
            statCard(icon: "arrow.up.left.and.arrow.down.right", value: buildingDimensions(floor), label: "Building Area")
            statCard(icon: "square.split.bottomrightquarter", value: floor.formattedFloorArea, label: "Floor Area")
            statCard(icon: "arrow.up.and.down", value: floor.formattedCeiling, label: "Ceiling Height")
        }
        .listRowInsets(EdgeInsets())
        .padding(12)
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

    // MARK: - Room breakdown

    private func roomSection(title: String, rooms: [Room]) -> some View {
        Section {
            ForEach(rooms) { room in
                HStack {
                    Image(systemName: room.type.icon)
                        .foregroundStyle(.orange)
                        .frame(width: 20)
                    Text(room.name)
                    Spacer()
                    Text(room.formattedDimensions)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            HStack {
                Text(title)
                Spacer()
                Text("\(rooms.count)")
            }
        }
    }
}
