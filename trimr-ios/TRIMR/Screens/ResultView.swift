import SwiftUI

struct ResultView: View {
    @EnvironmentObject var app: AppState

    /// Which slice of the result to render. `.full` is the real app screen
    /// (unchanged). `.card` and `.details` let onboarding present the same
    /// real components split across two screens.
    enum Section { case full, card, details }

    let response: AnalyzeResponse?
    let userImage: UIImage?
    let onReset: (() -> Void)?
    let sectionMode: Section
    /// When false (try-on of a user-chosen cut) the "Why It Works" section is
    /// hidden and not persisted — a rationale would be dishonest when the
    /// rating is mediocre.
    let showWhy: Bool

    init(response: AnalyzeResponse? = nil,
         userImage: UIImage? = nil,
         onReset: (() -> Void)? = nil,
         section: Section = .full,
         showWhy: Bool = true) {
        self.response = response
        self.userImage = userImage
        self.onReset = onReset
        self.sectionMode = section
        self.showWhy = showWhy
    }

    // MARK: - Sample data (preview / no response)

    private let sampleFaceShape = "Square"
    private let sampleFaceDescription = "Strong, angular jawline with forehead and cheekbones of similar width — bold geometric proportions."
    private let sampleName = "Curly Top"
    private let sampleScore = 92
    private let samplePhotoAsset = "Curlytop"
    private let sampleWhy = "The Curly Top is an excellent choice for your square face — the volume and soft movement up top break up the strong angles of your jaw and frame your features without adding width at the sides. Keeping length on top lets your natural curl do the work, while tighter sides keep the shape clean and intentional rather than bulky."
    private let sampleBrief = "Sides: Taper or low fade — blend from a 1.5–2 guard down to a 0.5 at the skin, kept tight so the volume reads on top. Top: Leave 3–4 inches (7–10cm) to let the curl form; point-cut through the ends for separation, never blunt. Back: Round off and blend naturally into the taper."
    private let sampleHow = [
        "Work a curl cream through damp (not soaking) hair, raking it in evenly.",
        "Scrunch upward toward the scalp to encourage curl clumps — don't comb it out.",
        "Diffuse on low heat / low speed, or air-dry, cupping the curls as they set.",
        "Once dry, scrunch out any crunch with a drop of light oil and shape with your fingers.",
    ]

    private struct CompatRow { let icon: String; let label: String; let value: Int }
    private let compat: [CompatRow] = [
        .init(icon: "brain.head.profile", label: "Face Shape Match", value: 95),
        .init(icon: "person.fill", label: "Age Appropriate", value: 93),
        .init(icon: "wrench.adjustable.fill", label: "Maintenance", value: 90),
        .init(icon: "flame.fill", label: "Trend Score", value: 94),
        .init(icon: "scissors", label: "Styling Difficulty", value: 88),
    ]

    /// Bars to render: prefers the real breakdown from the AI response, falls
    /// back to the static sample for previews and the no-response onboarding
    /// sample card. Keeps the visual order matching the static `compat` so the
    /// view code below doesn't care which source is used.
    private var compatRows: [CompatRow] {
        guard let b = response?.recommendation.compatibilityBreakdown else {
            return compat
        }
        return [
            .init(icon: "brain.head.profile",     label: "Face Shape Match",   value: b.faceShapeMatch ?? 50),
            .init(icon: "person.fill",            label: "Age Appropriate",    value: b.ageAppropriateness ?? 50),
            .init(icon: "wrench.adjustable.fill", label: "Maintenance",        value: b.maintenance ?? 50),
            .init(icon: "flame.fill",             label: "Trend Score",        value: b.trendScore ?? 50),
            .init(icon: "scissors",               label: "Styling Difficulty", value: b.stylingDifficulty ?? 50),
        ]
    }

    @State private var open: Set<String> = []
    @State private var saved = false
    @State private var saving = false
    @State private var saveError: String?
    @State private var briefCopied = false

    // MARK: - Resolved values (real > sample)

    private var faceShape: String { (response?.faceShape ?? sampleFaceShape).capitalized }
    private var faceDescription: String? { response?.faceDescription ?? sampleFaceDescription }
    private var name: String { response?.recommendation.name ?? sampleName }
    private var score: Int { response?.recommendation.rating ?? sampleScore }
    private var why: String { response?.recommendation.whyItWorks ?? sampleWhy }
    private var brief: String? { response?.recommendation.barberInstructions ?? sampleBrief }
    private var how: [String] {
        if let tips = response?.recommendation.stylingTips, !tips.isEmpty { return tips }
        return sampleHow
    }
    private var generatedImageURL: URL? {
        guard let raw = response?.recommendation.generatedImage,
              raw.hasPrefix("https://") || raw.hasPrefix("data:"),
              let u = URL(string: raw) else { return nil }
        return u
    }
    private var photoAsset: String { samplePhotoAsset }

    private var faceIcon: String {
        switch faceShape.lowercased() {
        case "oval": return "⬭"
        case "round": return "◯"
        case "square": return "▢"
        case "heart": return "♡"
        case "oblong": return "⬮"
        case "diamond": return "◇"
        case "triangle": return "△"
        default: return "⬭"
        }
    }

    private var scoreColor: Color {
        if score <= 40 { return Theme.red }
        if score <= 70 { return Theme.gold }
        return Theme.green
    }

    private var scoreGradient: LinearGradient {
        LinearGradient(colors: [scoreColor, Theme.gold],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var rankLabel: String { "01  •  BEST MATCH" }

    private var shareCaption: String {
        "I used AI to find my perfect haircut 🤯\n\nFace shape: \(faceShape) — my match is the \(name) (\(score)/100) ✂️\n\nFind yours free with TRIMR\n\n#hairtok #haircut #menshairstyle #barber #hairstyle"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                switch sectionMode {
                case .full:    fullContent
                case .card:    cardContent
                case .details: detailsContent
                }
            }
        }
        .background(Theme.bgDeep.ignoresSafeArea())
        .alert("Save failed", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    // MARK: - Full screen (real app — unchanged)

    @ViewBuilder private var fullContent: some View {
        faceShapeBadge
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)

        VStack(spacing: 8) {
            Text("Your Perfect Cut.")
                .font(TFont.display(34))
                .tracking(-1.2)
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
            Text("AI-matched to your face shape and hair")
                .font(TFont.body(13))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.bottom, 28)

        HStack(spacing: 12) {
            Text(rankLabel)
                .font(TFont.mono(12, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.text)
            Spacer()
            if let url = generatedImageURL {
                SavePhotoButton(source: .remote(url))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)

        aiPhoto
            .padding(.horizontal, 20)
            .padding(.bottom, 22)

        nameScoreHeader
            .padding(.horizontal, 20)
            .padding(.bottom, 18)

        progressBar
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

        compatBreakdown
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

        detailsSections
            .padding(.horizontal, 16)
            .padding(.bottom, 24)

        HStack(spacing: 10) {
            saveButton
            shareButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)

        if onReset != nil {
            Button {
                onReset?()
            } label: {
                Text("New Analysis")
                    .font(TFont.mono(11, weight: .semibold))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(Capsule().stroke(Theme.border))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
        }

        Spacer().frame(height: 130)
    }

    // MARK: - Onboarding split: the card (photo + name/score + breakdown)

    @ViewBuilder private var cardContent: some View {
        aiPhoto
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 22)

        nameScoreHeader
            .padding(.horizontal, 20)
            .padding(.bottom, 18)

        progressBar
            .padding(.horizontal, 20)
            .padding(.bottom, 18)

        compatBreakdown
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

        Spacer().frame(height: 120)
    }

    // MARK: - Onboarding split: the rest (why / brief / style / products)

    @ViewBuilder private var detailsContent: some View {
        detailsSections
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)

        Spacer().frame(height: 120)
    }

    /// Shared collapsible sections, used by both `.full` and `.details`.
    @ViewBuilder private var detailsSections: some View {
        VStack(spacing: 10) {
            if showWhy {
                section(key: "why", icon: "lightbulb.fill", title: "WHY IT WORKS FOR YOU") {
                    Text(why)
                        .font(TFont.body(13))
                        .foregroundStyle(Theme.muted)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let brief, !brief.isEmpty {
                section(key: "brief", icon: "scissors", title: "BARBER BRIEF") {
                    briefBlock(brief: brief)
                }
            }

            if !how.isEmpty {
                section(key: "how", icon: "drop.fill", title: "HOW TO STYLE") {
                    howBlock
                }
            }

            productsBlock
        }
    }

    // MARK: - Face shape badge

    private var faceShapeBadge: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 12) {
                Text(faceIcon)
                    .font(.system(size: 60))
                Text("YOUR FACE SHAPE")
                    .font(TFont.mono(10, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(Theme.muted)
                Text(faceShape)
                    .font(TFont.display(32))
                    .tracking(-1)
                    .foregroundStyle(Theme.text)
                if let desc = faceDescription, !desc.isEmpty {
                    Text(desc)
                        .font(TFont.body(13))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 30, leading: 24, bottom: 30, trailing: 24))
            .background(
                LinearGradient(colors: [Theme.gold.opacity(0.10), Theme.gold.opacity(0.02)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22).stroke(Theme.gold.opacity(0.30))
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))

            if let img = userImage {
                VStack(spacing: 4) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.gold.opacity(0.45), lineWidth: 1.5))
                    HStack(spacing: 1) {
                        Text("\(score)")
                            .font(TFont.display(11))
                            .foregroundStyle(scoreColor)
                        Text("/100")
                            .font(TFont.mono(7))
                            .foregroundStyle(Theme.muted)
                    }
                }
                .padding(14)
            }
        }
    }

    // MARK: - AI Photo

    private var aiPhoto: some View {
        Group {
            if let url = generatedImageURL {
                BeforeAfterSlider(beforeImage: userImage, afterURL: url, cornerRadius: 16)
            } else {
                // Standard sample: real before/after slider, 1:1 like the app.
                BeforeAfterSlider(
                    beforeImage: UIImage(named: "SampleBefore"),
                    afterURL: nil,
                    afterImage: UIImage(named: "SampleAfter"),
                    aspectRatio: 1,
                    cornerRadius: 16
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Name + Score header

    private var nameScoreHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(name)
                    .font(TFont.display(28))
                    .tracking(-0.6)
                    .foregroundStyle(Theme.text)
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(score)")
                        .font(TFont.display(44))
                        .tracking(-1.8)
                        .foregroundStyle(scoreGradient)
                    Text("/ 100")
                        .font(TFont.mono(9, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(Theme.muted)
                }
            }
            .padding(.bottom, 18)
            Rectangle().fill(Theme.border).frame(height: 1)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: 0x1A1A1A)).frame(height: 10)
                Capsule()
                    .fill(LinearGradient(
                        colors: [Theme.red, Theme.gold, Theme.green],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, geo.size.width * CGFloat(score) / 100), height: 10)
            }
        }
        .frame(height: 10)
    }

    // MARK: - Compatibility breakdown

    private var compatBreakdown: some View {
        VStack(spacing: 12) {
            ForEach(Array(compatRows.enumerated()), id: \.offset) { _, r in
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: r.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.muted)
                            .frame(width: 16)
                        Text(r.label)
                            .font(TFont.body(12))
                            .foregroundStyle(Theme.text)
                        Spacer(minLength: 0)
                        Text("\(r.value)")
                            .font(TFont.mono(11, weight: .semibold))
                            .foregroundStyle(Theme.text)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: 0x1A1A1A)).frame(height: 4)
                            Capsule()
                                .fill(r.value > 70 ? Theme.green : Theme.gold)
                                .frame(width: max(0, geo.size.width * CGFloat(r.value) / 100), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }
        }
    }

    // MARK: - Brief block

    private func briefBlock(brief: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(brief)
                .font(TFont.body(13))
                .foregroundStyle(Theme.muted)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                UIPasteboard.general.string = "\(name) — Barber Brief\n\n\(brief)\n\nGenerated by trimrai.com"
                briefCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { briefCopied = false }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: briefCopied ? "checkmark" : "doc.on.doc.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(briefCopied ? "COPIED" : "COPY")
                        .font(TFont.mono(10, weight: .bold))
                        .tracking(1.5)
                }
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Theme.gold.opacity(0.10))
                .overlay(Capsule().stroke(Theme.gold.opacity(0.35)))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - How block

    private var howBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(how.enumerated()), id: \.offset) { idx, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(idx + 1).")
                        .font(TFont.display(13))
                        .foregroundStyle(Theme.text)
                        .frame(minWidth: 22, alignment: .leading)
                    Text(step)
                        .font(TFont.body(13))
                        .foregroundStyle(Theme.muted)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Products

    private var productsBlock: some View {
        BasedProductsBlock(products: BasedProducts.products(for: name))
    }

    // MARK: - Save / Share

    private var saveButton: some View {
        Button {
            guard !saving, !saved else { return }
            let imageRef = response?.recommendation.storagePath
                ?? response?.recommendation.generatedImage
                ?? ""
            let breakdown: CompatibilityBreakdown = response?.recommendation.compatibilityBreakdown
                ?? CompatibilityBreakdown(
                    faceShapeMatch: compat.first(where: { $0.label == "Face Shape Match" })?.value,
                    hairTextureMatch: nil,
                    ageAppropriateness: compat.first(where: { $0.label == "Age Appropriate" })?.value,
                    maintenance: compat.first(where: { $0.label == "Maintenance" })?.value,
                    trendScore: compat.first(where: { $0.label == "Trend Score" })?.value,
                    stylingDifficulty: compat.first(where: { $0.label == "Styling Difficulty" })?.value
                )
            let savedProducts = (response?.recommendation.products ?? [])
                .map { SavedProduct(name: $0.name, purpose: $0.purpose) }
            saving = true
            Task {
                defer { saving = false }
                do {
                    try await app.saveCut(
                        kind: .analysis,
                        imageUrl: imageRef,
                        name: name,
                        score: score,
                        faceShape: faceShape,
                        whyItWorks: showWhy ? why : nil,
                        barberInstructions: brief,
                        stylingTips: how,
                        products: savedProducts.isEmpty ? nil : savedProducts,
                        compatibilityBreakdown: breakdown
                    )
                    saved = true
                } catch {
                    saveError = (error as NSError).localizedDescription
                }
            }
        } label: {
            HStack(spacing: 6) {
                if saving {
                    ProgressView().tint(Theme.gold).scaleEffect(0.7)
                } else {
                    Image(systemName: saved ? "checkmark" : "bookmark.fill")
                        .font(.system(size: 11, weight: .bold))
                }
                Text(saved ? "SAVED" : (saving ? "SAVING…" : "SAVE TO LIBRARY"))
                    .font(TFont.mono(11, weight: .bold))
                    .tracking(1.5)
            }
            .foregroundStyle(saved ? Theme.green : Theme.gold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(saved ? Theme.green.opacity(0.10) : Theme.gold.opacity(0.08))
            .overlay(Capsule().stroke(saved ? Theme.green.opacity(0.40) : Theme.gold.opacity(0.40), lineWidth: 1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(saved || saving)
    }

    private var shareButton: some View {
        ShareLink(item: shareCaption,
                  subject: Text("My haircut match: \(name)"),
                  message: Text(shareCaption)) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 11, weight: .semibold))
                Text("POST THIS")
                    .font(TFont.mono(11, weight: .bold))
                    .tracking(1.5)
            }
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(Capsule().stroke(Theme.border))
            .clipShape(Capsule())
        }
    }

    // MARK: - Section (collapsible)

    @ViewBuilder
    private func section<Content: View>(key: String, icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        let isOpen = open.contains(key)
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    if isOpen { open.remove(key) } else { open.insert(key) }
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Theme.gold.opacity(0.12))
                        Image(systemName: icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.gold)
                    }
                    .frame(width: 28, height: 28)
                    Text(title)
                        .font(TFont.mono(11, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.muted)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18))
                .background(Color(hex: 0x1A1A1A))
            }
            .buttonStyle(.plain)
            if isOpen {
                content()
                    .padding(EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: 0x0A0A0A))
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#if DEBUG
#Preview("ResultView – sample data") {
    ResultView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
#endif
