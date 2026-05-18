import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var profile: ProfileStore

    @State private var showSignOut = false
    @State private var showDelete = false
    @State private var isRestoring = false
    @State private var showRestoreResult = false
    @State private var restoreResultMessage = ""

    private struct Row: Identifiable {
        let id = UUID()
        let icon: String
        let tint: Color
        let title: String
        let sub: String?
        let action: (() -> Void)?
        let danger: Bool
    }

    private var rows: [Row] {
        [
            .init(
                icon: "questionmark.circle.fill", tint: Color(hex: 0x7A6DE0),
                title: "Photo Guidelines", sub: "Learn what makes a good photo",
                action: { app.push(.photoGuidelines) }, danger: false
            ),
            .init(
                icon: "creditcard.fill", tint: Theme.gold,
                title: "Buy Looks", sub: "Top up your credits",
                action: { app.push(.pricing) }, danger: false
            ),
            .init(
                icon: "arrow.clockwise.circle.fill", tint: Color(hex: 0x3DB5B0),
                title: "Restore Purchases", sub: isRestoring ? "Restoring…" : "Restore previous purchases",
                action: { restorePurchases() }, danger: false
            ),
            .init(
                icon: "globe", tint: Color(hex: 0x3DB5B0),
                title: "Language", sub: "🇺🇸 English",
                action: { app.push(.language) }, danger: false
            ),
            .init(
                icon: "lock.shield.fill", tint: Theme.green,
                title: "Privacy Policy", sub: "Read our privacy policy",
                action: { app.push(.privacy) }, danger: false
            ),
            .init(
                icon: "doc.text.fill", tint: Color(hex: 0x7A6DE0),
                title: "Terms of Service", sub: "Read our terms of service",
                action: { app.push(.terms) }, danger: false
            ),
            .init(
                icon: "star.fill", tint: Theme.rose,
                title: "Rate Us", sub: "Love TRIMR? Leave us a review!",
                action: { openAppStoreReview() }, danger: false
            ),
            .init(
                icon: "rectangle.portrait.and.arrow.right", tint: Theme.muted,
                title: "Sign Out", sub: "Sign out of your account",
                action: { showSignOut = true }, danger: false
            ),
            .init(
                icon: "trash.fill", tint: Theme.red,
                title: "Delete Account", sub: "Permanently delete your account",
                action: { showDelete = true }, danger: true
            ),
        ]
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                profileHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 18)

                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { idx, row in
                        settingsRow(row)
                        if idx < rows.count - 1 {
                            Rectangle().fill(Theme.border).frame(height: 0.5)
                                .padding(.leading, 76)
                        }
                    }
                }
                .background(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 16)

                Text("TRIMR · v1.0.0")
                    .font(TFont.mono(9, weight: .medium)).tracking(2)
                    .foregroundStyle(Theme.muted2)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)

                Spacer().frame(height: 110)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .alert("Restore Purchases", isPresented: $showRestoreResult) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreResultMessage)
        }
        .confirmationDialog(
            "Sign out of TRIMR?",
            isPresented: $showSignOut,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) { signOut() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your saved cuts stay on this device.")
        }
        .confirmationDialog(
            "Delete your account?",
            isPresented: $showDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Permanently", role: .destructive) { deleteAccount() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your account, saved cuts, and analysis history will be removed. This cannot be undone.")
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.primaryGlow)
                Text(initialsLetter)
                    .font(TFont.display(22))
                    .foregroundStyle(.white)
            }
            .frame(width: 56, height: 56)
            .shadow(color: Theme.primary.opacity(0.35), radius: 14, y: 6)

            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(TFont.display(17))
                    .tracking(-0.2)
                    .foregroundStyle(Theme.text)
                Text(emailDisplay)
                    .font(TFont.body(12))
                    .foregroundStyle(Theme.muted)
            }

            Spacer(minLength: 0)

            if profile.isPro {
                Button { app.push(.pricing) } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("PRO")
                            .font(TFont.mono(10, weight: .bold)).tracking(1.5)
                    }
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Theme.goldGlow)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Button { app.push(.pricing) } label: {
                    Text("\(profile.lookCredits) LOOKS")
                        .font(TFont.mono(10, weight: .bold)).tracking(1.5)
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .overlay(Capsule().stroke(Theme.borderStrong))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func settingsRow(_ r: Row) -> some View {
        Button {
            r.action?()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(r.tint.opacity(0.18))
                    Image(systemName: r.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(r.tint)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 3) {
                    Text(r.title)
                        .font(TFont.body(15, weight: .semibold))
                        .foregroundStyle(r.danger ? Theme.red : Theme.text)
                    if let sub = r.sub {
                        Text(sub)
                            .font(TFont.body(12))
                            .foregroundStyle(Theme.muted)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                if !r.danger {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.muted2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Actions

    private func openAppStoreReview() {
        // TODO: replace REPLACE_WITH_APPLE_APP_ID with the numeric App ID from App Store Connect
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/idREPLACE_WITH_APPLE_APP_ID?action=write-review") else { return }
        UIApplication.shared.open(url)
    }

    private func signOut() {
        Task { await app.signOut() }
    }

    private func deleteAccount() {
        Task { await app.deleteAccount() }
    }

    /// StoreKit-based restore (independent of RevenueCat). `StoreKitManager`
    /// re-redeems entitlements via `validate-apple-iap`, so any look packs that
    /// never reached the backend are re-credited.
    private func restorePurchases() {
        guard !isRestoring else { return }
        isRestoring = true
        Task {
            await app.store.restorePurchases()
            await app.profile.load()
            isRestoring = false
            restoreResultMessage = app.store.purchaseError
                ?? app.store.restoreMessage
                ?? "Restore complete."
            showRestoreResult = true
        }
    }

    private var emailDisplay: String {
        profile.profile?.email ?? auth.session?.user.email ?? "—"
    }

    private var displayName: String {
        if let name = profile.profile?.name, !name.isEmpty { return name }
        if !app.userName.isEmpty { return app.userName }
        if let email = auth.session?.user.email { return email.components(separatedBy: "@").first ?? "User" }
        return "User"
    }

    private var initialsLetter: String {
        let s = displayName.trimmingCharacters(in: .whitespaces)
        return s.first.map { String($0).uppercased() } ?? "S"
    }
}
