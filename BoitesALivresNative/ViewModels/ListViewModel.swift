import Foundation
import Observation

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

    func initialLoad() async {
        guard !loading else { return }
        loading = true
        currentPage = 0
        hasMore = true
        boxes = []
        errorMessage = nil
        do {
            let loc = try? await locationService.requestCurrentLocation()
            lastLat = loc?.coordinate.latitude ?? Constants.defaultLocation.latitude
            lastLng = loc?.coordinate.longitude ?? Constants.defaultLocation.longitude
            let data = try await supabase.fetchNearby(
                lat: lastLat, lng: lastLng,
                radiusKm: radiusKm, dept: nil,
                photoFilter: photoFilter, page: 0
            )
            boxes = data
            hasMore = data.count == Constants.listPageSize
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }

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
        } catch {
            // silently ignore pagination error
        }
        loadingMore = false
    }

    func applyFilters() async {
        await initialLoad()
    }
}
