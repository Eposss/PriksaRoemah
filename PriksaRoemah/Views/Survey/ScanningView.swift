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

    var body: some View {
        ZStack {
            RoomPlanContainer(manager: session.roomPlan)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        if session.isRoomPlanScanning || !session.currentFloorRooms.isEmpty {
                            showDiscardAlert = true
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.black.opacity(0.35))
                            .clipShape(Circle())
                    }
                    Spacer()
                    statusBadge
                    Spacer()
                    // Spacer placeholder biar statusBadge tetap center secara visual
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal)
                .padding(.top)
                Spacer()
            }

            VStack {
                Spacer()
                scanButton
                    .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
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
                showNewRoomSheet = false
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

    // MARK: - Scan button (shutter mengambang, tidak menutupi preview)

    private var scanButton: some View {
        VStack(spacing: 10) {
            Button {
                if session.isRoomPlanScanning {
                    session.roomPlan.stop(keepSessionAlive: true)
                } else {
                    session.roomPlan.start()
                }
            } label: {
                ZStack {
                    Circle().fill(.white).frame(width: 72, height: 72)
                    if session.isRoomPlanScanning {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.red)
                            .frame(width: 28, height: 28)
                    } else {
                        Circle().fill(Color.blue).frame(width: 58, height: 58)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.6), lineWidth: 3)
                        .frame(width: 80, height: 80)
                )
            }
            .buttonStyle(.plain)

            Text(session.isRoomPlanScanning ? "Finish Room" : "Start Scan")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.black.opacity(0.35))
                .clipShape(Capsule())
        }
    }

    // MARK: - New Room sheet
    //
    // Sesuai mockup: nama ruangan (editable), "Next Room" (lanjut scan ruangan
    // lain di lantai yang sama), "Finish Scanning" (lantai ini selesai), "Rescan".

    private var newRoomSheet: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            Text("New Room")
                .font(.headline)

            TextField("Room name", text: $pendingRoomName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 24)

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
                        .background(Color.blue)
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
            .padding(.horizontal, 24)

            Spacer()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled(true)
    }

    private func commitRoomAndContinue() {
        session.addRoom(name: pendingRoomName, type: pendingType)
        roomCounter += 1
        session.resetScanForNextRoom()
        showNewRoomSheet = false
    }

    private func commitRoomAndFinishFloor() {
        session.addRoom(name: pendingRoomName, type: pendingType)
        showNewRoomSheet = false
        session.roomPlan.stop(keepSessionAlive: true)
        Task {
            await session.finishCurrentFloor()
            await MainActor.run {
                path.append(.reviewScan(houseID: houseID))
            }
        }
    }
}
