import SwiftUI
import RoomPlan

struct ScanningView: View {

    @ObservedObject var session: SurveySession

    // MARK: - Post-scan sheet state
    @State private var showPostScanSheet = false
    @State private var wantsToGoToInfo   = false   // flag untuk navigasi setelah sheet dismiss
    @State private var navigateToInfo    = false

    @State private var pendingFloor    = "1"
    @State private var pendingRoomName = ""
    @State private var pendingType: RoomType = .bedroom

    private let floorOptions = ["1", "2", "3", "4"]

    var body: some View {
        ZStack {
            // MARK: Camera — RoomPlan
            RoomPlanContainer(manager: session.roomPlan)
                .ignoresSafeArea()

            // MARK: Top overlay
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.scannedRooms.isEmpty
                             ? "Belum ada ruangan"
                             : "\(session.scannedRooms.count) ruangan terscan")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(session.isRoomPlanScanning ? "Sedang scanning..." : "Siap scan")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                        if session.isRoomPlanScanning {
                            Label("AI menganalisis \(session.currentRoomDetections.count) temuan",
                                  systemImage: "waveform.path.ecg")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    Spacer()
                    Circle()
                        .fill(session.isRoomPlanScanning ? Color.green : Color.red)
                        .frame(width: 14, height: 14)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal)
                Spacer()
            }

            // MARK: Bottom overlay
            VStack {
                Spacer()
                VStack(spacing: 12) {
                    if !session.scannedRooms.isEmpty && !session.isRoomPlanScanning {
                        Text("\(session.scannedRooms.count) ruangan selesai")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Button {
                        if session.isRoomPlanScanning {
                            // keepSessionAlive: true → ARSession tetap jalan supaya ruangan
                            // berikutnya masih dalam koordinat dunia yang sama (perlu untuk StructureBuilder)
                            session.roomPlan.stop(keepSessionAlive: true)
                        } else {
                            session.roomPlan.start()
                        }
                    } label: {
                        Text(session.isRoomPlanScanning ? "Finish Scan" : "Start Scan")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(session.isRoomPlanScanning ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding()
            }
        }
        .navigationTitle("Scanning")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)

        // MARK: - Post-scan sheet trigger
        // Pakai capturedRoom yang sudah diforward di SurveySession (bukan session.roomPlan.capturedRoom)
        // supaya .onChange ini benar-benar reaktif
        .onReceive(session.$capturedRoom) { newValue in
            if newValue != nil && !showPostScanSheet {
                showPostScanSheet = true
            }
        }

        // MARK: - Navigation ke RoomInfoView setelah sheet dismiss
        .onChange(of: showPostScanSheet) { _, isShowing in
            if !isShowing && wantsToGoToInfo {
                navigateToInfo    = true
                wantsToGoToInfo   = false
            }
        }
        .navigationDestination(isPresented: $navigateToInfo) {
            RoomInfoView(session: session)
        }

        // MARK: - Post-scan sheet
        .sheet(isPresented: $showPostScanSheet) {
            postScanSheet
        }
    }

    // MARK: - Post-scan sheet (floor picker + room type + next/selesai)
    private var postScanSheet: some View {
        NavigationStack {
            Form {
                Section("Floor") {
                    Picker("Floor", selection: $pendingFloor) {
                        ForEach(floorOptions, id: \.self) { floor in
                            Text("\(floor)st floor").tag(floor)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Room type") {
                    Picker("Room type", selection: $pendingType) {
                        ForEach(RoomType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Room name (opsional)") {
                    TextField("contoh: Bedroom 1", text: $pendingRoomName)
                }
            }
            .navigationTitle("Room Info")
            .navigationBarTitleDisplayMode(.inline)

            VStack(spacing: 12) {
                // Scan ruangan berikutnya
                Button {
                    commitRoom()
                    session.resetScanForNextRoom()
                    pendingRoomName = ""
                    showPostScanSheet = false
                } label: {
                    Text("next ruangan")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue, lineWidth: 1.5))
                }
                .foregroundStyle(.blue)

                // Selesai — lanjut ke RoomInfoView
                Button {
                    commitRoom()
                    wantsToGoToInfo  = true
                    showPostScanSheet = false
                } label: {
                    Text("selesai")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding([.horizontal, .bottom])
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func commitRoom() {
        session.addRoom(
            name:  pendingRoomName,
            floor: pendingFloor,
            type:  pendingType
        )
    }
}
