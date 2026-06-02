import Foundation

// MARK: - Box Review

// Avis utilisateur sur une boîte à livres : commentaire, état, nombre estimé de livres.
// Soumis depuis l'app, validé par modération admin, visible aux autres une fois approuvé.
struct BoxReview: Codable, Identifiable, Hashable {
    let id: Int
    let box_id: Int
    let author_name: String?
    let comment: String
    let box_condition: String
    let book_count: Int?
    let status: String
    let created_at: String
    let reviewed_at: String?

    // MARK: - Sub-types

    enum Condition: String, CaseIterable, Codable {
        case bon, moyen, mauvais
    }

    enum Status: String {
        case pending, approved, rejected
    }

    // MARK: - Computed

    var condition: Condition? { Condition(rawValue: box_condition) }
    var statusValue: Status? { Status(rawValue: status) }

    var displayName: String {
        guard let name = author_name?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
            return NSLocalizedString("Anonyme", comment: "")
        }
        return name
    }

    // Equatable + Hashable by id
    static func == (lhs: BoxReview, rhs: BoxReview) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
