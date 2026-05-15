import SwiftUI
import Supabase

struct AnalyzeView: View {
    enum Phase { case upload, analyzing, results, error }
    @State private var phase: Phase = .upload
    @State private var response: AnalyzeResponse?
    @State private var errorMessage: String = ""
    @State private var showUploadSheet = false
    @State private var beforePhoto: UIImage?

    @EnvironmentObject var app: AppState
    @EnvironmentObject var profile: ProfileStore
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var photoStore: TryOnPhotoStore

    var body: some View {
        ZStack {
            switch phase {
            case .upload:    uploadPhase
            case .analyzing: analyzingPhase
            case .results:   resultsPhase
            case .error:     errorPhase
            }
        }
        .fullScreenCover(isPresented: $showUploadSheet) {
            PreviewUploadSheet(
                title: "Analysis",
                itemName: nil,
                swatchHex: nil,
                thumbnailAsset: nil,
                thumbnailUIImage: nil,
                headline: "Upload your photo for analysis",
                subtitle: "We'll read your face geometry and rank the cuts that suit you most",
                isGenerating: false,
                canAfford: profile.canAnalyse,
                generateCostLabel: "Generate · 1 Look",
                onGenerate: { cropped in
                    showUploadSheet = false
                    run(image: cropped)
                },
                onClose: { showUploadSheet = false },
                onTopUp: {
                    showUploadSheet = false
                    app.push(.pricing)
                }
            )
            .environmentObject(photoStore)
        }
    }

    private func run(image: UIImage) {
        beforePhoto = image
        guard profile.canAnalyse else {
            app.push(.pricing)
            return
        }
        withAnimation { phase = .analyzing }

        Task {
            // Resize + JPEG + base64 of a multi-MB UIImage takes 100-500ms — run it
            // off the main thread, in parallel with face validation, so the analyzing
            // UI is responsive while the photo is still being prepared.
            let encodingTask = Task.detached(priority: .userInitiated) {
                image.base64DataURL()
            }

            // Reject no-face photos client-side so we don't burn a credit + backend cost.
            guard await FaceValidator.hasFace(in: image) else {
                encodingTask.cancel()
                errorMessage = "We couldn't find a face in that photo. Try a clear, front-facing selfie in good light."
                withAnimation { phase = .error }
                return
            }
            guard let base64 = await encodingTask.value else {
                errorMessage = "Couldn't read that photo. Try another one."
                withAnimation { phase = .error }
                return
            }
            do {
                guard await auth.ensureSession() else {
                    errorMessage = "Please sign in again and try once more."
                    withAnimation { phase = .error }
                    return
                }
                let body = AnalyzeRequest(image: base64, preferences: nil)
                let result: AnalyzeResponse = try await Supa.client.functions
                    .invoke("analyze-hairstyle", options: .init(body: body))
                self.response = result
                await profile.refresh()
                withAnimation { phase = .results }
            } catch {
                errorMessage = (error as NSError).localizedDescription
                withAnimation { phase = .error }
            }
        }
    }

    // MARK: - Upload Phase

    private var uploadPhase: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Image("AnalyzeHero")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geo.size.width)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .clipped()
                    .ignoresSafeArea(edges: .top)

                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color(hex: 0x080604).opacity(0.0), location: 0.00),
                        Gradient.Stop(color: Color(hex: 0x080604).opacity(0.55), location: 0.45),
                        Gradient.Stop(color: Color(hex: 0x080604).opacity(0.96), location: 0.72),
                        Gradient.Stop(color: Color(hex: 0x080604), location: 1.00)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Text("Find your perfect cut.")
                        .font(TFont.display(28)).tracking(-0.6)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.bottom, 14)

                    Text("Let AI read your face geometry and find the single cut that suits you most.")
                        .font(TFont.body(14))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.text.opacity(0.78))
                        .lineSpacing(5)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 26)

                    Button {
                        showUploadSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Start Analysis")
                                .font(TFont.display(15)).tracking(0.2)
                        }
                        .foregroundStyle(Color(hex: 0x080604))
                        .frame(maxWidth: .infinity).padding(.vertical, 17)
                        .background(Theme.goldGlow)
                        .clipShape(Capsule())
                        .shadow(color: Theme.gold.opacity(0.35), radius: 20, y: 10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(Theme.bgDeep.ignoresSafeArea())
        }
    }

    // MARK: - Analyzing Phase

    private var analyzingPhase: some View {
        AnalyzingChecklistView()
    }

    // MARK: - Results Phase

    private var resultsPhase: some View {
        ResultView(
            response: response,
            userImage: beforePhoto ?? photoStore.photo,
            onReset: {
                response = nil
                beforePhoto = nil
                withAnimation { phase = .upload }
            }
        )
    }

    // MARK: - Error Phase

    private var errorPhase: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.red)

            VStack(spacing: 8) {
                Text("Analysis failed")
                    .font(TFont.display(20))
                    .foregroundStyle(Theme.text)
                Text(errorMessage.isEmpty ? "Something went wrong. Please try again." : errorMessage)
                    .font(TFont.body(13))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }

            Button {
                response = nil
                withAnimation { phase = .upload }
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
}
