import SwiftUI
import UIKit

/// Dedicated upload step shown after a user picks a hair color or hairstyle.
/// Mirrors the web `PreviewUploadStep` component: selected-item chip up top,
/// big 1:1 photo box (drag to pan when filled), headline + subtitle, manual
/// Generate CTA at the bottom. On Generate, the visible square is cropped
/// from the underlying photo and handed to the parent via `onGenerate(UIImage)`.
struct PreviewUploadSheet: View {
    let title: String
    let itemName: String?
    let swatchHex: UInt32?
    let thumbnailAsset: String?
    let thumbnailUIImage: UIImage?
    let headline: String
    let subtitle: String
    let isGenerating: Bool
    let canAfford: Bool
    let generateCostLabel: String  // e.g. "Generate · 1 Look"
    let onGenerate: (UIImage) -> Void
    let onClose: () -> Void
    let onTopUp: () -> Void

    @EnvironmentObject var photoStore: TryOnPhotoStore
    @State private var photoSource: PhotoSource?
    @State private var showSourceChoice = false
    @State private var dragAccumulator: CGSize = .zero
    @State private var measuredBoxSize: CGFloat = 0
    @State private var pendingPhoto: UIImage?

    private var hasPhoto: Bool { photoStore.photo != nil }
    private var generateDisabled: Bool { !hasPhoto || isGenerating || !canAfford }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                VStack(spacing: 24) {
                    photoBox
                        .padding(.top, 8)
                    copyBlock
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 140)
            }

            if isGenerating { generatingOverlay }
        }
        .stickyCTA(visible: !isGenerating) {
            VStack(spacing: 8) {
                if !canAfford {
                    Text("0 looks left — top up to generate")
                        .font(TFont.mono(11)).tracking(1)
                        .foregroundStyle(Theme.gold)
                        .onTapGesture { onTopUp() }
                }
                generateButton
            }
        }
        .fullScreenCover(
            item: $photoSource,
            onDismiss: {
                // Commit after dismiss with animations off — committing during
                // the picker dismiss animates the photo box and visibly shifts
                // the page. Don't move this into accept(). Cancel path enters
                // here too with pendingPhoto == nil, hence the guard.
                if let pending = pendingPhoto {
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) {
                        photoStore.photo = pending
                    }
                    pendingPhoto = nil
                }
            }
        ) { source in
            switch source {
            case .library:
                PhotoLibraryPicker(
                    onPicked: accept,
                    onCancel: { photoSource = nil }
                )
                .ignoresSafeArea()
            case .camera:
                CameraPicker(
                    onPicked: accept,
                    onCancel: { photoSource = nil }
                )
                .ignoresSafeArea()
            }
        }
        .confirmationDialog("Add your photo", isPresented: $showSourceChoice, titleVisibility: .visible) {
            Button("Take Photo") { photoSource = .camera }
            Button("Choose from Library") { photoSource = .library }
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: photoStore.photo) { _, _ in
            // New / cleared photo — reset pan gesture baseline.
            dragAccumulator = .zero
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                onClose()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                    Text("Pick another")
                        .font(TFont.mono(10, weight: .semibold)).tracking(1.5)
                }
                .foregroundStyle(Theme.muted2)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .overlay(Capsule().stroke(Theme.border))
            }
            .buttonStyle(.plain)

            if let name = itemName {
                HStack(spacing: 8) {
                    if let hex = swatchHex {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 22, height: 22)
                            .overlay(Circle().stroke(Color.white.opacity(0.15)))
                    } else if let img = thumbnailUIImage {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
                    } else if let asset = thumbnailAsset {
                        Image(asset).resizable().scaledToFill()
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
                    }
                    Text(name)
                        .font(TFont.body(13, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    // MARK: - Photo box

    private var photoBox: some View {
        let boxSize = UIScreen.main.bounds.width - 40
        return photoBoxContent(boxSize: boxSize)
            .frame(width: boxSize, height: boxSize)
            .onAppear { measuredBoxSize = boxSize }
    }

    @ViewBuilder
    private func photoBoxContent(boxSize: CGFloat) -> some View {
        ZStack {
            if let img = photoStore.photo {
                let bounds = panBounds(for: img.size, boxSize: boxSize)
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: boxSize, height: boxSize)
                    .offset(photoStore.pan)
                    .frame(width: boxSize, height: boxSize)
                    .clipped()
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 2)
                            .onChanged { value in
                                let next = CGSize(
                                    width: dragAccumulator.width + value.translation.width,
                                    height: dragAccumulator.height + value.translation.height
                                )
                                photoStore.pan = CGSize(
                                    width: clamp(next.width, -bounds.x, bounds.x),
                                    height: clamp(next.height, -bounds.y, bounds.y)
                                )
                            }
                            .onEnded { _ in
                                dragAccumulator = photoStore.pan
                            }
                    )
            } else {
                Button {
                    showSourceChoice = true
                } label: {
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Theme.surface)
                                .overlay(Circle().strokeBorder(Theme.borderStrong, style: .init(lineWidth: 1.5, dash: [4, 4])))
                            Image(systemName: "plus")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(Theme.muted)
                        }
                        .frame(width: 72, height: 72)

                        Text("Tap to upload photo")
                            .font(TFont.mono(11)).tracking(1)
                            .foregroundStyle(Theme.muted)
                    }
                    .frame(width: boxSize, height: boxSize)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: boxSize, height: boxSize)
        .background(hasPhoto ? Theme.card : Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .strokeBorder(
                    hasPhoto ? Theme.border : Theme.borderStrong,
                    style: .init(lineWidth: hasPhoto ? 1 : 1.8, dash: hasPhoto ? [] : [6, 4])
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(alignment: .topTrailing) {
            if hasPhoto {
                Button {
                    photoStore.clear()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove photo")
                .padding(12)
            }
        }
        .overlay(alignment: .bottom) {
            if hasPhoto {
                Text("Drag to center your face")
                    .font(TFont.mono(9)).tracking(1.5)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Capsule())
                    .padding(.bottom, 12)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Copy

    private var copyBlock: some View {
        VStack(spacing: 10) {
            Text(headline)
                .font(TFont.display(22))
                .tracking(-0.4)
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(TFont.body(13))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }

    // MARK: - Generate CTA

    private var generateButton: some View {
        Button {
            if !canAfford { onTopUp(); return }
            guard let original = photoStore.photo, measuredBoxSize > 0 else { return }
            // Crop on a background queue — UIGraphicsImageRenderer + draw can stall
            // the main thread for ~50-150ms on large photos, which the user feels
            // as a tap delay before the Generating state appears.
            let pan = photoStore.pan
            let boxSize = measuredBoxSize
            Task {
                let cropped = await Task.detached(priority: .userInitiated) {
                    Self.croppedSquare(original, pan: pan, boxSize: boxSize)
                }.value
                onGenerate(cropped)
            }
        } label: {
            Text(isGenerating ? "Generating…" : generateCostLabel)
                .font(TFont.display(14))
                .tracking(1.2)
                .foregroundStyle(generateDisabled ? Color.black.opacity(0.55) : Color(hex: 0x080604))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    generateDisabled
                        ? AnyShapeStyle(Color.white.opacity(0.18))
                        : AnyShapeStyle(Theme.goldGlow)
                )
                .clipShape(Capsule())
                .shadow(color: generateDisabled ? .clear : Theme.gold.opacity(0.25), radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(generateDisabled)
        .opacity(isGenerating ? 0.85 : 1)
    }

    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().tint(Theme.gold).scaleEffect(1.4)
                Text("Generating…")
                    .font(TFont.body(13, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Text("~ 30 seconds")
                    .font(TFont.mono(9)).tracking(1.8)
                    .foregroundStyle(Theme.muted)
            }
            .padding(24)
            .background(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private func accept(_ image: UIImage) {
        pendingPhoto = image
        photoSource = nil
    }

    // MARK: - Pan / crop math

    /// Maximum pan in screen points so the image edges never reveal blank
    /// background (the smaller dimension already fills the box).
    private func panBounds(for imgSize: CGSize, boxSize: CGFloat) -> CGPoint {
        let side = min(imgSize.width, imgSize.height)
        guard side > 0 else { return .zero }
        let displayScale = boxSize / side
        let displayedW = imgSize.width * displayScale
        let displayedH = imgSize.height * displayScale
        return CGPoint(
            x: max(0, (displayedW - boxSize) / 2),
            y: max(0, (displayedH - boxSize) / 2)
        )
    }

    private func clamp(_ value: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        min(max(value, lo), hi)
    }

    /// Crop the visible square (in screen-point terms) out of the underlying
    /// UIImage. Pure function — `nonisolated static` so it can run on a
    /// background Task without dragging the View struct across actor boundaries.
    fileprivate nonisolated static func croppedSquare(_ image: UIImage, pan: CGSize, boxSize: CGFloat) -> UIImage {
        let imgSize = image.size  // accounts for orientation
        let side = min(imgSize.width, imgSize.height)
        guard side > 0, boxSize > 0 else { return image }
        let displayScale = boxSize / side
        let originX = (imgSize.width - side) / 2 - pan.width / displayScale
        let originY = (imgSize.height - side) / 2 - pan.height / displayScale
        let clampedX = min(max(originX, 0), imgSize.width - side)
        let clampedY = min(max(originY, 0), imgSize.height - side)
        let cropRect = CGRect(x: clampedX, y: clampedY, width: side, height: side)

        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: cropRect.size, format: format)
        return renderer.image { _ in
            image.draw(at: CGPoint(x: -cropRect.origin.x, y: -cropRect.origin.y))
        }
    }
}
