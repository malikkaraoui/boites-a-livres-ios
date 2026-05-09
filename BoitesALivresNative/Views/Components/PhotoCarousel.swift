import SwiftUI
import UIKit

// MARK: - Photo Carousel

struct PhotoCarousel: View {
    let photos: [BoxPhoto]
    let localImage: UIImage?
    let uploading: Bool
    @State private var currentPage = 0

    // Count includes approved photos plus local preview or upload placeholder
    private var totalCount: Int {
        var count = photos.count
        if localImage != nil { count += 1 }
        else if uploading && photos.isEmpty { count += 1 }
        return count
    }

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                CachedAsyncImage(url: URL(string: photo.url)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        Color(.systemGray5)
                            .overlay(Image(systemName: "photo").font(.system(size: 40)).foregroundStyle(.secondary))
                    case .empty:
                        Color(.systemGray6).overlay(ProgressView())
                    }
                }
                .frame(height: 220)
                .clipped()
                .tag(index)
            }

            // Local image preview (pre-upload)
            if let img = localImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 220)
                    .clipped()
                    .tag(photos.count)
            } else if uploading && photos.isEmpty {
                Color(.systemGray5)
                    .frame(height: 220)
                    .overlay(ProgressView().scaleEffect(1.5))
                    .tag(0)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: totalCount > 1 ? .always : .never))
        .frame(height: 220)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}
