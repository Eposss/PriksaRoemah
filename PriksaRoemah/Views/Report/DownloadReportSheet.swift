import SwiftUI

struct DownloadReportSheet: View {

    let house: House
    @Environment(\.dismiss) private var dismiss

    @State private var include2D  = true
    @State private var include3D  = false
    @State private var showDone   = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {

                Text("Pilih bagian yang mau disertakan")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 0) {
                    Toggle(isOn: $include2D) {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Floor Plan (2D)")
                                    .font(.subheadline)
                                Text("~10.5 Mb")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()

                    Divider()

                    Toggle(isOn: $include3D) {
                        HStack {
                            Image(systemName: "cube")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Floor Plan (3D)")
                                    .font(.subheadline)
                                Text("~32 Mb")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    // TODO: implement actual PDF/USDZ export
                    showDone = true
                } label: {
                    Label("Download", systemImage: "arrow.down.circle.fill")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(include2D || include3D ? Color.blue : Color(.systemGray4))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!include2D && !include3D)

                Spacer()
            }
            .padding()
            .navigationTitle("Download Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Tutup") { dismiss() }
                }
            }
            .alert("Berhasil disimpan", isPresented: $showDone) {
                Button("OK") { dismiss() }
            } message: {
                Text("Report \(house.name) siap diunduh.")
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    DownloadReportSheet(house: House.dummyAll[0])
}
