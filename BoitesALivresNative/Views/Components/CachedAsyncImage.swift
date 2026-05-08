import SwiftUI
import UIKit

enum CachedImagePhase {
    case empty, success(Image), failure
}

/// Remplace `AsyncImage` en s'appuyant sur `ImageCacheService`.
/// Sert depuis le cache (mem/disque) si dispo, sinon fetch réseau et cache.
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
