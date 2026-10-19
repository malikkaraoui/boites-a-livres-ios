import CoreLocation
import MapKit
import SwiftUI

// MARK: - Proposition de localisation (F01 M0020)

// Parcours « La boîte est-elle bien ici ? » : confirmer, ou placer le repère sur la carte.
// Rien ne change sur la carte avant validation admin. La position du téléphone ne quitte jamais
// l'appareil : seules la position PROPOSÉE pour la boîte et la précision GPS partent vers le serveur.
struct LocationUpdateSheet: View {
    let box: BookBox
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var locationService = LocationService.shared

    private enum Kind: String { case confirm, move }
    private enum Phase: Equatable { case editing, sending, sent, failed(String) }

    private struct ProposedPlace {
        var address: String?
        var city: String?
        var postalCode: String?
        var department: String?
    }

    @State private var kind: Kind? = nil
    @State private var camera: MapCameraPosition = .automatic
    @State private var pinCenter: CLLocationCoordinate2D? = nil
    @State private var place = ProposedPlace()
    @State private var phase: Phase = .editing

    private let green = Color(red: 0.102, green: 0.718, blue: 0.608)

    private var gps: CLLocation? { locationService.currentLocation }
    private var accuracy: Double { gps?.horizontalAccuracy ?? -1 }
    private var gpsOK: Bool { gps != nil && LocationRules.canSend(accuracy: accuracy) }
    private var boxLocation: CLLocation { CLLocation(latitude: box.lat, longitude: box.lng) }

    // Distance téléphone -> boîte : calculée sur le téléphone uniquement
    private var nearEnough: Bool {
        guard let gps else { return false }
        return gps.distance(from: boxLocation) <= LocationRules.proximityMeters
    }

    // Distance repère -> boîte, pour le déplacement
    private var pinDistance: Double? {
        guard let pinCenter else { return nil }
        return CLLocation(latitude: pinCenter.latitude, longitude: pinCenter.longitude).distance(from: boxLocation)
    }

    private var canSubmit: Bool {
        guard phase == .editing, let kind, gpsOK, nearEnough else { return false }
        if kind == .move {
            guard let d = pinDistance, d <= LocationRules.moveMaxMeters else { return false }
        }
        return true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if phase == .sent {
                        sentView
                    } else {
                        editingView
                    }
                }
                .padding(20)
            }
            .navigationTitle("Localisation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .onAppear {
            locationService.requestAuthorization()
            locationService.startUpdatingIfAuthorized()
            locationService.beginPrecisionUpdates()
        }
        .onDisappear { locationService.endPrecisionUpdates() }
    }

    // MARK: - Écrans

    @ViewBuilder
    private var editingView: some View {
        Text("La boîte est-elle bien ici ?")
            .font(.system(size: 20, weight: .bold))

        HStack(spacing: 12) {
            choiceButton(title: "Oui, elle est bien là", icon: "checkmark.circle.fill", selected: kind == .confirm) {
                select(.confirm)
            }
            choiceButton(title: "Non, elle est ailleurs", icon: "mappin.slash", selected: kind == .move) {
                select(.move)
            }
        }

        if gps == nil {
            notice("Position introuvable. Active la localisation pour proposer une position.", color: .orange)
        } else if !nearEnough {
            notice("Approche-toi à moins de 50 m de la boîte pour proposer une localisation.", color: .orange)
        }

        precisionRow

        if kind == .move {
            moveSection
        }
        if kind == .confirm {
            note("Ta position GPS est envoyée comme position proposée pour la boîte, et rien d'autre.")
        }
        if !box.has_photo {
            note("Pas encore de photo ? Tu peux en ajouter une depuis la fiche de la boîte.")
        }
        if case .failed(let message) = phase {
            notice(message, color: .red)
        }
        submitButton
    }

    private var sentView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(green)
            Text("Merci !")
                .font(.system(size: 22, weight: .bold))
            Text("Ta proposition sera vérifiée par un administrateur.")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            Button("Fermer") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(green)
        }
    }

    // Indicateur 5 barres et précision ; envoi seulement à 10 m ou mieux
    private var precisionRow: some View {
        let bars = gps == nil ? 0 : LocationRules.precisionBars(accuracy: accuracy)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .bottom, spacing: 10) {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(1...5, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(level <= bars ? green : Color(.systemGray4))
                            .frame(width: 6, height: CGFloat(4 + level * 3))
                    }
                }
                Text(precisionText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(gpsOK ? Color(.label) : .orange)
            }
            if gps != nil && !gpsOK {
                Text("Patiente, le GPS affine ta position…")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var precisionText: String {
        guard gps != nil else { return "Précision : inconnue" }
        guard accuracy >= 0 else { return "Précision : inconnue" }
        return String(format: "Précision : ± %.0f m", accuracy)
    }

    private var moveSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Place la carte pour que le repère soit sur la boîte. Ton adresse n'est pas demandée : elle est proposée à partir du repère.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            ZStack {
                Map(position: $camera) {
                    Marker(box.address ?? "Boîte", coordinate: box.coordinate)
                        .tint(.gray)
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    let center = context.region.center
                    pinCenter = center
                    Task { place = await reverseGeocode(center) }
                }
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(green)
                    .shadow(radius: 3)
                    .offset(y: -18)
                    .allowsHitTesting(false)
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            if let address = place.address {
                Text([address, place.postalCode, place.city].compactMap { $0 }.joined(separator: ", "))
                    .font(.system(size: 14))
            }
            if let d = pinDistance, d > LocationRules.moveMaxMeters {
                notice("Le déplacement dépasse 500 m : rapproche le repère de la boîte.", color: .red)
            }
            Button("Centrer sur ma position") { centerOnGPS() }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(green)
        }
    }

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            Group {
                if phase == .sending {
                    ProgressView().tint(.white)
                } else {
                    Text("Envoyer ma proposition")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(canSubmit ? green : Color(.systemGray4))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!canSubmit)
    }

    // MARK: - Actions

    private func select(_ newKind: Kind) {
        lightHaptic()
        kind = newKind
        if newKind == .move { centerOnGPS() }
    }

    private func centerOnGPS() {
        let target = gps?.coordinate ?? box.coordinate
        camera = .region(MKCoordinateRegion(center: target, latitudinalMeters: 80, longitudinalMeters: 80))
        pinCenter = target
        Task { place = await reverseGeocode(target) }
    }

    // Adresse proposée par géocodage inverse, sur le téléphone seulement
    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> ProposedPlace {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let mark = try? await CLGeocoder().reverseGeocodeLocation(location).first else {
            return ProposedPlace()
        }
        let street = [mark.subThoroughfare, mark.thoroughfare].compactMap { $0 }.joined(separator: " ")
        return ProposedPlace(
            address: street.isEmpty ? nil : street,
            city: mark.locality,
            postalCode: mark.postalCode,
            department: mark.postalCode.map { String($0.prefix(2)) }
        )
    }

    private func submit() async {
        guard canSubmit, let kind, let gps else { return }
        guard let token = NotificationService.shared.getPushToken(), !token.isEmpty else {
            phase = .failed("Autorise les notifications : la proposition est liée à cet appareil.")
            return
        }
        phase = .sending
        do {
            switch kind {
            case .confirm:
                try await SupabaseService.shared.insertLocationUpdate(
                    boxId: box.id, kind: kind.rawValue,
                    lat: gps.coordinate.latitude, lng: gps.coordinate.longitude,
                    address: nil, city: nil, postalCode: nil, department: nil,
                    source: "gps", accuracyM: accuracy, deviceToken: token
                )
            case .move:
                let pin = pinCenter ?? gps.coordinate
                let fromGPS = CLLocation(latitude: pin.latitude, longitude: pin.longitude).distance(from: gps) < 1
                try await SupabaseService.shared.insertLocationUpdate(
                    boxId: box.id, kind: kind.rawValue,
                    lat: pin.latitude, lng: pin.longitude,
                    address: place.address, city: place.city, postalCode: place.postalCode, department: place.department,
                    source: fromGPS ? "gps" : "manual", accuracyM: accuracy, deviceToken: token
                )
            }
            // Anti-répétition 30 jours après un envoi réussi
            LocationPromptLog.mark(boxId: box.id)
            phase = .sent
        } catch {
            phase = .failed(Self.message(for: error))
        }
    }

    // Messages clairs pour les refus serveur ; jamais de détail technique affiché
    static func message(for error: Error) -> String {
        if let e = error as? SupabaseError, case .httpError(let code, let body) = e {
            if body.contains("23505") || body.contains("duplicate") {
                return "Tu as déjà une proposition en attente pour cette boîte."
            }
            if body.contains("maximum") {
                return "Proposition refusée : elle est trop loin de la boîte."
            }
            if code == 404 {
                return "Le service de localisation n'est pas encore disponible."
            }
        }
        return "Envoi impossible pour le moment. Réessaie dans un instant."
    }

    // MARK: - Éléments visuels

    private func choiceButton(title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 22))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(selected ? .white : green)
            .background(selected ? green : green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func notice(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
    }
}
