import Foundation
import PhotosUI
import SwiftUI
import UIKit

enum PhotoError: LocalizedError {
    case compressionFailed, noImage

    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Impossible de compresser l'image"
        case .noImage: return "Aucune image sélectionnée"
        }
    }
}

struct CameraPickerView: UIViewControllerRepresentable {
    let onImagePicked: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.onImagePicked(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImagePicked(nil)
        }
    }
}

struct LibraryPickerView: UIViewControllerRepresentable {
    let onImagePicked: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: LibraryPickerView
        init(_ parent: LibraryPickerView) { self.parent = parent }

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

final class PhotoService {
    static let shared = PhotoService()
    private let submissionsKey = "pendingPhotoSubmissions"

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

    func loadSubmissions() async -> [PhotoSubmission] {
        do {
            return try await SupabaseService.shared.fetchPhotoSubmissions()
        } catch {
            return []
        }
    }
}
