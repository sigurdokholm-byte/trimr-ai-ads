import SwiftUI

struct HomeView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var profile: ProfileStore
    @State private var bannerIdx: Int = 0
    @State private var autoTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 18)

                DailyDashboardCard()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)

                SectionTitle(
                    title: "More tools"
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                actionGrid
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)

                SectionTitle(
                    title: "Trending cuts",
                    trailing: AnyView(LinkChip(label: "See all") { app.activeTab = .tryon })
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                trendingRail

                Spacer().frame(height: 110)
            }
        }
        .background(Theme.bgDeep.ignoresSafeArea())
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            (Text("TRIM").foregroundStyle(Theme.text) + Text("R").foregroundStyle(Theme.gold))
                .font(TFont.display(24))
                .tracking(3)
            Spacer()
            PlanPill(isPro: profile.isPro, looksLeft: profile.isPro ? nil : profile.lookCredits) {
                app.push(.pricing)
            }
            Button {
                app.push(.settings)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .frame(width: 38, height: 38)
                    .background(Theme.card)
                    .overlay(Circle().stroke(Theme.border))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Hero Carousel

    private var heroCarousel: some View {
        VStack(spacing: 12) {
            TabView(selection: $bannerIdx) {
                ForEach(Array(CatalogData.banners.enumerated()), id: \.offset) { i, b in
                    heroCard(b).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 26))

            // Pill pagination below the photos
            HStack(spacing: 6) {
                ForEach(0..<CatalogData.banners.count, id: \.self) { i in
                    Capsule()
                        .fill(i == bannerIdx ? Theme.text : Theme.text.opacity(0.28))
                        .frame(width: i == bannerIdx ? 20 : 6, height: 6)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) { bannerIdx = i }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: bannerIdx)
        }
        .onReceive(autoTimer) { _ in
            withAnimation(.easeInOut(duration: 0.45)) {
                bannerIdx = (bannerIdx + 1) % CatalogData.banners.count
            }
        }
    }

    private func heroCard(_ b: BannerItem) -> some View {
        Button { route(b.target) } label: {
            Image(b.image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()
                .accessibilityLabel(Text(b.title))
        }
        .buttonStyle(.plain)
        .frame(height: 200)
    }

    private func eyebrow(for target: BannerItem.BannerTarget) -> String {
        switch target {
        case .analyze: return "AI FACE ANALYSIS"
        case .tryon: return "TRY-ON STUDIO"
        case .haircolor: return "COLOR STUDIO"
        }
    }

    private func route(_ target: BannerItem.BannerTarget) {
        switch target {
        case .analyze: app.activeTab = .analyze
        case .tryon: app.activeTab = .tryon
        case .haircolor: app.push(.haircolor)
        }
    }

    // MARK: Action Grid — 3 color-coded cards

    private var actionGrid: some View {
        VStack(spacing: 10) {
            ActionCard(
                title: "Analyse my face",
                icon: "faceid",
                accent: Theme.gold,
                accentGradient: Theme.goldGlow,
                prominent: true
            ) { app.activeTab = .analyze }

            HStack(spacing: 10) {
                ActionCard(
                    title: "Try a style",
                    icon: "wand.and.stars",
                    accent: Theme.gold,
                    accentGradient: Theme.goldGlow,
                    prominent: false
                ) { app.activeTab = .tryon }

                ActionCard(
                    title: "Try a color",
                    icon: "paintpalette.fill",
                    accent: Theme.gold,
                    accentGradient: Theme.goldGlow,
                    prominent: false
                ) { app.push(.haircolor) }
            }
        }
    }

    // MARK: Trending rail

    private var trendingRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CatalogData.tryOnCuts.prefix(8)) { cut in
                    ZStack(alignment: .bottomLeading) {
                        Image(cut.image).resizable().scaledToFill()
                            .frame(width: 150, height: 200)
                            .clipped()
                        LinearGradient(colors: [.clear, .clear, Color(hex: 0x080604).opacity(0.9)],
                                       startPoint: .top, endPoint: .bottom)
                        Text(cut.name)
                            .font(TFont.body(12, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(12)
                    }
                    .frame(width: 150, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .onTapGesture { app.activeTab = .tryon }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Action Card (reusable)

private struct ActionCard: View {
    var eyebrow: String? = nil
    let title: String
    var sub: String? = nil
    let icon: String
    let accent: Color
    let accentGradient: LinearGradient
    let prominent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if prominent { prominentBody } else { compactBody }
            }
        }
        .buttonStyle(.plain)
    }

    private var prominentBody: some View {
        HStack(spacing: 16) {
            iconBadge(size: 54, iconSize: 22)
            VStack(alignment: .leading, spacing: 5) {
                if let eyebrow {
                    Text(eyebrow).labelMono(size: 9, tracking: 2).foregroundStyle(accent)
                }
                Text(title)
                    .font(TFont.display(19))
                    .tracking(-0.3)
                    .foregroundStyle(Theme.text)
                if let sub {
                    Text(sub)
                        .font(TFont.body(12))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(accent)
                .padding(12)
                .background(accent.opacity(0.12))
                .clipShape(Circle())
        }
        .padding(EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 16))
        .frame(maxWidth: .infinity)
        .background(
            ZStack(alignment: .topTrailing) {
                Theme.card
                Circle()
                    .fill(accent.opacity(0.22))
                    .frame(width: 180, height: 180)
                    .blur(radius: 70)
                    .offset(x: 60, y: -80)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(accent.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var compactBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            iconBadge(size: 44, iconSize: 18)
            VStack(alignment: .leading, spacing: 3) {
                if let eyebrow {
                    Text(eyebrow).labelMono(size: 9, tracking: 1.8).foregroundStyle(accent)
                }
                Text(title)
                    .font(TFont.display(15))
                    .foregroundStyle(Theme.text)
                if let sub {
                    Text(sub)
                        .font(TFont.body(11))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
        .background(
            ZStack(alignment: .topTrailing) {
                Theme.card
                Circle()
                    .fill(accent.opacity(0.25))
                    .frame(width: 130, height: 130)
                    .blur(radius: 55)
                    .offset(x: 40, y: -60)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func iconBadge(size: CGFloat, iconSize: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(accentGradient)
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(Color(hex: 0x0A0804))
        }
        .frame(width: size, height: size)
        .shadow(color: accent.opacity(0.4), radius: 14, y: 6)
    }
}
