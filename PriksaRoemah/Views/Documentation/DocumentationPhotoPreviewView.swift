//
//  DocumentationPhotoPreviewView.swift
//  PriksaRoemah
//
//  Full-screen photo viewer — dibuka dari grid Documentation. Sesuai Figma
//  "floor page - filled": foto besar full-bleed, overlay NOTE di bawah, strip
//  thumbnail buat pindah antar foto, tombol back di kiri atas.
//

import SwiftUI

struct DocumentationPhotoPreviewView: View {

    let photos: [DocumentationPhoto]
    @State var selectedIndex: Int

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            TabView(selection: $selectedIndex) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    if let uiImage = UIImage(data: photo.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack {
                Spacer()
                noteOverlay
                thumbnailStrip
            }

            backButton
        }
        .preferredColorScheme(.dark)
    }

    private var currentPhoto: DocumentationPhoto? {
        photos.indices.contains(selectedIndex) ? photos[selectedIndex] : nil
    }

    private var backButton: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var noteOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NOTE")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text(currentPhoto?.note.isEmpty == false ? currentPhoto!.note : "–")
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.black.opacity(0.45))
    }

    private var thumbnailStrip: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        if let uiImage = UIImage(data: photo.imageData) {
                            Button {
                                withAnimation { selectedIndex = index }
                            } label: {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 56, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(.white, lineWidth: index == selectedIndex ? 2 : 0)
                                    )
                                    .opacity(index == selectedIndex ? 1 : 0.5)
                            }
                            .buttonStyle(.plain)
                            .id(index)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(.black.opacity(0.7))
            .onChange(of: selectedIndex) { _, newValue in
                withAnimation { scrollProxy.scrollTo(newValue, anchor: .center) }
            }
        }
    }
}
