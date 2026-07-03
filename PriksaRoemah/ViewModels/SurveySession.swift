import SwiftUI
import Combine
import RoomPlan
import simd

// Intermediate room data selama sesi scan berlangsung
struct ScannedRoom: Identifiable {
    let id = UUID()
    var name: String
    var floor: String
    var type: RoomType
}

final class SurveySession: ObservableObject {

    // MARK: - Forwarded dari RoomPlanManager (fix nested ObservableObject bug)
    // SwiftUI tidak auto-forward perubahan dari nested ObservableObject.
    // Solusi: forward manual lewat Combine sink ke @Published di level ini.
    @Published var capturedRoom: CapturedRoom?
    @Published var isRoomPlanScanning: Bool = false

    // MARK: - Survey Progress
    @Published var scannedRooms: [ScannedRoom] = []

    // MARK: - House Info (diisi di RoomInfoView)
    @Published var houseName:  String = ""
    @Published var harga:      String = ""
    @Published var luasTanah:  String = ""
    @Published var catatan:    String = ""

    // MARK: - Collection
    @Published var savedHouses: [House] = House.dummyAll

    // MARK: - Detection
    @Published var detections: [Detection] = []

    // MARK: - Managers
    let roomPlan = RoomPlanManager()
    let detector = DetectionManager()
    let camera   = CameraManager()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init() {
        // Forward roomPlan perubahan supaya View yang observe session ikut update
        roomPlan.$capturedRoom
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in self?.capturedRoom = value }
            .store(in: &cancellables)

        roomPlan.$isScanning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in self?.isRoomPlanScanning = value }
            .store(in: &cancellables)

        detector.$detections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in self?.detections = value }
            .store(in: &cancellables)
    }

    // MARK: - Room Management

    func addRoom(name: String, floor: String, type: RoomType) {
        let label = name.trimmingCharacters(in: .whitespaces).isEmpty ? type.rawValue : name
        scannedRooms.append(ScannedRoom(name: label, floor: floor, type: type))
    }

    /// Reset hanya state scan (bukan house info) supaya user bisa lanjut scan ruangan berikutnya
    func resetScanForNextRoom() {
        capturedRoom = nil
        roomPlan.capturedRoom = nil
    }

    // MARK: - Build & Save House

    func buildHouse() -> House {
        let rooms = scannedRooms.map { Room(name: $0.name, type: $0.type, floor: $0.floor) }
        return House(
            name:            houseName,
            developer:       "",
            harga:           harga,
            luasTanah:       luasTanah,
            catatan:         catatan,
            rooms:           rooms,
            floorAreaSqM:    computeFloorArea(),
            wallAreaSqM:     computeWallArea(),
            ceilingHeightM:  computeCeilingHeight()
        )
    }

    /// Panggil ini setelah save — bersihkan sesi untuk survey berikutnya
    func startNewSurvey() {
        scannedRooms   = []
        houseName      = ""
        harga          = ""
        luasTanah      = ""
        catatan        = ""
        capturedRoom   = nil
        roomPlan.capturedRoom = nil
    }

    // MARK: - Metric Computation dari CapturedRoom
    // Bounding-box estimasi — cukup untuk tampilan relatif, bukan pengukuran legal

    private func computeFloorArea() -> Double {
        guard let room = capturedRoom, !room.walls.isEmpty else { return 0 }
        var minX = Float.greatestFiniteMagnitude, maxX = -Float.greatestFiniteMagnitude
        var minZ = Float.greatestFiniteMagnitude, maxZ = -Float.greatestFiniteMagnitude
        for wall in room.walls {
            let p = wall.transform.columns.3
            minX = min(minX, p.x); maxX = max(maxX, p.x)
            minZ = min(minZ, p.z); maxZ = max(maxZ, p.z)
        }
        return Double((maxX - minX) * (maxZ - minZ))
    }

    private func computeWallArea() -> Double {
        guard let room = capturedRoom else { return 0 }
        return room.walls.reduce(0) { $0 + Double($1.dimensions.x * $1.dimensions.y) }
    }

    private func computeCeilingHeight() -> Double {
        guard let room = capturedRoom else { return 0 }
        return room.walls.map { Double($0.dimensions.y) }.max() ?? 0
    }
}
