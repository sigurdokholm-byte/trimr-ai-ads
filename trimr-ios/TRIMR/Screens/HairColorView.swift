import SwiftUI
import Supabase

struct HairColorView: View {
    @State private var selected: Int? = nil
    @State private var showUploadSheet = false
    @State private var resultUrl: String?
    @State private var beforePhoto: UIImage?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var saved = false
    @State private var saving = false
    @State private var saveError: String?

    @EnvironmentObject var app: AppState
    @EnvironmentObject var profile: ProfileStore
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var photoStore: TryOnPhotoStore

    private var selectedColorObject: HairColor? {
        guard let s = selected else { return nil }
        return CatalogData.hairColors[s]
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    subhead
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 20)

                    if let url = resultUrl {
                        resultImage(url)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 22)
                    }

                    HStack {
                        Text("SELECT COLOR").labelMono(size: 10, tracking: 2).foregroundStyle(Theme.gold)
                        Spacer()
                        if let s = selected {
                            Text(CatalogData.hairColors[s].name.uppercased())
                                .font(TFont.mono(9, weight: .semibold)).tracking(1.5)
                                .foregroundStyle(Theme.text)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)

                    let cols = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
                    LazyVGrid(columns: cols, spacing: 12) {
                        ForEach(Array(CatalogData.hairColors.enumerated()), id: \.offset) { idx, c in
                            colorCard(idx: idx, color: c)
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer().frame(height: 120)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
        }
        .alert("Couldn't apply colour", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Save failed", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
        .onChange(of: resultUrl) { _, _ in saved = false }
        .fullScreenCover(isPresented: $showUploadSheet) {
            if let color = selectedColorObject {
                PreviewUploadSheet(
                    title: "Hair Color",
                    itemName: color.name,
                    swatchHex: color.hex,
                    thumbnailAsset: nil,
                    thumbnailUIImage: nil,
                    headline: "Upload your photo to preview hair color",
                    subtitle: "We'll apply the color to your photo",
                    isGenerating: isGenerating,
                    canAfford: profile.canColor,
                    generateCostLabel: "Generate · 1 Look",
                    onGenerate: { cropped in generate(image: cropped) },
                    onClose: {
                        if !isGenerating { showUploadSheet = false }
                    },
                    onTopUp: {
                        showUploadSheet = false
                        app.push(.pricing)
                    }
                )
                .environmentObject(photoStore)
            }
        }
    }

    // MARK: - Actions

    private func generate(image: UIImage) {
        guard let idx = selected else { return }
        beforePhoto = image
        guard profile.canColor else {
            showUploadSheet = false
            app.push(.pricing); return
        }
        let color = CatalogData.hairColors[idx].name
        isGenerating = true
        Task {
            defer { isGenerating = false }
            // Encode in parallel with face validation off the main thread.
            let encodingTask = Task.detached(priority: .userInitiated) {
                image.base64DataURL()
            }
            guard await FaceValidator.hasFace(in: image) else {
                encodingTask.cancel()
                errorMessage = "We couldn't find a face in that photo. Try a clear, front-facing selfie in good light."
                return
            }
            guard let base64 = await encodingTask.value else {
                errorMessage = "Couldn't read your photo."
                return
            }
            do {
                guard await auth.ensureSession() else {
                    errorMessage = "Please sign in again and try once more."
                    return
                }
                let body = HairColorRequest(image: base64, color: color)
                let resp: TryonResponse = try await Supa.client.functions
                    .invoke("hair-color", options: .init(body: body))
                resultUrl = resp.imageUrl
                showUploadSheet = false
                await profile.refresh()
                ReviewPrompt.recordSuccessfulGeneration()
            } catch {
                errorMessage = (error as NSError).localizedDescription
            }
        }
    }

    // MARK: - Subviews

    private var subhead: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Test any shade")
                .font(TFont.display(24)).tracking(-0.4)
                .foregroundStyle(Theme.text)
            Text("Pick a colour — we'll preview it on your photo next.")
                .font(TFont.body(13))
                .foregroundStyle(Theme.muted)
                .lineSpacing(3)
        }
    }

    private func resultImage(_ url: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Text("YOUR NEW COLOUR")
                    .labelMono(size: 9, tracking: 2)
                    .foregroundStyle(Theme.gold)
                Spacer()
                SavePhotoButton(source: URL(string: url).map { .remote($0) } ?? .none)
                Button {
                    guard !saving, !saved, let idx = selected else { return }
                    let colorName = CatalogData.hairColors[idx].name
                    saving = true
                    Task {
                        defer { saving = false }
                        do {
                            try await app.saveCut(
                                kind: .hairColor,
                                imageUrl: url,
                                name: "\(colorName) — Hair Color"
                            )
                            saved = true
                        } catch {
                            saveError = (error as NSError).localizedDescription
                        }
                    }
                } label: {
                    Group {
                        if saving {
                            ProgressView().tint(Theme.gold).scaleEffect(0.7)
                        } else {
                            Image(systemName: saved ? "checkmark" : "bookmark.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(saved ? Theme.green : Theme.gold)
                        }
                    }
                    .frame(width: 34, height: 34)
                    .overlay(Circle().stroke((saved ? Theme.green : Theme.gold).opacity(0.4)))
                }
                .buttonStyle(.plain)
                .disabled(saved || saving)
            }
            BeforeAfterSlider(beforeImage: beforePhoto, afterURL: URL(string: url))
        }
    }

    private func colorCard(idx: Int, color c: HairColor) -> some View {
        let isSelected = selected == idx
        return Color(hex: c.hex)
            .aspectRatio(3/4, contentMode: .fit)
            .overlay {
                if UIImage(named: c.image) != nil {
                    Image(c.image).resizable().scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .clipped()
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, Color(hex: 0x080604).opacity(0.95)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 70)
            }
            .overlay(alignment: .bottomLeading) {
                Text(c.name)
                    .font(TFont.body(11, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Theme.gold : Color.white.opacity(0.06),
                            lineWidth: isSelected ? 2 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    ZStack {
                        Circle().fill(Theme.goldGlow)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(Color(hex: 0x080604))
                    }
                    .frame(width: 22, height: 22)
                    .shadow(color: Theme.gold.opacity(0.5), radius: 8, y: 3)
                    .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .scaleEffect(isSelected ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    selected = idx
                    resultUrl = nil
                }
                showUploadSheet = true
            }
    }
}
