import SwiftUI

struct OnboardingView: View {

    var onGetStarted: () -> Void

    private let orange = Color(red: 0.898, green: 0.337, blue: 0.086)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.902, green: 0.384, blue: 0.165),
                    Color(red: 0.929, green: 0.706, blue: 0.518),
                    Color(red: 0.937, green: 0.867, blue: 0.784)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        Image("HuniLogo")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.white)
                            .frame(width: 90, height: 53.13)

                        Text("Getting Started\nin Huni")
                            .font(.system(size: 34, weight: .bold))
                            .tracking(0.4)
                            .foregroundStyle(Color(white: 0.96))
                            .multilineTextAlignment(.center)

                        VStack(alignment: .leading, spacing: 8) {
                            featureRow(
                                icon: Image("IconScanMap")
                                    .resizable()
                                    .aspectRatio(CGSize(width: 37.0156, height: 32.1875), contentMode: .fit),
                                title: "Scan & Map",
                                description: "Scan the house you want to survey to create accurate 2D floor plans and 3D models automatically."
                            )
                            featureRow(
                                icon: Image("IconMeasureAnalyze")
                                    .resizable()
                                    .aspectRatio(CGSize(width: 25.675, height: 32.0938), contentMode: .fit),
                                title: "Measure & Analyze",
                                description: "Get instant measurements, room count, and key building details in one place."
                            )
                            featureRow(
                                icon: Image(systemName: "note.text").resizable().scaledToFit(),
                                title: "Notes & Details",
                                description: "Save price, land size, and personal notes for every house you survey — all in one collection."
                            )
                        }
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 24)
                }
                .scrollBounceBehavior(.basedOnSize)

                Button(action: onGetStarted) {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.43)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(orange)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
    }

    private func featureRow<Icon: View>(icon: Icon, title: String, description: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            icon
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.43)
                    .foregroundStyle(.white)
                Text(description)
                    .font(.system(size: 15))
                    .tracking(-0.08)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }
}

#Preview {
    OnboardingView(onGetStarted: {})
}
