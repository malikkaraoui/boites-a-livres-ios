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

    // Vrai dès que l'utilisateur a touché la carte : le GPS ne déplace plus le repère (F01 M0039)
    private var userPlacedPin = false
    // Première position GPS déjà appliquée à la caméra et au repère (F01 M0039)
    private var autoCentered = false

    private let supabase = SupabaseService.shared

    init() {
        if let gps = LocationService.shared.currentLocation {
            pinCoordinate = gps.coordinate
            cameraPosition = .camera(MapCamera(centerCoordinate: gps.coordinate, distance: 300))
            autoCentered = true
        } else {
            pinCoordinate = Constants.defaultLocation
            cameraPosition = .camera(MapCamera(centerCoordinate: Constants.defaultLocation, distance: 500))
        }
    }

    // Premier fix GPS sur l'étape position : caméra ET repère dessus, tant que l'utilisateur n'a pas touché la carte (F01 M0039)
    func applyFirstFix(_ gps: CLLocation) {
        guard step == .map, !autoCentered, !userPlacedPin else { return }
        autoCentered = true
        pinCoordinate = gps.coordinate
        cameraPosition = .camera(MapCamera(centerCoordinate: gps.coordinate, distance: 300))
    }

    // Ouverture de l'étape position et « Replacer » : caméra centrée sur le GPS, repère inchangé (F01 M0039)
    func centerCameraOnGPS() {
        guard let gps = LocationService.shared.currentLocation else { return }
        cameraPosition = .camera(MapCamera(centerCoordinate: gps.coordinate, distance: 300))
    }

    // Toucher la carte : le repère va au point touché (F01 M0039)
    func placePin(at coordinate: CLLocationCoordinate2D) {
        userPlacedPin = true
        pinCoordinate = coordinate
    }

    func returnToMap() {
        step = .map
        centerCameraOnGPS()
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

    // Présence sur place : GPS à 10 m ou mieux et point à 50 m au plus (F01 M0023, #31)
    var presenceOK: Bool { (presenceDistance ?? .infinity) <= LocationRules.presenceMeters }

    // Photo obligatoire (prise sur place) + présence : sinon le bouton reste grisé
    var canSubmit: Bool { selectedImage != nil && presenceOK }

    var submitHint: String? {
        if selectedImage == nil { return "Ajoute une photo de la boîte" }
        if presenceDistance == nil { return "Patiente, le GPS affine ta position (50 m ou mieux)…" }
        if !presenceOK { return "Tu dois être à moins de 50 m du point proposé." }
        return nil
    }

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
