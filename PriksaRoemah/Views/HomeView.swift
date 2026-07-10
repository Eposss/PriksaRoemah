import SwiftUI

struct HomeView: View {

    @StateObject private var session = SurveySession()
    @State private var path: [SurveyRoute] = []
    @State private var showDiscardInProgressAlert = false

    private var hasInProgressSurvey: Bool {
        session.pendingFloor != nil || !session.currentFloorRooms.isEmpty
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if session.savedHouses.isEmpty {
                    emptyState
                } else {
                    collectionList
                }
            }
            .navigationTitle("Surveys")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if hasInProgressSurvey {
                            showDiscardInProgressAlert = true
                        } else {
                            session.startNewSurvey()
                            path.append(.instruction(houseID: nil))
                        }
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationDestination(for: SurveyRoute.self) { route in
                destination(for: route)
            }
            .alert("Discard In-Progress Survey?", isPresented: $showDiscardInProgressAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Discard", role: .destructive) {
                    session.startNewSurvey()
                    path.append(.instruction(houseID: nil))
                }
            } message: {
                Text("You have an unsaved scan in progress. Starting a new survey will discard it.")
            }
        }
    }

    @ViewBuilder
    private func destination(for route: SurveyRoute) -> some View {
        switch route {
        case .instruction(let houseID):
            InstructionView(session: session, houseID: houseID, path: $path)
        case .scanning(let houseID):
            ScanningView(session: session, houseID: houseID, path: $path)
        case .reviewScan(let houseID):
            ReviewScanView(session: session, houseID: houseID, path: $path)
        case .floorsList(let houseID):
            FloorsListView(session: session, houseID: houseID, path: $path)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "house.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            VStack(spacing: 8) {
                Text("No Entries")
                    .font(.title2.bold())
                Text("To add an entry, tap the plus button.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
    }

    private var collectionList: some View {
        List {
            ForEach(session.savedHouses) { house in
                NavigationLink(value: SurveyRoute.floorsList(houseID: house.id)) {
                    HouseCard(house: house)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(.plain)
    }
}

#Preview { HomeView() }
