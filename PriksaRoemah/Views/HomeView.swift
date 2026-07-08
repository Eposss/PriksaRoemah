import SwiftUI

struct HomeView: View {

    @StateObject private var session = SurveySession()
    @State private var showNewSurvey = false

    var body: some View {
        NavigationStack {
            Group {
                if session.savedHouses.isEmpty {
                    emptyState
                } else {
                    collectionList
                }
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // ✅ FIX BUG 3: startNewSurvey() dipanggil di sini,
                    // BUKAN di InstructionView.onAppear.
                    Button {
                        session.startNewSurvey()
                        showNewSurvey = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationDestination(isPresented: $showNewSurvey) {
                InstructionView(session: session)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "house.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            VStack(spacing: 8) {
                Text("No Surveys Yet")
                    .font(.title2.bold())
                Text("Start your first home inspection.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                session.startNewSurvey()
                showNewSurvey = true
            } label: {
                Text("Start Survey")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            Spacer()
        }
        .padding()
    }

    private var collectionList: some View {
        List {
            ForEach(session.savedHouses) { house in
                NavigationLink {
                    ReportView(house: house)
                } label: {
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
