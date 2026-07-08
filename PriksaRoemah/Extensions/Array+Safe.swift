//
//  Array+Safe.swift
//  PriksaRoemah
//
//  Created by Ignasius Holy Prasetya on 05/07/26.
//

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
