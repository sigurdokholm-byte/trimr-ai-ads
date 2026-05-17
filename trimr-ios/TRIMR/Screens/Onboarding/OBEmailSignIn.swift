import SwiftUI

struct OBEmailSignIn: View {
    let onDone: () -> Void

    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) private var dismiss

    enum Mode: String, CaseIterable { case signIn = "Sign In", signUp = "Create Account" }
    @State private var mode: Mode

    init(initialMode: Mode = .signUp, onDone: @escaping () -> Void) {
        self.onDone = onDone
        _mode = State(initialValue: initialMode)
    }

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var inFlight = false
    @FocusState private var focus: Field?

    enum Field { case email, password }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                modePicker
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 24)

                VStack(alignment: .leading, spacing: 14) {
                    labelled("EMAIL") {
                        TextField("you@domain.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focus, equals: .email)
                    }
                    labelled("PASSWORD") {
                        SecureField("••••••••", text: $password)
                            .textContentType(mode == .signUp ? .newPassword : .password)
                            .focused($focus, equals: .password)
                            .onSubmit(submit)
                    }
                }
                .padding(.horizontal, 20)

                if let err = auth.lastError {
                    Text(err)
                        .font(TFont.body(12))
                        .foregroundStyle(Theme.red)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                }

                Spacer()

                Button(action: submit) {
                    HStack(spacing: 8) {
                        if inFlight {
                            ProgressView().tint(Color(hex: 0x0A0804))
                        }
                        Text(inFlight ? "Please wait…" : mode.rawValue)
                            .font(TFont.body(16, weight: .bold))
                    }
                    .foregroundStyle(canSubmit ? Color(hex: 0x0A0804) : Color(hex: 0x1A1610))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(canSubmit ? AnyShapeStyle(Theme.goldGlow) : AnyShapeStyle(Color(hex: 0x5A544A)))
                    .clipShape(Capsule())
                    .opacity(canSubmit ? 1 : 0.6)
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(mode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.muted)
                }
            }
            .onAppear { focus = .email; auth.lastError = nil }
        }
        .preferredColorScheme(.dark)
    }

    private var cleanedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var canSubmit: Bool {
        !inFlight && isValidEmail(cleanedEmail) && password.count >= 6
    }

    private func isValidEmail(_ s: String) -> Bool {
        // Conservative RFC-ish check — matches what Supabase GoTrue accepts.
        let pattern = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return s.range(of: pattern, options: .regularExpression) != nil
    }

    private func submit() {
        guard canSubmit else { return }
        inFlight = true
        auth.lastError = nil
        Task {
            let ok: Bool
            let e = cleanedEmail
            switch mode {
            case .signIn: ok = await auth.signInWithEmail(email: e, password: password)
            case .signUp: ok = await auth.signUpWithEmail(email: e, password: password)
            }
            inFlight = false
            if ok { onDone() }
        }
    }

    @ViewBuilder
    private func labelled<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(TFont.mono(9, weight: .semibold)).tracking(1.8)
                .foregroundStyle(Theme.muted)
            content()
                .font(TFont.body(15))
                .foregroundStyle(Theme.text)
                .padding(16)
                .background(Color(hex: 0x1C1812))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(Mode.allCases, id: \.self) { m in
                let active = mode == m
                Button { mode = m; auth.lastError = nil } label: {
                    Text(m.rawValue)
                        .font(TFont.body(13, weight: active ? .bold : .medium))
                        .foregroundStyle(active ? Color(hex: 0x0A0804) : Theme.muted)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(active ? AnyShapeStyle(Theme.goldGlow) : AnyShapeStyle(Color.clear))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.card)
        .overlay(Capsule().stroke(Theme.border))
        .clipShape(Capsule())
    }
}
