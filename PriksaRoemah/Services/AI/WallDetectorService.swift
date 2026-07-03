//
//  WallDetectorService.swift
//  PriksaRoemah
//
//  Created by Ignasius Holy Prasetya on 02/07/26.
//

import Foundation
import Vision
import CoreML

final class WallDetectorService {

    static let shared = WallDetectorService()

    private let visionModel: VNCoreMLModel

    private init() {

        let config = MLModelConfiguration()

        guard
            let model = try? WallDetector(configuration: config).model,
            let visionModel = try? VNCoreMLModel(for: model)
        else {

            fatalError("Cannot load WallDetector")

        }

        self.visionModel = visionModel

    }

    func detect(
        cgImage: CGImage,
        completion: @escaping ([Detection]) -> Void
    ) {

        let request = VNCoreMLRequest(model: visionModel) { request, _ in

            guard let observations = request.results as? [VNRecognizedObjectObservation] else {

                DispatchQueue.main.async {
                    completion([])
                }

                return

            }

            let detections = observations.compactMap { observation -> Detection? in

                guard let topLabel = observation.labels.first else {

                    return nil

                }

                return Detection(
                    label: topLabel.identifier,
                    confidence: topLabel.confidence,
                    boundingBox: observation.boundingBox
                )

            }

            DispatchQueue.main.async {

                completion(detections)

            }

        }

        request.imageCropAndScaleOption = VNImageCropAndScaleOption.scaleFill

        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            options: [:]
        )

        DispatchQueue.global(qos: .userInitiated).async {

            try? handler.perform([request])

        }

    }

}
