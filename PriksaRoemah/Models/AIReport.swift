//
//  AIReport.swift
//  PriksaRoemah
//
//  Created by Ignasius Holy Prasetya on 02/07/26.
//

import Foundation

enum Priority: String {

    case low
    case medium
    case high

}

struct AIReport {

    let conditionScore: Int

    let priority: Priority

    let summary: String

    let recommendation: [String]

    let detections: [Detection]

}
