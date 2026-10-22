import Observation
import SwiftUI
import UIKit

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

// Toucher un bouton d'envoi grisé : retour d'erreur (F01 M0045)
func errorHaptic() {
    UINotificationFeedbackGenerator().notificationOccurred(.error)
}

// Ferme le clavier quel que soit le champ qui l'a (avec ou sans @FocusState) (F01 M0047)
func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// Dernier toucher sur un bouton grisé : élément visé, compteur, message (F01 M0045)
@MainActor @Observable
final class MissingFeedback<Target: Hashable> {
    private(set) var target: Target?
    private(set) var count = 0
    private(set) var message: String?
    private var clearTask: Task<Void, Never>?

    func flash(_ target: Target, message: String?) {
        self.target = target
        count += 1
        self.message = message
        clearTask?.cancel()
        clearTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !Task.isCancelled { self.message = nil }
        }
    }

    // Compteur réservé à l'élément visé : les autres restent à 0 et ne clignotent pas
    func tick(for item: Target) -> Int { target == item ? count : 0 }

    func message(for item: Target) -> String? { target == item ? message : nil }
}

// Clignotement de l'élément manquant : 3 pulsations (≈ 1 s), ou surlignage fixe si « Réduire les animations » (F01 M0045)
struct MissingHighlight: ViewModifier {
    let tick: Int
    var cornerRadius: CGFloat = 12
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lit = false

    private let alert = Color.orange

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: cornerRadius).fill(alert.opacity(lit ? 0.14 : 0)))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(alert, lineWidth: 2).opacity(lit ? 1 : 0))
            .onChange(of: tick) { _, value in
                guard value > 0 else { return }
                Task { @MainActor in await pulse() }
            }
    }

    @MainActor
    private func pulse() async {
        if reduceMotion {
            lit = true
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            lit = false
            return
        }
        for _ in 0..<3 {
            withAnimation(.easeInOut(duration: 0.15)) { lit = true }
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(.easeInOut(duration: 0.15)) { lit = false }
            try? await Task.sleep(nanoseconds: 180_000_000)
        }
    }
}

extension View {
    func missingHighlight(tick: Int, cornerRadius: CGFloat = 12) -> some View {
        modifier(MissingHighlight(tick: tick, cornerRadius: cornerRadius))
    }
}

extension Color {
    // Fond des champs de saisie des feuilles : identique à systemGray6 en clair, éclairci en sombre
    // pour rester visible sur la feuille (F01 M0049, build 26)
    static let formField = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? .tertiarySystemBackground : .systemGray6
    })
}
