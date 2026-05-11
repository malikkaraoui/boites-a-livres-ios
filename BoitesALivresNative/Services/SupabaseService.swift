import Foundation

// MARK: - Error Handling

/// Errors specific to Supabase operations
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

// MARK: - Supabase Service

/// Actor-based service for all Supabase backend calls (database, storage, auth)
actor SupabaseService {
    static let shared = SupabaseService()

    private let baseURL = Constants.supabaseURL
    private let anonKey = Constants.supabaseAnonKey

    // Build HTTP request with Supabase auth headers and JSON content type
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

    // Call Postgres stored procedure via RPC: encode params, send POST, decode result
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

    // Fetch max 200 nearby boxes for map view: no pagination, photo filter applied
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

    // Fetch paginated nearby boxes for list view: department and photo filter applied
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

    // Retrieve box by ID from database; throw 404 if not found
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

    // Fetch nearby boxes excluding specified box ID (for detail view "nearby" section)
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

    // List all approved photos in storage for a box (with fallback scraped URL)
    func listPhotos(for boxId: Int, fallbackUrl: String? = nil) async throws -> [BoxPhoto] {
        struct Body: Encodable { let prefix: String; let limit: Int; let offset: Int }
        let body = try JSONEncoder().encode(Body(prefix: "\(boxId)/", limit: 50, offset: 0))
        var req = makeRequest(path: "/storage/v1/object/list/boites-photos", method: "POST", body: body)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: req)
        struct StorageFile: Codable { let name: String }

        var result: [BoxPhoto] = []

        // Include original scraped photo first, always at top
        if let url = fallbackUrl {
            result.append(BoxPhoto(id: "base_\(boxId)", url: url))
        }

        // Append user-submitted approved photos from storage
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

    // Upload photo to storage bucket (not yet approved, pending review)
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

    // Record photo submission for moderation queue
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

    // Upload a photo for a new box submission (stored under submissions/ prefix, pending review)
    func uploadBoxSubmissionPhoto(_ imageData: Data) async throws -> String {
        let filename = "\(UUID().uuidString).jpg"
        let path = "submissions/\(filename)"
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

    // Submit a new book box location for moderation
    func insertBoxSubmission(lat: Double, lng: Double, address: String?, city: String?,
                             postalCode: String?, department: String?, notes: String?,
                             photoUrl: String? = nil, deviceToken: String?) async throws {
        struct Params: Encodable {
            let lat: Double, lng: Double
            let address: String?, city: String?, postal_code: String?, department: String?
            let notes: String?, photo_url: String?, device_token: String?
        }
        let body = try JSONEncoder().encode(Params(
            lat: lat, lng: lng, address: address, city: city,
            postal_code: postalCode, department: department,
            notes: notes, photo_url: photoUrl, device_token: deviceToken
        ))
        var req = makeRequest(path: "/rest/v1/box_submissions", method: "POST", body: body)
        req.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw SupabaseError.httpError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
    }

    // Fetch all photo submissions for current user (optionally filtered by box)
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

// MARK: - Data Models

// Photo submission record from database
struct PhotoSubmission: Codable, Identifiable {
    let id: Int
    let box_id: Int
    let url: String
    let status: String
    let submitted_at: String
    let review_notes: String?
}
