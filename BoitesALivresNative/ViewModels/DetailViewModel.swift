import Foundation
import Observation
import UIKit

@MainActor @Observable
final class DetailViewModel {
    var box: BookBox? = nil
    var photos: [BoxPhoto] = []
    var nearbyBoxes: [BookBox] = []
    var loading = false
    var uploading = false
    var showPhotoModal = false
    var alertTitle = ""
    var alertMessage = ""
    var showAlert = false
    var localPhotoImage: UIImage? = nil  // image locale en attente d'upload

    private let supabase = SupabaseService.shared

    func load(boxId: Int) async {
        loading = true
        defer { loading = false }
        guard let data = try? await supabase.fetchById(boxId) else { return }
        box = data
        async let photosTask = (try? await supabase.listPhotos(for: boxId, fallbackUrl: data.photo_url)) ?? []
        async let nearbyTask = (try? await supabase.fetchNearbyTo(id: boxId, lat: data.lat, lng: data.lng)) ?? []
        photos = await photosTask
        nearbyBoxes = await nearbyTask
    }

    func refresh(boxId: Int) async {
        guard let fresh = try? await supabase.fetchById(boxId) else { return }
        box = fresh
        if let ph = try? await supabase.listPhotos(for: boxId, fallbackUrl: fresh.photo_url), !ph.isEmpty {
            photos = ph
        }
    }

    func handlePhoto(source: PhotoSource, boxId: Int) async {
        showPhotoModal = false
        guard photos.count < Constants.maxPhotosPerBox else {
            alertTitle = "Limite atteinte"
            alertMessage = "Maximum \(Constants.maxPhotosPerBox) photos par boîte."
            showAlert = true
            return
        }
        uploading = true
        defer { uploading = false; localPhotoImage = nil }
        do {
            let image: UIImage?
            switch source {
            case .camera:
                image = nil // handled via CameraPickerView in the View
            case .library:
                image = nil // handled via LibraryPickerView in the View
            }
            _ = image
        }
    }

    func submitPhoto(_ image: UIImage, boxId: Int) async {
        uploading = true
        localPhotoImage = image
        defer { uploading = false; localPhotoImage = nil }
        do {
            _ = try await PhotoService.shared.submitPhoto(image, for: boxId)
            alertTitle = "Photo envoyée"
            alertMessage = "Merci ! La photo est en attente de validation avant publication."
            showAlert = true
            // Refresh photos after short delay
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if let ph = try? await supabase.listPhotos(for: boxId) {
                photos = ph
            }
        } catch {
            alertTitle = "Erreur"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    enum PhotoSource { case camera, library }
}
