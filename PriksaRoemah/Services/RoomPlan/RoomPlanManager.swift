import Foundation
import RoomPlan
import ARKit
import Combine

final class RoomPlanManager: ObservableObject {

    @Published var capturedRoom: CapturedRoom?      // hasil ruangan yang baru saja selesai
    @Published var isScanning = false

    /// Semua CapturedRoom yang sudah "commit" dalam 1 survey — dipakai StructureBuilder di akhir
    private(set) var completedRooms: [CapturedRoom] = []

    weak var captureView: RoomCaptureView?

    /// Akses langsung ke ARSession yang dipakai RoomPlan — dipakai untuk sampling frame AI
    var arSession: ARSession? { captureView?.captureSession.arSession }

    func start() {
        guard let captureView else {
            print("[RoomPlanManager] captureView belum di-set — pastikan RoomPlanContainer sudah muncul di layar sebelum start() dipanggil.")
            return
        }
        capturedRoom = nil
        let config = RoomCaptureSession.Configuration()
        // captureSession instance-nya sama terus (dibuat sekali di RoomPlanContainer),
        // jadi kalau ARSession tidak di-pause, world tracking tetap nyambung antar ruangan.
        captureView.captureSession.run(configuration: config)
        isScanning = true
    }

    /// keepSessionAlive = true saat mau lanjut scan ruangan berikutnya dalam survey yang sama
    /// (supaya semua ruangan bisa digabung StructureBuilder dengan koordinat yang benar).
    /// keepSessionAlive = false saat survey benar-benar selesai.
    func stop(keepSessionAlive: Bool) {
        captureView?.captureSession.stop(pauseARSession: !keepSessionAlive)
        isScanning = false
    }

    func resetForNextRoom() {
        capturedRoom = nil
    }

    /// Simpan hasil ruangan yang baru selesai ke daftar ruangan yang sudah commit
    func commitCurrentRoom() {
        guard let room = capturedRoom else { return }
        completedRooms.append(room)
    }

    func resetSurvey() {
        capturedRoom = nil
        completedRooms.removeAll()
    }

    /// Gabungkan semua ruangan jadi satu struktur rumah (perlu iOS 17+ & device LiDAR)
    func buildStructure() async throws -> CapturedStructure {
        let builder = StructureBuilder(options: [.beautifyObjects])
        return try await builder.capturedStructure(from: completedRooms)
    }
}
