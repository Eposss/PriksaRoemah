//
//  PrimaryButton.swift
//  HVMAN
//
//  Created by Ignasius Holy Prasetya on 02/07/26.
//

import SwiftUI

struct PrimaryButton: View {

    let title: String
    let action: () -> Void

    var body: some View {

        Button(action: action) {

            Text(title)
                .bold()
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()

        }
        .background(Color.blue)
        .clipShape(Capsule())

    }

}
