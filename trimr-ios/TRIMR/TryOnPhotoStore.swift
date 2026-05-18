import Foundation
import UIKit

/// Shared in-memory photo for hair-color, hairstyle try-on, and analysis flows.
/// Mirrors the web `TryOnPhotoContext` so picking a second item after a generation
/// pre-fills the photo (and the user's last pan position) instead of re-uploading.
@MainActor
final class TryOnPhotoStore: ObservableObject {
    @Published var photo: UIImage? {
        didSet { pan = .zero }
    }
    @Published var pan: CGSize = .zero

    func clear() {
        photo = nil
        // pan is reset by photo's didSet
    }
}
