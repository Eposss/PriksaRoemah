import Foundation
import RoomPlan
import ARKit
import Combine

final class RoomPlanManager: ObservableObject {

    @Published var capturedRoom: CapturedRoom?      // hasil ruangan yang baru saja selesai
    @Published var isScanning = false

    /// Semua CapturedRoom yang sudah "commit" untuk LANTAI YANG SEDANG discan —
    /// dipakai StructureBuilder saat lantai itu selesai. Di-clear tiap kali
    /// pindah ke lantai berikutnya lewat extractCompletedRoomsForFloor(),
    /// TAPI ARSession-nya sendiri tetap hidup (world tracking gak reset),
    /// supaya kalau user scan ulang/nambah ruangan masih presisi.
    private(set) var completedRooms: [CapturedRoom] = []

    weak var captureView: RoomCaptureView?

    /// Akses langsung ke ARSession yang dipakai RoomPlan.
    var arSession: ARSession? { captureView?.captureSession.arSession }

    /// Nyalakan kamera live (ARSession world tracking) TANPA memulai RoomPlan
    /// capture — dipakai supaya feed kamera sudah kelihatan (di-blur di balik
    /// layar instruksi) sebelum user benar-benar menekan "Start Scan".
    func startPreview() {
        guard let arSession = captureView?.captureSession.arSession else {
            print("[RoomPlanManager] captureView belum di-set — tidak bisa startPreview().")
            return
        }
        arSession.run(ARWorldTrackingConfiguration())
    }

    func start() {
        guard let captureView else {
            print("[RoomPlanManager] captureView belum di-set — pastikan RoomPlanContainer sudah muncul di layar sebelum start() dipanggil.")
            return
        }
        capturedRoom = nil
        let config = RoomCaptureSession.Configuration()
        // captureSession instance-nya sama terus (dibuat sekali di RoomPlanContainer),
        // jadi kalau ARSession tidak di-pause, world tracking tetap nyambung antar ruangan
        // DAN antar lantai (selama app tidak backgrounded / session tidak di-stop total).
        captureView.captureSession.run(configuration: config)
        isScanning = true
    }

    /// keepSessionAlive = true saat mau lanjut scan ruangan/lantai berikutnya
    /// dalam survey yang sama. keepSessionAlive = false saat survey benar-benar selesai.
    func stop(keepSessionAlive: Bool) {
        captureView?.captureSession.stop(pauseARSession: !keepSessionAlive)
        isScanning = false
    }

    func resetForNextRoom() {
        capturedRoom = nil
    }

    /// Simpan hasil ruangan yang baru selesai ke daftar ruangan lantai saat ini.
    func commitCurrentRoom() {
        guard let room = capturedRoom else { return }
        completedRooms.append(room)
    }

    /// Dipanggil saat 1 lantai selesai (user tekan "Finish Scanning" di New Room sheet).
    /// Mengambil semua CapturedRoom yang sudah commit untuk lantai ini, lalu
    /// mengosongkan bucket-nya supaya lantai berikutnya mulai dari nol —
    /// TANPA mematikan ARSession (world tracking tetap jalan).
    func extractCompletedRoomsForFloor() -> [CapturedRoom] {
        let rooms = completedRooms
        completedRooms.removeAll()
        return rooms
    }

    /// Dipanggil saat survey (seluruh rumah, semua lantai) benar-benar selesai/dibatalkan.
    func resetSurvey() {
        capturedRoom = nil
        completedRooms.removeAll()
    }

    /// Gabungkan CapturedRoom yang diberikan jadi satu CapturedStructure (1 lantai).
    /// Perlu iOS 17+ & device LiDAR.
    func buildStructure(from rooms: [CapturedRoom]) async throws -> CapturedStructure {
        let builder = StructureBuilder(options: [.beautifyObjects])
        return try await builder.capturedStructure(from: rooms)
    }
}
