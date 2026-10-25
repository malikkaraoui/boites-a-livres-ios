import CoreLocation
import Foundation
import UserNotifications

// MARK: - Alerte de proximité (F01 M0020)

// Rappel « La boîte est-elle bien ici ? » quand on entre dans un rayon de 100 m, app fermée.
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
    // Boîtes dont l'alerte a déjà été traitée pendant cette présence (levée à la sortie)
    private var handledInside = Set<Int>()
    // Demandes de position fraîche en attente (vitesse avant alerte) ; une seule requestLocation à la fois
    private var pendingFixes: [(CLLocation?) -> Void] = []
    private var savedAccuracy: CLLocationAccuracy?
    private var fixGeneration = 0
    private static let freshMaxAgeSeconds: TimeInterval = 10

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // Activée par défaut (clé absente) ; seul un désactivement explicite de l'utilisateur la coupe
    var isEnabled: Bool {
        LocationRules.alertEnabled(stored: UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool)
    }

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

    // Enregistre les régions puis demande l'état courant de chacune : une alerte immédiate
    // si on est déjà dans un rayon (F01 M0023 B1), sans attendre une entrée
    private func apply(_ picks: [BookBox]) {
        stopBoxRegions()
        let chosen = Array(picks.prefix(LocationRules.regionLimit))
        handledInside.formIntersection(chosen.map(\.id))
        ProximityJournal.add(String(localized: "régions enregistrées : \(chosen.count)"))
        for box in chosen {
            let region = CLCircularRegion(center: box.coordinate, radius: LocationRules.alertRadiusMeters,
                                          identifier: "\(Self.regionPrefix)\(box.id)")
            region.notifyOnEntry = true
            region.notifyOnExit = true
            manager.startMonitoring(for: region)
            manager.requestState(for: region)
        }
    }

    // Entrée ou état « dedans » : la vitesse décide avant toute notification (issue #65).
    // Au-dessus de 7 km/h ou vitesse inconnue : rien d'écrit (ni notification, ni anti-répétition, ni handledInside).
    private func handleInside(boxId: Int, origin: String) {
        ProximityJournal.add(String(localized: "dans le rayon de la boîte \(String(boxId)) (\(origin))"))
        guard !handledInside.contains(boxId) else { return }
        freshLocation { [weak self] location in
            guard let self else { return }
            let decision = location.map { LocationRules.alertSpeedDecision(speedMps: $0.speed) } ?? .unknown
            switch decision {
            case .notify:
                self.notifyIfAllowed(boxId: boxId)
            case .tooFast:
                let kmh = String(Int(((location?.speed ?? 0) * 3.6).rounded()))
                ProximityJournal.add(String(localized: "boîte \(String(boxId)) : en mouvement (\(kmh) km/h), pas de notification"))
            case .unknown:
                ProximityJournal.add(String(localized: "boîte \(String(boxId)) : vitesse inconnue, pas de notification"))
            }
        }
    }

    // Position de moins de 10 s : celle du gestionnaire si elle est assez récente, sinon une demande ponctuelle
    // à précision maximale, avec délai borné (10 s). nil = pas de position à temps.
    private func freshLocation(_ done: @escaping (CLLocation?) -> Void) {
        if let location = manager.location, Date().timeIntervalSince(location.timestamp) <= Self.freshMaxAgeSeconds {
            done(location)
            return
        }
        pendingFixes.append(done)
        guard pendingFixes.count == 1 else { return }
        savedAccuracy = manager.desiredAccuracy
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestLocation()
        fixGeneration += 1
        let generation = fixGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.freshMaxAgeSeconds) { [weak self] in
            guard let self, self.fixGeneration == generation else { return }
            self.resolveFixes(nil)
        }
    }

    // Rend les demandes en attente (position ou nil) et remet la précision d'origine. Sans demande en attente : no-op.
    private func resolveFixes(_ location: CLLocation?) {
        guard !pendingFixes.isEmpty else { return }
        let done = pendingFixes
        pendingFixes = []
        if let saved = savedAccuracy {
            manager.desiredAccuracy = saved
            savedAccuracy = nil
        }
        done.forEach { $0(location) }
    }

    // Une seule notification par présence ; anti-répétition 30 j ; tout est journalisé localement.
    // Une alerte affichée compte comme vue : la date est posée à l'envoi, sans attendre une réponse (F01 M0024)
    private func notifyIfAllowed(boxId: Int) {
        guard !handledInside.contains(boxId) else { return }
        handledInside.insert(boxId)
        let blocked = LocationRules.isBlocked(lastPrompt: LocationPromptLog.all()[boxId], now: Date())
        guard !blocked else {
            ProximityJournal.add(String(localized: "notification bloquée : boîte \(String(boxId)), anti-répétition 30 j"))
            return
        }
        ProximityJournal.add(String(localized: "notification envoyée : boîte \(String(boxId))"))
        LocationPromptLog.mark(boxId: boxId)
        ProximityJournal.add(String(localized: "anti-répétition posée : boîte \(String(boxId)), 30 j"))
        scheduleNotification(boxId: boxId)
    }

    private func stopBoxRegions() {
        for region in manager.monitoredRegions where region.identifier.hasPrefix(Self.regionPrefix) {
            manager.stopMonitoring(for: region)
        }
    }

    private func registerCategory() {
        let later = UNNotificationAction(identifier: Self.laterActionId, title: String(localized: "Plus tard"), options: [])
        let category = UNNotificationCategory(identifier: Self.categoryId, actions: [later],
                                              intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    private func scheduleNotification(boxId: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "📚 Boîte à livres à côté")
        content.body = String(localized: "Est-elle bien ici ?")
        content.sound = .default
        content.categoryIdentifier = Self.categoryId
        content.userInfo = ["type": Self.notifType, "boxId": boxId]
        let request = UNNotificationRequest(identifier: "proximity-\(boxId)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: CLLocationManagerDelegate

    // Position significative (plusieurs centaines de mètres) : recalcul des 20 régions
    // La réponse d'un requestLocation (demande de vitesse) répond aux demandes en attente ; sans attente, no-op.
    // Le recalcul des régions tourne dans tous les cas.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let fresh = locations.last, Date().timeIntervalSince(fresh.timestamp) <= Self.freshMaxAgeSeconds {
            resolveFixes(fresh)
        }
        refreshRegions(origin: locations.last?.coordinate)
    }

    // Position indisponible : les demandes en attente reçoivent nil, donc pas d'alerte (décision fondateur)
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[Proximité] position indisponible : \(error.localizedDescription)")
        resolveFixes(nil)
    }

    // Entrée dans une boîte : rappel local si on est à pied (≤ 7 km/h), sauf anti-répétition 30 jours
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard isEnabled, let boxId = boxId(of: region) else { return }
        handleInside(boxId: boxId, origin: String(localized: "entrée"))
    }

    // Sortie : la présence est close, la prochaine entrée peut de nouveau notifier (F01 M0023, revue R017)
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let boxId = boxId(of: region) else { return }
        handledInside.remove(boxId)
    }

    // État courant d'une région (demandé après chaque enregistrement) : déjà dedans → même alerte
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard isEnabled, let boxId = boxId(of: region) else { return }
        if state == .inside {
            handleInside(boxId: boxId, origin: String(localized: "état au démarrage"))
        } else if state == .outside {
            handledInside.remove(boxId)
        }
    }

    private func boxId(of region: CLRegion) -> Int? {
        guard region.identifier.hasPrefix(Self.regionPrefix) else { return nil }
        return Int(region.identifier.dropFirst(Self.regionPrefix.count))
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways { start() }
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("[Proximité] surveillance en échec : \(error.localizedDescription)")
    }
}


// MARK: - Rappel #29 : alerte désactivée faute de « Toujours » ou de « Position exacte »

// Une fois par retour dans l'app, si l'alerte est activée mais incomplète. « Annuler » : silence 7 jours.
enum ProximityReminder {
    private static let snoozeKey = "proximityReminderSnoozedUntil"
    static let snoozeSeconds: TimeInterval = 7 * 86_400

    // Message à afficher, ou nil si rien à signaler (alerte désactivée, réglages complets, ou silence)
    static func message(now: Date = Date()) -> String? {
        guard ProximityAlertService.shared.isEnabled else { return nil }
        if now.timeIntervalSince1970 < UserDefaults.standard.double(forKey: snoozeKey) { return nil }
        let manager = CLLocationManager()
        if manager.authorizationStatus != .authorizedAlways {
            return String(localized: "Pour être prévenu près d'une boîte, même app fermée, choisis Position › Toujours.")
        }
        if manager.accuracyAuthorization == .reducedAccuracy {
            return String(localized: "Active Position exacte : le parcours de localisation exige une précision de 50 m au plus.")
        }
        return nil
    }

    static func snooze(now: Date = Date()) {
        UserDefaults.standard.set(now.addingTimeInterval(snoozeSeconds).timeIntervalSince1970, forKey: snoozeKey)
    }
}

// MARK: - Journal des alertes (F01 M0023 B2)

// Journal local seulement : rien n'est envoyé au serveur. 200 lignes au plus, la plus ancienne part en premier.
enum ProximityJournal {
    private static let key = "proximityJournal"
    static let maxLines = 200

    static func add(_ text: String, at now: Date = Date()) {
        var lines = UserDefaults.standard.stringArray(forKey: key) ?? []
        lines.append("\(now.formatted(.dateTime.day().month().hour().minute().second())) \(text)")
        if lines.count > maxLines { lines.removeFirst(lines.count - maxLines) }
        UserDefaults.standard.set(lines, forKey: key)
    }

    static func lines() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
