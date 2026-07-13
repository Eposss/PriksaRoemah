//
//  DocumentationView.swift
//  PriksaRoemah
//
//  Created by Ignasius Holy Prasetya on 09/07/26.
//


import SwiftUI
import PhotosUI

/// Halaman "Documentation" — semua foto dokumentasi rumah, dikelompokkan per
/// RoomType (Bedroom, Bathroom, Kitchen, dst), gabungan seluruh lantai.
struct DocumentationView: View {

    @ObservedObject var session: SurveySession
    let houseID: UUID

    @State private var showAddSheet = false
    @State private var preview: PhotoPreviewRequest?

    private var house: House? { session.savedHouses.first { $0.id == houseID } }

    var body: some View {
        Group {
            if let house {
                content(house: house)
            } else {
                Text("Survey tidak ditemukan.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func content(house: House) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if house.documentationPhotos.isEmpty {
                    emptyState
                } else {
                    ForEach(house.documentationByRoomType, id: \.type) { group in
                        categorySection(house: house, type: group.type, photos: group.photos)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Documentation")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottomTrailing) {
            Button { showAddSheet = true } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.orange)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
        }
        .sheet(isPresented: $showAddSheet) {
            AddDocumentationPhotoSheet(session: session, houseID: houseID)
        }
        .fullScreenCover(item: $preview) { request in
            DocumentationPhotoPreviewView(photos: request.photos, selectedIndex: request.index)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
                .frame(width: 84, height: 84)
                .background(Color.orange.opacity(0.12), in: Circle())

            VStack(spacing: 6) {
                Text("Belum ada dokumentasi")
                    .font(.headline)
                Text("Tap tombol + untuk menambah foto pertama.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.top, 100)
    }

    private func categorySection(house: House, type: RoomType, photos: [DocumentationPhoto]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(type.rawValue).font(.headline)
                Spacer()
                NavigationLink {
                    DocumentationCategoryView(session: session, houseID: houseID, roomType: type)
                } label: {
                    Text("See All").font(.subheadline).foregroundStyle(.orange)
                }
            }
            .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Array(photos.prefix(2).enumerated()), id: \.element.id) { index, photo in
                    photoCard(photo, allPhotosInGroup: photos, index: index)
                }
            }
            .padding(.horizontal)
        }
    }

    private func photoCard(_ photo: DocumentationPhoto, allPhotosInGroup: [DocumentationPhoto], index: Int) -> some View {
        Button {
            preview = PhotoPreviewRequest(photos: allPhotosInGroup, index: index)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                if let uiImage = UIImage(data: photo.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .clipped()
                }
                Text("NOTE").font(.caption2).foregroundStyle(.secondary)
                Text(photo.note.isEmpty ? "–" : photo.note)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Item buat `.fullScreenCover(item:)` — bungkus foto-foto 1 grup + index yang
/// ditap sekaligus, biar nggak ada race antara 2 @State kepisah pas kebuka.
struct PhotoPreviewRequest: Identifiable {
    let id = UUID()
    let photos: [DocumentationPhoto]
    let index: Int
}

#Preview {
    let session = SurveySession()
    return NavigationStack {
        DocumentationView(session: session, houseID: session.savedHouses[0].id)
    }
}