import SwiftUI

struct OBName: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double
    @Binding var value: String
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("first, what's your name?")
                        .font(TFont.display(26))
                        .tracking(-0.4)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.text)
                    Text("let's make this personal")
                        .font(TFont.body(15))
                        .foregroundStyle(Theme.muted)
                }
                .padding(.top, 36)

                TextField("", text: $value, prompt: Text("Enter your name").foregroundStyle(Theme.muted))
                    .font(TFont.body(16))
                    .foregroundStyle(Theme.text)
                    .focused($focused)
                    .padding(18)
                    .background(Color(hex: 0x1C1812))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .textContentType(.givenName)
                    .submitLabel(.next)
                    .onSubmit { if !value.trimmingCharacters(in: .whitespaces).isEmpty { onNext() } }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                if !value.trimmingCharacters(in: .whitespaces).isEmpty { onNext() }
            } label: {
                Text("Next")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(value.trimmingCharacters(in: .whitespaces).isEmpty ? Color(hex: 0x1A1610) : Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(value.trimmingCharacters(in: .whitespaces).isEmpty ? Color(hex: 0x5A544A) : Theme.gold)
                    .clipShape(Capsule())
                    .opacity(value.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear { focused = true }
    }
}
