//
//  SearchBar.swift
//  HVMAN
//
//  Created by Ignasius Holy Prasetya on 02/07/26.
//

import SwiftUI

struct SearchBar: View {

    @Binding var text: String

    var body: some View {

        HStack {

            Image(systemName: "magnifyingglass")

            TextField("Search", text: $text)

        }
        .padding(12)
        .background(Color.gray.opacity(0.12))
        .clipShape(Capsule())

    }

}
