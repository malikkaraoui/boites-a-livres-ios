import Foundation
import Observation

// MARK: - Version minimale (F01 M0025)

// Lit `app_config` (id = 1) au lancement et à chaque retour au premier plan.
// Version de l'app < min_version : `mustUpdate` passe à true et l'écran bloquant s'affiche.
// Échec de lecture (hors ligne, erreur, table absente) : on journalise et on ne change rien
// à l'état courant. Jamais de blocage sur un échec.
@MainActor @Observable
final class AppVersionGate {
    static let shared = AppVersionGate()
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6768351762")!

    // true = écran « Mise à jour nécessaire » affiché par-dessus l'app
    var mustUpdate = false

    private init() {}

    func check() async {
        let app = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        do {
            let config = try await SupabaseService.shared.fetchAppConfig()
            mustUpdate = AppVersion.isBelow(app, minimum: config.min_version)
        } catch {
            print("[Version] lecture app_config en échec, app non bloquée : \(error.localizedDescription)")
        }
    }
}
