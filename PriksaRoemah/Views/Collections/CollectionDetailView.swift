import SwiftUI

// CollectionDetailView sekarang hanya wrapper ke ReportView.
// Dipertahankan kalau ada NavigationLink lama yang masih pointing ke sini.
struct CollectionDetailView: View {
    let house: House

    var body: some View {
        ReportView(house: house)
    }
}

#Preview {
    NavigationStack {
        CollectionDetailView(house: House.dummyAll[0])
    }
}
