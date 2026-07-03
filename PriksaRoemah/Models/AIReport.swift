//
//  AIReport.swift
//  HVMAN
//
//  Created by Ignasius Holy Prasetya on 02/07/26.
//

import Foundation

enum Priority: String, Hashable {

    case low
    case medium
    case high

    /// Dipakai untuk cari priority "terburuk" saat agregasi beberapa ruangan
    var rank: Int {
        switch self {
        case .low:    return 0
        case .medium: return 1
        case .high:   return 2
        }
    }

}

struct AIReport: Hashable {

    let conditionScore: Int

    let priority: Priority

    let summary: String

    let recommendation: [String]

    let detections: [Detection]

}
