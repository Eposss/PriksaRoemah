import SwiftUI
import Combine
import RoomPlan
import ARKit
import simd

struct ScannedRoom: Identifiable {
    let id = UUID()
    var name: String
    var floor: String
    var type: RoomType
    var capturedRoom: CapturedRoom?
}

final class SurveySession: ObservableObject {

    // MARK: - Forwarded dari RoomPlanManager
    @Published var capturedRoom: CapturedRoom?
    @Published var isRoomPlanScanning: Bool = false

    // MARK: - Survey Progress
    @Published var scannedRooms: [ScannedRoom] = []

    // MARK: - House Info
    @Published var houseName:  String = ""
    @Published var harga:      String = ""
    @Published var luasTanah:  String = ""
    @Published var catatan:    String = ""

    // MARK: - Collection
    @Published var savedHouses: [House] = []

    // MARK: - Building progress
    @Published var isBuildingHouse = false

    // MARK: - Managers
    let roomPlan = RoomPlanManager()

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

    // MARK: - Room Management

    func addRoom(name: String, floor: String, type: RoomType) {
        let label            = name.trimmingCharacters(in: .whitespaces).isEmpty ? type.rawValue : name
        let capturedRoomSnap = capturedRoom

        let scanned = ScannedRoom(
            name:         label,
            floor:        floor,
            type:         type,
            capturedRoom: capturedRoomSnap
        )
        scannedRooms.append(scanned)
        roomPlan.commitCurrentRoom()

        // Reset capturedRoom segera setelah commit supaya onChange(of: capturedRoom)
        // di ScanningView tidak re-trigger saat view re-appear.
        capturedRoom          = nil
        roomPlan.capturedRoom = nil
    }

    func resetScanForNextRoom() {
        capturedRoom          = nil
        roomPlan.capturedRoom = nil
    }

    // MARK: - Build & Save House

    @MainActor
    func buildHouse() async -> House {
        isBuildingHouse = true
        defer { isBuildingHouse = false }

        let rooms = scannedRooms.map {
            Room(name: $0.name, type: $0.type, floor: $0.floor)
        }

        var usdzURL: URL?
        var wallSegments: [WallSegment2D] = []

        if !roomPlan.completedRooms.isEmpty {
            do {
                let structure = try await roomPlan.buildStructure()
                wallSegments  = FloorPlanGeometry.wallSegments(from: structure)
                let url       = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(UUID().uuidString).usdz")
                try structure.export(to: url)
                usdzURL = url
            } catch {
                print("[SurveySession] StructureBuilder gagal, fallback:", error)
                if let first = roomPlan.completedRooms.first {
                    wallSegments = FloorPlanGeometry.wallSegments(from: first)
                    let url      = FileManager.default.temporaryDirectory
                        .appendingPathComponent("\(UUID().uuidString).usdz")
                    try? first.export(to: url)
                    usdzURL = url
                }
            }
        }

        return House(
            name:           houseName,
            developer:      "",
            harga:          harga,
            luasTanah:      luasTanah,
            catatan:        catatan,
            rooms:          rooms,
            usdzURL:        usdzURL,
            wallSegments:   wallSegments,
            floorAreaSqM:   computeFloorArea(from: wallSegments),
            wallAreaSqM:    computeWallArea(),
            ceilingHeightM: computeCeilingHeight()
        )
    }

    func startNewSurvey() {
        roomPlan.stop(keepSessionAlive: false)
        roomPlan.resetSurvey()
        scannedRooms   = []
        houseName      = ""
        harga          = ""
        luasTanah      = ""
        catatan        = ""
        capturedRoom   = nil
    }

    // MARK: - Metrics

    private func computeFloorArea(from segments: [WallSegment2D]) -> Double {
        guard !segments.isEmpty else { return 0 }
        let bounds = FloorPlanGeometry.bounds(of: segments)
        return Double(bounds.width * bounds.height)
    }

    private func computeWallArea() -> Double {
        scannedRooms.reduce(0) { total, scanned in
            guard let room = scanned.capturedRoom else { return total }
            return total + room.walls.reduce(0) { $0 + Double($1.dimensions.x * $1.dimensions.y) }
        }
    }

    private func computeCeilingHeight() -> Double {
        scannedRooms
            .compactMap { $0.capturedRoom?.walls.map { Double($0.dimensions.y) }.max() }
            .max() ?? 0
    }
}
