import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if auth.isLoading {
                ProgressView().tint(Theme.gold)
            } else if !app.onboardingComplete {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainShell()
                    .transition(.opacity)
            }
            #if DEBUG
            DevNavigator()
            #endif
        }
        .animation(.easeInOut(duration: 0.25), value: app.onboardingComplete)
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn {
                Task { await app.bootstrap() }
            }
        }
    }
}

struct MainShell: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch app.navStack.last {
                case .haircolor:        ScreenWrap(title: "Hair Color") { HairColorView() }
                case .result:           ScreenWrap(title: nil) { ResultView() }
                case .pricing:          ScreenWrap(title: "Pricing") { PricingView() }
                case .settings:         ScreenWrap(title: "Settings") { SettingsView() }
                case .photoGuidelines:  ScreenWrap(title: "Photo Guidelines") { PhotoGuidelinesView() }
                case .language:         ScreenWrap(title: "Language") { LanguageView() }
                case .privacy:          ScreenWrap(title: "Privacy Policy") { PrivacyPolicyView() }
                case .terms:            ScreenWrap(title: "Terms of Service") { TermsOfServiceView() }
                case nil:
                    tabContent
                }
            }
            TabBar(active: app.activeTab) { tab in
                app.navStack.removeAll()
                app.activeTab = tab
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    @ViewBuilder private var tabContent: some View {
        switch app.activeTab {
        case .home:    HomeView()
        case .tryon:   ScreenWrap(title: "Try-On Studio") { TryOnView() }
        case .analyze: AnalyzeView()
        case .library: LibraryView()
        }
    }
}

struct ScreenWrap<Content: View>: View {
    let title: String?
    @ViewBuilder let content: () -> Content
    @EnvironmentObject var app: AppState

    var body: some View {
        VStack(spacing: 0) {
            if title != nil {
                ScreenHeader(title: title, onBack: app.navStack.isEmpty ? nil : { app.pop() })
            }
            content()
        }
    }
}

struct TabBar: View {
    let active: AppState.Tab
    let onChange: (AppState.Tab) -> Void

    struct Item { let tab: AppState.Tab; let kind: TabIcon.Kind; let label: String }
    let items: [Item] = [
        .init(tab: .home,    kind: .home,     label: "Explore"),
        .init(tab: .tryon,   kind: .wand,     label: "Try-On"),
        .init(tab: .analyze, kind: .face,     label: "Analyse"),
        .init(tab: .library, kind: .bookmark, label: "Library"),
    ]

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(items, id: \.tab) { item in
                Button {
                    onChange(item.tab)
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Theme.gold.opacity(active == item.tab ? 0.14 : 0))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Theme.gold.opacity(active == item.tab ? 0.3 : 0), lineWidth: 1)
                                )
                                .frame(width: 42, height: 30)
                            TabIcon(kind: item.kind, active: active == item.tab)
                        }
                        .frame(width: 46, height: 30)
                        Text(item.label)
                            .font(TFont.body(10, weight: active == item.tab ? .semibold : .medium))
                            .foregroundStyle(active == item.tab ? Theme.gold : Theme.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(height: 14)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: active)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 28)
        .background(Color(hex: 0x0C0906))
        .overlay(Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5), alignment: .top)
    }
}
