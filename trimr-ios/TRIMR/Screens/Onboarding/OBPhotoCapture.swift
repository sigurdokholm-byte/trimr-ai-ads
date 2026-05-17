import SwiftUI
import UIKit

struct OBPhotoCapture: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double
    @Binding var capturedImage: UIImage?

    @State private var photoSource: PhotoSource? = nil
    @State private var pendingImage: UIImage? = nil
    @State private var validating: Bool = false
    @State private var validationError: String? = nil
    @State private var showSourceChoice: Bool = false

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            if let img = pendingImage {
                preview(img)
            } else {
                empty
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .fullScreenCover(item: $photoSource) { src in
            // fullScreenCover (not .sheet) keeps the underlying page from
            // scaling down ~92% and bouncing back when the picker presents —
            // that scale-bounce is what users perceive as "the page drops down".
            switch src {
            case .camera:
                if cameraAvailable {
                    CameraPicker(
                        onPicked: { img in pendingImage = img; photoSource = nil; validationError = nil },
                        onCancel: { photoSource = nil }
                    )
                } else {
                    // Simulator or no-camera device: fall back to library so we don't crash.
                    PhotoLibraryPicker(
                        onPicked: { img in pendingImage = img; photoSource = nil; validationError = nil },
                        onCancel: { photoSource = nil }
                    )
                }
            case .library:
                PhotoLibraryPicker(
                    onPicked: { img in pendingImage = img; photoSource = nil; validationError = nil },
                    onCancel: { photoSource = nil }
                )
            }
        }
        .confirmationDialog("Choose photo source", isPresented: $showSourceChoice, titleVisibility: .visible) {
            Button("Take Selfie") { photoSource = .camera }
            Button("Photo Library") { photoSource = .library }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var empty: some View {
        VStack(spacing: 22) {
            Spacer().frame(height: 12)
            Text("take or pick a selfie")
                .font(TFont.display(30)).tracking(-0.6)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.text)
            Text("front-facing, good lighting")
                .font(TFont.body(14)).foregroundStyle(Theme.muted)

            Spacer()

            ZStack {
                Circle().fill(Theme.gold.opacity(0.08))
                Circle().stroke(Theme.gold.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
                Image(systemName: "camera.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(Theme.gold)
            }
            .frame(width: 220, height: 220)

            Spacer()

            VStack(spacing: 10) {
                Button { photoSource = cameraAvailable ? .camera : .library } label: {
                    Text(cameraAvailable ? "Take Selfie" : "Choose Photo")
                        .font(TFont.body(16, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                        .background(Theme.gold).clipShape(Capsule())
                }
                .buttonStyle(.plain)

                if cameraAvailable {
                    Button { photoSource = .library } label: {
                        Text("Upload from Camera Roll")
                            .font(TFont.body(14, weight: .medium))
                            .foregroundStyle(Theme.text)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .overlay(Capsule().stroke(Color.white.opacity(0.12)))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func preview(_ img: UIImage) -> some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)
            Text("looks good?")
                .font(TFont.display(30)).tracking(-0.6)
                .foregroundStyle(Theme.text)
                .padding(.bottom, 16)

            Image(uiImage: img)
                .resizable().scaledToFill()
                .frame(maxWidth: .infinity).frame(height: 380).clipped()
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.08)))
                .padding(.horizontal, 24)

            if let err = validationError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.red)
                    Text(err)
                        .font(TFont.body(13))
                        .foregroundStyle(Theme.red)
                }
                .padding(.top, 14)
                .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 10) {
                Button {
                    Task { await useThisPhoto(img) }
                } label: {
                    HStack {
                        if validating { ProgressView().tint(Color(hex: 0x0A0804)) }
                        Text(validating ? "Checking…" : "Use This Photo")
                            .font(TFont.body(16, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x0A0804))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.gold).clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(validating)

                Button {
                    pendingImage = nil
                    validationError = nil
                } label: {
                    Text("Retake")
                        .font(TFont.body(14, weight: .medium))
                        .foregroundStyle(Theme.text)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .overlay(Capsule().stroke(Color.white.opacity(0.12)))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    @MainActor
    private func useThisPhoto(_ img: UIImage) async {
        validating = true
        defer { validating = false }
        let ok = await FaceValidator.hasFace(in: img)
        if ok {
            capturedImage = img
            onNext()
        } else {
            validationError = "We couldn't find a face. Try a clearer front-facing selfie."
        }
    }
}
