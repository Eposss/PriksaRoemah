import SwiftUI

struct HouseCard: View {

    let house: House

    var body: some View {
        HStack(spacing: 14) {

            // Thumbnail placeholder
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "house.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(house.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                Text("Lt \(house.luasTanah) m²  ·  \(house.roomCount) ruangan")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Rp \(house.harga)")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .fontWeight(.medium)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }
}
