import SwiftUI
import RevenueCat

@main
struct TRIMRApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var tryOnPhoto = TryOnPhotoStore()
    @StateObject private var rcManager = RevenueCatManager()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Observer mode (.myApp): RevenueCat drives the paywall / purchase /
        // restore UI but does NOT finish StoreKit transactions. The app-wide
        // StoreKitManager listener finishes each one only after
        // `validate-apple-iap` credits the profile, preserving the
        // "unfinished transaction replays on next launch" guarantee. RC's own
        // finishing (.revenueCat mode) would silently drop a paid purchase if
        // the backend credit call failed.
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .info
        #endif
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: RevenueCatConfig.apiKey)
                .with(purchasesAreCompletedBy: .myApp, storeKitVersion: .storeKit2)
                .build()
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(appState.auth)
                .environmentObject(appState.profile)
                .environmentObject(appState.store)
                .environmentObject(rcManager)
                .environmentObject(tryOnPhoto)
                .preferredColorScheme(.dark)
                .task {
                    await appState.bootstrap()
                    // Tie RC's anonymous user to the Supabase user id so the
                    // dashboard groups events per real account.
                    if let uid = appState.auth.userId {
                        _ = try? await Purchases.shared.logIn(uid.uuidString)
                        await rcManager.refresh()
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    // Don't burn network roundtrips polling profile while the user
                    // isn't even looking at the app.
                    switch newPhase {
                    case .active:
                        if appState.auth.isSignedIn { appState.profile.startPolling() }
                    case .background, .inactive:
                        appState.profile.stopPolling()
                    @unknown default:
                        break
                    }
                }
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @AppStorage("trimr_user_name") var userName: String = ""
    @AppStorage("trimr_onboarded") var onboardingComplete: Bool = false

    @Published var activeTab: Tab = .home
    @Published var navStack: [Screen] = []
    @Published var savedCuts: [SavedCut] = []

    private var loadCutsTask: Task<Void, Never>?
    private var savedCutsLoadedOnce: Bool = false

    let auth = AuthManager()
    let profile = ProfileStore()
    /// App-lifetime StoreKit 2 manager. Owning it here (not per-paywall-view)
    /// keeps its `Transaction.updates` listener alive for the whole session so
    /// purchases made through RevenueCat's paywall are still redeemed with the
    /// `validate-apple-iap` backend even after the paywall is dismissed.
    let store = StoreKitManager()

    enum Tab: String, CaseIterable {
        case home, tryon, analyze, library
    }

    enum Screen: Hashable {
        case haircolor
        case result
        case pricing
        case settings
        case photoGuidelines
        case language
        case privacy
        case terms
    }

    /// Whether onboarding is complete. Set in `OnboardingView.finish()` either when
    /// the user signs in or taps "Maybe later" on the post-payment signup step.
    /// Anonymous sessions exist before this is true, so we cannot key onboarding
    /// completion off `auth.isSignedIn` anymore.
    var onboarded: Bool { onboardingComplete }

    func push(_ screen: Screen) { navStack.append(screen) }
    func pop() { _ = navStack.popLast() }
    func popToRoot() { navStack.removeAll() }

    // MARK: - Bootstrap

    func bootstrap() async {
        // Wait for the restored session to settle.
        while auth.isLoading { try? await Task.sleep(nanoseconds: 50_000_000) }
        // Ensure we always have a session — anonymous if no one has signed in yet.
        // This lets onboarding (analyze, IAP) work pre-signin; the pre-signin
        // anon profile is later merged into the real account by
        // `AuthManager.attemptMerge` after sign-in completes.
        if !auth.isSignedIn {
            _ = await auth.signInAnonymouslyIfNeeded()
        }
        // Crash-recovery: if a previous launch signed in but the merge call
        // never landed (network drop, app killed), retry now before we render
        // the dashboard so credits show up.
        if auth.isSignedIn && !auth.isAnonymous {
            await auth.attemptMerge()
        }
        if auth.isSignedIn {
            await profile.load()
            profile.startPolling()
            await loadSavedCuts()
        }
    }

    /// Pulls fresh profile + library data immediately after a sign-in completes.
    ///
    /// `RootView`'s `onChange(of: auth.isSignedIn)` can't cover this: onboarding
    /// always opens an anonymous session first, so signing in is an anon → real
    /// swap where `isSignedIn` stays `true` the whole time — the handler never
    /// fires. Without an explicit pull here, freshly-merged look credits only
    /// surfaced on the next 60s poll tick, so the home screen sat on 0 looks for
    /// up to a minute after login. The anon → real credit merge is already
    /// awaited inside `AuthManager.signInWith*`, so the profiles row is correct
    /// server-side by the time we get here.
    func refreshAfterSignIn() async {
        // Safety net: retries the merge only if it didn't land inside the
        // sign-in call (e.g. network drop). No-op once the snapshot is cleared.
        await auth.attemptMerge()
        await profile.load()
        profile.startPolling()
        // Saved cuts were last loaded for the anonymous session; force a reload
        // so the real account's library shows up too.
        await loadSavedCuts(force: true)
    }

    // MARK: - Saved cuts (server-backed; in-memory cache)

    /// Loads saved cuts once per session unless `force == true`. Coalesces
    /// concurrent callers onto the same in-flight `Task`, so navigating Library
    /// → Detail → Library doesn't re-fetch and re-sign URLs every appearance.
    /// `.refreshable` and write-through callers (saveCut, removeSavedCut) pass
    /// `force: true` to skip the cache.
    func loadSavedCuts(force: Bool = false) async {
        guard let uid = auth.userId else { return }

        if let existing = loadCutsTask {
            await existing.value
            return
        }
        if !force && savedCutsLoadedOnce { return }

        let task = Task { [uid] in
            do {
                let rows: [SavedHaircutRow] = try await Supa.client
                    .from("saved_haircuts")
                    .select()
                    .eq("user_id", value: uid.uuidString)
                    .order("created_at", ascending: false)
                    .execute()
                    .value

                // Resolve every row's image URL in parallel: signed-URL roundtrips
                // dominate load time and they're independent, so a TaskGroup turns
                // N×latency into 1×.
                let cuts = await withTaskGroup(of: (Int, SavedCut).self) { group in
                    for (index, row) in rows.enumerated() {
                        group.addTask { (index, await Self.resolve(row: row)) }
                    }
                    var byIndex: [(Int, SavedCut)] = []
                    for await pair in group { byIndex.append(pair) }
                    return byIndex.sorted { $0.0 < $1.0 }.map(\.1)
                }
                savedCuts = cuts
                savedCutsLoadedOnce = true
            } catch {
                print("[loadSavedCuts] Supabase select failed:", error.localizedDescription)
                // Keep in-memory cache; surface nothing.
            }
        }
        loadCutsTask = task
        await task.value
        loadCutsTask = nil
    }

    /// Resolves one row's `generated_image` to a URL string the UI can load directly.
    /// Pass-through for HTTP(S) and `data:` URIs (legacy saves stored the image inline
    /// as base64; `URLSession`/`UIImage` decode `data:` natively). Storage paths are
    /// signed for one hour. `loadSavedCuts` re-runs on every Library appearance, so
    /// expiry isn't user-visible.
    private static func resolve(row: SavedHaircutRow) async -> SavedCut {
        let raw = row.generatedImage ?? ""
        let resolvedImage: String
        let storagePath: String?
        if raw.isEmpty {
            resolvedImage = ""
            storagePath = nil
        } else if raw.hasPrefix("http://") || raw.hasPrefix("https://") || raw.hasPrefix("data:") {
            resolvedImage = raw
            storagePath = nil
        } else {
            storagePath = raw
            do {
                let signed = try await Supa.client.storage
                    .from("hairstyle-previews")
                    .createSignedURL(path: raw, expiresIn: 3600)
                resolvedImage = signed.absoluteString
            } catch {
                print("[loadSavedCuts] createSignedURL failed for path '\(raw)':", error.localizedDescription)
                resolvedImage = ""
            }
        }

        return SavedCut(
            id: row.id.uuidString,
            name: row.haircutName,
            image: resolvedImage,
            storagePath: storagePath,
            score: row.score,
            faceShape: row.faceShape,
            whyItWorks: row.whyItWorks,
            barberInstructions: row.barberInstructions,
            stylingTips: row.stylingTips,
            products: row.products,
            compatibilityBreakdown: row.compatibilityBreakdown,
            createdAt: row.createdAt
        )
    }

    /// Persist a save via the `save-to-library` edge function. The function uploads
    /// the FAL image to Supabase Storage so it doesn't expire, then inserts the row.
    /// Throws on auth failure, network failure, or non-2xx response so callers can
    /// surface the real reason instead of silently doing nothing.
    func saveCut(
        kind: SavedKind,
        imageUrl: String,
        name: String,
        score: Int? = nil,
        faceShape: String? = nil,
        whyItWorks: String? = nil,
        barberInstructions: String? = nil,
        stylingTips: [String]? = nil,
        products: [SavedProduct]? = nil,
        compatibilityBreakdown: CompatibilityBreakdown? = nil
    ) async throws {
        guard let token = auth.session?.accessToken else {
            throw NSError(domain: "save-to-library", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Please sign in again to save."])
        }
        var req = URLRequest(url: TrimrConfig.supabaseURL
            .appendingPathComponent("functions/v1/save-to-library"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(TrimrConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        let body = SaveToLibraryRequest(
            kind: kind.rawValue,
            imageUrl: imageUrl.isEmpty ? nil : imageUrl,
            haircutName: name,
            score: score,
            faceShape: faceShape,
            whyItWorks: whyItWorks,
            barberInstructions: barberInstructions,
            stylingTips: stylingTips,
            products: products,
            compatibilityBreakdown: compatibilityBreakdown
        )
        req.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: req)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            let raw = String(data: data, encoding: .utf8) ?? ""
            var msg = "Save failed (HTTP \(code))"
            if let parsed = try? JSONDecoder().decode([String: String].self, from: data),
               let serverMsg = parsed["error"], !serverMsg.isEmpty {
                msg = "\(serverMsg) (HTTP \(code))"
            } else if !raw.isEmpty {
                msg = "\(String(raw.prefix(200))) (HTTP \(code))"
            }
            print("[save-to-library] failed:", msg)
            throw NSError(domain: "save-to-library", code: code,
                          userInfo: [NSLocalizedDescriptionKey: msg])
        }
        await loadSavedCuts(force: true)
    }

    func removeSavedCut(_ cut: SavedCut) {
        guard let uid = auth.userId, let rowId = UUID(uuidString: cut.id) else { return }
        savedCuts.removeAll { $0.id == cut.id }
        Task {
            _ = try? await Supa.client
                .from("saved_haircuts")
                .delete()
                .eq("user_id", value: uid.uuidString)
                .eq("id", value: rowId.uuidString)
                .execute()
        }
    }

    func isSaved(name: String) -> Bool {
        savedCuts.contains { $0.name == name }
    }

    // MARK: - Sign out flows

    func signOut() async {
        await auth.signOut()
        profile.clear()
        savedCuts.removeAll()
        savedCutsLoadedOnce = false
        popToRoot()
        activeTab = .home
        // Send the user back to the top of onboarding so the next login is a
        // fresh start. AppStorage flips drive RootView, which swaps MainShell
        // for OnboardingView; OnboardingView's @StateObject re-instantiates so
        // we don't carry over half-filled quiz answers.
        userName = ""
        onboardingComplete = false
        // Re-establish an anonymous session so the onboarding flow (analyze,
        // paywall) can still call its edge functions before the user signs in.
        await bootstrap()
    }

    func deleteAccount() async {
        _ = await auth.deleteAccount()
        profile.clear()
        savedCuts.removeAll()
        savedCutsLoadedOnce = false
        popToRoot()
        activeTab = .home
        userName = ""
        onboardingComplete = false
        await bootstrap()
    }
}
