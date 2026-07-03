import SwiftUI

// CollectionListView sekarang tidak dipakai langsung —
// HomeView sudah handle collection list secara langsung.
// File ini dipertahankan untuk backward compat / future use.
struct CollectionListView: View {

    @ObservedObject var session: SurveySession

    var body: some View {
        Group {
            if session.savedHouses.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "house.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Belum ada survey")
                        .font(.headline)
                    Spacer()
                }
            } else {
                List {
                    Section {
                        NavigationLink {
                            InstructionView(session: session)
                        } label: {
                            Label("Add New Survey", systemImage: "plus.circle.fill")
                        }
                    }

                    Section("Recent") {
                        ForEach(session.savedHouses) { house in
                            NavigationLink {
                                ReportView(house: house)
                            } label: {
                                HouseCard(house: house)
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Collections")
    }
}
