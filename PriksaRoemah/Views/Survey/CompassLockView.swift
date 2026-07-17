import SwiftUI

/// Compass live buat nge-SET arah hadap rumah: user arahin HP ke depan rumah,
/// panah atas nunjuk arah yang lagi dihadapin, lalu tekan "Lock Facing" buat
/// mengunci arah itu. Jauh lebih akurat daripada snapshot heading otomatis pas
/// save (yang arah HP-nya sembarangan).
struct CompassLockView: View {

    @ObservedObject var compass: CompassService
    @Binding var locked: HouseFacing?

    private let orange = Color(red: 0.910, green: 0.349, blue: 0.090)

    private var heading: Double { compass.headingDegrees ?? 0 }
    private var hasHeading: Bool { compass.headingDegrees != nil }

    var body: some View {
        VStack(spacing: 16) {
            dial
            readout
            lockButton
        }
        .frame(maxWidth: .infinity)
        .onAppear { compass.start() }
    }

    // MARK: - Dial

    private var dial: some View {
        ZStack {
            Circle()
                .fill(Color(.tertiarySystemGroupedBackground))
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.1)))

            // Rose N/E/S/W diputar -heading, jadi label di bawah panah atas =
            // arah yang lagi dihadapin.
            ZStack {
                roseLabel("N", at: 0, highlight: true)
                roseLabel("E", at: 90)
                roseLabel("S", at: 180)
                roseLabel("W", at: 270)
            }
            .rotationEffect(.degrees(-heading))
            .animation(.easeOut(duration: 0.15), value: heading)

            // Panah tetap di atas = arah HP.
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 16))
                .foregroundStyle(orange)
                .offset(y: -82)
        }
        .frame(width: 180, height: 180)
        .opacity(hasHeading ? 1 : 0.4)
    }

    private func roseLabel(_ text: String, at angle: Double, highlight: Bool = false) -> some View {
        // Posisikan pakai offset trig (bukan rotationEffect) supaya glyph-nya
        // tetap tegak; rose-nya sendiri yang diputar -heading (label ikut miring
        // bareng rose, mirip Compass bawaan Apple).
        let r: CGFloat = 64
        let a = angle * .pi / 180
        return Text(text)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(highlight ? orange : .secondary)
            .offset(x: r * sin(a), y: -r * cos(a))
    }

    // MARK: - Readout + Lock

    @ViewBuilder
    private var readout: some View {
        if !hasHeading {
            Text("Calibrating compass…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else if let locked {
            Text("Locked: \(locked.displayName)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(orange)
        } else {
            Text("Facing \(HouseFacing.nearest(toDegrees: heading).displayName) · \(Int(heading))°")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var lockButton: some View {
        Button {
            if locked == nil {
                if hasHeading { locked = HouseFacing.nearest(toDegrees: heading) }
            } else {
                locked = nil   // buka lagi buat re-aim
            }
        } label: {
            Text(locked == nil ? "Lock Facing" : "Re-lock")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(locked == nil ? orange : Color(.systemGray2), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!hasHeading)
    }
}
