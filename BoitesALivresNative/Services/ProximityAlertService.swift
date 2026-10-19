import CoreLocation
import Foundation
import UserNotifications

// MARK: - Alerte de proximité (F01 M0020)

// Rappel « La boîte est-elle bien ici ? » quand on entre dans un rayon de 50 m, app fermée.
// Régions CLCircularRegion : 20 au plus, les plus proches hors anti-répétition.
// Aucune position n'est envoyée au serveur : les boîtes viennent du cache local.
final class ProximityAlertService: NSObject, CLLocationManagerDelegate {
    static let shared = ProximityAlertService()

    static let enabledKey = "proximityAlertEnabled"
    static let notifType = "location-proximity"
    static let categoryId = "PROXIMITY"
    static let laterActionId = "LATER"
    private static let regionPrefix = "box-"

    private let manager = CLLocationManager()

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var isEnabled: Bool { UserDefaults.standard.bool(forKey: Self.enabledKey) }

    // Appelé au lancement, de façon synchrone : reprend la surveillance si activée et autorisée « Toujours »
    func start() {
        registerCategory()
        guard isEnabled, manager.authorizationStatus == .authorizedAlways else { return }
        manager.startMonitoringSignificantLocationChanges()
        refreshRegions(origin: manager.location?.coordinate)
    }

    // Depuis l'écran d'explication seulement (Réglages) : active puis demande « Toujours »
    func enable() {
        UserDefaults.standard.set(true, forKey: Self.enabledKey)
        if manager.authorizationStatus == .notDetermined || manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
        start()
    }

    func disable() {
        UserDefaults.standard.set(false, forKey: Self.enabledKey)
        manager.stopMonitoringSignificantLocationChanges()
        stopBoxRegions()
    }

    // Recalcule les régions à partir des boîtes en cache, sans réseau
    private func refreshRegions(origin: CLLocationCoordinate2D?) {
        guard let origin, isEnabled else { return }
        Task { @MainActor in
            let boxes = await LocalCacheService.shared.allCachedBoxes()
            let picks = LocationRules.regionCandidates(
                boxes: boxes, origin: origin, prompts: LocationPromptLog.all(), now: Date()
            )
            apply(picks)
        }
    }

    private func apply(_ picks: [BookBox]) {
        stopBoxRegions()
        for box in picks.prefix(LocationRules.regionLimit) {
            let region = CLCircularRegion(center: box.coordinate, radius: LocationRules.proximityMeters,
                                          identifier: "\(Self.regionPrefix)\(box.id)")
            region.notifyOnEntry = true
            region.notifyOnExit = false
            manager.startMonitoring(for: region)
        }
    }

    private func stopBoxRegions() {
        for region in manager.monitoredRegions where region.identifier.hasPrefix(Self.regionPrefix) {
            manager.stopMonitoring(for: region)
        }
    }

    private func registerCategory() {
        let later = UNNotificationAction(identifier: Self.laterActionId, title: "Plus tard", options: [])
        let category = UNNotificationCategory(identifier: Self.categoryId, actions: [later],
                                              intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    private func scheduleNotification(boxId: Int) {
        let content = UNMutableNotificationContent()
        content.title = "📚 Boîte à livres à côté"
        content.body = "Est-elle bien ici ?"
        content.sound = .default
        content.categoryIdentifier = Self.categoryId
        content.userInfo = ["type": Self.notifType, "boxId": boxId]
        let request = UNNotificationRequest(identifier: "proximity-\(boxId)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: CLLocationManagerDelegate

    // Position significative (plusieurs centaines de mètres) : recalcul des 20 régions
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        refreshRegions(origin: locations.last?.coordinate)
    }

    // Entrée dans une boîte : rappel local, sauf anti-répétition 30 jours
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard isEnabled, region.identifier.hasPrefix(Self.regionPrefix),
              let boxId = Int(region.identifier.dropFirst(Self.regionPrefix.count)) else { return }
        let blocked = LocationRules.isBlocked(lastPrompt: LocationPromptLog.all()[boxId], now: Date())
        guard !blocked else { return }
        scheduleNotification(boxId: boxId)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways { start() }
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("[Proximité] surveillance en échec : \(error.localizedDescription)")
    }
}
