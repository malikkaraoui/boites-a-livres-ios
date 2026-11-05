import Foundation
import Observation

// MARK: - Deep Link Router

@MainActor @Observable
final class DeepLinkRouter {
    static let shared = DeepLinkRouter()

    // Box ID to navigate to when deep link is received; observed for navigation stack updates
    var pendingBoxId: Int?
    // Fiche à ouvrir avec le parcours « Localisation » (tap sur la notification de proximité)
    var pendingLocationBoxId: Int?
    // Boîte à montrer sur la carte (bouton « Voir sur la carte » de la fiche) : centre la carte, sans rouvrir la fiche
    var pendingMapFocus: MapFocus?

    struct MapFocus: Equatable {
        let boxId: Int
        let latitude: Double
        let longitude: Double
    }
}
