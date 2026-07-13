import SwiftUI

struct HomeView: View {

    @StateObject private var session = SurveySession()
    @State private var showNewSurvey = false
    @State private var isEditing = false
    @State private var selectedIDs: Set<House.ID> = []
    @State private var searchText = ""
    @State private var showDeleteConfirmation = false

    private let orange = Color(red: 0.910, green: 0.349, blue: 0.090)

    private var filteredHouses: [House] {
        guard !searchText.isEmpty else { return session.savedHouses }
        return session.savedHouses.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                Group {
                    if session.savedHouses.isEmpty {
                        emptyState
                    } else {
                        surveyList
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .overlay(alignment: .bottom) {
                bottomBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showNewSurvey) {
                ScanningView(session: session)
            }
            .alert("Delete selected house?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteSelected() }
            } message: {
                Text("This action cannot be undone and all its associated data will be permanently removed.")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Surveys")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.black)

            Spacer()

            if !session.savedHouses.isEmpty {
                editButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private var editButton: some View {
        Button {
            withAnimation {
                isEditing.toggle()
                if !isEditing { selectedIDs.removeAll() }
            }
        } label: {
            if isEditing {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(orange, in: Circle())
            } else {
                Text("Edit")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(.white.opacity(0.7), in: Capsule())
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image("HuniLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 62, height: 68)

            Text("No Entries")
                .font(.system(size: 22, weight: .bold))
                .tracking(-0.26)
                .foregroundStyle(.black)

            Text("To add an entry, tap the plus button.")
                .font(.system(size: 17))
                .tracking(-0.23)
                .foregroundStyle(Color(red: 0.239, green: 0.239, blue: 0.239))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .offset(y: -60)
    }

    // MARK: - Survey list

    private var surveyList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(filteredHouses) { house in
                    surveyRow(house)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 140)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func surveyRow(_ house: House) -> some View {
        HStack(spacing: 10) {
            if isEditing {
                selectionCircle(for: house)
            }

            Group {
                if isEditing {
                    HouseCard(house: house)
                } else {
                    NavigationLink {
                        ReportView(house: house)
                    } label: {
                        HouseCard(house: house)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditing { toggleSelection(house) }
        }
    }

    private func selectionCircle(for house: House) -> some View {
        let isSelected = selectedIDs.contains(house.id)
        return ZStack {
            Circle()
                .fill(isSelected ? orange : .white)
            Circle()
                .stroke(Color(white: 0.85), lineWidth: isSelected ? 0 : 1.5)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 32, height: 32)
    }

    // MARK: - Bottom bar

    @ViewBuilder
    private var bottomBar: some View {
        if isEditing {
            editingToolbar
        } else if session.savedHouses.isEmpty {
            HStack {
                Spacer()
                addButton
            }
        } else {
            HStack(spacing: 12) {
                searchField
                addButton
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color(white: 0.75))
            TextField("Search", text: $searchText)
                .foregroundStyle(.black)
        }
        .font(.system(size: 17))
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(.white.opacity(0.7), in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
    }

    private var editingToolbar: some View {
        HStack {
            Button(action: toggleSelectAll) {
                Text(allSelected ? "Deselect All" : "Select All")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(.white.opacity(0.7), in: Capsule())
            }

            Spacer()

            Button {
                if !selectedIDs.isEmpty { showDeleteConfirmation = true }
            } label: {
                Text("Delete")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(selectedIDs.isEmpty ? .secondary : Color(red: 1.0, green: 0.22, blue: 0.235))
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(.white.opacity(0.7), in: Capsule())
            }
            .disabled(selectedIDs.isEmpty)
        }
    }

    // ✅ FIX BUG 3: startNewSurvey() dipanggil di sini,
    // BUKAN di InstructionView.onAppear.
    private var addButton: some View {
        Button {
            session.startNewSurvey()
            showNewSurvey = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(orange)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
        }
    }

    // MARK: - Selection helpers

    private var allSelected: Bool {
        !filteredHouses.isEmpty && Set(filteredHouses.map(\.id)).isSubset(of: selectedIDs)
    }

    private func toggleSelection(_ house: House) {
        if selectedIDs.contains(house.id) {
            selectedIDs.remove(house.id)
        } else {
            selectedIDs.insert(house.id)
        }
    }

    private func toggleSelectAll() {
        if allSelected {
            selectedIDs.subtract(filteredHouses.map(\.id))
        } else {
            selectedIDs.formUnion(filteredHouses.map(\.id))
        }
    }

    private func deleteSelected() {
        session.savedHouses.removeAll { selectedIDs.contains($0.id) }
        selectedIDs.removeAll()
        isEditing = false
    }
}

#Preview { HomeView() }
