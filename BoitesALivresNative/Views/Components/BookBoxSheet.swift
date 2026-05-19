import SwiftUI

// MARK: - Book Box Sheet

struct BookBoxSheet: View {
    let box: BookBox
    let onDetail: () -> Void

    @AppStorage("useImperialUnits") private var useImperialUnits = false
    private let green = Color(red: 0.102, green: 0.718, blue: 0.608)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let urlStr = box.photo_url, let url = URL(string: urlStr) {
                CachedAsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        Color(.systemGray5)
                            .overlay(Image(systemName: "photo").font(.system(size: 30)).foregroundStyle(.secondary))
                    case .empty:
                        Color(.systemGray6).overlay(ProgressView())
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Boîte #\(box.id)")
                            .font(.system(size: 17, weight: .bold))
                        if let city = box.city {
                            Text(city)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        if let address = box.address {
                            Text(address)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    if box.photo_url != nil {
                        Image(systemName: "photo.fill")
                            .foregroundStyle(green)
                            .font(.system(size: 20))
                    }
                }

                if let dist = box.distance_m {
                    Text(formatDistance(dist))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(green)
                }
            }
            .padding(12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )

            Button {
                mediumHaptic()
                onDetail()
            } label: {
                Text("Voir le détail")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: green.opacity(0.35), radius: 8, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(20)
    }

    private func formatDistance(_ meters: Double) -> String {
        if useImperialUnits {
            let miles = meters / 1609.344
            return miles < 0.1 ? "\(Int(meters * 3.28084)) ft" : String(format: "%.1f mi", miles)
        }
        return meters < 1000 ? "\(Int(meters)) m" : String(format: "%.1f km", meters / 1000)
    }
}
