import SwiftUI

// MARK: - Book Box Sheet

struct BookBoxSheet: View {
    let box: BookBox
    let onDetail: () -> Void

    private let blue = Color(red: 37/255, green: 99/255, blue: 235/255)

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
            }

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
                if box.has_photo {
                    Image(systemName: "photo.fill")
                        .foregroundStyle(blue)
                        .font(.system(size: 20))
                }
            }

            if let dist = box.distance_m {
                Text(formatDistance(dist))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(blue)
            }

            Button {
                onDetail()
            } label: {
                Text("Voir le détail")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
    }

    // Format distance in meters as meters or kilometers
    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }
}
