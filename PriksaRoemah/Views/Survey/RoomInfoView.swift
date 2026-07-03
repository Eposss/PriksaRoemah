import SwiftUI

struct RoomInfoView: View {

    @ObservedObject var session: SurveySession

    @State private var savedHouse: House?
    @State private var navigateToReport = false

    var canSave: Bool {
        !session.houseName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !session.harga.trimmingCharacters(in: .whitespaces).isEmpty &&
        !session.luasTanah.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section {
                TextField("Nama Cluster*", text: $session.houseName)
                TextField("Harga (Rp)*", text: $session.harga)
                    .keyboardType(.numberPad)
                TextField("Luas Tanah (m²)*", text: $session.luasTanah)
                    .keyboardType(.decimalPad)
                TextField("Catatan", text: $session.catatan, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            } header: {
                Text("Informasi")
            } footer: {
                Text("* Wajib diisi")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Ruangan terscan (\(session.scannedRooms.count))") {
                if session.scannedRooms.isEmpty {
                    Text("Belum ada ruangan yang di-scan.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(session.scannedRooms) { room in
                        HStack {
                            Image(systemName: room.type.icon)
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            Text(room.name)
                            Spacer()
                            Text("Lantai \(room.floor)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Informasi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    let house = session.buildHouse()
                    session.savedHouses.insert(house, at: 0)
                    savedHouse = house
                    session.startNewSurvey()
                    navigateToReport = true
                }
                .fontWeight(.semibold)
                .disabled(!canSave)
            }
        }
        .navigationDestination(isPresented: $navigateToReport) {
            if let house = savedHouse {
                ReportView(house: house)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RoomInfoView(session: SurveySession())
    }
}
