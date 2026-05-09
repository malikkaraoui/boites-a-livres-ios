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

    private let supabase = SupabaseService.shared
    private let locationService = LocationService.shared

    // Load first page of boxes using live location if available, fallback to default coordinate
    func initialLoad() async {
        guard !loading else { return }
        // Prefer live location (continuously updated) over the 60s-old CLLocation cache
        let lat: Double
        let lng: Double
        if let live = locationService.currentLocation {
            lat = live.coordinate.latitude
            lng = live.coordinate.longitude
        } else if let loc = try? await locationService.requestCurrentLocation() {
            lat = loc.coordinate.latitude
            lng = loc.coordinate.longitude
        } else {
            lat = Constants.defaultLocation.latitude
            lng = Constants.defaultLocation.longitude
        }
        await loadFromCoordinate(lat: lat, lng: lng)
    }

    // Fetch page 0 from coordinate, cache location for pagination, prefetch photos
    private func loadFromCoordinate(lat: Double, lng: Double) async {
        loading = true
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
        do {
            let data = try await supabase.fetchNearby(
                lat: lastLat, lng: lastLng,
                radiusKm: radiusKm, dept: nil,
                photoFilter: photoFilter, page: nextPage
            )
            boxes.append(contentsOf: data)
            currentPage = nextPage
            hasMore = data.count == Constants.listPageSize
            prefetchPhotos(for: data)
        } catch {
            // silently ignore pagination error
        }
        loadingMore = false
    }

    // Reset to page 0 with new filter settings
    func applyFilters() async {
        await initialLoad()
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
