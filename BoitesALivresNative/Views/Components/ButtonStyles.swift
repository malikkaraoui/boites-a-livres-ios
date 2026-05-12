import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

func lightHaptic() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
}

func mediumHaptic() {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
}
