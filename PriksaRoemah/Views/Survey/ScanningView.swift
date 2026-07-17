import SwiftUI
import RoomPlan

struct ScanningView: View {

    @ObservedObject var session: SurveySession
    var houseID: UUID?
    @Binding var path: [SurveyRoute]

    @State private var showNewRoomSheet = false
    @State private var showDiscardAlert = false
    @State private var showRescanAlert = false

    @State private var pendingRoomName = ""
    @State private var pendingType: RoomType = .bedroom
    @State private var roomCounter = 1
    @State private var showInstructions = true

    var body: some View {
        ZStack {
            RoomPlanContainer(manager: session.roomPlan)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        if session.isRoomPlanScanning || session.capturedRoom != nil || !session.currentFloorRooms.isEmpty {
                            showDiscardAlert = true
                        } else {
                            // Belum ada yang discan — nggak ada yang perlu
                            // dikonfirmasi, langsung keluar ke koleksi.
                            session.roomPlan.stop(keepSessionAlive: false)
                            path = []
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    // Sembunyikan status card + tombol Start Scan selama New Room
                    // sheet muncul — di fase ini user cukup pilih Next Room /
                    // Finish / Rescan (di sheet) atau X.
                    if !showNewRoomSheet {
                        statusBadge
                        Spacer()
                        scanActionButton
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                Spacer()
            }

            if showInstructions {
                InstructionView {
                    withAnimation { showInstructions = false }
                }
                .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            session.roomPlan.startPreview()
        }
        .onReceive(session.$capturedRoom) { room in
            guard room != nil else { return }
            pendingRoomName = "Room \(roomCounter)"
            pendingType     = .bedroom
            showNewRoomSheet = true
        }
        .sheet(isPresented: $showNewRoomSheet) {
            newRoomSheet
        }
        .alert("Discard Scan?", isPresented: $showDiscardAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Discard", role: .destructive) {
                session.roomPlan.stop(keepSessionAlive: false)
                session.startNewSurvey()
                path = []
            }
        } message: {
            Text("Your 2D and 3D results won't be saved.")
        }
        .alert("Rescan This Room?", isPresented: $showRescanAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Rescan", role: .destructive) {
                // Buang capturedRoom yang barusan, kembali ke kamera TANPA
                // commit ke currentFloorRooms.
                session.resetScanForNextRoom()
                withAnimation { showNewRoomSheet = false }
            }
        } message: {
            Text("This room's scan result will be discarded.")
        }
    }

    // MARK: - Status indicator
    //
    // Revisi: sebelum scanning, tampilkan card penuh. Begitu scanning aktif,
    // ciutkan jadi indikator minimal (teks + titik hijau) supaya tidak
    // menutupi guide bawaan RoomPlan ("Move closer", "Move slower", dll).

    @ViewBuilder
    private var statusBadge: some View {
        if session.isRoomPlanScanning {
            HStack(spacing: 6) {
                Circle().fill(Color.green).frame(width: 8, height: 8)
                Text("Sedang scanning...")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.black.opacity(0.35))
            .clipShape(Capsule())
        } else {
            VStack(spacing: 2) {
                Text(session.currentFloorRooms.isEmpty
                     ? "Belum ada ruangan"
                     : "\(session.currentFloorRooms.count) ruangan terscan")
                    .font(.subheadline.weight(.semibold))
                Text("Siap scan")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Scan action button (di top bar, bukan shutter di bawah — supaya
    // tidak ketiban preview 3D bawaan RoomPlan yang ke-render di tengah/bawah)

    private var scanActionButton: some View {
        Button {
            if session.isRoomPlanScanning {
                session.roomPlan.stop(keepSessionAlive: true)
            } else {
                session.roomPlan.start()
            }
        } label: {
            Text(session.isRoomPlanScanning ? "Finish Room" : "Start Scan")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(
                    session.isRoomPlanScanning ? Color.red : Color(red: 0.910, green: 0.349, blue: 0.090),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - New Room sheet
    //
    // Sesuai mockup: nama ruangan (editable), "Next Room" (lanjut scan ruangan
    // lain di lantai yang sama), "Finish Scanning" (lantai ini selesai), "Rescan".

    private var newRoomSheet: some View {
        ScrollView {
            VStack(spacing: 20) {
            Text("New Room")
                .font(.headline)

            TextField("Room name", text: $pendingRoomName)
                .textFieldStyle(.roundedBorder)

            Picker("Room type", selection: $pendingType) {
                ForEach(RoomType.allCases) {
                    Label($0.rawValue, systemImage: $0.icon).tag($0)
                }
            }
            .pickerStyle(.menu)

            VStack(spacing: 12) {
                Button {
                    commitRoomAndContinue()
                } label: {
                    Text("Next Room")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.910, green: 0.349, blue: 0.090))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    commitRoomAndFinishFloor()
                } label: {
                    Text("Finish Scanning")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button(role: .destructive) {
                    showRescanAlert = true
                } label: {
                    Text("Rescan")
                        .foregroundStyle(.red)
                }
            }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        // Peek kecil nge-anchor konten dari atas (judul "New Room" dulu), bisa
        // ditarik naik buat lihat semua. Nggak bisa di-dismiss penuh (biar user
        // nggak nyangkut), background tetap interaktif (model 3D bisa diputar).
        .presentationDetents([.height(140), .height(380)])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled)
        .interactiveDismissDisabled(true)
    }

    private func commitRoomAndContinue() {
        session.addRoom(name: pendingRoomName, type: pendingType)
        roomCounter += 1
        session.resetScanForNextRoom()
        withAnimation { showNewRoomSheet = false }
        // Balik ke kamera live (preview) + tombol "Start Scan" — TIDAK langsung
        // mulai scan. User tekan Start Scan sendiri buat mulai ruangan berikutnya.
        session.roomPlan.startPreview()
    }

    private func commitRoomAndFinishFloor() {
        session.addRoom(name: pendingRoomName, type: pendingType)
        withAnimation { showNewRoomSheet = false }
        session.roomPlan.stop(keepSessionAlive: true)
        Task {
            await session.finishCurrentFloor()
            await MainActor.run {
                path.append(.reviewScan(houseID: houseID))
            }
        }
    }
}
