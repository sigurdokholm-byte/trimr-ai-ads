import SwiftUI
import Supabase

struct TryOnView: View {
    enum Phase { case picker, analyzing, results, error }
    @State private var phase: Phase = .picker
    @State private var selected: Int? = nil
    @State private var customSelected: Bool = false
    @State private var customReferenceImage: UIImage?
    @State private var customRefSource: PhotoSource?
    @State private var showCustomRefChoice = false
    @State private var showUploadSheet = false
    @State private var response: AnalyzeResponse?
    @State private var beforePhoto: UIImage?
    @State private var isGenerating = false
    @State private var errorMessage: String?

    @EnvironmentObject var app: AppState
    @EnvironmentObject var profile: ProfileStore
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var photoStore: TryOnPhotoStore

    private var filteredIndices: [Int] { Array(CatalogData.tryOnCuts.indices) }
    private var hasSelection: Bool { selected != nil || customSelected }

    private var selectedItemName: String {
        if customSelected { return "Custom Reference" }
        if let i = selected { return CatalogData.tryOnCuts[i].name }
        return ""
    }

    private var selectedThumbnailAsset: String? {
        guard !customSelected, let i = selected else { return nil }
        return CatalogData.tryOnCuts[i].image
    }

    var body: some View {
        ZStack {
            switch phase {
            case .picker:    pickerPhase
            case .analyzing: AnalyzingChecklistView()
            case .results:   resultsPhase
            case .error:     errorPhase
            }
        }
        .fullScreenCover(item: $customRefSource) { source in
            switch source {
            case .library:
                PhotoLibraryPicker(
                    onPicked: acceptCustomReference,
                    onCancel: { customRefSource = nil }
                )
            case .camera:
                CameraPicker(
                    onPicked: acceptCustomReference,
                    onCancel: { customRefSource = nil }
                )
                .ignoresSafeArea()
            }
        }
        .confirmationDialog("Upload your reference photo", isPresented: $showCustomRefChoice, titleVisibility: .visible) {
            Button("Take Photo") { customRefSource = .camera }
            Button("Choose from Library") { customRefSource = .library }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Try-on failed", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .fullScreenCover(isPresented: $showUploadSheet) {
            if hasSelection {
                PreviewUploadSheet(
                    title: "Try On",
                    itemName: selectedItemName,
                    swatchHex: nil,
                    thumbnailAsset: selectedThumbnailAsset,
                    thumbnailUIImage: customSelected ? customReferenceImage : nil,
                    headline: "Upload your photo to preview hairstyle",
                    subtitle: "We'll apply the hairstyle to your photo",
                    isGenerating: isGenerating,
                    canAfford: profile.canTryOn,
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

    private var pickerPhase: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                let cols = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
                LazyVGrid(columns: cols, spacing: 10) {
                    customReferenceCard
                    ForEach(filteredIndices, id: \.self) { idx in
                        cutCard(idx: idx, cut: CatalogData.tryOnCuts[idx])
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer().frame(height: 120)
            }
        }
        .background(Theme.bgDeep.ignoresSafeArea())
    }

    private var resultsPhase: some View {
        ResultView(
            response: response,
            userImage: beforePhoto ?? photoStore.photo,
            onReset: {
                response = nil
                beforePhoto = nil
                selected = nil
                customSelected = false
                withAnimation { phase = .picker }
            },
            showWhy: false
        )
    }

    private var errorPhase: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.red)
            VStack(spacing: 8) {
                Text("Try-on failed")
                    .font(TFont.display(20))
                    .foregroundStyle(Theme.text)
                Text(errorMessage?.isEmpty == false ? errorMessage! : "Something went wrong. Please try again.")
                    .font(TFont.body(13))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            Button {
                response = nil
                withAnimation { phase = .picker }
            } label: {
                Text("Try Again")
                    .font(TFont.body(14, weight: .bold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .padding(.horizontal, 28).padding(.vertical, 14)
                    .background(Theme.goldGlow)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
    }

    // MARK: - Actions

    private func acceptCustomReference(_ image: UIImage) {
        customReferenceImage = image
        customRefSource = nil
        customSelected = true
        selected = nil
        response = nil
        showUploadSheet = true
    }

    private func generate(image: UIImage) {
        guard hasSelection else { return }
        beforePhoto = image
        guard profile.canTryOn else {
            showUploadSheet = false
            app.push(.pricing); return
        }
        isGenerating = true
        Task {
            defer { isGenerating = false }
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

                let referenceUrl: String
                let targetStyle: String?

                if customSelected, let custom = customReferenceImage {
                    referenceUrl = try await uploadCustomReference(image: custom)
                    targetStyle = nil
                } else if let idx = selected {
                    let cut = CatalogData.tryOnCuts[idx]
                    referenceUrl = cut.referenceUrl.absoluteString
                    targetStyle = cut.name
                } else {
                    return
                }

                var body = AnalyzeRequest(image: base64, preferences: nil)
                body.targetStyle = targetStyle
                body.referenceUrl = referenceUrl

                let result: AnalyzeResponse = try await Supa.client.functions
                    .invoke("analyze-hairstyle", options: .init(body: body))
                response = result
                showUploadSheet = false
                await profile.refresh()
                ReviewPrompt.recordSuccessfulGeneration()
                withAnimation { phase = .results }
            } catch {
                errorMessage = (error as NSError).localizedDescription
                showUploadSheet = false
                withAnimation { phase = .error }
            }
        }
    }

    private func uploadCustomReference(image: UIImage) async throws -> String {
        guard let uid = auth.userId else {
            throw NSError(domain: "TryOn", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }
        guard let data = await Task.detached(priority: .userInitiated, operation: {
            image.jpegData(compressionQuality: 0.85)
        }).value else {
            throw NSError(domain: "TryOn", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't encode reference image"])
        }
        let path = "\(uid.uuidString.lowercased())/custom-ref-\(UUID().uuidString.lowercased()).jpg"
        _ = try await Supa.client.storage
            .from("hairstyle-previews")
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: false))
        let signed = try await Supa.client.storage
            .from("hairstyle-previews")
            .createSignedURL(path: path, expiresIn: 600)
        return signed.absoluteString
    }

    // MARK: - Subviews

    private var customReferenceCard: some View {
        Color(hex: 0x1A140D)
            .aspectRatio(3/4, contentMode: .fit)
            .overlay {
                if let img = customReferenceImage {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Theme.gold.opacity(0.12))
                            Circle().strokeBorder(Theme.gold.opacity(0.55), style: .init(lineWidth: 1.5, dash: [4, 4]))
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Theme.gold)
                        }
                        .frame(width: 56, height: 56)

                        VStack(spacing: 4) {
                            Text("Upload your\nreference photo")
                                .font(TFont.body(12, weight: .semibold))
                                .foregroundStyle(Theme.text)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            Text("A cut you've seen elsewhere")
                                .font(TFont.body(9))
                                .foregroundStyle(Theme.muted)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .clipped()
            .background(Theme.gold.opacity(customReferenceImage == nil ? 0.04 : 0))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        customSelected ? Theme.gold : (customReferenceImage == nil ? Theme.gold.opacity(0.4) : Color.clear),
                        style: .init(lineWidth: customSelected ? 2 : 1.5, dash: customReferenceImage == nil ? [6, 4] : [])
                    )
            )
            .overlay(alignment: .bottom) {
                if customReferenceImage != nil {
                    LinearGradient(
                        colors: [.clear, Color(hex: 0x080604).opacity(0.9)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 70)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if customReferenceImage != nil {
                    Text("Custom")
                        .font(TFont.body(12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(EdgeInsets(top: 0, leading: 12, bottom: 12, trailing: 12))
                }
            }
            .overlay(alignment: .topTrailing) {
                if customSelected {
                    ZStack {
                        Circle().fill(Theme.goldGlow)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Color(hex: 0x080604))
                    }
                    .frame(width: 26, height: 26)
                    .shadow(color: Theme.gold.opacity(0.5), radius: 10, y: 4)
                    .padding(10)
                } else if customReferenceImage != nil {
                    Button { customReferenceImage = nil; customSelected = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .scaleEffect(customSelected ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: customSelected)
            .onTapGesture {
                if customReferenceImage == nil {
                    showCustomRefChoice = true
                } else {
                    customSelected = true
                    selected = nil
                    response = nil
                    showUploadSheet = true
                }
            }
    }

    private func cutCard(idx: Int, cut: Haircut) -> some View {
        Color(hex: 0x1A140D)
            .aspectRatio(3/4, contentMode: .fit)
            .overlay {
                Image(cut.image).resizable().scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipped()
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, Color(hex: 0x080604).opacity(0.95)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 90)
            }
            .overlay(alignment: .bottomLeading) {
                Text(cut.name)
                    .font(TFont.body(12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(EdgeInsets(top: 0, leading: 12, bottom: 12, trailing: 12))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(selected == idx ? Theme.gold : Color.clear, lineWidth: 2)
            )
            .overlay(alignment: .topTrailing) {
                if selected == idx {
                    ZStack {
                        Circle().fill(Theme.goldGlow)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Color(hex: 0x080604))
                    }
                    .frame(width: 26, height: 26)
                    .shadow(color: Theme.gold.opacity(0.5), radius: 10, y: 4)
                    .padding(10)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .scaleEffect(selected == idx ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
            .onTapGesture {
                selected = idx
                customSelected = false
                response = nil
                showUploadSheet = true
            }
    }
}
