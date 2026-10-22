import CoreLocation
import Foundation

// MARK: - Error Handling

enum LocationError: LocalizedError {
    case unavailable, timeout, denied

    var errorDescription: String? {
        switch self {
        case .unavailable: return String(localized: "Position non disponible")
        case .timeout: return String(localized: "Délai de géolocalisation dépassé")
        case .denied: return String(localized: "Accès à la localisation refusé")
        }
    }
}

// MARK: - Location Service

/// Manages geolocation with reduced accuracy for faster fixes and cached position logic
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
        // Reduced accuracy for 3-5x faster fix; 100m precision sufficient for map centering
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 50
        authorizationStatus = manager.authorizationStatus
        currentLocation = manager.location // Load cached location immediately
        #if DEBUG
        if let simulated = UITestHooks.simulatedLocation { currentLocation = simulated }
        #endif
    }

    // Trigger system dialog for "When In Use" location permission
    func requestAuthorization() {
        guard authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    // Start CLLocationManager updates if authorized and not already running
    func startUpdatingIfAuthorized() {
        guard !isUpdating else { return }
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else { return }
        manager.startUpdatingLocation()
        isUpdating = true
    }

    // Précision maximale et position à chaque mouvement pendant l'écran de localisation seulement
    // (F01 M0023, retour terrain 19/10 : précision figée à ± 14 m faute de distanceFilter levé)
    func beginPrecisionUpdates() {
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        startUpdatingIfAuthorized()
    }

    // Retour au réglage économe (F01 M0020 / M0023)
    func endPrecisionUpdates() {
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 50
    }

    // Get current location: return cached if < 60s old, else request fresh with 15s timeout
    func requestCurrentLocation() async throws -> CLLocation {
        // Return the cached location immediately if it is less than 60 seconds old
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

        // Start continuous updates — faster first fix than one-shot requestLocation()
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

    // Block until authorization status changes from notDetermined
    private func waitForAuthorizationChange() async -> CLAuthorizationStatus {
        if authorizationStatus != .notDetermined { return authorizationStatus }
        return await withCheckedContinuation { cont in
            authContinuations.append(cont)
        }
    }
}

// MARK: - Location Manager Delegate

extension LocationService: CLLocationManagerDelegate {
    // Resume location continuation, update published location, stop on first valid fix
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

    // Resume continuation with error: thrown to waiting requestCurrentLocation caller
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationContinuation?.resume(throwing: error)
            self.locationContinuation = nil
        }
    }

    // Update authorization status, start tracking if granted, resume waiting continuations
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            let status = manager.authorizationStatus
            // Start tracking immediately upon authorization
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

// MARK: - Helpers

// Convert meters to readable string: below 1000m shows meters, above shows kilometers
func formatDistance(_ meters: Double) -> String {
    if meters < 1000 { return "\(Int(meters)) m" }
    return String(format: "%.1f km", meters / 1000)
}
