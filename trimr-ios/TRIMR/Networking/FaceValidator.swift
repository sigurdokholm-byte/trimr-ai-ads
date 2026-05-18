import UIKit
import Vision

enum FaceValidator {
    /// Returns true if the Vision face detector finds at least one face in `image`.
    /// Tries every CGImagePropertyOrientation since EXIF-stripped photos from the
    /// camera roll often confuse Vision. If we can't find a face after all rotations,
    /// we still return `true` — the backend does its own face validation, and a
    /// false-negative here just blocks legitimate photos.
    static func hasFace(in image: UIImage) async -> Bool {
        guard let cgImage = image.cgImage else { return true }
        let orientations: [CGImagePropertyOrientation] = [
            cgOrientation(from: image.imageOrientation),
            .up, .right, .down, .left,
        ]
        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                for orientation in orientations {
                    let request = VNDetectFaceRectanglesRequest()
                    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
                    if (try? handler.perform([request])) != nil,
                       (request.results?.count ?? 0) >= 1 {
                        continuation.resume(returning: true)
                        return
                    }
                }
                continuation.resume(returning: true)
            }
        }
    }

    private static func cgOrientation(from o: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch o {
        case .up:            return .up
        case .down:          return .down
        case .left:          return .left
        case .right:         return .right
        case .upMirrored:    return .upMirrored
        case .downMirrored:  return .downMirrored
        case .leftMirrored:  return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default:    return .up
        }
    }
}
