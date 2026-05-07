import Foundation

actor LocalCacheService {
    static let shared = LocalCacheService()

    private var cache: [String: [BookBox]] = [:]

    func getBoxes(zone: String) -> [BookBox]? { cache[zone] }
    func setBoxes(_ boxes: [BookBox], zone: String) { cache[zone] = boxes }
    func clear() { cache.removeAll() }

    static func zoneKey(lat: Double, lng: Double, radiusKm: Double) -> String {
        let rLat = (lat * 10).rounded() / 10
        let rLng = (lng * 10).rounded() / 10
        return "\(rLat),\(rLng),r\(Int(radiusKm))"
    }
}
