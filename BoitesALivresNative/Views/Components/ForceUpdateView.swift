import SwiftUI

// MARK: - Mise à jour obligatoire (F01 M0025)

// Écran plein et non fermable : pas de bouton « Fermer », aucun accès au reste de l'app.
// Seule issue : ouvrir la fiche App Store.
struct ForceUpdateView: View {
    @Environment(\.openURL) private var openURL

    private let accent = Color.accentColor

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.app")
                .font(.system(size: 56))
                .foregroundStyle(accent)

            Text("Mise à jour nécessaire")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Une nouvelle version de Boîtes à Livres est disponible. Mets à jour l'app pour continuer.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button {
                openURL(AppVersionGate.appStoreURL)
            } label: {
                Text("Mettre à jour")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 32)
            .padding(.top, 12)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}
