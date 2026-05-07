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
    var cameraPosition: MapCameraPosition = .userLocation(fallback: .camera(
        MapCamera(centerCoordinate: Constants.defaultLocation, distance: 8000)
    ))
    var errorMessage: String? = nil

    private let locationService = LocationService.shared
    private let supabase = SupabaseService.shared
    private let cache = LocalCacheService.shared

    func onAppear() async {
        locationService.requestAuthorization()
        do {
            let loc = try await locationService.requestCurrentLocation()
            let coord = loc.coordinate
            withAnimation {
                cameraPosition = .camera(MapCamera(
                    centerCoordinate: coord,
                    distance: CLLocationDistance(radiusKm * 1000 * 2)
                ))
            }
            await loadBoxes(lat: coord.latitude, lng: coord.longitude)
        } catch {
            let fallback = Constants.defaultLocation
            withAnimation {
                cameraPosition = .camera(MapCamera(
                    centerCoordinate: fallback,
                    distance: CLLocationDistance(radiusKm * 1000 * 2)
                ))
            }
            await loadBoxes(lat: fallback.latitude, lng: fallback.longitude)
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
            return
        }
        loading = true
        errorMessage = nil
        do {
            let data = try await supabase.fetchNearbyMap(lat: lat, lng: lng, radiusKm: radiusKm)
            boxes = data
            await cache.setBoxes(data, zone: zoneKey)
        } catch {
            errorMessage = error.localizedDescription
            boxes = []
        }
        loading = false
    }
}
