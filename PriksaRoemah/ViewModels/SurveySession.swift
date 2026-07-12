import SwiftUI
import Combine
import RoomPlan
import simd

/// Ruangan yang baru saja discan, sebelum lantainya di-"Finish Scanning".
struct ScannedRoom: Identifiable {
    let id = UUID()
    var name: String
    var type: RoomType
    var capturedRoom: CapturedRoom?
}

final class SurveySession: ObservableObject {

    // MARK: - Forwarded dari RoomPlanManager
    @Published var capturedRoom: CapturedRoom?
    @Published var isRoomPlanScanning: Bool = false

    // MARK: - Progress lantai yang SEDANG discan
    @Published var currentFloorRooms: [ScannedRoom] = []
    @Published var currentFloorNumber: Int = 1

    // MARK: - Lantai yang barusan selesai discan, nunggu di-review (ReviewScanView)
    // sebelum masuk House baru atau ditambahkan ke House existing (lihat ReviewScanView).
    @Published var pendingFloor: Floor?

    // MARK: - House Info draft (diisi di ReviewScanView sheet, hanya untuk House baru)
    @Published var houseName:  String = ""
    @Published var harga:      String = ""
    @Published var luasTanah:  String = ""
    @Published var catatan:    String = ""

    // MARK: - Collection
    @Published var savedHouses: [House] = House.dummyAll

    // MARK: - Building progress
    @Published var isBuildingFloor = false
    @Published var isBuildingHouse = false

    // MARK: - Managers
    let roomPlan = RoomPlanManager()
    let compass  = CompassService()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init() {
        roomPlan.$capturedRoom
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in self?.capturedRoom = value }
            .store(in: &cancellables)

        roomPlan.$isScanning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] scanning in
                self?.isRoomPlanScanning = scanning
            }
            .store(in: &cancellables)
    }

    // MARK: - Room Management (dalam 1 lantai)

    func addRoom(name: String, type: RoomType) {
        let label            = name.trimmingCharacters(in: .whitespaces).isEmpty ? type.rawValue : name
        let capturedRoomSnap = capturedRoom

        let scanned = ScannedRoom(name: label, type: type, capturedRoom: capturedRoomSnap)
        currentFloorRooms.append(scanned)
        roomPlan.commitCurrentRoom()

        capturedRoom          = nil
        roomPlan.capturedRoom = nil
    }

    func resetScanForNextRoom() {
        capturedRoom          = nil
        roomPlan.capturedRoom = nil
    }

    // MARK: - Finish 1 lantai ("Finish Scanning" di New Room sheet)

    @MainActor
    func finishCurrentFloor(label: String? = nil) async {
        isBuildingFloor = true
        defer { isBuildingFloor = false }

        let floorLabel = label?.trimmingCharacters(in: .whitespaces).isEmpty == false
            ? label!
            : "Floor \(currentFloorNumber)"

        let capturedRoomsForFloor = roomPlan.extractCompletedRoomsForFloor()

        var usdzURL: URL?
        var wallSegments: [WallSegment2D] = []

        // Titik tengah tiap ruangan diambil dari CapturedStructure.sections
        // (BUKAN dari CapturedRoom.identifier matching — percobaan sebelumnya
        // gagal karena StructureBuilder nggak menjamin identifier tetap sama
        // antar CapturedRoom input & output, jadi lookup-nya diam-diam gagal
        // & fallback ke koordinat lokal yang belum di-align, makanya semua
        // label numpuk di 1 titik). `structure.sections[i].center` adalah
        // properti dari CapturedStructure itu sendiri — satu object yang sama
        // dengan yang punya `structure.walls` (yang sudah pasti di koordinat
        // gabungan karena dipakai langsung buat gambar wallSegments di atas),
        // jadi frame koordinatnya nggak ambigu kayak CapturedRoom.walls yang
        // bisa lokal atau global tergantung sumbernya.
        var sections: [CapturedStructure.Section] = []

        if !capturedRoomsForFloor.isEmpty {
            do {
                let structure = try await roomPlan.buildStructure(from: capturedRoomsForFloor)
                wallSegments  = FloorPlanGeometry.wallSegments(from: structure)
                sections      = structure.sections
                let url       = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(UUID().uuidString).usdz")
                try structure.export(to: url)
                usdzURL = url
            } catch {
                print("[SurveySession] StructureBuilder gagal untuk \(floorLabel), fallback:", error)
                if let first = capturedRoomsForFloor.first {
                    wallSegments = FloorPlanGeometry.wallSegments(from: first)
                    let url      = FileManager.default.temporaryDirectory
                        .appendingPathComponent("\(UUID().uuidString).usdz")
                    try? first.export(to: url)
                    usdzURL = url
                }
                // StructureBuilder gagal -> nggak ada section teralign sama
                // sekali. Ini cuma kepakai kalau cuma 1 ruangan (wallSegments
                // juga fallback ke room pertama di atas), jadi center-nya
                // dibiarkan 0,0 di bawah — nggak ada ruangan lain buat numpuk
                // bareng jadi labelnya tetap kebaca di tengah 1 denah itu.
            }
        }

        // widthM/lengthM dihitung dari bounding box CapturedRoom mentah tiap
        // ruangan (ukuran nggak berubah kena rotasi/translasi align, jadi
        // aman dipakai walau belum di-align) — dipasangkan by INDEX ke
        // currentFloorRooms karena keduanya selalu 1:1 (di-append bareng tiap
        // commitCurrentRoom()). Center-nya dari `sections[index].center`,
        // dipasangkan by INDEX juga karena 1 CapturedRoom input -> 1 Section
        // output berurutan.
        let rooms: [Room] = currentFloorRooms.enumerated().map { index, scanned in
            var widthM: Double = 0
            var lengthM: Double = 0
            if capturedRoomsForFloor.indices.contains(index) {
                let bounds = FloorPlanGeometry.bounds(of: FloorPlanGeometry.wallSegments(from: capturedRoomsForFloor[index]))
                widthM  = Double(bounds.width)
                lengthM = Double(bounds.height)
            }
            var centerXM: Double = 0
            var centerYM: Double = 0
            if sections.indices.contains(index) {
                let center = sections[index].center
                centerXM = Double(center.x)
                centerYM = Double(center.z)
            }
            return Room(
                name: scanned.name, type: scanned.type,
                widthM: widthM, lengthM: lengthM,
                centerXM: centerXM, centerYM: centerYM
            )
        }

        let floor = Floor(
            label:          floorLabel,
            rooms:          rooms,
            usdzURL:        usdzURL,
            wallSegments:   wallSegments,
            floorAreaSqM:   computeFloorArea(from: wallSegments),
            wallAreaSqM:    computeWallArea(for: capturedRoomsForFloor),
            ceilingHeightM: computeCeilingHeight(for: capturedRoomsForFloor)
        )

        pendingFloor = floor
        currentFloorRooms = []
    }

    /// Batal lantai yang barusan selesai di-"Finish Scanning" (dari ReviewScanView,
    /// tombol X). User kembali ke ScanningView untuk scan ulang lantai yang sama.
    func discardPendingFloor() {
        pendingFloor = nil
    }

    func startNextFloor() {
        currentFloorRooms     = []
        capturedRoom          = nil
        roomPlan.capturedRoom = nil
    }

    // MARK: - House Facing (compass)

    /// Arah hadap terdeteksi dari heading compass saat ini. Dipakai saat House baru
    /// dibuat (createHouse) — sekali kesimpen di House, tidak berubah lagi otomatis.
    var detectedFacing: HouseFacing? {
        compass.headingDegrees.map(HouseFacing.nearest(toDegrees:))
    }

    // MARK: - Save pendingFloor sebagai House baru (ReviewScanView sheet, lantai pertama)

    @MainActor
    func createHouse() -> House {
        isBuildingHouse = true
        defer { isBuildingHouse = false }

        let floor = pendingFloor.map { f -> Floor in
            var f = f
            f.notes = catatan
            return f
        }

        let house = House(
            name:      houseName,
            developer: "",
            harga:     harga,
            luasTanah: luasTanah,
            catatan:   catatan,
            facing:    detectedFacing,
            floors:    floor.map { [$0] } ?? []
        )

        savedHouses.insert(house, at: 0)
        pendingFloor = nil
        currentFloorNumber = 1
        houseName = ""; harga = ""; luasTanah = ""; catatan = ""
        return house
    }

    /// Tambahkan pendingFloor ke House yang sudah ada ("Add Floor" dari FloorsListView).
    func appendPendingFloorToHouse(houseID: UUID, notes: String = "") {
        guard var floor = pendingFloor,
              let hIndex = savedHouses.firstIndex(where: { $0.id == houseID }) else { return }
        floor.notes = notes
        savedHouses[hIndex].floors.append(floor)
        pendingFloor = nil
        currentFloorNumber = 1
    }

    func startNewSurvey() {
        roomPlan.stop(keepSessionAlive: false)
        roomPlan.resetSurvey()
        pendingFloor       = nil
        currentFloorRooms  = []
        currentFloorNumber = 1
        houseName = ""
        harga     = ""
        luasTanah = ""
        catatan   = ""
        capturedRoom = nil
        compass.start()
    }

    // MARK: - Update saved House/Floor (Documentation: Notes, Gallery, Facing)
    //
    // savedHouses & floors di dalamnya adalah struct (value type), jadi update
    // dilakukan dengan cari index-nya lalu replace in place. @Published
    // savedHouses otomatis nge-trigger UI refresh di semua view yang observe.

    func updateFloor(houseID: UUID, floorID: UUID, mutate: (inout Floor) -> Void) {
        guard let hIndex = savedHouses.firstIndex(where: { $0.id == houseID }),
              let fIndex = savedHouses[hIndex].floors.firstIndex(where: { $0.id == floorID }) else { return }
        mutate(&savedHouses[hIndex].floors[fIndex])
    }

    func addDocumentationPhoto(houseID: UUID, photo: DocumentationPhoto) {
        guard let hIndex = savedHouses.firstIndex(where: { $0.id == houseID }) else { return }
        savedHouses[hIndex].documentationPhotos.append(photo)
    }

    func deleteDocumentationPhotos(houseID: UUID, photoIDs: Set<UUID>) {
        guard let hIndex = savedHouses.firstIndex(where: { $0.id == houseID }) else { return }
        savedHouses[hIndex].documentationPhotos.removeAll { photoIDs.contains($0.id) }
    }

    func deleteFloors(houseID: UUID, floorIDs: Set<UUID>) {
        guard let hIndex = savedHouses.firstIndex(where: { $0.id == houseID }) else { return }
        savedHouses[hIndex].floors.removeAll { floorIDs.contains($0.id) }
    }

    // MARK: - Metric Computation (per lantai yang baru saja di-build)

    private func computeFloorArea(from segments: [WallSegment2D]) -> Double {
        guard !segments.isEmpty else { return 0 }
        let bounds = FloorPlanGeometry.bounds(of: segments)
        return Double(bounds.width * bounds.height)
    }

    private func computeWallArea(for capturedRooms: [CapturedRoom]) -> Double {
        capturedRooms.reduce(0) { total, room in
            total + room.walls.reduce(0) { $0 + Double($1.dimensions.x * $1.dimensions.y) }
        }
    }

    private func computeCeilingHeight(for capturedRooms: [CapturedRoom]) -> Double {
        capturedRooms
            .map { $0.walls.map { Double($0.dimensions.y) }.max() ?? 0 }
            .max() ?? 0
    }
}
