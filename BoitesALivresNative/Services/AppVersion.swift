import Foundation

// MARK: - Comparaison de versions (F01 M0025)

// Comparaison numérique `x.y.z` segment par segment : 1.10.0 > 1.9.9.
// Segment manquant = 0 : « 1.3 » = « 1.3.0 ». Pure fonction, sans effet de bord.
enum AppVersion {

    // Découpe `x.y.z` en entiers ; nil si un segment n'est pas un nombre positif.
    static func parse(_ version: String) -> [Int]? {
        let parts = version.trimmingCharacters(in: .whitespaces).split(separator: ".", omittingEmptySubsequences: false)
        guard !parts.isEmpty else { return nil }
        var numbers: [Int] = []
        for part in parts {
            guard !part.isEmpty, part.allSatisfy({ $0.isASCII && $0.isNumber }), let n = Int(part) else { return nil }
            numbers.append(n)
        }
        return numbers
    }

    // Vrai seulement si `app` est strictement sous `minimum`.
    // Une valeur illisible (version de l'app ou minimum) renvoie false : on ne bloque jamais sur doute.
    static func isBelow(_ app: String, minimum: String) -> Bool {
        guard let current = parse(app), let floor = parse(minimum) else { return false }
        for i in 0..<max(current.count, floor.count) {
            let a = i < current.count ? current[i] : 0
            let m = i < floor.count ? floor[i] : 0
            if a != m { return a < m }
        }
        return false
    }
}
