import SwiftUI

// MARK: - Splash View

// Animated splash screen kept intentionally short to avoid slowing perceived launch
struct SplashView: View {
    @Binding var isVisible: Bool

    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color("LaunchBackground")
                .ignoresSafeArea()

            Image("SplashIcon")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                scale = 1.0
                opacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.12)) {
                    isVisible = false
                }
            }
        }
    }
}
