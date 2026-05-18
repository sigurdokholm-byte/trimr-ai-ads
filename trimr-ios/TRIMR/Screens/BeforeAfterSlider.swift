import SwiftUI
import UIKit

/// Reusable before/after image comparison slider. The "after" image (URL) sits
/// underneath; the "before" image (UIImage) is layered on top and masked to
/// reveal only the left side, controlled by a draggable vertical splitter.
/// Defaults to a 1:1 frame and a 50% split.
struct BeforeAfterSlider: View {
    let beforeImage: UIImage?
    let afterURL: URL?
    /// Optional bundled "after" image. Takes precedence over `afterURL` when
    /// set (used for the standard onboarding sample, which has no remote URL).
    var afterImage: UIImage? = nil
    var aspectRatio: CGFloat = 1.0
    var cornerRadius: CGFloat = 22

    @State private var splitFraction: CGFloat = 0.5
    @State private var dragStartFraction: CGFloat = 0.5

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = width / aspectRatio
            let splitX = max(0, min(width, splitFraction * width))

            ZStack(alignment: .leading) {
                afterLayer(width: width, height: height)
                beforeLayer(width: width, height: height, splitX: splitX)
                divider(height: height, splitX: splitX)
                cornerLabels(width: width, height: height, splitX: splitX)
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(Theme.border))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let proposed = dragStartFraction + value.translation.width / max(width, 1)
                        splitFraction = max(0.02, min(0.98, proposed))
                    }
                    .onEnded { _ in
                        dragStartFraction = splitFraction
                    }
            )
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .onAppear {
            // Always start centered when the slider mounts.
            splitFraction = 0.5
            dragStartFraction = 0.5
        }
    }

    @ViewBuilder
    private func afterLayer(width: CGFloat, height: CGFloat) -> some View {
        if let img = afterImage {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
        } else if let url = afterURL {
            CachedAsyncImage(url: url)
                .frame(width: width, height: height)
                .clipped()
        } else {
            Rectangle().fill(Theme.surface)
                .frame(width: width, height: height)
        }
    }

    @ViewBuilder
    private func beforeLayer(width: CGFloat, height: CGFloat, splitX: CGFloat) -> some View {
        if let before = beforeImage {
            Image(uiImage: before)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
                .mask(
                    HStack(spacing: 0) {
                        Rectangle().frame(width: splitX, height: height)
                        Spacer(minLength: 0)
                    }
                    .frame(width: width, height: height)
                )
        }
    }

    private func divider(height: CGFloat, splitX: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .frame(width: 2, height: height)
                .shadow(color: .black.opacity(0.45), radius: 4)

            // Knob
            Circle()
                .fill(Color.white)
                .frame(width: 38, height: 38)
                .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
                .overlay(
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .black))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .black))
                    }
                    .foregroundStyle(Color(hex: 0x080604))
                )
        }
        .position(x: splitX, y: height / 2)
        .allowsHitTesting(false)
    }

    private func cornerLabels(width: CGFloat, height: CGFloat, splitX: CGFloat) -> some View {
        ZStack {
            // BEFORE (top-left, only when there's any "before" visible)
            if splitX > 32 {
                Text("BEFORE")
                    .font(TFont.mono(9, weight: .semibold)).tracking(1.6)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Capsule())
                    .position(x: 16 + 30, y: 18)
            }
            // AFTER (top-right, only when there's any "after" visible)
            if splitX < width - 32 {
                Text("AFTER")
                    .font(TFont.mono(9, weight: .semibold)).tracking(1.6)
                    .foregroundStyle(Color(hex: 0x080604))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Theme.gold)
                    .clipShape(Capsule())
                    .position(x: width - 16 - 26, y: 18)
            }
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}
