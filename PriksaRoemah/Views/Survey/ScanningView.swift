import SwiftUI
import RoomPlan

struct ScanningView: View {

    @ObservedObject var session: SurveySession

    @State private var showPostScanSheet = false
    @State private var navigateToInfo    = false
    @State private var pendingFloor      = "1"
    @State private var pendingRoomName   = ""
    @State private var pendingType: RoomType = .bedroom
    @State private var showInstructions  = true

    private let floorOptions = ["1", "2", "3", "4"]

    var body: some View {
        ZStack {
            RoomPlanContainer(manager: session.roomPlan)
                .ignoresSafeArea()

            VStack {
                statusBadge
                Spacer()
            }

            VStack {
                Spacer()
                scanButton
                    .padding(.bottom, 24)
            }

            if showInstructions {
                InstructionView {
                    withAnimation { showInstructions = false }
                }
                .transition(.opacity)
            }
        }
        .navigationTitle("Scanning")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(showInstructions ? .hidden : .visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            session.roomPlan.startPreview()
        }
        .onReceive(session.$capturedRoom) { room in
            guard room != nil else { return }
            showPostScanSheet = true
        }
        .navigationDestination(isPresented: $navigateToInfo) {
            RoomInfoView(session: session)
        }
        .sheet(isPresented: $showPostScanSheet) {
            postScanSheet
        }
    }

    // MARK: - Status badge
    //
    // Revisi: sebelum scanning mulai, tampilkan card penuh (info jumlah
    // ruangan + status). Begitu scanning AKTIF, ciutkan jadi indikator minimal
    // (teks + titik hijau saja, tanpa background card besar) supaya tidak
    // menutupi guide bawaan RoomPlan ("Move closer", "Move slower", dll) yang
    // muncul di area atas layar selama scanning.

    @ViewBuilder
    private var statusBadge: some View {
        if session.isRoomPlanScanning {
            minimalStatusIndicator
                .padding(.top)
        } else {
            fullStatusCard
                .padding(.horizontal)
                .padding(.top)
        }
    }

    private var minimalStatusIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            Text("Sedang scanning...")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.black.opacity(0.35))
        .clipShape(Capsule())
    }

    private var fullStatusCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.scannedRooms.isEmpty
                     ? "Belum ada ruangan"
                     : "\(session.scannedRooms.count) ruangan terscan")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Siap scan")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
            Circle()
                .fill(Color.red)
                .frame(width: 14, height: 14)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Scan button
    //
    // Revisi: bukan lagi bar full-width dengan background card besar (yang
    // menghalangi preview RoomPlan) — sekarang tombol shutter bulat mengambang
    // di bawah, mirip aplikasi scanning pada umumnya. Info "N ruangan selesai"
    // dipindah jadi capsule kecil di atas tombol, bukan blok penuh.

    private var scanButton: some View {
        VStack(spacing: 10) {
            if !session.scannedRooms.isEmpty && !session.isRoomPlanScanning {
                Text("\(session.scannedRooms.count) ruangan selesai discan")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.35))
                    .clipShape(Capsule())
            }

            Button {
                if session.isRoomPlanScanning {
                    session.roomPlan.stop(keepSessionAlive: true)
                } else {
                    session.roomPlan.start()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 72, height: 72)
                    if session.isRoomPlanScanning {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.red)
                            .frame(width: 28, height: 28)
                    } else {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 58, height: 58)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.6), lineWidth: 3)
                        .frame(width: 80, height: 80)
                )
            }
            .buttonStyle(.plain)

            Text(session.isRoomPlanScanning ? "Finish Scan" : "Start Scan")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.black.opacity(0.35))
                .clipShape(Capsule())
        }
    }

    // MARK: - Post-scan sheet

    private var postScanSheet: some View {
        NavigationStack {
            Form {
                Section("Floor") {
                    Picker("Floor", selection: $pendingFloor) {
                        ForEach(floorOptions, id: \.self) { Text("Lantai \($0)").tag($0) }
                    }
                    .pickerStyle(.menu)
                }
                Section("Room type") {
                    Picker("Room type", selection: $pendingType) {
                        ForEach(RoomType.allCases) {
                            Label($0.rawValue, systemImage: $0.icon).tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("Room name (opsional)") {
                    TextField("contoh: Bedroom 1", text: $pendingRoomName)
                }
            }
            .navigationTitle("Info Ruangan")
            .navigationBarTitleDisplayMode(.inline)

            VStack(spacing: 12) {
                Button {
                    commitAndContinue()
                    pendingRoomName = ""
                    pendingType     = .bedroom
                    pendingFloor    = "1"
                    showPostScanSheet = false
                } label: {
                    Text("Scan ruangan lain")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.blue, lineWidth: 1.5)
                        )
                }
                .foregroundStyle(.blue)

                Button {
                    commitAndContinue()
                    showPostScanSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        navigateToInfo = true
                    }
                } label: {
                    Text("Selesai — isi info rumah")
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
        .interactiveDismissDisabled(true)
    }

    private func commitAndContinue() {
        session.addRoom(
            name:  pendingRoomName,
            floor: pendingFloor,
            type:  pendingType
        )
    }
}
