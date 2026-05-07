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
    private var continuation: CheckedContinuation<CLLocation, Error>?

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func requestCurrentLocation() async throws -> CLLocation {
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            throw LocationError.denied
        }
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        return try await withThrowingTaskGroup(of: CLLocation.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { cont in
                    Task { @MainActor in
                        self.continuation = cont
                        self.manager.requestLocation()
                    }
                }
            }
            group.addTask {
                try await Task.sleep(for: .seconds(10))
                throw LocationError.timeout
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = loc
            self.continuation?.resume(returning: loc)
            self.continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.continuation?.resume(throwing: error)
            self.continuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }
}

func formatDistance(_ meters: Double) -> String {
    if meters < 1000 { return "\(Int(meters)) m" }
    return String(format: "%.1f km", meters / 1000)
}
