#if DEBUG
import CoreLocation
import Foundation
import SwiftUI

// MARK: - Hooks de test d'interface (XCUITest)

// Lus au lancement par la cible BoitesALivresNativeUITests. Entièrement compilés en DEBUG :
// en Release, ce fichier n'existe pas et aucun appel ci-dessous n'est compilé.
enum UITestHooks {
    private static var arguments: [String] { ProcessInfo.processInfo.arguments }

    // Mode test actif : pas de demande de notifications (appel APNs), pas de demande de notation,
    // pas d'alerte de rappel de proximité au retour au premier plan.
    static var isActive: Bool { arguments.contains("-UITEST_ACTIVE") }

    // -UITEST_APPEARANCE light|dark
    static var forcedColorScheme: ColorScheme? {
        switch value(after: "-UITEST_APPEARANCE") {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    // -UITEST_LOCATION lat,lon : position simulée, sans autorisation système
    static var simulatedLocation: CLLocation? {
        guard let raw = value(after: "-UITEST_LOCATION") else { return nil }
        let parts = raw.split(separator: ",").compactMap { Double($0) }
        guard parts.count == 2 else { return nil }
        return CLLocation(latitude: parts[0], longitude: parts[1])
    }

    private static func value(after flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}
#endif
