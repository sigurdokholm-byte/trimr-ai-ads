import Foundation
import Photos
import SwiftUI
import UIKit

/// Saves AI-generated try-on images to the user's Photo Library using
/// write-only (`.addOnly`) authorization, so the app never asks for read
/// access. Reuses `LibraryImageCache.memory` so an image already on screen
/// doesn't need to be re-downloaded.
enum PhotoSaver {
    enum SaveError: LocalizedError {
        case permissionDenied
        case downloadFailed(String)
        case decodeFailed
        case writeFailed(String)
        case nothingToSave

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "TRIMR doesn't have permission to save to Photos. Enable it in Settings → TRIMR → Photos."
            case .downloadFailed(let message):
                return "Couldn't download the image. \(message)"
            case .decodeFailed:
                return "Couldn't read the image data."
            case .writeFailed(let message):
                return "Couldn't save to Photos. \(message)"
            case .nothingToSave:
                return "Nothing to save yet."
            }
        }
    }

    static func save(remoteURL url: URL) async throws {
        try await ensurePermission()
        let image = try await loadImage(from: url)
        try await write(image: image)
    }

    static func save(image: UIImage) async throws {
        try await ensurePermission()
        try await write(image: image)
    }

    // MARK: - Permission

    private static func ensurePermission() async throws {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch current {
        case .authorized, .limited:
            return
        case .notDetermined:
            let granted = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard granted == .authorized || granted == .limited else { throw SaveError.permissionDenied }
        case .denied, .restricted:
            throw SaveError.permissionDenied
        @unknown default:
            throw SaveError.permissionDenied
        }
    }

    // MARK: - Image fetch

    private static func loadImage(from url: URL) async throws -> UIImage {
        if let cached = LibraryImageCache.memory.object(forKey: url as NSURL) {
            return cached
        }

        if url.scheme == "data" {
            return try await Task.detached(priority: .userInitiated) { () throws -> UIImage in
                let s = url.absoluteString
                guard let comma = s.firstIndex(of: ","),
                      let data = Data(base64Encoded: String(s[s.index(after: comma)...]),
                                      options: .ignoreUnknownCharacters),
                      let img = UIImage(data: data) else {
                    throw SaveError.decodeFailed
                }
                return img
            }.value
        }

        do {
            var req = URLRequest(url: url)
            req.cachePolicy = .returnCacheDataElseLoad
            let (data, response) = try await LibraryImageCache.session.data(for: req)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw SaveError.downloadFailed("HTTP \(http.statusCode)")
            }
            guard let img = UIImage(data: data) else { throw SaveError.decodeFailed }
            return img
        } catch let error as SaveError {
            throw error
        } catch {
            throw SaveError.downloadFailed(error.localizedDescription)
        }
    }

    // MARK: - Write

    private static func write(image: UIImage) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    cont.resume()
                } else {
                    cont.resume(throwing: SaveError.writeFailed(error?.localizedDescription ?? "Unknown error"))
                }
            }
        }
    }
}

/// Compact circular icon button that mirrors the style of the existing
/// "save to library" bookmark button. Handles its own saving/saved/error
/// state so callers just hand it the image source.
struct SavePhotoButton: View {
    enum Source {
        case remote(URL)
        case image(UIImage)
        case none
    }

    let source: Source
    var size: CGFloat = 34

    @State private var saving = false
    @State private var saved = false
    @State private var errorMessage: String?

    var body: some View {
        Button {
            guard !saving, !saved else { return }
            saving = true
            Task {
                defer { saving = false }
                do {
                    switch source {
                    case .remote(let url):
                        try await PhotoSaver.save(remoteURL: url)
                    case .image(let img):
                        try await PhotoSaver.save(image: img)
                    case .none:
                        throw PhotoSaver.SaveError.nothingToSave
                    }
                    saved = true
                    Haptics.success()
                } catch {
                    errorMessage = (error as NSError).localizedDescription
                }
            }
        } label: {
            Group {
                if saving {
                    ProgressView().tint(Theme.gold).scaleEffect(0.7)
                } else {
                    Image(systemName: saved ? "checkmark" : "square.and.arrow.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(saved ? Theme.green : Theme.gold)
                }
            }
            .frame(width: size, height: size)
            .overlay(Circle().stroke((saved ? Theme.green : Theme.gold).opacity(0.4)))
        }
        .buttonStyle(.plain)
        .disabled(saving || saved || isNone)
        .alert("Couldn't save to Photos",
               isPresented: Binding(get: { errorMessage != nil },
                                    set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var isNone: Bool {
        if case .none = source { return true }
        return false
    }
}
