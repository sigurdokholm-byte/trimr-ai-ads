import SwiftUI

struct LibraryDetailView: View {
    let cut: SavedCut
    var onDelete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var open: Set<String> = []
    @State private var briefCopied = false
    @State private var confirmDelete = false

    private var score: Int { cut.score ?? 0 }

    private var faceIcon: String {
        switch (cut.faceShape ?? "").lowercased() {
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

    private var compatRows: [(icon: String, label: String, value: Int)] {
        guard let b = cut.compatibilityBreakdown else { return [] }
        var rows: [(String, String, Int)] = []
        if let v = b.faceShapeMatch     { rows.append(("brain.head.profile", "Face Shape Match", v)) }
        if let v = b.hairTextureMatch   { rows.append(("waveform.path",      "Hair Texture",     v)) }
        if let v = b.ageAppropriateness { rows.append(("person.fill",        "Age Appropriate",  v)) }
        if let v = b.maintenance        { rows.append(("wrench.adjustable.fill", "Maintenance",  v)) }
        if let v = b.trendScore         { rows.append(("flame.fill",         "Trend Score",      v)) }
        if let v = b.stylingDifficulty  { rows.append(("scissors",           "Styling Difficulty", v)) }
        return rows
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if cut.faceShape != nil {
                    faceShapeBadge
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                }

                aiPhoto
                    .padding(.horizontal, 20)
                    .padding(.bottom, 22)

                nameScoreHeader
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)

                if score > 0 {
                    progressBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                }

                if !compatRows.isEmpty {
                    compatBreakdown
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }

                VStack(spacing: 10) {
                    if let why = cut.whyItWorks, !why.isEmpty {
                        section(key: "why", icon: "lightbulb.fill", title: "WHY IT WORKS FOR YOU") {
                            Text(why)
                                .font(TFont.body(13))
                                .foregroundStyle(Theme.muted)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if let brief = cut.barberInstructions, !brief.isEmpty {
                        section(key: "brief", icon: "scissors", title: "BARBER BRIEF") {
                            briefBlock(brief: brief)
                        }
                    }

                    if let tips = cut.stylingTips, !tips.isEmpty {
                        section(key: "how", icon: "drop.fill", title: "HOW TO STYLE") {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(Array(tips.enumerated()), id: \.offset) { idx, step in
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
                    }

                    if let products = cut.products, !products.isEmpty {
                        productsBlock(products: products)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)

                if onDelete != nil {
                    Button {
                        confirmDelete = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Remove from library")
                                .font(TFont.body(13, weight: .semibold))
                        }
                        .foregroundStyle(Theme.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.red.opacity(0.10))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.red.opacity(0.30)))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }

                Spacer().frame(height: 60)
            }
        }
        .background(Theme.bgDeep.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 10) {
                if !cut.image.isEmpty, let url = URL(string: cut.image) {
                    SavePhotoButton(source: .remote(url), size: 36)
                }
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.text)
                        .frame(width: 36, height: 36)
                        .background(Theme.card)
                        .overlay(Circle().stroke(Theme.border))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(EdgeInsets(top: 12, leading: 0, bottom: 0, trailing: 16))
        }
        .alert("Remove this save?", isPresented: $confirmDelete) {
            Button("Remove", role: .destructive) {
                onDelete?()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete \(cut.name) from your library. You can always save it again later.")
        }
    }

    private var faceShapeBadge: some View {
        VStack(spacing: 12) {
            Text(faceIcon)
                .font(.system(size: 60))
            Text("FACE SHAPE")
                .font(TFont.mono(10, weight: .medium))
                .tracking(3)
                .foregroundStyle(Theme.muted)
            Text(cut.faceShape?.capitalized ?? "")
                .font(TFont.display(32))
                .tracking(-1)
                .foregroundStyle(Theme.text)
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 30, leading: 24, bottom: 30, trailing: 24))
        .background(
            LinearGradient(colors: [Theme.gold.opacity(0.10), Theme.gold.opacity(0.02)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.gold.opacity(0.30)))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var aiPhoto: some View {
        Group {
            if !cut.image.isEmpty, let url = URL(string: cut.image) {
                CachedAsyncImage(url: url)
            } else {
                Rectangle().fill(Color(hex: 0x0A0A0A))
                    .overlay(Image(systemName: "photo").foregroundStyle(Theme.muted))
            }
        }
        .frame(maxWidth: 400)
        .frame(height: 320)
        .clipped()
        .background(Color(hex: 0x0A0A0A))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border))
        .frame(maxWidth: .infinity)
    }

    private var nameScoreHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(cut.name)
                    .font(TFont.display(28))
                    .tracking(-0.6)
                    .foregroundStyle(Theme.text)
                Spacer(minLength: 12)
                if score > 0 {
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

    private func briefBlock(brief: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(brief)
                .font(TFont.body(13))
                .foregroundStyle(Theme.muted)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                UIPasteboard.general.string = "\(cut.name) — Barber Brief\n\n\(brief)\n\nGenerated by trimrai.com"
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

    private func productsBlock(products: [SavedProduct]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                Text("RECOMMENDED PRODUCTS")
                    .font(TFont.mono(10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.text)
            }
            .padding(.bottom, 14)

            VStack(spacing: 10) {
                ForEach(Array(products.enumerated()), id: \.offset) { _, p in
                    HStack(spacing: 12) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.gold)
                            .frame(width: 52, height: 52)
                            .background(Color(hex: 0x0F0B07))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(p.name)
                                .font(TFont.body(12, weight: .semibold))
                                .foregroundStyle(Theme.text)
                                .lineLimit(2)
                            Text(p.purpose)
                                .font(TFont.body(10))
                                .foregroundStyle(Theme.muted)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(EdgeInsets(top: 16, leading: 14, bottom: 16, trailing: 14))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0x0A0A0A))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

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

struct LibraryFullscreenImage: View {
    let imageUrl: String
    let title: String
    var onDelete: (() -> Void)? = nil

    @EnvironmentObject var tryOnPhoto: TryOnPhotoStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let url = URL(string: imageUrl), tryOnPhoto.photo != nil {
                BeforeAfterSlider(
                    beforeImage: tryOnPhoto.photo,
                    afterURL: url,
                    aspectRatio: 1.0,
                    cornerRadius: 18
                )
                .padding(.horizontal, 16)
            } else if let url = URL(string: imageUrl) {
                CachedAsyncImage(url: url, contentMode: .fit)
                    .padding(.horizontal, 16)
            }
        }
        .overlay(alignment: .topLeading) {
            Text(title)
                .font(TFont.body(13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.leading, 20)
                .padding(.top, 12)
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 10) {
                if let url = URL(string: imageUrl), !imageUrl.isEmpty {
                    SavePhotoButton(source: .remote(url), size: 36)
                }
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 16)
            .padding(.top, 12)
        }
        .overlay(alignment: .bottom) {
            if onDelete != nil {
                Button {
                    confirmDelete = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Remove from library")
                            .font(TFont.body(13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .background(Color.red.opacity(0.55))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.18)))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 36)
            }
        }
        .alert("Remove this save?", isPresented: $confirmDelete) {
            Button("Remove", role: .destructive) {
                onDelete?()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete \(title) from your library. You can always save it again later.")
        }
    }
}
