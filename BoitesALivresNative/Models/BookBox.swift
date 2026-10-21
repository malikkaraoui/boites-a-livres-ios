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
    // Dénormalisé depuis box_reviews à chaque approbation pour colorer le pin carte.
    var last_review_condition: String?
    var last_review_book_count: Int?
    var last_review_at: String?
    var reviews_approved_count: Int?

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

// Ordre d'affichage des photos publiées : slots validés, photo_url en tête si absente, sans doublon
enum PhotoList {
    static func merge(slotUrls: [String], fallbackUrl: String?) -> [String] {
        var urls = slotUrls
        if let fallback = fallbackUrl, !urls.contains(fallback) {
            urls.insert(fallback, at: 0)
        }
        var seen = Set<String>()
        return urls.filter { seen.insert($0).inserted }
    }
}

// Aperçu carte : candidats = photo_url puis photos validées (slot croissant), sans doublon.
// On affiche la première candidate qui n'a pas encore échoué ; nil = rien à afficher.
enum PreviewPhotoPicker {
    static func candidates(photoUrl: String?, validated: [String]) -> [String] {
        var seen = Set<String>()
        return ([photoUrl].compactMap { $0 } + validated).filter { seen.insert($0).inserted }
    }

    static func current(candidates: [String], failed: Set<String>) -> String? {
        candidates.first { !failed.contains($0) }
    }
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

    // RPC nearby_book_boxes attend un BOOLEAN — null = pas de filtre.
    var boolValue: Bool? {
        switch self {
        case .all: return nil
        case .withPhoto: return true
        case .withoutPhoto: return false
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

// MARK: - Localisation (F01 M0020)

// Ma proposition de localisation (RPC my_location_updates) : statut, motif, sans position
struct LocationUpdateRecord: Codable, Identifiable, Hashable {
    let id: Int
    let box_id: Int
    let kind: String
    let status: String
    let address: String?
    let city: String?
    let submitted_at: String
    let reviewed_at: String?
    let review_notes: String?
}

// Règles pures de la localisation : seuils, barres de précision, sélection des régions
enum LocationRules {
    // Présence sur place (ajout, bouton Localisation, écran Localisation) : 50 m, inchangé
    static let presenceMeters: Double = 50
    // Rayon des régions de l'alerte de proximité : 100 m (F01 M0036)
    static let alertRadiusMeters: Double = 100
    // Déplacement maximal du repère par rapport à la boîte : 100 m (F01 M0036)
    static let moveMaxMeters: Double = 100

    // Alerte de proximité activée par défaut : clé absente = activée, seul « false » explicite la coupe (F01 M0036)
    static func alertEnabled(stored: Bool?) -> Bool { stored ?? true }
    static let confirmMaxAccuracyMeters: Double = 10
    static let regionLimit = 20
    static let repeatWindowSeconds: TimeInterval = 30 * 86_400
    static let deletionMaxMeters: Double = 100

    // « Signaler une suppression » : distance inconnue = refusé
    static func canReportDeletion(distance: Double?) -> Bool {
        guard let distance else { return false }
        return distance <= deletionMaxMeters
    }

    // Barres de précision : ≤5 m = 5, ≤10 m = 4, ≤20 m = 3, ≤50 m = 2, sinon 1 ; précision inconnue (<0) = 1
    static func precisionBars(accuracy: Double) -> Int {
        guard accuracy >= 0 else { return 1 }
        switch accuracy {
        case ...5: return 5
        case ...10: return 4
        case ...20: return 3
        case ...50: return 2
        default: return 1
        }
    }

    // Envoi possible seulement avec 10 m de précision ou mieux (4 à 5 barres)
    static func canSend(accuracy: Double) -> Bool {
        accuracy >= 0 && accuracy <= confirmMaxAccuracyMeters
    }

    // Repère placé à la main : précision GPS jusqu'à 50 m (accepté en production, source = manual)
    static let manualMaxAccuracyMeters: Double = 50
    static func canSendManual(accuracy: Double) -> Bool {
        accuracy >= 0 && accuracy <= manualMaxAccuracyMeters
    }

    // Position « fraîche » : postérieure à l'ouverture de l'étape position, précision valide.
    // Le cache de CLLocationManager et le rejeu de @Published sont plus anciens : jamais pris pour le premier fix (F01 M0040, R032)
    static func isFresh(timestamp: Date, openedAt: Date, accuracy: Double) -> Bool {
        accuracy >= 0 && timestamp >= openedAt
    }

    // Effet d'un fix sur la carte : centrer la caméra seulement ; poser aussi le repère si l'utilisateur n'a jamais touché la carte
    enum FirstFixEffect: Equatable { case none, cameraOnly, cameraAndPin }
    static func firstFixEffect(isWaiting: Bool, onMapStep: Bool, isFresh: Bool, userPlacedPin: Bool) -> FirstFixEffect {
        guard isWaiting, onMapStep, isFresh else { return .none }
        return userPlacedPin ? .cameraOnly : .cameraAndPin
    }

    // Source envoyée au serveur : « gps » seulement si GPS précis (≤ 10 m) ET repère posé sur la position GPS
    static func source(accuracy: Double, pinIsGPS: Bool) -> String {
        (canSend(accuracy: accuracy) && pinIsGPS) ? "gps" : "manual"
    }

    // Anti-répétition : une boîte proposée il y a moins de 30 jours n'alerte plus
    static func isBlocked(lastPrompt: Date?, now: Date) -> Bool {
        guard let last = lastPrompt else { return false }
        return now.timeIntervalSince(last) < repeatWindowSeconds
    }

    // Les `limit` boîtes les plus proches (à vol d'oiseau), hors anti-répétition
    static func regionCandidates(boxes: [BookBox], origin: CLLocationCoordinate2D,
                                 prompts: [Int: Date], now: Date, limit: Int = regionLimit) -> [BookBox] {
        let here = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        return boxes
            .filter { !isBlocked(lastPrompt: prompts[$0.id], now: now) }
            .map { box in (box, here.distance(from: CLLocation(latitude: box.lat, longitude: box.lng))) }
            .sorted { $0.1 < $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }
}

// Note libre de l'ajout de boîte : jamais deux sauts de ligne d'affilée (F01 M0038, #38)
enum NoteText {
    // Saisie et collage : un `\n` au plus entre deux lignes (espaces et retours tolérés entre eux)
    static func limitLineBreaks(_ raw: String) -> String {
        var out = raw
        while true {
            let next = out.replacingOccurrences(of: "\\n[ \\t\\r]*\\n", with: "\n", options: .regularExpression)
            if next == out { return out }
            out = next
        }
    }

    // Envoi : même règle, plus espaces et sauts de ligne superflus en début et fin
    static func forSend(_ raw: String) -> String {
        limitLineBreaks(raw).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// Journal des dates de rappel par boîte, sur le téléphone seulement (UserDefaults)
enum LocationPromptLog {
    private static let key = "locationPromptTimes"

    static func all() -> [Int: Date] {
        let raw = UserDefaults.standard.dictionary(forKey: key) as? [String: Double] ?? [:]
        var out: [Int: Date] = [:]
        for (id, time) in raw {
            if let boxId = Int(id) { out[boxId] = Date(timeIntervalSince1970: time) }
        }
        return out
    }

    static func mark(boxId: Int, at now: Date = Date()) {
        var raw = UserDefaults.standard.dictionary(forKey: key) as? [String: Double] ?? [:]
        raw["\(boxId)"] = now.timeIntervalSince1970
        UserDefaults.standard.set(raw, forKey: key)
    }
}
