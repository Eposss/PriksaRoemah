//
//  AIAnalysisService.swift
//  PriksaRoemah
//
//  Created by Ignasius Holy Prasetya on 02/07/26.
//

import Foundation

final class AIAnalysisService {

    static let shared = AIAnalysisService()

    private init() {}

    func analyze(
        detections: [Detection]
    ) -> AIReport {

        let mouldCount = detections.count

        let score = max(0, 100 - mouldCount * 8)

        let priority: Priority

        switch mouldCount {

        case 0:

            priority = .low

        case 1...3:

            priority = .medium

        default:

            priority = .high

        }

        let summary: String

        switch mouldCount {

        case 0:

            summary = "No visible mould detected."

        case 1...3:

            summary = "Minor mould detected on wall surfaces."

        default:

            summary = "Extensive mould detected. Immediate inspection is recommended."

        }

        var recommendation: [String] = []

        if mouldCount > 0 {

            recommendation.append("Inspect moisture source.")
            recommendation.append("Clean affected area.")
            recommendation.append("Improve ventilation.")

        }

        if recommendation.isEmpty {

            recommendation.append("No repair required.")

        }

        return AIReport(

            conditionScore: score,
            priority: priority,
            summary: summary,
            recommendation: recommendation,
            detections: detections

        )

    }

}
