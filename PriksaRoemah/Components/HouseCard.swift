import SwiftUI

struct HouseCard: View {

    let house: House

    private let tagBackground = Color(red: 1.0, green: 0.902, blue: 0.859)
    private let tagForeground = Color(red: 0.898, green: 0.337, blue: 0.086)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 8) {
                    Text(house.name)
                        .font(.system(size: 17))
                        .tracking(-0.43)
                        .foregroundStyle(.black)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Text(house.formattedDate)
                        .font(.system(size: 15))
                        .tracking(-0.08)
                        .foregroundStyle(Color(white: 0.239))
                }

                HStack(spacing: 0) {
                    HStack(spacing: 4) {
                        Image(systemName: "bed.double.fill")
                            .font(.system(size: 15))
                        Text("\(house.bedroomCount)")
                    }
                    .padding(.trailing, 8)

                    HStack(spacing: 4) {
                        Image(systemName: "shower.fill")
                            .font(.system(size: 15))
                        Text("\(house.bathroomCount)")
                    }
                    .padding(.horizontal, 8)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color(red: 0.776, green: 0.776, blue: 0.784))
                            .frame(width: 1)
                    }
                }
                .font(.system(size: 15))
                .tracking(-0.08)
                .foregroundStyle(Color(white: 0.239))

                HStack {
                    HStack(spacing: 4) {
                        areaTag(house.formattedAreaTag, suffix: "Building")
                        areaTag(house.formattedAreaTag, suffix: "Floor")
                    }

                    Spacer()

                    Text(house.formattedPriceShort)
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.43)
                        .foregroundStyle(.black)
                }
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.949, green: 0.949, blue: 0.969), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 3)
    }

    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(white: 0.949))
            .aspectRatio(368.0 / 198.0, contentMode: .fit)
    }

    private func areaTag(_ value: String, suffix: String) -> some View {
        Text("\(value) \(suffix)")
            .font(.system(size: 15))
            .tracking(-0.08)
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(tagForeground)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(tagBackground)
            .clipShape(Capsule())
    }
}
