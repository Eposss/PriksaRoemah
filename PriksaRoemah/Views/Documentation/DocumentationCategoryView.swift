//
//  DocumentationCategoryView.swift
//  PriksaRoemah
//
//  Created by Ignasius Holy Prasetya on 09/07/26.
//


import SwiftUI

/// Full grid semua foto 1 RoomType — destination dari "See All" di DocumentationView.
struct DocumentationCategoryView: View {

    @ObservedObject var session: SurveySession
    let houseID: UUID
    let roomType: RoomType

    @State private var isSelecting = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var showAddSheet = false

    private var photos: [DocumentationPhoto] {
        session.savedHouses.first { $0.id == houseID }?
            .documentationPhotos.filter { $0.roomType == roomType } ?? []
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(photos) { photo in
                    photoCard(photo)
                }
            }
            .padding()
        }
        .navigationTitle(roomType.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isSelecting ? "Selesai" : "Edit") {
                    isSelecting.toggle()
                    if !isSelecting { selectedIDs.removeAll() }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isSelecting && !selectedIDs.isEmpty {
                Button(role: .destructive) {
                    session.deleteDocumentationPhotos(houseID: houseID, photoIDs: selectedIDs)
                    selectedIDs.removeAll()
                    isSelecting = false
                } label: {
                    Label("Hapus \(selectedIDs.count) foto", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.12))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding()
                .background(.ultraThinMaterial)
            } else if !isSelecting {
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
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddDocumentationPhotoSheet(session: session, houseID: houseID, defaultRoomType: roomType)
        }
    }

    private func photoCard(_ photo: DocumentationPhoto) -> some View {
        let isSelected = selectedIDs.contains(photo.id)
        return Button {
            guard isSelecting else { return }
            if isSelected { selectedIDs.remove(photo.id) } else { selectedIDs.insert(photo.id) }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    if let uiImage = UIImage(data: photo.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 130)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .clipped()
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.blue : .clear, lineWidth: 3)
                            )
                    }
                    if isSelecting {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? .blue : .white)
                            .padding(6)
                    }
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