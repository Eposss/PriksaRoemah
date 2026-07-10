//
//  DocumentationPhoto.swift
//  PriksaRoemah
//
//  Created by Ignasius Holy Prasetya on 09/07/26.
//

import Foundation

/// Satu foto dokumentasi — biasa aja, TANPA AI/analisis apapun.
/// Ditag per RoomType (bukan per Floor/Room spesifik), sesuai alur "+" di
/// halaman Documentation: user cuma pilih Room Type + catatan singkat.
struct DocumentationPhoto: Identifiable, Hashable {
    let id = UUID()
    var imageData: Data
    var roomType: RoomType
    var note: String = ""
    var dateAdded: Date = Date()
}
