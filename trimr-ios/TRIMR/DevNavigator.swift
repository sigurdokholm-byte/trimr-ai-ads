#if DEBUG
import SwiftUI

extension Notification.Name {
    static let devJumpOnboardingStep = Notification.Name("trimr.dev.jumpOnboardingStep")
}

struct DevNavigator: View {
    @EnvironmentObject var app: AppState
    @AppStorage("trimr_dev_navigator_hidden") private var hidden: Bool = false
    @State private var showSheet: Bool = false

    var body: some View {
        if !hidden {
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showSheet = true
                    } label: {
                        Text("DEV")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .tracking(1.4)
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.yellow)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.45), radius: 6, y: 2)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                            hidden = true
                        }
                    )
                    .padding(.trailing, 12)
                }
                .padding(.top, 4)
                Spacer()
            }
            .ignoresSafeArea(.keyboard)
            .sheet(isPresented: $showSheet) {
                DevNavigatorSheet(isPresented: $showSheet)
                    .environmentObject(app)
            }
        }
    }
}

private struct DevNavigatorSheet: View {
    @EnvironmentObject var app: AppState
    @Binding var isPresented: Bool
    @AppStorage("trimr_onboarded") private var onboarded: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section("Onboarding") {
                    Button {
                        onboarded = false
                        app.popToRoot()
                        isPresented = false
                    } label: {
                        Label("Replay onboarding (reset)", systemImage: "arrow.counterclockwise")
                    }
                    NavigationLink {
                        OnboardingStepJumpList(isPresented: $isPresented)
                    } label: {
                        Label("Jump to step…", systemImage: "list.bullet")
                    }
                    Button {
                        onboarded = true
                        isPresented = false
                    } label: {
                        Label("Skip to app", systemImage: "forward.fill")
                    }
                }

                Section("App tabs") {
                    ForEach(AppState.Tab.allCases, id: \.self) { tab in
                        Button {
                            onboarded = true
                            app.popToRoot()
                            app.activeTab = tab
                            isPresented = false
                        } label: {
                            Label(tabLabel(tab), systemImage: tabIcon(tab))
                        }
                    }
                }

                Section("Screens") {
                    ForEach(allScreens(), id: \.0) { item in
                        Button {
                            onboarded = true
                            app.popToRoot()
                            app.push(item.1)
                            isPresented = false
                        } label: {
                            Label(item.0, systemImage: "rectangle.portrait")
                        }
                    }
                }

                Section {
                    Button("Hide DEV pill (long-press to restore)") {
                        UserDefaults.standard.set(true, forKey: "trimr_dev_navigator_hidden")
                        isPresented = false
                    }
                    .foregroundStyle(.red)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Dev Navigator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }

    private func tabLabel(_ tab: AppState.Tab) -> String {
        switch tab {
        case .home: return "Explore"
        case .tryon: return "Try-On"
        case .analyze: return "Analyse"
        case .library: return "Library"
        }
    }

    private func tabIcon(_ tab: AppState.Tab) -> String {
        switch tab {
        case .home: return "house.fill"
        case .tryon: return "wand.and.stars"
        case .analyze: return "face.smiling"
        case .library: return "bookmark.fill"
        }
    }

    private func allScreens() -> [(String, AppState.Screen)] {
        [
            ("Hair Color",       .haircolor),
            ("Result",           .result),
            ("Pricing",          .pricing),
            ("Settings",         .settings),
            ("Photo Guidelines", .photoGuidelines),
            ("Language",         .language),
            ("Privacy",          .privacy),
            ("Terms",            .terms),
        ]
    }
}

private struct OnboardingStepJumpList: View {
    @EnvironmentObject var app: AppState
    @Binding var isPresented: Bool
    @AppStorage("trimr_onboarded") private var onboarded: Bool = false

    private var steps: [(OnboardingStep, String)] {
        [
            (.splash,           "splash"),
            (.problem,          "problem"),
            (.solution,         "solution"),
            (.name,             "name"),
            (.age,              "age"),
            (.satisfaction,     "satisfaction"),
            (.bombshell,        "bombshell"),
            (.bridge,           "bridge"),
            (.hairTypeQuiz,     "hairTypeQuiz"),
            (.reflection1,      "reflection1"),
            (.styleGoalQuiz,    "styleGoalQuiz"),
            (.productCountQuiz, "productCountQuiz"),
            (.intent,           "intent"),
            (.reflection2,      "reflection2"),
            (.reviews,          "reviews"),
            (.chart,            "chart"),
            (.photoCapture,     "photoCapture"),
            (.analyzing,        "analyzing"),
            (.freeReveal,       "freeReveal"),
            (.day1,             "day1"),
            (.personalizing,    "personalizing"),
            (.summary,          "summary"),
            (.commitment,       "commitment"),
            (.snapshot,         "snapshot"),
            (.notifications,    "notifications"),
            (.socialProof,      "socialProof"),
            (.paywall,          "paywall"),
            (.fullReveal,       "fullReveal"),
            (.signIn,           "signIn"),
        ]
    }

    var body: some View {
        List {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, item in
                Button {
                    onboarded = false
                    app.popToRoot()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        NotificationCenter.default.post(
                            name: .devJumpOnboardingStep,
                            object: item.0
                        )
                    }
                    isPresented = false
                } label: {
                    HStack {
                        Text("\(index + 1)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 24, alignment: .trailing)
                        Text(item.1)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
        }
        .navigationTitle("Jump to step")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Restore-pill helper

/// Tap anywhere with three fingers to bring the DEV pill back if you've hidden it.
struct DevNavigatorRestoreOverlay: View {
    @AppStorage("trimr_dev_navigator_hidden") private var hidden: Bool = false

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture(count: 3)
                    .onEnded { _ in
                        hidden = false
                    }
            )
            .allowsHitTesting(false) // disabled by default to not block the app
    }
}
#endif
