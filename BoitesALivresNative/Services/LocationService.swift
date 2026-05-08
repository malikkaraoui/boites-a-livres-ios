import CoreLocation
import Foundation

enum LocationError: LocalizedError {
    case unavailable, timeout, denied

    var errorDescription: String? {
        switch self {
        case .unavailable: return "Position non disponible"
        case .timeout: return "Délai de géolocalisation dépassé"
        case .denied: return "Accès à la localisation refusé"
        }
    }
}

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?

    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var authContinuations: [CheckedContinuation<CLAuthorizationStatus, Never>] = []
    private var isUpdating = false

    override private init() {
        super.init()
        manager.delegate = self
        // Précision réduite = fix beaucoup plus rapide (3-5x). Suffisant pour centrer la carte.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 50
        authorizationStatus = manager.authorizationStatus
        currentLocation = manager.location // dernière position connue immédiatement
    }

    func requestAuthorization() {
        guard authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    func startUpdatingIfAuthorized() {
        guard !isUpdating else { return }
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else { return }
        manager.startUpdatingLocation()
        isUpdating = true
    }

    func requestCurrentLocation() async throws -> CLLocation {
        // Si on a déjà une position en cache (< 60s), la retourner immédiatement
        if let cached = currentLocation, abs(cached.timestamp.timeIntervalSinceNow) < 60 {
            return cached
        }

        switch authorizationStatus {
        case .denied, .restricted:
            throw LocationError.denied
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            let status = await waitForAuthorizationChange()
            guard status == .authorizedWhenInUse || status == .authorizedAlways else {
                throw LocationError.denied
            }
        default:
            break
        }

        // Démarrer le tracking continu (plus rapide que requestLocation pour le 1er fix)
        startUpdatingIfAuthorized()

        return try await withThrowingTaskGroup(of: CLLocation.self) { group in
            group.addTask { @MainActor in
                try await withCheckedThrowingContinuation { (cont: CheckedContinuation<CLLocation, Error>) in
                    self.locationContinuation = cont
                }
            }
            group.addTask {
                try await Task.sleep(for: .seconds(15))
                throw LocationError.timeout
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    private func waitForAuthorizationChange() async -> CLAuthorizationStatus {
        if authorizationStatus != .notDetermined { return authorizationStatus }
        return await withCheckedContinuation { cont in
            authContinuations.append(cont)
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = loc
            if let cont = self.locationContinuation {
                cont.resume(returning: loc)
                self.locationContinuation = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationContinuation?.resume(throwing: error)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            let status = manager.authorizationStatus
            // Démarrer dès l'autorisation accordée
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.startUpdatingIfAuthorized()
                if self.currentLocation == nil {
                    self.currentLocation = manager.location
                }
            }
            guard status != .notDetermined else { return }
            for cont in self.authContinuations { cont.resume(returning: status) }
            self.authContinuations.removeAll()
        }
    }
}

func formatDistance(_ meters: Double) -> String {
    if meters < 1000 { return "\(Int(meters)) m" }
    return String(format: "%.1f km", meters / 1000)
}
