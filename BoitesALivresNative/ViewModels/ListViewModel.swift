import Foundation
import CoreLocation
import Observation

// MARK: - List View Model

@MainActor @Observable
final class ListViewModel {
    var boxes: [BookBox] = []
    var loading = false
    var loadingMore = false
    var hasMore = true
    var currentPage = 0
    var radiusKm: Double = Constants.defaultRadiusKm
    var photoFilter: PhotoFilter = .all
    var errorMessage: String? = nil
    private var lastLat: Double = Constants.defaultLocation.latitude
    private var lastLng: Double = Constants.defaultLocation.longitude
    private var hasBootstrapped = false

    private let supabase = SupabaseService.shared
    private let locationService = LocationService.shared
    private let cache = LocalCacheService.shared

    // Load cached first page immediately, then refresh from fallback/live location in background
    func initialLoad(force: Bool = false) async {
        guard !loading else { return }
        if hasBootstrapped, !boxes.isEmpty, !force { return }
        hasBootstrapped = true

        let initialCoord = locationService.currentLocation?.coordinate ?? Constants.defaultLocation
        if boxes.isEmpty, let cached = await cache.getBoxes(zone: LocalCacheService.listKey(lat: initialCoord.latitude, lng: initialCoord.longitude, radiusKm: radiusKm, photoFilter: photoFilter, page: 0)) {
            boxes = cached
            lastLat = initialCoord.latitude
            lastLng = initialCoord.longitude
            hasMore = cached.count == Constants.listPageSize
            prefetchPhotos(for: cached)
        }

        locationService.requestAuthorization()
        locationService.startUpdatingIfAuthorized()

        await loadFromCoordinate(lat: initialCoord.latitude, lng: initialCoord.longitude)

        if let live = try? await locationService.requestCurrentLocation() {
            let coord = live.coordinate
            let movedEnough = abs(coord.latitude - initialCoord.latitude) > 0.001 || abs(coord.longitude - initialCoord.longitude) > 0.001
            if movedEnough {
                await loadFromCoordinate(lat: coord.latitude, lng: coord.longitude)
            }
        }
    }

    // Fetch page 0 from coordinate, cache location for pagination, prefetch photos
    private func loadFromCoordinate(lat: Double, lng: Double) async {
        let cacheKey = LocalCacheService.listKey(lat: lat, lng: lng, radiusKm: radiusKm, photoFilter: photoFilter, page: 0)
        let hadCachedData = !boxes.isEmpty
        if let cached = await cache.getBoxes(zone: cacheKey) {
            boxes = cached
            lastLat = lat
            lastLng = lng
            currentPage = 0
            hasMore = cached.count == Constants.listPageSize
            prefetchPhotos(for: cached)
        }

        loading = !hadCachedData && boxes.isEmpty
        defer { loading = false }
        errorMessage = nil
        do {
            let data = try await supabase.fetchNearby(
                lat: lat, lng: lng,
                radiusKm: radiusKm, dept: nil,
                photoFilter: photoFilter, page: 0
            )
            lastLat = lat
            lastLng = lng
            boxes = data
            currentPage = 0
            hasMore = data.count == Constants.listPageSize
            await cache.setBoxes(data, zone: cacheKey)
            prefetchPhotos(for: data)
        } catch is CancellationError {
            // Navigation push/pop cancels the task — silently discard to preserve existing state
        } catch {
            if boxes.isEmpty { errorMessage = error.localizedDescription }
        }
    }

    // Fetch next page and append to boxes if hasMore is true; suppress pagination errors
    func loadMore() async {
        guard !loadingMore && hasMore && !loading else { return }
        loadingMore = true
        let nextPage = currentPage + 1
        let cacheKey = LocalCacheService.listKey(lat: lastLat, lng: lastLng, radiusKm: radiusKm, photoFilter: photoFilter, page: nextPage)
        do {
            let data = try await supabase.fetchNearby(
                lat: lastLat, lng: lastLng,
                radiusKm: radiusKm, dept: nil,
                photoFilter: photoFilter, page: nextPage
            )
            boxes.append(contentsOf: data)
            currentPage = nextPage
            hasMore = data.count == Constants.listPageSize
            await cache.setBoxes(data, zone: cacheKey)
            prefetchPhotos(for: data)
        } catch {
            // silently ignore pagination error
        }
        loadingMore = false
    }

    // Reset to page 0 with new filter settings
    func applyFilters() async {
        await initialLoad(force: true)
    }

    // Auto-reload if user moved more than threshold; fetches from new location with re-sort
    func reloadIfMovedFar(newLocation: CLLocation, threshold: Double = 250) async {
        guard !loading else { return }
        let last = CLLocation(latitude: lastLat, longitude: lastLng)
        let distance = newLocation.distance(from: last)
        guard distance > threshold else { return }
        // Use newLocation directly: refetch and re-sort from the actual current position
        await loadFromCoordinate(
            lat: newLocation.coordinate.latitude,
            lng: newLocation.coordinate.longitude
        )
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
