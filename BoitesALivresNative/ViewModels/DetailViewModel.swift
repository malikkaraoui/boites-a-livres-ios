import Foundation
import Observation
import UIKit

// MARK: - Detail View Model

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
    var photoSubmitted = false
    var localPhotoImage: UIImage? = nil

    // MARK: - Photo Source

    enum PhotoSource { case camera, library }

    private let supabase = SupabaseService.shared

    // Fetch box details, photos list, and nearby boxes in parallel; suppress errors
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

    // Refresh box details and photos list; keep existing data on failure
    func refresh(boxId: Int) async {
        guard let fresh = try? await supabase.fetchById(boxId) else { return }
        box = fresh
        if let ph = try? await supabase.listPhotos(for: boxId, fallbackUrl: fresh.photo_url), !ph.isEmpty {
            photos = ph
        }
    }

    // Validate photo limit before handling; implementation delegated to View pickers
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

    // Upload image to Supabase storage and record submission; refresh photo list after 1s
    func submitPhoto(_ image: UIImage, boxId: Int) async {
        guard !uploading else { return }
        uploading = true
        localPhotoImage = image
        defer { uploading = false; localPhotoImage = nil }
        do {
            _ = try await PhotoService.shared.submitPhoto(image, for: boxId)
            photoSubmitted = true
            // Refresh photos after short delay
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if let ph = try? await supabase.listPhotos(for: boxId, fallbackUrl: box?.photo_url) {
                photos = ph
            }
        } catch {
            alertTitle = "Erreur"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
