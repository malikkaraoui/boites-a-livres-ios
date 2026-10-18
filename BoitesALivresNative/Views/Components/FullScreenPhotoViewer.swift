import SwiftUI

struct FullScreenPhotoViewer: View {
    let photos: [BoxPhoto]
    let startIndex: Int
    @State private var currentPage: Int
    // Photos dont le chargement a échoué : retirées de l'affichage
    @State private var deadURLs: Set<String> = []
    @Environment(\.dismiss) private var dismiss

    init(photos: [BoxPhoto], startIndex: Int) {
        self.photos = photos
        self.startIndex = startIndex
        self._currentPage = State(initialValue: startIndex)
    }

    private var visiblePhotos: [BoxPhoto] {
        photos.filter { !deadURLs.contains($0.url) }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentPage) {
                ForEach(Array(visiblePhotos.enumerated()), id: \.offset) { index, photo in
                    CachedAsyncImage(url: URL(string: photo.url), onFailure: { deadURLs.insert(photo.url) }) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .failure:
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundStyle(.white.opacity(0.35))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .empty:
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: visiblePhotos.count > 1 ? .always : .never))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .onChange(of: visiblePhotos.count) { _, count in
                currentPage = min(currentPage, max(count - 1, 0))
            }

            Button { lightHaptic(); dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.black.opacity(0.55))
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 56)
            .padding(.trailing, 20)
        }
    }
}
