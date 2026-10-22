import SwiftUI

// MARK: - Photo Submitted Success Screen

// Écran de référence du succès d'envoi : le composant partagé en reprend le rendu (F01 M0046)
struct PhotoSubmittedView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SubmissionSuccessView(
            icon: "photo.badge.checkmark.fill",
            title: "Photo soumise !",
            message: "Votre photo est en attente de validation.\nVous recevrez une notification à la décision.",
            primaryAction: { dismiss() }
        )
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
