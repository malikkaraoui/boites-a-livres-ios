import CoreLocation
import MapKit
import Observation
import SwiftUI
import UIKit

// MARK: - Add Box View Model

@MainActor @Observable
final class AddBoxViewModel {
    enum Step { case map, form }

    var step: Step = .map
    var cameraPosition: MapCameraPosition
    var pinCoordinate: CLLocationCoordinate2D

    // Form fields (pre-filled by reverse geocoding)
    var address: String = ""
    var city: String = ""
    var postalCode: String = ""
    var department: String = ""
    var notes: String = ""

    // Photo
    var selectedImage: UIImage? = nil

    // UI state
    var isGeocoding = false
    var isSubmitting = false
    var submitted = false
    var errorMessage: String? = nil

    // Vrai dès que l'utilisateur a déplacé la carte à la main : le premier fix ne la recentre plus (F01 M0041)
    private var userMovedMap = false
    // Ouverture de l'étape position : seul un fix postérieur compte (F01 M0040, R032)
    private var positionStepOpenedAt = Date()
    // Vrai tant que le premier fix frais de cette ouverture n'est pas reçu (F01 M0040)
    private var waitingFreshFix = true

    private let supabase = SupabaseService.shared

    init() {
        if let gps = LocationService.shared.currentLocation {
            pinCoordinate = gps.coordinate
            cameraPosition = .camera(MapCamera(centerCoordinate: gps.coordinate, distance: 300))
        } else {
            pinCoordinate = Constants.defaultLocation
            cameraPosition = .camera(MapCamera(centerCoordinate: Constants.defaultLocation, distance: 500))
        }
    }

    // Premier fix frais sur l'étape position : caméra centrée dessus, tant que l'utilisateur n'a pas bougé la carte.
    // Le repère suit le centre de la carte (followCamera), donc il suit ce recentrage.
    // Le cache et son rejeu à l'abonnement sont ignorés : leur horodatage précède l'ouverture (F01 M0040, R032)
    func applyFirstFix(_ gps: CLLocation) {
        let fresh = LocationRules.isFresh(timestamp: gps.timestamp, openedAt: positionStepOpenedAt,
                                          accuracy: gps.horizontalAccuracy)
        guard LocationRules.shouldCenterOnFirstFix(isWaiting: waitingFreshFix, onMapStep: step == .map,
                                                   isFresh: fresh, userMovedMap: userMovedMap) else { return }
        waitingFreshFix = false
        cameraPosition = .camera(MapCamera(centerCoordinate: gps.coordinate, distance: 300))
    }

    // La carte a été glissée ou pincée à la main (F01 M0041)
    func markMovedByUser() {
        userMovedMap = true
    }

    // Épingle fixe : le repère est le centre de la carte, à chaque fin de déplacement (F01 M0041)
    func followCamera(center: CLLocationCoordinate2D) {
        pinCoordinate = center
    }

    // « Replacer » rouvre l'étape position sur le point déjà posé : pas d'attente de fix, pas de recentrage GPS (F01 M0041)
    func returnToMap() {
        step = .map
        waitingFreshFix = false
        cameraPosition = .camera(MapCamera(centerCoordinate: pinCoordinate, distance: 300))
    }

    func confirmPosition() async {
        isGeocoding = true
        defer { isGeocoding = false }

        let location = CLLocation(latitude: pinCoordinate.latitude, longitude: pinCoordinate.longitude)
        let geocoder = CLGeocoder()

        typealias GeoResult = (address: String, city: String, postalCode: String, department: String)?
        let result: GeoResult = await withCheckedContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, _ in
                guard let p = placemarks?.first else {
                    continuation.resume(returning: nil)
                    return
                }
                let number = p.subThoroughfare ?? ""
                let street = p.thoroughfare ?? ""
                let addr = [number, street].filter { !$0.isEmpty }.joined(separator: " ")
                continuation.resume(returning: (
                    address: addr,
                    city: p.locality ?? p.subAdministrativeArea ?? "",
                    postalCode: p.postalCode ?? "",
                    department: p.administrativeArea ?? ""
                ))
            }
        }
        if let r = result {
            address = r.address
            city = r.city
            postalCode = r.postalCode
            department = r.department
        }
        step = .form
    }

    // Distance GPS -> point proposé, seulement si le GPS est précis (50 m ou mieux). Calculée sur le téléphone.
    private var presenceDistance: Double? {
        guard let gps = LocationService.shared.currentLocation,
              LocationRules.canSendManual(accuracy: gps.horizontalAccuracy) else { return nil }
        return gps.distance(from: CLLocation(latitude: pinCoordinate.latitude, longitude: pinCoordinate.longitude))
    }

    // Source unique des manques, dans l'ordre de l'écran (F01 M0045) : photo obligatoire, puis présence
    var missingRequirements: [SubmitRequirements.AddBox] {
        SubmitRequirements.addBox(hasPhoto: selectedImage != nil,
                                  distance: presenceDistance,
                                  maxDistance: LocationRules.presenceMeters)
    }

    // Photo obligatoire (prise sur place) + présence : sinon le bouton reste grisé
    var canSubmit: Bool { missingRequirements.isEmpty }

    var submitHint: String? { missingRequirements.first?.submitHint }

    func submit(deviceToken: String?) async {
        guard canSubmit else {
            errorMessage = submitHint
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        errorMessage = nil
        let cleanNotes = NoteText.forSend(notes)

        do {
            // Upload photo first if selected
            var photoUrl: String? = nil
            if let image = selectedImage,
               let compressed = resizeAndCompress(image) {
                photoUrl = try await supabase.uploadBoxSubmissionPhoto(compressed)
            }

            try await supabase.insertBoxSubmission(
                lat: pinCoordinate.latitude,
                lng: pinCoordinate.longitude,
                address: address.isEmpty ? nil : address,
                city: city.isEmpty ? nil : city,
                postalCode: postalCode.isEmpty ? nil : postalCode,
                department: department.isEmpty ? nil : department,
                notes: cleanNotes.isEmpty ? nil : cleanNotes,
                photoUrl: photoUrl,
                deviceToken: deviceToken
            )
            submitted = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resizeAndCompress(_ image: UIImage) -> Data? {
        let maxDim: CGFloat = 1200
        let size = image.size
        let scale = size.width > maxDim || size.height > maxDim
            ? min(maxDim / size.width, maxDim / size.height) : 1
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized?.jpegData(compressionQuality: 0.8)
    }
}
