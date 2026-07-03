//
//  DetectionManager.swift
//  PriksaRoemah
//
//  Created by Ignasius Holy Prasetya on 02/07/26.
//

import Foundation
import Combine
import CoreGraphics

final class DetectionManager: ObservableObject {

    @Published var detections: [Detection] = []

    private let detector = WallDetectorService.shared

    func detect(from cgImage: CGImage) {

        detector.detect(cgImage: cgImage) { [weak self] result in

            self?.detections = result

        }

    }

    func clear() {

        detections.removeAll()

    }

    var mouldCount: Int {

        detections.filter {
            $0.label.lowercased() == "mould"
        }.count

    }

    var highestConfidence: Float {

        detections.map(\.confidence).max() ?? 0

    }

}
