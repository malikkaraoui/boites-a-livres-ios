import Foundation
import Observation
import SwiftUI
import UIKit

// MARK: - Version minimale (F01 M0025, fenêtre dédiée F01 M0026)

// Lit `app_config` (id = 1) au lancement et à chaque retour au premier plan.
// Version de l'app < min_version : `mustUpdate` passe à true et l'écran bloquant s'affiche.
// Échec de lecture (hors ligne, erreur, table absente) : on journalise et on ne change rien
// à l'état courant. Jamais de blocage sur un échec.
@MainActor @Observable
final class AppVersionGate {
    static let shared = AppVersionGate()
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6768351762")!

    // true = écran « Mise à jour nécessaire » affiché au-dessus de tout (fenêtre dédiée)
    var mustUpdate = false {
        didSet { syncBlockingWindow() }
    }

    // Fenêtre dédiée : passe au-dessus des feuilles et modales déjà ouvertes (réserve R020)
    @ObservationIgnored private var blockingWindow: UIWindow?

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

    // Affiche la fenêtre bloquante tant que `mustUpdate`, la retire ensuite.
    // Sans scène active (app en arrière-plan), rien n'est fait : le prochain `check()` réessaie.
    private func syncBlockingWindow() {
        if mustUpdate {
            guard blockingWindow == nil, let scene = activeWindowScene() else { return }
            let window = UIWindow(windowScene: scene)
            window.windowLevel = UIWindow.Level.alert + 1
            window.rootViewController = UIHostingController(rootView: ForceUpdateView())
            window.makeKeyAndVisible()
            blockingWindow = window
        } else {
            blockingWindow?.isHidden = true
            blockingWindow = nil
        }
    }

    private func activeWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive }
            ?? scenes.first { $0.activationState == .foregroundInactive }
    }
}
