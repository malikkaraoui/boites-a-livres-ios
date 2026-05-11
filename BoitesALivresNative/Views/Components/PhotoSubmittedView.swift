import SwiftUI

// MARK: - Photo Submitted Success Screen

struct PhotoSubmittedView: View {
    @Environment(\.dismiss) private var dismiss
    private let green = Color(red: 0.102, green: 0.718, blue: 0.608)

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "photo.badge.checkmark.fill")
                .font(.system(size: 72))
                .foregroundStyle(green)

            Text("Photo soumise !")
                .font(.system(size: 24, weight: .bold))

            Text("Votre photo est en attente de validation.\nVous recevrez une notification à la décision.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Fermer") { dismiss() }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 14)
                .background(green)
                .clipShape(Capsule())

            Spacer()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
