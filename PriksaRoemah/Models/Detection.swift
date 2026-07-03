//
//  Detection.swift
//  PriksaRoemah
//
//  Created by Ignasius Holy Prasetya on 02/07/26.
//

import Foundation
import CoreGraphics

enum Severity: String {

    case low
    case medium
    case high
    case unknown

}

struct Detection: Identifiable {

    let id = UUID()

    let label: String

    let confidence: Float

    let boundingBox: CGRect

    var severity: Severity {

        switch confidence {

        case 0.90...:
            return .high

        case 0.70..<0.90:
            return .medium

        default:
            return .low

        }

    }

}
