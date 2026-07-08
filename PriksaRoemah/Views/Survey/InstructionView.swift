import SwiftUI

struct InstructionView: View {

    @ObservedObject var session: SurveySession

    private let steps = [
        ("Scan satu ruangan", "Scan satu ruangan dalam sekali sesi.", "cube.transparent"),
        ("Jalan pelan",       "Jalan pelan mengelilingi ruangan.",    "figure.walk"),
        ("Pastikan cahaya",   "Pastikan pencahayaan cukup terang.",   "sun.max"),
        ("Jangan halangi",    "Jangan halangi kamera saat scanning.", "camera")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 72))
                .foregroundStyle(.blue)
                .padding(.bottom, 24)

            Text("Survey Instructions")
                .font(.largeTitle.bold())
                .padding(.bottom, 32)

            VStack(alignment: .leading, spacing: 20) {
                ForEach(steps, id: \.0) { step in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: step.2)
                            .font(.system(size: 20))
                            .foregroundStyle(.blue)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.0).font(.subheadline.bold())
                            Text(step.1).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)

            Spacer()

            NavigationLink {
                ScanningView(session: session)
            } label: {
                Text("Mulai Scan")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding()
        .navigationTitle("Instruction")
        .navigationBarTitleDisplayMode(.inline)
        // ✅ FIX BUG 3: startNewSurvey() DIHAPUS dari sini.
        // Sekarang dipanggil dari HomeView saat user tap "mulai survey baru",
        // sehingga data tidak ter-clear kalau user navigasi balik ke halaman ini.
    }
}

#Preview {
    NavigationStack { InstructionView(session: SurveySession()) }
}
