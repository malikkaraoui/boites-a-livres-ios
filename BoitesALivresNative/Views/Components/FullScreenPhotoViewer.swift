import SwiftUI

struct FullScreenPhotoViewer: View {
    let photos: [BoxPhoto]
    let startIndex: Int
    @State private var currentPage: Int
    @Environment(\.dismiss) private var dismiss

    init(photos: [BoxPhoto], startIndex: Int) {
        self.photos = photos
        self.startIndex = startIndex
        self._currentPage = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentPage) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                    CachedAsyncImage(url: URL(string: photo.url)) { phase in
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
            .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .always : .never))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.black.opacity(0.55))
                    .clipShape(Circle())
            }
            .padding(.top, 56)
            .padding(.trailing, 20)
        }
    }
}
