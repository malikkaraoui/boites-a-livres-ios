import Foundation

enum SupabaseError: LocalizedError {
    case httpError(Int, String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .httpError(let code, let msg): return "Erreur HTTP \(code): \(msg)"
        case .decodingError(let e): return "Décodage échoué: \(e.localizedDescription)"
        case .networkError(let e): return "Réseau: \(e.localizedDescription)"
        }
    }
}

actor SupabaseService {
    static let shared = SupabaseService()

    private let baseURL = Constants.supabaseURL
    private let anonKey = Constants.supabaseAnonKey

    private func makeRequest(path: String, method: String = "GET", body: Data? = nil) -> URLRequest {
        var req = URLRequest(url: URL(string: "\(baseURL)\(path)")!)
        req.httpMethod = method
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = body
        return req
    }

    private func rpc<P: Encodable, R: Decodable>(_ fn: String, params: P) async throws -> R {
        let body = try JSONEncoder().encode(params)
        let req = makeRequest(path: "/rest/v1/rpc/\(fn)", method: "POST", body: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                let msg = String(data: data, encoding: .utf8) ?? ""
                throw SupabaseError.httpError(http.statusCode, msg)
            }
            do {
                return try JSONDecoder().decode(R.self, from: data)
            } catch {
                throw SupabaseError.decodingError(error)
            }
        } catch let e as SupabaseError {
            throw e
        } catch {
            throw SupabaseError.networkError(error)
        }
    }

    func fetchNearbyMap(lat: Double, lng: Double, radiusKm: Double,
                        photoFilter: PhotoFilter = .all) async throws -> [BookBox] {
        struct Params: Encodable {
            let user_lat: Double, user_lng: Double, radius_m: Int
            let filter_dept: String?, filter_photo: Int?, page_limit: Int, page_offset: Int
        }
        let p = Params(user_lat: lat, user_lng: lng, radius_m: Int(radiusKm * 1000),
                       filter_dept: nil, filter_photo: photoFilter.intValue,
                       page_limit: 200, page_offset: 0)
        return try await rpc("nearby_book_boxes", params: p)
    }

    func fetchNearby(lat: Double, lng: Double, radiusKm: Double,
                     dept: String? = nil, photoFilter: PhotoFilter = .all, page: Int = 0) async throws -> [BookBox] {
        struct Params: Encodable {
            let user_lat: Double, user_lng: Double, radius_m: Int
            let filter_dept: String?, filter_photo: Int?, page_limit: Int, page_offset: Int
        }
        let p = Params(user_lat: lat, user_lng: lng, radius_m: Int(radiusKm * 1000),
                       filter_dept: dept, filter_photo: photoFilter.intValue,
                       page_limit: Constants.listPageSize, page_offset: page * Constants.listPageSize)
        return try await rpc("nearby_book_boxes", params: p)
    }

    func fetchById(_ id: Int) async throws -> BookBox {
        let req = makeRequest(path: "/rest/v1/book_boxes?id=eq.\(id)&select=*")
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw SupabaseError.httpError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        let arr = try JSONDecoder().decode([BookBox].self, from: data)
        guard let box = arr.first else { throw SupabaseError.httpError(404, "Boîte introuvable") }
        return box
    }

    func fetchNearbyTo(id: Int, lat: Double, lng: Double) async throws -> [BookBox] {
        struct Params: Encodable {
            let user_lat: Double, user_lng: Double, radius_m: Int
            let filter_dept: String?, filter_photo: Int?, page_limit: Int, page_offset: Int
        }
        let p = Params(user_lat: lat, user_lng: lng, radius_m: 5000,
                       filter_dept: nil, filter_photo: nil,
                       page_limit: Constants.nearbyLimit + 1, page_offset: 0)
        let all: [BookBox] = try await rpc("nearby_book_boxes", params: p)
        return all.filter { $0.id != id }.prefix(Constants.nearbyLimit).map { $0 }
    }

    func listPhotos(for boxId: Int, fallbackUrl: String? = nil) async throws -> [BoxPhoto] {
        struct Body: Encodable { let prefix: String; let limit: Int; let offset: Int }
        let body = try JSONEncoder().encode(Body(prefix: "\(boxId)/", limit: 50, offset: 0))
        var req = makeRequest(path: "/storage/v1/object/list/boites-photos", method: "POST", body: body)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: req)
        struct StorageFile: Codable { let name: String }

        var result: [BoxPhoto] = []

        // Photo scrapée d'origine — toujours en tête, indépendamment des photos soumises
        if let url = fallbackUrl {
            result.append(BoxPhoto(id: "base_\(boxId)", url: url))
        }

        // Photos approuvées uploadées par les utilisateurs (sous-dossier {boxId}/)
        if let http = response as? HTTPURLResponse, http.statusCode < 400,
           let files = try? JSONDecoder().decode([StorageFile].self, from: data) {
            result += files.map { file in
                BoxPhoto(
                    id: file.name,
                    url: "\(baseURL)/storage/v1/object/public/boites-photos/\(boxId)/\(file.name)"
                )
            }
        }

        return result
    }

    func uploadPhoto(_ imageData: Data, for boxId: Int, filename: String) async throws -> String {
        let path = "\(boxId)/\(filename)"
        var req = URLRequest(url: URL(string: "\(baseURL)/storage/v1/object/boites-photos/\(path)")!)
        req.httpMethod = "POST"
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        req.httpBody = imageData

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw SupabaseError.httpError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return "\(baseURL)/storage/v1/object/public/boites-photos/\(path)"
    }

    func insertPhotoSubmission(boxId: Int, url: String, deviceToken: String?) async throws {
        struct Params: Encodable {
            let box_id: Int
            let url: String
            let device_token: String?
        }
        let body = try JSONEncoder().encode(Params(box_id: boxId, url: url, device_token: deviceToken))
        let req = makeRequest(path: "/rest/v1/photo_submissions", method: "POST", body: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw SupabaseError.httpError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
    }

    func fetchPhotoSubmissions(for boxId: Int? = nil) async throws -> [PhotoSubmission] {
        let filter = boxId.map { "box_id=eq.\($0)" } ?? ""
        let req = makeRequest(path: "/rest/v1/photo_submissions?order=submitted_at.desc\(filter.isEmpty ? "" : "&\(filter)")")
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw SupabaseError.httpError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return try JSONDecoder().decode([PhotoSubmission].self, from: data)
    }
}

struct PhotoSubmission: Codable, Identifiable {
    let id: Int
    let box_id: Int
    let url: String
    let status: String
    let submitted_at: String
    let review_notes: String?
}
