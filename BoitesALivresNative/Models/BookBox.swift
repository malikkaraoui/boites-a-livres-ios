import CoreLocation
import Foundation

// MARK: - Core Data Models

// Book box record from Supabase: location, metadata, and computed navigation properties
struct BookBox: Codable, Identifiable, Hashable {
    let id: Int
    let lat: Double
    let lng: Double
    let address: String?
    let city: String?
    let department: String?
    let postal_code: String?
    let has_photo: Bool
    let photo_url: String?
    let flag: Int
    var distance_m: Double?

    // CLLocationCoordinate2D binding for map annotations
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    // Build URL to official boites-a-livres.fr page or fallback to home
    var detailURL: URL? {
        guard let city, let postal_code,
              let citySlug = city.urlSlug, !citySlug.isEmpty
        else { return URL(string: "https://www.boites-a-livres.fr") }
        return URL(string: "https://www.boites-a-livres.fr/ville/\(citySlug)/\(postal_code)/boite-\(id)")
    }

    // Hashable and Equatable by ID only
    static func == (lhs: BookBox, rhs: BookBox) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - URL Slug Conversion

// MARK: - URL Slug Extension

extension String {
    // Normalize city name to URL slug: remove accents, lowercase, replace spaces with dashes
    var urlSlug: String? {
        let lowered = folding(options: .diacriticInsensitive, locale: .init(identifier: "fr_FR"))
            .lowercased()
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
        var out = ""
        var lastDash = false
        for scalar in lowered.unicodeScalars {
            if allowed.contains(scalar) {
                out.append(Character(scalar))
                lastDash = false
            } else if !lastDash, !out.isEmpty {
                out.append("-")
                lastDash = true
            }
        }
        if out.hasSuffix("-") { out.removeLast() }
        return out.isEmpty ? nil : out
    }
}

// MARK: - Photo Models

// Photo record: ID and Supabase storage URL
struct BoxPhoto: Identifiable {
    let id: String
    let url: String
}

// Photo filter options: all boxes, only with photos, only without photos
enum PhotoFilter: String, CaseIterable, Identifiable {
    case all = "Toutes"
    case withPhoto = "Avec photo"
    case withoutPhoto = "Sans photo"

    var id: String { rawValue }

    // Convert to database filter: nil for all, 1 for with photo, 0 for without
    var intValue: Int? {
        switch self {
        case .all: return nil
        case .withPhoto: return 1
        case .withoutPhoto: return 0
        }
    }
}

// MARK: - Box Submission

// Box submission sent to moderation queue by a volunteer
struct BoxSubmission: Codable, Identifiable {
    let id: UUID
    let lat: Double
    let lng: Double
    let address: String?
    let city: String?
    let postal_code: String?
    let department: String?
    let notes: String?
    let photo_url: String?
    let device_token: String?
    let status: String
    let submitted_at: String
}

// MARK: - Photo Submission Tracking

// User photo submission: local image path and pending/approved/rejected status
struct PendingPhotoSubmission: Codable, Identifiable {
    let id: UUID
    let boxId: Int
    let localImagePath: String
    let submittedAt: Date
    var status: SubmissionStatus
    var remoteUrl: String?

    // Submission status: pending moderation, approved, or rejected
    enum SubmissionStatus: String, Codable {
        case pending, approved, rejected
    }
}
