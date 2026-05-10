import Foundation
import CryptoKit

// MARK: - Local Cache Service

actor LocalCacheService {
    static let shared = LocalCacheService()

    struct CachedBoxesEntry: Codable {
        let savedAt: Date
        let boxes: [BookBox]
    }

    private var cache: [String: CachedBoxesEntry] = [:]
    private let cacheDir: URL

    init() {
        let baseDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDir = baseDir.appendingPathComponent("BoxCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    // Retrieve cached boxes for zone key from memory, then disk
    func getBoxes(zone: String) -> [BookBox]? {
        if let cached = cache[zone] { return cached.boxes }
        guard let data = try? Data(contentsOf: fileURL(for: zone)),
              let decoded = try? JSONDecoder().decode(CachedBoxesEntry.self, from: data) else {
            return nil
        }
        cache[zone] = decoded
        return decoded.boxes
    }

    // Store boxes in memory cache and persist them to disk for next launches
    func setBoxes(_ boxes: [BookBox], zone: String) {
        let entry = CachedBoxesEntry(savedAt: Date(), boxes: boxes)
        cache[zone] = entry
        if let data = try? JSONEncoder().encode(entry) {
            try? data.write(to: fileURL(for: zone), options: [.atomic])
        }
    }

    // Clear all cached zones from memory and disk
    func clear() {
        cache.removeAll()
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    // Generate zone cache key from rounded coordinates and radius
    static func zoneKey(lat: Double, lng: Double, radiusKm: Double) -> String {
        let rLat = (lat * 10).rounded() / 10
        let rLng = (lng * 10).rounded() / 10
        return "\(rLat),\(rLng),r\(Int(radiusKm))"
    }

    static func mapKey(lat: Double, lng: Double, radiusKm: Double) -> String {
        "map:\(zoneKey(lat: lat, lng: lng, radiusKm: radiusKm))"
    }

    static func listKey(lat: Double, lng: Double, radiusKm: Double, photoFilter: PhotoFilter, page: Int) -> String {
        let filterKey = photoFilter.intValue.map(String.init) ?? "all"
        return "list:\(zoneKey(lat: lat, lng: lng, radiusKm: radiusKm)):photo:\(filterKey):p\(page)"
    }

    private func fileURL(for zone: String) -> URL {
        let digest = SHA256.hash(data: Data(zone.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return cacheDir.appendingPathComponent(name).appendingPathExtension("json")
    }
}
