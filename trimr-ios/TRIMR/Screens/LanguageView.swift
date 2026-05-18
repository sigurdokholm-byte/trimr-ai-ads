import SwiftUI

struct LanguageView: View {
    @AppStorage("trimr_language") private var selected: String = "en"

    private struct Lang { let code: String; let flag: String; let label: String; let native: String; let enabled: Bool }

    private let languages: [Lang] = [
        .init(code: "en", flag: "🇺🇸", label: "English",    native: "English",    enabled: true),
        .init(code: "es", flag: "🇪🇸", label: "Spanish",    native: "Español",    enabled: false),
        .init(code: "fr", flag: "🇫🇷", label: "French",     native: "Français",   enabled: false),
        .init(code: "de", flag: "🇩🇪", label: "German",     native: "Deutsch",    enabled: false),
        .init(code: "it", flag: "🇮🇹", label: "Italian",    native: "Italiano",   enabled: false),
        .init(code: "pt", flag: "🇵🇹", label: "Portuguese", native: "Português",  enabled: false),
        .init(code: "nl", flag: "🇳🇱", label: "Dutch",      native: "Nederlands", enabled: false),
        .init(code: "da", flag: "🇩🇰", label: "Danish",     native: "Dansk",      enabled: false),
        .init(code: "sv", flag: "🇸🇪", label: "Swedish",    native: "Svenska",    enabled: false),
        .init(code: "ja", flag: "🇯🇵", label: "Japanese",   native: "日本語",      enabled: false),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Pick the language you want the app to use. More coming soon.")
                    .font(TFont.body(13))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 18)

                VStack(spacing: 0) {
                    ForEach(Array(languages.enumerated()), id: \.offset) { idx, lang in
                        row(lang)
                        if idx < languages.count - 1 {
                            Rectangle().fill(Theme.border).frame(height: 0.5)
                                .padding(.leading, 58)
                        }
                    }
                }
                .background(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 16)

                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.gold.opacity(0.7))
                    Text("Other languages ship in a future update.")
                        .font(TFont.mono(10)).tracking(1.2)
                        .foregroundStyle(Theme.muted)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 110)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func row(_ lang: Lang) -> some View {
        let isSelected = selected == lang.code
        return Button {
            guard lang.enabled else { return }
            selected = lang.code
        } label: {
            HStack(spacing: 14) {
                Text(lang.flag)
                    .font(.system(size: 22))
                    .frame(width: 32, height: 32)
                    .background(Theme.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.border))

                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.label)
                        .font(TFont.body(14, weight: .semibold))
                        .foregroundStyle(lang.enabled ? Theme.text : Theme.muted)
                    Text(lang.native)
                        .font(TFont.body(11))
                        .foregroundStyle(Theme.muted)
                }

                Spacer(minLength: 0)

                if !lang.enabled {
                    Text("SOON")
                        .font(TFont.mono(9, weight: .semibold)).tracking(1.4)
                        .foregroundStyle(Theme.muted2)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .overlay(Capsule().stroke(Theme.border))
                } else if isSelected {
                    ZStack {
                        Circle().fill(Theme.goldGlow)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(Color(hex: 0x0A0804))
                    }
                    .frame(width: 22, height: 22)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .contentShape(Rectangle())
            .opacity(lang.enabled ? 1 : 0.55)
        }
        .buttonStyle(.plain)
    }
}
