import Foundation
import PhotosUI
import SwiftUI
import UIKit

// MARK: - Error Handling

enum PhotoError: LocalizedError {
    case compressionFailed, noImage

    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Impossible de compresser l'image"
        case .noImage: return "Aucune image sélectionnée"
        }
    }
}

// MARK: - Camera Picker

struct CameraPickerView: UIViewControllerRepresentable {
    let onImagePicked: (UIImage?) -> Void

    /// Create coordinator for camera picker delegate callbacks
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    /// Initialize camera picker controller
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Self.frenchifyCancel(in: uiViewController.view)
        }
    }

    private static func frenchifyCancel(in view: UIView) {
        for sub in view.subviews {
            if let btn = sub as? UIButton, btn.title(for: .normal) == "Cancel" {
                btn.setTitle("Annuler", for: .normal)
                btn.setTitle("Annuler", for: .highlighted)
                btn.titleLabel?.adjustsFontSizeToFitWidth = false
                btn.titleLabel?.lineBreakMode = .byClipping
                btn.sizeToFit()
                btn.frame = CGRect(
                    x: btn.frame.minX,
                    y: btn.frame.minY,
                    width: max(btn.frame.width, 80),
                    height: btn.frame.height
                )
            } else if let label = sub as? UILabel, label.text == "Cancel" {
                label.text = "Annuler"
                label.adjustsFontSizeToFitWidth = false
                label.lineBreakMode = .byClipping
                label.sizeToFit()
            }
            frenchifyCancel(in: sub)
        }
    }

    /// Delegate to handle camera picker callbacks
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        /// Handle successful image capture and dismiss picker
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.onImagePicked(info[.originalImage] as? UIImage)
        }

        /// Handle user cancellation of photo capture
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImagePicked(nil)
        }
    }
}

// MARK: - Photo Library Picker

struct LibraryPickerView: UIViewControllerRepresentable {
    let onImagePicked: (UIImage?) -> Void

    /// Create coordinator for photo picker delegate callbacks
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    /// Initialize photo picker with single-image mode
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    /// Delegate to handle photo picker callbacks
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: LibraryPickerView
        init(_ parent: LibraryPickerView) { self.parent = parent }

        /// Load selected image and call parent callback on main thread
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                parent.onImagePicked(nil)
                return
            }
            provider.loadObject(ofClass: UIImage.self) { obj, _ in
                DispatchQueue.main.async { self.parent.onImagePicked(obj as? UIImage) }
            }
        }
    }
}

// MARK: - Photo Service

final class PhotoService {
    static let shared = PhotoService()
    private let submissionsKey = "pendingPhotoSubmissions"

    /// Resize and compress image, upload to storage, record submission with device token
    func submitPhoto(_ image: UIImage, for boxId: Int) async throws -> String {
        guard let resized = resizeImage(image, maxDimension: 1200),
              let data = resized.jpegData(compressionQuality: 0.8) else {
            throw PhotoError.compressionFailed
        }
        let filename = "\(UUID().uuidString).jpg"
        let remoteUrl = try await SupabaseService.shared.uploadPhoto(data, for: boxId, filename: filename)

        let deviceToken = NotificationService.shared.getPushToken()
        try await SupabaseService.shared.insertPhotoSubmission(boxId: boxId, url: remoteUrl, deviceToken: deviceToken)

        return remoteUrl
    }

    /// Resize image to max dimension while preserving aspect ratio
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    // Load all photo submissions from Supabase for current user; returns empty array on failure
    func loadSubmissions() async -> [PhotoSubmission] {
        do {
            return try await SupabaseService.shared.fetchPhotoSubmissions()
        } catch {
            return []
        }
    }
}
