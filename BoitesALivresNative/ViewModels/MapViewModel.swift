import Foundation
import MapKit
import Observation
import SwiftUI

// MARK: - Map View Model

@MainActor @Observable
final class MapViewModel {
    var boxes: [BookBox] = []
    var loading = false
    var selectedBox: BookBox? = nil
    var radiusKm: Double = Constants.defaultRadiusKm
    var mapStyleMode: MapStyleMode = .standard
    private var hasBootstrapped = false

    enum MapStyleMode { case standard, hybrid, imagery }

    // Cycle through map styles: standard → hybrid → imagery → standard
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

    // Load cached data immediately, then refresh from fallback/live location in background
    func onAppear() async {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true

        let initialCoord = locationService.currentLocation?.coordinate ?? Constants.defaultLocation
        cameraPosition = .camera(MapCamera(
            centerCoordinate: initialCoord,
            distance: CLLocationDistance(radiusKm * 1000 * 2)
        ))

        if boxes.isEmpty, let cached = await cache.getBoxes(zone: LocalCacheService.mapKey(lat: initialCoord.latitude, lng: initialCoord.longitude, radiusKm: radiusKm)) {
            boxes = cached
            prefetchPhotos(for: cached)
        }

        locationService.requestAuthorization()
        locationService.startUpdatingIfAuthorized()

        Task(priority: .utility) { [weak self] in
            guard let self else { return }
            await self.loadBoxes(lat: initialCoord.latitude, lng: initialCoord.longitude)
        }

        Task(priority: .background) { [weak self] in
            guard let self else { return }
            do {
                let loc = try await self.locationService.requestCurrentLocation()
                let coord = loc.coordinate
                guard coord.latitude != initialCoord.latitude || coord.longitude != initialCoord.longitude else { return }
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
                // Fallback already shown — keep the current camera position
            }
        }
    }

    // Update search radius and reload boxes with new camera zoom
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

    // Animate camera to current user location if available
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

    // Fetch nearby boxes from cache or backend, invalidate cache if zone changes
    private func loadBoxes(lat: Double, lng: Double) async {
        let cacheKey = LocalCacheService.mapKey(lat: lat, lng: lng, radiusKm: radiusKm)
        let hadCachedData = !boxes.isEmpty
        if let cached = await cache.getBoxes(zone: cacheKey) {
            boxes = cached
            prefetchPhotos(for: cached)
        }

        loading = !hadCachedData && boxes.isEmpty
        errorMessage = nil
        do {
            let data = try await supabase.fetchNearbyMap(lat: lat, lng: lng, radiusKm: radiusKm)
            boxes = data
            await cache.setBoxes(data, zone: cacheKey)
            prefetchPhotos(for: data)
        } catch {
            if boxes.isEmpty {
                errorMessage = error.localizedDescription
                boxes = []
            }
        }
        loading = false
    }

    // Background prefetch of box photos using low-priority task to avoid UI jank
    private func prefetchPhotos(for boxes: [BookBox]) {
        let urls = boxes.compactMap { $0.photo_url.flatMap(URL.init(string:)) }
        guard !urls.isEmpty else { return }
        Task.detached(priority: .utility) {
            await ImageCacheService.shared.prefetch(urls: urls)
        }
    }
}
