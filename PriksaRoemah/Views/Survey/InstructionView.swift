import SwiftUI

struct InstructionView: View {

    /// Called when the user finishes the last page — the caller (ScanningView)
    /// dismisses this overlay to reveal the live camera / scan UI underneath.
    var onFinish: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let blue = Color(red: 0, green: 0.533, blue: 1)
    private let orange = Color(red: 0.898, green: 0.337, blue: 0.086)

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                header

                TabView(selection: $currentPage) {
                    page1.tag(0)
                    page2.tag(1)
                    page3.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                pageControl
                    .padding(.bottom, 8)

                ctaButton
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Chrome

    /// No static image here on purpose — this overlay sits on top of the live
    /// camera preview (RoomPlanContainer) in ScanningView's ZStack, so this
    /// just blurs/dims whatever is rendered behind it rather than painting over it.
    private var background: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(Color.black.opacity(0.6))
            .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            Button {
                if currentPage == 0 {
                    dismiss()
                } else {
                    withAnimation { currentPage -= 1 }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.thinMaterial, in: Circle())
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var pageControl: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.white.opacity(index == currentPage ? 1 : 0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .frame(height: 44)
    }

    private var ctaButton: some View {
        Button {
            if currentPage < 2 {
                withAnimation { currentPage += 1 }
            } else {
                onFinish()
            }
        } label: {
            Text(currentPage == 2 ? "Start Scan" : "Continue")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(red: 0.898, green: 0.957, blue: 1.0))
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(orange)
                .clipShape(RoundedRectangle(cornerRadius: 32))
        }
    }

    // MARK: - Shared helpers

    private func title(_ prefix: String, highlighted: String, suffix: String) -> some View {
        (
            Text(prefix)
            + Text(highlighted).foregroundColor(Color(red: 0.929, green: 0.478, blue: 0.271))
            + Text(suffix)
        )
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(.white)
        .tracking(0.38)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private func description(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17))
            .tracking(-0.43)
            .foregroundStyle(Color(white: 0.6))
            .multilineTextAlignment(.center)
    }

    // MARK: - Pages

    private var page1: some View {
        VStack(spacing: 61) {
            title("Scan ", highlighted: "One Room", suffix: " at a Time")

            VStack(spacing: 20) {
                ZStack {
                    Image("InstructionPage1Illustration")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 360, height: 113.7)
                        .clipped()
                        .position(x: 180, y: 185.77)

                    VStack(spacing: 4) {
                        Text("Start scanning")
                            .font(.system(size: 12))
                            .tracking(0.06)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(blue)
                            .clipShape(Capsule())
                        Image("InstructionArrowStart")
                            .resizable()
                            .frame(width: 20, height: 39)
                    }
                    .position(x: 144, y: 140)

                    VStack(spacing: 4) {
                        Text("End scanning")
                            .font(.system(size: 12))
                            .tracking(0.06)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(blue)
                            .clipShape(Capsule())
                        Image("InstructionArrowEnd")
                            .resizable()
                            .frame(width: 20, height: 29)
                    }
                    .position(x: 291.5, y: 159)

                    Text("One floor")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(-0.08)
                        .foregroundStyle(.white)
                        .position(x: 180, y: 267.62)
                }
                .frame(width: 360, height: 369.54)

                description("You have to scan every room and spaces. Make sure you are in the room you want to scan before you start scanning. The scanning session will pause after every room scan")
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 24)
    }

    private var page2: some View {
        VStack(spacing: 61) {
            title("Scan ", highlighted: "Every Space", suffix: "")

            VStack(spacing: 20) {
                Image("InstructionPage2Illustration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 360, height: 369.54)

                description("Include rooms, hallways, and staircases — anything that connects two spaces needs its own scan too. Make sure to scan every space possible in a floor level. If you don't do this the generated plan will be messed up and you have to redo the whole scan")
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 24)
    }

    private var page3: some View {
        VStack(spacing: 61) {
            title("Scan ", highlighted: "One Floor", suffix: " at a Time")

            VStack(spacing: 20) {
                Image("InstructionPage3Illustration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 360, height: 369.54)

                description("Start from the ground floor first, you can add another floor later.")
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 24)
    }
}

#Preview {
    InstructionView(onFinish: {})
}
