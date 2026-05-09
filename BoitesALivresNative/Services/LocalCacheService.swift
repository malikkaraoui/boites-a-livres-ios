import Foundation

// MARK: - Local Cache Service

actor LocalCacheService {
    static let shared = LocalCacheService()

    private var cache: [String: [BookBox]] = [:]

    // Retrieve cached boxes for zone key; returns nil if not cached
    func getBoxes(zone: String) -> [BookBox]? { cache[zone] }

    // Store boxes in memory cache for zone key
    func setBoxes(_ boxes: [BookBox], zone: String) { cache[zone] = boxes }

    // Clear all cached zones
    func clear() { cache.removeAll() }

    // Generate zone cache key from rounded coordinates and radius
    static func zoneKey(lat: Double, lng: Double, radiusKm: Double) -> String {
        let rLat = (lat * 10).rounded() / 10
        let rLng = (lng * 10).rounded() / 10
        return "\(rLat),\(rLng),r\(Int(radiusKm))"
    }
}
