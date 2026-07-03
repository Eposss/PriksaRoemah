//
//  RoomPlanContainer.swift
//  PriksaRoemah
//
//  Created by Ignasius Holy Prasetya on 03/07/26.
//


import SwiftUI
import RoomPlan

struct RoomPlanContainer: UIViewRepresentable {

    @ObservedObject var manager: RoomPlanManager

    func makeCoordinator() -> RoomPlanCoordinator {
        RoomPlanCoordinator(manager: manager)
    }

    func makeUIView(context: Context) -> RoomCaptureView {
        let captureView = RoomCaptureView(frame: .zero)
        captureView.captureSession.delegate = context.coordinator
        captureView.delegate = context.coordinator
        manager.captureView = captureView
        return captureView
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}
}

// Coordinator dipindah ke top-level — nested class di extension
// punya mangled name tidak stabil untuk NSCoding (penyebab error).
final class RoomPlanCoordinator: NSObject,
                                  RoomCaptureViewDelegate,
                                  RoomCaptureSessionDelegate {

    let manager: RoomPlanManager

    init(manager: RoomPlanManager) {
        self.manager = manager
    }

    required init?(coder: NSCoder) {
        fatalError("RoomPlanCoordinator is created by RoomPlanContainer and cannot be decoded.")
    }

    func encode(with coder: NSCoder) {}

    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        DispatchQueue.main.async {
            self.manager.capturedRoom = processedResult
            self.manager.isScanning   = false
        }
    }

    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
        if let error {
            print("[RoomPlan] Session ended with error:", error.localizedDescription)
        }
    }
}
