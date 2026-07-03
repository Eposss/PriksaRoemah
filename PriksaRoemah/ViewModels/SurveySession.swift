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
    var capturedRoom: CapturedRoom?
    var detections: [Detection] = []
    var aiReport: AIReport?
}

final class SurveySession: ObservableObject {

    // MARK: - Forwarded dari RoomPlanManager
    @Published var capturedRoom: CapturedRoom?
    @Published var isRoomPlanScanning: Bool = false

    // MARK: - Survey Progress
    @Published var scannedRooms: [ScannedRoom] = []

    // MARK: - AI — deteksi yang terkumpul SELAMA ruangan yang sedang di-scan
    @Published var currentRoomDetections: [Detection] = []

    // MARK: - House Info
    @Published var houseName:  String = ""
    @Published var harga:      String = ""
    @Published var luasTanah:  String = ""
    @Published var catatan:    String = ""

    // MARK: - Collection
    @Published var savedHouses: [House] = House.dummyAll

    // MARK: - Building progress (dipakai UI saat StructureBuilder jalan)
    @Published var isBuildingHouse = false

    // MARK: - Managers
    let roomPlan  = RoomPlanManager()
    let detector  = DetectionManager()
    let camera    = CameraManager()
    private let analyst = AIAnalysisService.shared

    // Sampling frame kamera untuk AI selama scanning (bukan upload foto manual lagi)
    private var frameSamplingTimer: Timer?
    private let frameSamplingInterval: TimeInterval = 1.5
    private let ciContext = CIContext()

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
                if scanning {
                    self?.startLiveAISampling()
                } else {
                    self?.stopLiveAISampling()
                }
            }
            .store(in: &cancellables)

        // Deteksi baru dari tiap frame di-APPEND (bukan overwrite), supaya
        // AI Processing (step 6) mengakumulasi temuan sepanjang scan berjalan.
        detector.$detections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newDetections in
                guard let self, !newDetections.isEmpty else { return }
                self.currentRoomDetections.append(contentsOf: newDetections)
            }
            .store(in: &cancellables)
    }

    // MARK: - Live AI sampling (langsung dari feed kamera RoomPlan)

    private func startLiveAISampling() {
        frameSamplingTimer?.invalidate()
        frameSamplingTimer = Timer.scheduledTimer(withTimeInterval: frameSamplingInterval, repeats: true) { [weak self] _ in
            self?.sampleCurrentFrameForAI()
        }
    }

    private func stopLiveAISampling() {
        frameSamplingTimer?.invalidate()
        frameSamplingTimer = nil
    }

    private func sampleCurrentFrameForAI() {
        guard let frame = roomPlan.arSession?.currentFrame else { return }
        let pixelBuffer = frame.capturedImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
        detector.detect(from: cgImage)
    }

    // MARK: - Room Management

    /// Dipanggil saat user menekan "next ruangan" / "selesai" di post-scan sheet
    func addRoom(name: String, floor: String, type: RoomType) {
        let label = name.trimmingCharacters(in: .whitespaces).isEmpty ? type.rawValue : name
        let report = analyst.analyze(detections: currentRoomDetections)

        let scanned = ScannedRoom(
            name: label,
            floor: floor,
            type: type,
            capturedRoom: capturedRoom,
            detections: currentRoomDetections,
            aiReport: report
        )
        scannedRooms.append(scanned)
        roomPlan.commitCurrentRoom()

        // reset akumulator supaya ruangan berikutnya mulai dari nol
        currentRoomDetections = []
        detector.clear()
    }

    /// Reset hanya state scan ruangan (bukan house info) — ARSession TETAP hidup
    /// (dipanggil dari ScanningView setelah "Finish Scan" + commit lewat addRoom)
    func resetScanForNextRoom() {
        capturedRoom = nil
        roomPlan.resetForNextRoom()
    }

    // MARK: - Build & Save House

    /// Gabungkan semua ruangan (StructureBuilder) → hitung denah 2D asli,
    /// export USDZ untuk 3D, dan agregasi semua AIReport ruangan.
    @MainActor
    func buildHouse() async -> House {
        isBuildingHouse = true
        defer { isBuildingHouse = false }

        let rooms = scannedRooms.map {
            Room(name: $0.name, type: $0.type, floor: $0.floor, aiReport: $0.aiReport)
        }

        var usdzURL: URL?
        var wallSegments: [WallSegment2D] = []

        if !roomPlan.completedRooms.isEmpty {
            do {
                let structure = try await roomPlan.buildStructure()
                wallSegments = FloorPlanGeometry.wallSegments(from: structure)
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(UUID().uuidString).usdz")
                try structure.export(to: url)
                usdzURL = url
            } catch {
                // Fallback: gagal digabung (mis. cuma 1 ruangan, atau relocalization gagal) —
                // tetap tampilkan ruangan pertama saja daripada kosong total.
                print("[SurveySession] StructureBuilder gagal, fallback ke 1 ruangan:", error)
                if let first = roomPlan.completedRooms.first {
                    wallSegments = FloorPlanGeometry.wallSegments(from: first)
                    let url = FileManager.default.temporaryDirectory
                        .appendingPathComponent("\(UUID().uuidString).usdz")
                    try? first.export(to: url)
                    usdzURL = url
                }
            }
        }

        return House(
            name:            houseName,
            developer:       "",
            harga:           harga,
            luasTanah:       luasTanah,
            catatan:         catatan,
            rooms:           rooms,
            floorAreaSqM:    computeFloorArea(from: wallSegments),
            wallAreaSqM:     computeWallArea(),
            ceilingHeightM:  computeCeilingHeight(),
            usdzURL:         usdzURL,
            wallSegments:    wallSegments,
            overallReport:   aggregateReport(from: scannedRooms.compactMap(\.aiReport))
        )
    }

    /// Gabungkan AIReport tiap ruangan jadi satu ringkasan (Property Dashboard / Survey Report)
    private func aggregateReport(from reports: [AIReport]) -> AIReport? {
        guard !reports.isEmpty else { return nil }

        let avgScore = reports.map(\.conditionScore).reduce(0, +) / reports.count
        let allDetections = reports.flatMap(\.detections)
        let worstPriority = reports.map(\.priority).max { $0.rank < $1.rank } ?? .low
        let recs = Array(Set(reports.flatMap(\.recommendation))).sorted()

        let summary = allDetections.isEmpty
            ? "Tidak ditemukan masalah pada \(reports.count) ruangan yang di-scan."
            : "\(allDetections.count) potensi masalah ditemukan di \(reports.count) ruangan."

        return AIReport(
            conditionScore: avgScore,
            priority: worstPriority,
            summary: summary,
            recommendation: recs.isEmpty ? ["Tidak ada perbaikan yang diperlukan."] : recs,
            detections: allDetections
        )
    }

    /// Panggil ini setelah save — bersihkan sesi untuk survey berikutnya
    func startNewSurvey() {
        roomPlan.stop(keepSessionAlive: false)   // baru sekarang ARSession benar-benar di-pause
        roomPlan.resetSurvey()

        scannedRooms   = []
        currentRoomDetections = []
        houseName      = ""
        harga          = ""
        luasTanah      = ""
        catatan        = ""
        capturedRoom   = nil
    }

    // MARK: - Metric Computation

    private func computeFloorArea(from segments: [WallSegment2D]) -> Double {
        guard !segments.isEmpty else { return 0 }
        let bounds = FloorPlanGeometry.bounds(of: segments)
        return Double(bounds.width * bounds.height)
    }

    private func computeWallArea() -> Double {
        scannedRooms.reduce(0) { total, room in
            guard let room = room.capturedRoom else { return total }
            return total + room.walls.reduce(0) { $0 + Double($1.dimensions.x * $1.dimensions.y) }
        }
    }

    private func computeCeilingHeight() -> Double {
        scannedRooms
            .compactMap { $0.capturedRoom?.walls.map { Double($0.dimensions.y) }.max() }
            .max() ?? 0
    }
}
