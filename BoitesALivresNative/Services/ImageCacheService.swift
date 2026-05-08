import Foundation
import UIKit
import CryptoKit

/// Cache image deux niveaux : mémoire (NSCache) + disque (Caches/ImageCache).
/// Clé = SHA256(url). Invalidation = changement d'URL (les images Supabase
/// changent d'URL quand elles sont remplacées, donc pas besoin d'ETag).
final class ImageCacheService {
    static let shared = ImageCacheService()

    private let memCache = NSCache<NSString, UIImage>()
    private let diskDir: URL
    private let session: URLSession
    private let diskQueue = DispatchQueue(label: "ImageCacheService.disk", qos: .utility)
    private let maxDiskBytes: Int64 = 200 * 1024 * 1024

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskDir = caches.appendingPathComponent("ImageCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskDir, withIntermediateDirectories: true)

        memCache.countLimit = 200
        memCache.totalCostLimit = 60 * 1024 * 1024 // 60 Mo en mémoire

        let config = URLSessionConfiguration.default
        config.urlCache = nil
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)
    }

    /// Lit l'image depuis le cache (mem → disque), sinon fetch réseau et cache.
    /// Retourne nil en cas d'échec.
    func image(for url: URL) async -> UIImage? {
        let key = url.absoluteString as NSString
        if let img = memCache.object(forKey: key) { return img }

        let path = diskPath(for: url)
        if let data = try? Data(contentsOf: path), let img = UIImage(data: data) {
            memCache.setObject(img, forKey: key, cost: data.count)
            return img
        }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let img = UIImage(data: data) else { return nil }
            try? data.write(to: path)
            memCache.setObject(img, forKey: key, cost: data.count)
            let dir = diskDir
            let max = maxDiskBytes
            diskQueue.async { Self.enforceDiskLimit(at: dir, maxBytes: max) }
            return img
        } catch {
            return nil
        }
    }

    /// Préchargement parallèle limité (4 simultanés). N'écrase pas un cache existant.
    func prefetch(urls: [URL], maxConcurrent: Int = 4) async {
        guard !urls.isEmpty else { return }
        await withTaskGroup(of: Void.self) { group in
            var iter = urls.makeIterator()
            for _ in 0..<maxConcurrent {
                guard let url = iter.next() else { break }
                group.addTask { _ = await self.image(for: url) }
            }
            while await group.next() != nil {
                if let url = iter.next() {
                    group.addTask { _ = await self.image(for: url) }
                }
            }
        }
    }

    /// Vide tout : mémoire + disque.
    func clear() {
        memCache.removeAllObjects()
        diskQueue.sync {
            try? FileManager.default.removeItem(at: self.diskDir)
            try? FileManager.default.createDirectory(at: self.diskDir, withIntermediateDirectories: true)
        }
    }

    // MARK: - Privé

    private func diskPath(for url: URL) -> URL {
        let data = Data(url.absoluteString.utf8)
        let hash = SHA256.hash(data: data)
        let name = hash.compactMap { String(format: "%02x", $0) }.joined()
        return diskDir.appendingPathComponent(name)
    }

    private static func enforceDiskLimit(at diskDir: URL, maxBytes: Int64) {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: diskDir,
            includingPropertiesForKeys: [.contentAccessDateKey, .fileSizeKey]
        ) else { return }

        let entries = files.compactMap { url -> (URL, Date, Int64)? in
            guard let r = try? url.resourceValues(forKeys: [.contentAccessDateKey, .fileSizeKey]),
                  let d = r.contentAccessDate, let s = r.fileSize else { return nil }
            return (url, d, Int64(s))
        }
        var total = entries.reduce(Int64(0)) { $0 + $1.2 }
        guard total > maxBytes else { return }
        let sorted = entries.sorted { $0.1 < $1.1 } // plus ancien d'abord
        for (file, _, size) in sorted {
            if total <= maxBytes { break }
            try? fm.removeItem(at: file)
            total -= size
        }
    }
}
