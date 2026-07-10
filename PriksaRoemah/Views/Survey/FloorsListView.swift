//
//  FloorsListView.swift
//  PriksaRoemah
//
//  Created by Ignasius Holy Prasetya on 08/07/26.
//

import SwiftUI

/// Halaman "Floors" — muncul setelah tap 1 survey dari HomeView.
struct FloorsListView: View {

    @ObservedObject var session: SurveySession
    let houseID: UUID
    @Binding var path: [SurveyRoute]

    @State private var isSelecting = false
    @State private var selectedFloorIDs: Set<UUID> = []
    @State private var showDeleteConfirm = false

    private var house: House? { session.savedHouses.first { $0.id == houseID } }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

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
            VStack(alignment: .leading, spacing: 16) {
                infoCard(house: house)

                Text("Floors")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 14) {
                    addFloorTile
                    ForEach(house.floors) { floor in
                        floorTile(house: house, floor: floor)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
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
                session.deleteFloors(houseID: houseID, floorIDs: selectedFloorIDs)
                selectedFloorIDs.removeAll()
                isSelecting = false
            }
        } message: {
            Text("Tindakan ini tidak bisa dibatalkan dan semua data terkait akan dihapus permanen.")
        }
    }

    // MARK: - Info card (House Facing — otomatis dari compass, read-only + Documentation)

    private func infoCard(house: House) -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "location.north.fill")
                    .foregroundStyle(.orange)
                    .frame(width: 24)
                Text("House Facing")
                    .foregroundStyle(.primary)
                Spacer()
                Text(house.facing?.displayName ?? "Not detected")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider().padding(.leading, 52)

            NavigationLink {
                DocumentationView(session: session, houseID: houseID)
            } label: {
                HStack {
                    Image(systemName: "photo.stack.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 24)
                    Text("Documentation")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.primary.opacity(0.08)))
        .padding(.horizontal)
    }

    // MARK: - Tiles
    //
    // addFloorTile punya Text label kosong (opacity 0) di bawah kotaknya supaya
    // total tinggi tile sama persis dengan floorTile (yang punya label "Floor N")
    // — tanpa ini kedua kolom grid jadi beda tinggi & kelihatan tidak simetris.

    private var addFloorTile: some View {
        Button {
            session.startNextFloor()
            session.currentFloorNumber = (house?.floors.count ?? 0) + 1
            path.append(.instruction(houseID: houseID))
        } label: {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.secondary)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.primary.opacity(0.08)))
                Text(" ")
                    .font(.caption.weight(.medium))
                    .opacity(0)
            }
        }
        .buttonStyle(.plain)
    }

    private func floorTile(house: House, floor: Floor) -> some View {
        let isSelected = selectedFloorIDs.contains(floor.id)

        return Group {
            if isSelecting {
                Button { toggleSelection(floor) } label: { floorTileContent(floor, isSelected: isSelected) }
                    .buttonStyle(.plain)
            } else {
                NavigationLink {
                    ReportView(session: session, houseID: house.id, floorID: floor.id)
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
                    .fill(Color(.secondarySystemGroupedBackground))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(FloorPlan2DView(wallSegments: floor.wallSegments).padding(6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(isSelected ? Color.blue : Color.primary.opacity(0.08), lineWidth: isSelected ? 3 : 1)
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
    let session = SurveySession()
    return NavigationStack {
        FloorsListView(session: session, houseID: session.savedHouses[1].id, path: .constant([]))
    }
}
