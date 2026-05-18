import SwiftUI
import PhotosUI
import UIKit

// MARK: - Photo library picker (SwiftUI)

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let onPicked: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker
        init(_ parent: PhotoLibraryPicker) { self.parent = parent }

        // Dismissal is driven by the SwiftUI binding the caller flips inside
        // onPicked / onCancel — never call picker.dismiss(animated:) here, or
        // the binding desyncs and the parent presentation can glitch.
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let item = results.first?.itemProvider, item.canLoadObject(ofClass: UIImage.self) else {
                DispatchQueue.main.async { [weak self] in self?.parent.onCancel() }
                return
            }
            item.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                DispatchQueue.main.async {
                    if let ui = image as? UIImage {
                        self?.parent.onPicked(ui)
                    } else {
                        self?.parent.onCancel()
                    }
                }
            }
        }
    }
}

// MARK: - Camera picker

struct CameraPicker: UIViewControllerRepresentable {
    let onPicked: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        // Dismissal is driven by the SwiftUI binding inside onPicked / onCancel.
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let ui = info[.originalImage] as? UIImage {
                parent.onPicked(ui)
            } else {
                parent.onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}

// MARK: - Unified source sheet

enum PhotoSource: Identifiable {
    case library, camera
    var id: Int { self == .library ? 0 : 1 }
}

extension UIImage {
    /// Resize to max `maxDim` on the longest edge, then encode JPEG.
    func resizedJPEG(maxDim: CGFloat = 1024, quality: CGFloat = 0.85) -> Data? {
        let longEdge = max(size.width, size.height)
        guard longEdge > 0 else { return nil }
        let scale = min(1.0, maxDim / longEdge)
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let shrunk = renderer.image { _ in draw(in: CGRect(origin: .zero, size: targetSize)) }
        return shrunk.jpegData(compressionQuality: quality)
    }

    /// Base64 data URL suitable for posting to the analyze/tryon edge functions.
    func base64DataURL(maxDim: CGFloat = 1024, quality: CGFloat = 0.85) -> String? {
        guard let data = resizedJPEG(maxDim: maxDim, quality: quality) else { return nil }
        return "data:image/jpeg;base64,\(data.base64EncodedString())"
    }
}
