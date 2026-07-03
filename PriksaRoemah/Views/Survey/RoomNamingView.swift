import SwiftUI

// RoomNamingView sudah tidak dipakai di flow utama.
// Room type & name sekarang diisi via post-scan sheet di ScanningView.
// File ini dipertahankan agar tidak ada referensi compile error
// kalau ada NavigationLink lama yang belum dibersihkan.
@available(*, deprecated, message: "Gunakan post-scan sheet di ScanningView")
struct RoomNamingView: View {
    @ObservedObject var session: SurveySession
    var body: some View {
        Form {
            Section("Room Type") {
                Picker("Type", selection: $session.isRoomPlanScanning) {
                    Text("–").tag(false)
                }
            }
        }
        .navigationTitle("Room (deprecated)")
    }
}
