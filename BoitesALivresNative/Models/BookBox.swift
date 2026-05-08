import CoreLocation
import Foundation

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

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var detailURL: URL? {
        guard let city, let postal_code,
              let citySlug = city.urlSlug, !citySlug.isEmpty
        else { return URL(string: "https://www.boites-a-livres.fr") }
        return URL(string: "https://www.boites-a-livres.fr/ville/\(citySlug)/\(postal_code)/boite-\(id)")
    }

    static func == (lhs: BookBox, rhs: BookBox) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension String {
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

struct BoxPhoto: Identifiable {
    let id: String
    let url: String
}

enum PhotoFilter: String, CaseIterable, Identifiable {
    case all = "Toutes"
    case withPhoto = "Avec photo"
    case withoutPhoto = "Sans photo"

    var id: String { rawValue }

    var intValue: Int? {
        switch self {
        case .all: return nil
        case .withPhoto: return 1
        case .withoutPhoto: return 0
        }
    }
}

struct PendingPhotoSubmission: Codable, Identifiable {
    let id: UUID
    let boxId: Int
    let localImagePath: String
    let submittedAt: Date
    var status: SubmissionStatus
    var remoteUrl: String?

    enum SubmissionStatus: String, Codable {
        case pending, approved, rejected
    }
}
