//
//  AddDocumentationPhotoSheet.swift
//  PriksaRoemah
//
//  Created by Ignasius Holy Prasetya on 09/07/26.
//


import SwiftUI
import PhotosUI

/// Alur tambah foto dokumentasi baru — sesuai video: ambil/pilih foto dulu,
/// lalu pilih Room Type + catatan, simpan. TANPA analisis AI apapun.
struct AddDocumentationPhotoSheet: View {

    @ObservedObject var session: SurveySession
    let houseID: UUID
    var defaultRoomType: RoomType = .bedroom

    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var roomType: RoomType
    @State private var note: String = ""

    @State private var showSourceDialog = false
    @State private var showCamera = false
    @State private var showLibraryPicker = false

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    init(session: SurveySession, houseID: UUID, defaultRoomType: RoomType = .bedroom) {
        self.session = session
        self.houseID = houseID
        self.defaultRoomType = defaultRoomType
        _roomType = State(initialValue: defaultRoomType)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                photoArea

                Form {
                    Picker("Room Type", selection: $roomType) {
                        ForEach(RoomType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    TextField("Catatan (opsional)", text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        save()
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(imageData == nil ? Color.secondary : Color.orange)
                    }
                    .disabled(imageData == nil)
                }
            }
        }
    }

    private var photoArea: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .onTapGesture { showSourceDialog = true }
            } else {
                Button {
                    showSourceDialog = true
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32))
                        Text("Pilih atau ambil foto")
                            .font(.subheadline)
                    }
                    .foregroundStyle(Color.orange)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .background(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.orange.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            .padding(1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .confirmationDialog("Add Photo", isPresented: $showSourceDialog, titleVisibility: .visible) {
            if isCameraAvailable {
                Button("Take Photo") { showCamera = true }
            }
            Button("Choose from Library") { showLibraryPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showCamera) {
            InspectionCameraPicker { uiImage in
                imageData = uiImage.jpegData(compressionQuality: 0.85)
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showLibraryPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    imageData = data
                }
            }
        }
    }

    private func save() {
        guard let imageData else { return }
        let photo = DocumentationPhoto(imageData: imageData, roomType: roomType, note: note)
        session.addDocumentationPhoto(houseID: houseID, photo: photo)
        dismiss()
    }
}