//
//  FloorsListView.swift
//  PriksaRoemah
//
//  Created by Ignasius Holy Prasetya on 08/07/26.
//


import SwiftUI

/// Halaman "Floors" — muncul setelah tap 1 survey dari HomeView.
/// List semua lantai yang sudah discan untuk House ini.
struct FloorsListView: View {

    let house: House

    @State private var isSelecting = false
    @State private var selectedFloorIDs: Set<UUID> = []
    @State private var showDeleteConfirm = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                addFloorTile
                ForEach(house.floors) { floor in
                    floorTile(floor)
                }
            }
            .padding()
        }
        .navigationTitle(house.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isSelecting ? "Selesai" : "Edit") {
                    isSelecting.toggle()
                    if !isSelecting { selectedFloorIDs.removeAll() }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isSelecting && !selectedFloorIDs.isEmpty {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Hapus \(selectedFloorIDs.count) lantai", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.12))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .alert("Hapus lantai terpilih?", isPresented: $showDeleteConfirm) {
            Button("Batal", role: .cancel) {}
            Button("Hapus", role: .destructive) {
                // Catatan: House dipassing sebagai `let` (bukan Binding) di sini.
                // Untuk beneran menghapus & persist, FloorsListView perlu terima
                // Binding<House> (atau akses ke SurveySession/storage) dari caller —
                // tempat ini baru nyiapin UI-nya, logic hapus-nya nunggu keputusan
                // soal di mana House disimpan setelah save (in-memory vs storage).
            }
        } message: {
            Text("Tindakan ini tidak bisa dibatalkan dan semua data terkait akan dihapus permanen.")
        }
    }

    // MARK: - Tiles

    private var addFloorTile: some View {
        Button {
            // TODO: mulai sesi scan lantai baru untuk House yang sudah tersimpan ini.
            // Butuh desain terpisah karena SurveySession saat ini dibangun untuk
            // alur "1 survey baru dari awal", bukan "nambah lantai ke House lama".
        } label: {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.secondary)
                )
        }
        .buttonStyle(.plain)
    }

    private func floorTile(_ floor: Floor) -> some View {
        let isSelected = selectedFloorIDs.contains(floor.id)

        return Group {
            if isSelecting {
                Button { toggleSelection(floor) } label: { floorTileContent(floor, isSelected: isSelected) }
                    .buttonStyle(.plain)
            } else {
                NavigationLink {
                    ReportView(house: house, floor: floor)
                } label: {
                    floorTileContent(floor, isSelected: false)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func floorTileContent(_ floor: Floor, isSelected: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        FloorPlan2DView(wallSegments: floor.wallSegments)
                            .padding(6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.blue : .clear, lineWidth: 3)
                    )

                if isSelecting {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? .blue : .secondary)
                        .background(Circle().fill(.white))
                        .padding(6)
                }
            }
            Text(floor.label)
                .font(.caption.weight(.medium))
        }
    }

    private func toggleSelection(_ floor: Floor) {
        if selectedFloorIDs.contains(floor.id) {
            selectedFloorIDs.remove(floor.id)
        } else {
            selectedFloorIDs.insert(floor.id)
        }
    }
}

#Preview {
    NavigationStack {
        FloorsListView(house: House.dummyAll[1])
    }
}