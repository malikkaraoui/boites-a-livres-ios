import SwiftUI

// MARK: - Submission Success (pleine page, dans la feuille)

// Écran de succès unique après un envoi (photo, boîte, localisation, avis, suppression).
// Remplace les alertes système « Avis envoyé » / « Demande envoyée » (F01 M0046).
// Référence visuelle : PhotoSubmittedView. Ne pas diverger sans raison.
struct SubmissionSuccessView<Secondary: View>: View {
    private let green = Color(red: 0.102, green: 0.718, blue: 0.608)

    let icon: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let primaryTitle: LocalizedStringKey
    let primaryAction: () -> Void
    let secondary: Secondary

    init(
        icon: String = "checkmark.circle.fill",
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        primaryTitle: LocalizedStringKey = "Fermer",
        primaryAction: @escaping () -> Void,
        @ViewBuilder secondary: () -> Secondary
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.primaryTitle = primaryTitle
        self.primaryAction = primaryAction
        self.secondary = secondary()
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(green)

            Text(title)
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)

            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            secondary

            Button { lightHaptic(); primaryAction() } label: {
                Text(primaryTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(green)
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

extension SubmissionSuccessView where Secondary == EmptyView {
    init(
        icon: String = "checkmark.circle.fill",
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        primaryTitle: LocalizedStringKey = "Fermer",
        primaryAction: @escaping () -> Void
    ) {
        self.init(
            icon: icon,
            title: title,
            message: message,
            primaryTitle: primaryTitle,
            primaryAction: primaryAction,
            secondary: { EmptyView() }
        )
    }
}
