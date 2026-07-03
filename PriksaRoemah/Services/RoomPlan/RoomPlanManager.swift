import Foundation
import RoomPlan
import Combine

final class RoomPlanManager: ObservableObject {

    @Published var capturedRoom: CapturedRoom?
    @Published var isScanning = false

    weak var captureView: RoomCaptureView?

    func start() {
        guard let captureView else {
            print("[RoomPlanManager] captureView belum di-set — pastikan RoomPlanContainer sudah muncul di layar sebelum start() dipanggil.")
            return
        }
        capturedRoom = nil   // reset sebelum scan baru
        let config = RoomCaptureSession.Configuration()
        captureView.captureSession.run(configuration: config)
        isScanning = true
    }

    func stop() {
        captureView?.captureSession.stop()
        isScanning = false
    }
}
