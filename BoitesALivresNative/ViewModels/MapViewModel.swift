import Foundation
import MapKit
import Observation
import SwiftUI

@MainActor @Observable
final class MapViewModel {
    var boxes: [BookBox] = []
    var loading = false
    var selectedBox: BookBox? = nil
    var radiusKm: Double = Constants.defaultRadiusKm
    var mapStyleMode: MapStyleMode = .standard

    enum MapStyleMode { case standard, hybrid, imagery }

    func cycleMapStyle() {
        switch mapStyleMode {
        case .standard: mapStyleMode = .hybrid
        case .hybrid: mapStyleMode = .imagery
        case .imagery: mapStyleMode = .standard
        }
    }
    // Concrete camera (not .userLocation) so MapKit renders tiles immediately on device
    var cameraPosition: MapCameraPosition = .camera(
        MapCamera(centerCoordinate: Constants.defaultLocation, distance: 8000)
    )
    var errorMessage: String? = nil

    private let locationService = LocationService.shared
    private let supabase = SupabaseService.shared
    private let cache = LocalCacheService.shared

    func onAppear() async {
        // Si on a déjà une position connue (cached du précédent run), centrer tout de suite
        if let cached = locationService.currentLocation {
            let coord = cached.coordinate
            cameraPosition = .camera(MapCamera(
                centerCoordinate: coord,
                distance: CLLocationDistance(radiusKm * 1000 * 2)
            ))
            if boxes.isEmpty {
                await loadBoxes(lat: coord.latitude, lng: coord.longitude)
            }
        } else {
            // Charger fallback en attendant le GPS pour que la carte soit utilisable
            let fallback = Constants.defaultLocation
            if boxes.isEmpty {
                await loadBoxes(lat: fallback.latitude, lng: fallback.longitude)
            }
        }

        // GPS en tâche de fond — non bloquant pour l'UI
        locationService.requestAuthorization()
        locationService.startUpdatingIfAuthorized()

        Task { [weak self] in
            guard let self else { return }
            do {
                let loc = try await self.locationService.requestCurrentLocation()
                let coord = loc.coordinate
                await MainActor.run {
                    withAnimation {
                        self.cameraPosition = .camera(MapCamera(
                            centerCoordinate: coord,
                            distance: CLLocationDistance(self.radiusKm * 1000 * 2)
                        ))
                    }
                }
                await self.loadBoxes(lat: coord.latitude, lng: coord.longitude)
            } catch {
                // Fallback déjà affiché — garder la caméra courante
            }
        }
    }

    func changeRadius(_ km: Double) {
        guard km != radiusKm else { return }
        radiusKm = km
        Task {
            let loc = locationService.currentLocation?.coordinate ?? Constants.defaultLocation
            await loadBoxes(lat: loc.latitude, lng: loc.longitude)
            withAnimation {
                cameraPosition = .camera(MapCamera(
                    centerCoordinate: loc,
                    distance: CLLocationDistance(km * 1000 * 2)
                ))
            }
        }
    }

    func centerOnUser() {
        if let loc = locationService.currentLocation {
            withAnimation {
                cameraPosition = .camera(MapCamera(
                    centerCoordinate: loc.coordinate,
                    distance: 5000
                ))
            }
        }
    }

    private func loadBoxes(lat: Double, lng: Double) async {
        let zoneKey = LocalCacheService.zoneKey(lat: lat, lng: lng, radiusKm: radiusKm)
        if let cached = await cache.getBoxes(zone: zoneKey) {
            boxes = cached
            prefetchPhotos(for: cached)
            return
        }
        loading = true
        errorMessage = nil
        do {
            let data = try await supabase.fetchNearbyMap(lat: lat, lng: lng, radiusKm: radiusKm)
            boxes = data
            await cache.setBoxes(data, zone: zoneKey)
            prefetchPhotos(for: data)
        } catch {
            errorMessage = error.localizedDescription
            boxes = []
        }
        loading = false
    }

    /// Précharge en arrière-plan les images des boîtes affichées (rayon courant ≤ 30 km).
    private func prefetchPhotos(for boxes: [BookBox]) {
        let urls = boxes.compactMap { $0.photo_url.flatMap(URL.init(string:)) }
        guard !urls.isEmpty else { return }
        Task.detached(priority: .utility) {
            await ImageCacheService.shared.prefetch(urls: urls)
        }
    }
}
