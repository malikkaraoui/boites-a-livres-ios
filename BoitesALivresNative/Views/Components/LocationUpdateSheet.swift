import CoreLocation
import MapKit
import SwiftUI

// MARK: - Proposition de localisation (F01 M0020)

// Parcours « La boîte est-elle bien ici ? » : un seul écran, la carte centrée sur la boîte.
// Repère laissé sur la boîte = confirmation ; repère déplacé = nouvelle position (100 m au plus).
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

    @State private var camera: MapCameraPosition = .automatic
    @State private var pinCenter: CLLocationCoordinate2D? = nil
    @State private var place = ProposedPlace()
    @State private var phase: Phase = .editing
    @State private var feedback = MissingFeedback<SubmitRequirements.Location>()

    private let green = Color(red: 0.102, green: 0.718, blue: 0.608)

    // Photo ajoutée depuis l'écran « Merci ! » : la fiche ouvre le circuit photo existant
    var onAddPhoto: (() -> Void)? = nil

    private var gps: CLLocation? { locationService.currentLocation }
    private var accuracy: Double { gps?.horizontalAccuracy ?? -1 }
    // Décision unique (F01 M0042) : confirmer, déplacer, ou bloquer avec sa raison
    private var action: LocationRules.Action {
        LocationRules.locationAction(
            pinDistance: pinDistance ?? 0,
            accuracy: accuracy,
            userDistance: gps.map { $0.distance(from: boxLocation) }
        )
    }
    private var kind: Kind {
        if case .move = action { return .move }
        return .confirm
    }
    private var isConfirm: Bool { action == .confirm }
    // Précision jusqu'à 50 m, pour la confirmation comme pour le déplacement (F01 M0042)
    private var accuracyOK: Bool { LocationRules.canSendManual(accuracy: accuracy) }
    private var gpsOK: Bool { gps != nil && accuracyOK }
    private var boxLocation: CLLocation { CLLocation(latitude: box.lat, longitude: box.lng) }

    // Distance téléphone -> boîte : calculée sur le téléphone uniquement (présence, 50 m)
    private var nearEnough: Bool {
        guard let gps else { return false }
        return gps.distance(from: boxLocation) <= LocationRules.presenceMeters
    }

    // Distance repère -> boîte, pour le déplacement
    private var pinDistance: Double? {
        guard let pinCenter else { return nil }
        return CLLocation(latitude: pinCenter.latitude, longitude: pinCenter.longitude).distance(from: boxLocation)
    }

    // Source unique des manques (F01 M0045) : le blocage de la décision, rien d'autre
    private var missingRequirements: [SubmitRequirements.Location] {
        SubmitRequirements.location(action: action)
    }

    private var canSubmit: Bool { phase == .editing && missingRequirements.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if phase == .sent {
                            sentView
                        } else {
                            editingView(proxy)
                        }
                    }
                    .padding(20)
                }
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
            centerOnBox()
        }
        .onDisappear { locationService.endPrecisionUpdates() }
    }

    // MARK: - Écrans

    @ViewBuilder
    private func editingView(_ proxy: ScrollViewProxy) -> some View {
        Text("La boîte est-elle bien ici ?")
            .font(.system(size: 20, weight: .bold))

        // Chaque blocage garde son message : le toucher du bouton grisé le fait clignoter (F01 M0045)
        VStack(alignment: .leading, spacing: 0) {
            if gps == nil {
                notice("Position introuvable. Active la localisation pour proposer une position.", color: .orange)
            } else if !nearEnough {
                notice("Approche-toi à moins de 50 m de la boîte pour proposer une localisation.", color: .orange)
            }
        }
        .id("distance")
        .missingHighlight(tick: feedback.tick(for: .distance), cornerRadius: 8)

        precisionRow
            .id("precision")

        VStack(alignment: .leading, spacing: 0) {
            if gps != nil && !accuracyOK {
                notice("Précision insuffisante (plus de 50 m) : attends un meilleur signal GPS, puis réessaie.", color: .orange)
            }
        }
        .id("precision-notice")
        .missingHighlight(tick: feedback.tick(for: .precision), cornerRadius: 8)

        mapSection

        if kind == .confirm {
            note("Ta position GPS est envoyée comme position proposée pour la boîte, et rien d'autre.")
        }
        if !box.has_photo {
            note("Pas encore de photo ? Tu peux en ajouter une depuis la fiche de la boîte.")
        }
        if case .failed(let message) = phase {
            notice(LocalizedStringKey(message), color: .red)
        }
        submitButton(proxy)
    }

    // Écran « Merci ! » centré (F01 M0023, retour terrain 5) ; photo proposée après l'envoi (point 4)
    // Action secondaire (photo) gardée au-dessus du bouton « Fermer » (F01 M0046)
    private var sentView: some View {
        SubmissionSuccessView(
            icon: "checkmark.seal.fill",
            title: "Merci !",
            message: "Ta proposition sera vérifiée par un administrateur.",
            primaryAction: { dismiss() }
        ) {
            if let onAddPhoto {
                if box.has_photo {
                    Button("Ajouter une photo") { onAddPhoto() }
                        .buttonStyle(.bordered)
                        .tint(green)
                } else {
                    Button {
                        onAddPhoto()
                    } label: {
                        Label("Ajouter une photo de la boîte", systemImage: "camera.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    // Indicateur 5 barres et précision ; envoi possible jusqu'à 50 m (source gps seulement à 10 m ou mieux)
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
            if gps != nil && !accuracyOK {
                Text("Patiente, le GPS affine ta position…")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var precisionText: String {
        guard gps != nil else { return String(localized: "Précision : inconnue") }
        guard accuracy >= 0 else { return String(localized: "Précision : inconnue") }
        return String(format: String(localized: "Précision : ± %.0f m"), accuracy)
    }

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Laisse le repère sur la boîte et envoie. Si elle est ailleurs, déplace la carte.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            ZStack {
                Map(position: $camera) {
                    UserAnnotation()
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
            VStack(alignment: .leading, spacing: 0) {
                if let d = pinDistance, d > LocationRules.moveMaxMeters {
                    notice("Tu ne peux pas déplacer la boîte de plus de 100 m.", color: .red)
                }
            }
            .id("moveTooFar")
            .missingHighlight(tick: feedback.tick(for: .moveTooFar), cornerRadius: 8)
            // Repère bougé mais sous le seuil : la boîte ne bouge pas (F01 M0042)
            if isConfirm, let d = pinDistance, d >= 1 {
                let threshold = LocationRules.moveMinMeters(accuracy: accuracy)
                note("Écart de \(Int(d.rounded())) m : dans la marge du GPS (moins de \(Int(threshold.rounded())) m), la boîte reste à sa place.")
            }
            Button("Centrer sur ma position") { centerOnGPS() }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(green)
        }
    }

    // Grisé mais touchable : toucher avec un blocage défile, fait clignoter le message et n'envoie rien (F01 M0045)
    private func submitButton(_ proxy: ScrollViewProxy) -> some View {
        Button {
            Task { await submitTapped(proxy) }
        } label: {
            Group {
                if phase == .sending {
                    ProgressView().tint(.white)
                } else {
                    Text(kind == .move ? "Envoyer le nouvel emplacement" : "Oui, elle est bien ici")
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
    }

    // MARK: - Actions

    private func submitTapped(_ proxy: ScrollViewProxy) async {
        guard phase != .sending else { return }
        guard let first = missingRequirements.first else {
            // Clavier fermé avant l'envoi : la page de remerciement s'affiche sans lui (F01 M0047)
            dismissKeyboard()
            await submit()
            return
        }
        // Aucun champ texte ici, mais un clavier ouvert ailleurs ne doit pas cacher le blocage (F01 M0047)
        dismissKeyboard()
        errorHaptic()
        withAnimation { proxy.scrollTo(first.anchor, anchor: .center) }
        feedback.flash(first, message: nil)
    }

    // Départ : zoom sur la boîte, repère posé sur sa position actuelle (donc « non déplacé »)
    private func centerOnBox() {
        camera = .region(MKCoordinateRegion(center: box.coordinate, latitudinalMeters: 80, longitudinalMeters: 80))
        pinCenter = box.coordinate
        Task { place = await reverseGeocode(box.coordinate) }
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
        guard canSubmit, let gps else { return }
        guard let token = NotificationService.shared.getPushToken(), !token.isEmpty else {
            phase = .failed("Autorise les notifications : la proposition est liée à cet appareil.")
            return
        }
        phase = .sending
        do {
            switch kind {
            case .confirm:
                // Contrainte serveur location_updates_accuracy_ck : « gps » seulement si précision ≤ 10 m
                try await SupabaseService.shared.insertLocationUpdate(
                    boxId: box.id, kind: kind.rawValue,
                    lat: gps.coordinate.latitude, lng: gps.coordinate.longitude,
                    address: nil, city: nil, postalCode: nil, department: nil,
                    source: LocationRules.source(accuracy: accuracy, pinIsGPS: true), accuracyM: accuracy, deviceToken: token
                )
            case .move:
                let pin = pinCenter ?? gps.coordinate
                let pinIsGPS = CLLocation(latitude: pin.latitude, longitude: pin.longitude).distance(from: gps) < 1
                try await SupabaseService.shared.insertLocationUpdate(
                    boxId: box.id, kind: kind.rawValue,
                    lat: pin.latitude, lng: pin.longitude,
                    address: place.address, city: place.city, postalCode: place.postalCode, department: place.department,
                    source: LocationRules.source(accuracy: accuracy, pinIsGPS: pinIsGPS), accuracyM: accuracy, deviceToken: token
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

    private func notice(_ text: LocalizedStringKey, color: Color) -> some View {
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
