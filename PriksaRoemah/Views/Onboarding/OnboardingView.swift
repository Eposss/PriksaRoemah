import SwiftUI

/// Onboarding 2 layar, cuma muncul sekali di first launch (lihat gating-nya di
/// PriksaRoemahApp — `hasCompletedOnboarding` di AppStorage). Sesuai Figma
/// "welcoming screen" (gradient oranye + Get Started) dulu, lalu "landing page"
/// (headline + Continue) yang lanjut masuk ke HomeView.
///
/// Foto asli di collage Figma "landing page" adalah stock photo pihak ketiga
/// (salah satunya ada watermark) — nggak dipakai di sini. Diganti kartu
/// ikon+gradient SF Symbol biar tetap native & bebas isu lisensi, gampang
/// ditukar foto asli nanti.
struct OnboardingView: View {

    var onFinished: () -> Void

    @State private var page: Int = 0

    private let brandOrange   = Color(hex: "E55616")
    private let chipBackground = Color(hex: "FFDFD1")
    private let chipText       = Color(hex: "E55D1F")

    var body: some View {
        Group {
            if page == 0 {
                welcomingScreen
                    .transition(.opacity)
            } else {
                landingPage
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: page)
    }

    // MARK: - Page 1: Landing (Figma "landing page")

    private var landingPage: some View {
        ZStack {
            Color(hex: "F5F5F5").ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(hex: "D8D6C9"), Color(hex: "DBB69C"),
                    Color(hex: "DF9670"), Color(hex: "E27643"), brandOrange
                ],
                center: .center, startRadius: 0, endRadius: 220
            )
            .frame(width: 240, height: 404)
            .blur(radius: 90)
            .opacity(0.6)
            .offset(y: -160)

            VStack(spacing: 40) {
                photoCollage
                VStack(spacing: 12) {
                    (
                        Text("Capture. Remember. ")
                            .foregroundStyle(.black)
                        + Text("Note. ")
                            .foregroundStyle(Color(hex: "E55C1D"))
                        + Text("All in One Place.")
                            .foregroundStyle(.black)
                    )
                    .font(.system(size: 34, weight: .bold))
                    .multilineTextAlignment(.center)

                    Text("Take photos of room and add your notes, never forget the details!")
                        .font(.footnote)
                        .foregroundStyle(Color(hex: "3D3D3D"))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 160)
            .frame(maxHeight: .infinity, alignment: .top)

            VStack {
                Spacer()
                Button {
                    onFinished()
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(brandOrange, in: RoundedRectangle(cornerRadius: 28))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    private var photoCollage: some View {
        ZStack {
            collageTile(icon: "bed.double.fill", tint: chipBackground.opacity(0.7))
                .rotationEffect(.degrees(-8))
                .offset(x: -95, y: 8)

            collageTile(icon: "fork.knife", tint: chipBackground.opacity(0.7))
                .rotationEffect(.degrees(8))
                .offset(x: 95, y: 0)

            noteCard
                .offset(x: 4, y: 20)

            chip("Kitchen")
                .rotationEffect(.degrees(-2))
                .offset(x: -108, y: -66)

            chip("Bedroom")
                .rotationEffect(.degrees(6))
                .offset(x: 100, y: -78)

            chip("Bathroom")
                .rotationEffect(.degrees(2))
                .offset(x: -95, y: 130)
        }
        .frame(height: 330)
    }

    private func collageTile(icon: String, tint: Color) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(tint)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 34))
                    .foregroundStyle(.white)
            )
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(.systemGray5)))
            .frame(width: 150, height: 210)
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(colors: [Color(hex: "F4C79E"), Color(hex: "E58A54")],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(Image(systemName: "sun.max.fill").font(.system(size: 30)).foregroundStyle(.white))
                .frame(width: 128, height: 128)

            VStack(alignment: .leading, spacing: 6) {
                Text("NOTE")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "3D3D3D"))
                Text("Morning sun feels great here. Window faces east and the air is fresh.")
                    .font(.system(size: 13))
                    .foregroundStyle(.black)
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(.systemGray5)))
        .shadow(color: .black.opacity(0.06), radius: 6)
        .frame(width: 168)
    }

    private func chip(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 13))
            .foregroundStyle(chipText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(chipBackground, in: Capsule())
    }

    // MARK: - Page 2: Welcoming (Figma "welcoming screen")

    private var welcomingScreen: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "E2601A"), Color(hex: "E58A54"),
                    Color(hex: "F0DCC8"), Color(hex: "F5F5F5")
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 16) {
                    Image("OnboardingLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 35)

                    Text("Getting Started\nin Huni")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 8) {
                    featureRow(
                        icon: "IconScanMap",
                        title: "Scan & Map",
                        description: "Scan your home to create accurate 2D floor plans and 3D models automatically"
                    )
                    featureRow(
                        icon: "IconMeasureAnalyze",
                        title: "Measure & Analyze",
                        description: "Get instant measurements, room count and key building details in one place."
                    )
                }
            }
            .padding(.top, 60)
            .padding(.horizontal, 40)
            .frame(maxHeight: .infinity, alignment: .top)

            VStack {
                Spacer()
                Button {
                    page = 1
                } label: {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(brandOrange, in: RoundedRectangle(cornerRadius: 28))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 10) {
            Image(icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
                .frame(width: 42, height: 58)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Landing") { OnboardingView(onFinished: {}) }
