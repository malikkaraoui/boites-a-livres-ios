import SwiftUI
import UIKit

// MARK: - Cached Image Phase

enum CachedImagePhase {
    case empty, success(Image), failure
}

// MARK: - Cached Async Image

// AsyncImage wrapper using ImageCacheService for two-tier memory/disk caching
struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    @ViewBuilder let content: (CachedImagePhase) -> Content

    @State private var phase: CachedImagePhase = .empty

    var body: some View {
        content(phase)
            .task(id: url?.absoluteString) {
                await load()
            }
    }

    // Load image from cache or network; update phase with result
    private func load() async {
        guard let url else {
            phase = .failure
            return
        }
        phase = .empty
        if let img = await ImageCacheService.shared.image(for: url) {
            phase = .success(Image(uiImage: img))
        } else {
            phase = .failure
        }
    }
}
