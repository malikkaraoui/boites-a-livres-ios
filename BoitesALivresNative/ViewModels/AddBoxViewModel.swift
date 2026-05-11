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

    private let supabase = SupabaseService.shared

    init() {
        let startCoord = LocationService.shared.currentLocation?.coordinate ?? Constants.defaultLocation
        pinCoordinate = startCoord
        cameraPosition = .camera(MapCamera(centerCoordinate: startCoord, distance: 500))
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

    func submit(deviceToken: String?) async {
        isSubmitting = true
        defer { isSubmitting = false }
        errorMessage = nil

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
                notes: notes.isEmpty ? nil : notes,
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
