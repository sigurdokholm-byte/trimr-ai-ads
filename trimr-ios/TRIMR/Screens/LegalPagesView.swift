import SwiftUI

// MARK: - Shared legal doc layout

struct LegalSection {
    let heading: String
    let body: String
}

private struct LegalDocView: View {
    let icon: String
    let title: String
    let summary: String
    let lastUpdated: String
    let sections: [LegalSection]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                headerCard
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 22)

                VStack(spacing: 14) {
                    ForEach(Array(sections.enumerated()), id: \.offset) { idx, s in
                        sectionCard(index: idx + 1, section: s)
                    }
                }
                .padding(.horizontal, 16)

                footerNote
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 110)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.gold.opacity(0.14))
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.gold)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(TFont.display(22))
                    .tracking(-0.4)
                    .foregroundStyle(Theme.text)
                Text(summary)
                    .font(TFont.body(13))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(4)
            }

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 9, weight: .semibold))
                Text("LAST UPDATED · \(lastUpdated)")
                    .font(TFont.mono(9, weight: .semibold)).tracking(1.6)
            }
            .foregroundStyle(Theme.muted2)
            .padding(.top, 4)
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .topTrailing) {
                Theme.card
                Circle().fill(Theme.gold.opacity(0.12)).frame(width: 160, height: 160)
                    .blur(radius: 70).offset(x: 60, y: -70)
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.border))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func sectionCard(index: Int, section: LegalSection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(String(format: "%02d", index))
                    .font(TFont.mono(10, weight: .bold)).tracking(1.5)
                    .foregroundStyle(Theme.gold)
                    .frame(width: 28, height: 22)
                    .background(Theme.gold.opacity(0.1))
                    .overlay(Capsule().stroke(Theme.gold.opacity(0.3)))
                    .clipShape(Capsule())
                Text(section.heading.uppercased())
                    .font(TFont.mono(10, weight: .bold)).tracking(2)
                    .foregroundStyle(Theme.text)
                Spacer(minLength: 0)
            }

            Text(section.body)
                .font(TFont.body(13))
                .foregroundStyle(Theme.muted)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 18, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var footerNote: some View {
        VStack(spacing: 6) {
            Text("Questions? Contact hello@trimrai.com")
                .font(TFont.body(12, weight: .medium))
                .foregroundStyle(Theme.text)
            Text("TRIMR · Apex Labs Ltd · London, UK")
                .font(TFont.mono(9)).tracking(1.4)
                .foregroundStyle(Theme.muted2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Privacy Policy

struct PrivacyPolicyView: View {
    var body: some View {
        LegalDocView(
            icon: "lock.shield.fill",
            title: "Privacy Policy",
            summary: "Short version: your photo and personal data belong to you. We never sell them. We only use them to give you the service you signed up for.",
            lastUpdated: "MAY 6, 2026",
            sections: [
                .init(heading: "What we collect",
                      body: "Your email address, a display name if you provide one, and photos you upload for analysis. We do not run any third-party analytics SDK in the app."),
                .init(heading: "How we use your photo",
                      body: "Your photo is processed by our AI to detect your face shape and generate style previews. It is stored encrypted on our servers for as long as your account exists so you can revisit your results. You can delete any photo from your Library at any time."),
                .init(heading: "What we never do",
                      body: "We never sell your data. We never use your photos or face data to train AI models. We never share your images with third parties unless legally required."),
                .init(heading: "Third parties",
                      body: "We use Apple (auth, billing), Supabase (hosting, database, storage), Resend (email), OpenRouter (AI face analysis), and FAL AI (AI image generation) to run the service. Your photo is sent to OpenRouter and FAL AI only as part of generating your hairstyle preview. They process data only on our instructions, under their respective privacy terms and signed Data Processing Agreements. All in-app purchases on iOS are billed by Apple."),
                .init(heading: "Your rights",
                      body: "You can delete your account at any time from Settings. To request a copy or correction of your data, email hello@trimrai.com. GDPR and UK DPA subject-access and erasure requests are honoured within 30 days."),
                .init(heading: "Children",
                      body: "Trimr is built for users 16 and older. If you believe a user under 16 has signed up, email hello@trimrai.com and we'll remove the account."),
                .init(heading: "Changes to this policy",
                      body: "We'll notify you in-app at least 14 days before any material change. Continued use after that date constitutes acceptance of the updated policy."),
            ]
        )
    }
}

// MARK: - Terms of Service

struct TermsOfServiceView: View {
    var body: some View {
        LegalDocView(
            icon: "doc.text.fill",
            title: "Terms of Service",
            summary: "The rules for using Trimr. Be respectful, use the app as intended, and understand that AI recommendations are guidance — not a guarantee.",
            lastUpdated: "MAY 6, 2026",
            sections: [
                .init(heading: "Your account",
                      body: "You must be 16 or older to use Trimr. Keep your login credentials secure — you're responsible for activity on your account. One account per person."),
                .init(heading: "Using the service",
                      body: "Trimr is a hairstyle recommendation and preview tool. You agree to only upload photos of yourself or photos you have explicit permission to use. Don't upload anything illegal, abusive, or sexually explicit."),
                .init(heading: "AI recommendations",
                      body: "Our recommendations are generated by machine learning and are not professional styling advice. Results may vary from what you see in real life. Always consult a qualified barber or stylist for your actual haircut."),
                .init(heading: "Credit packs & billing",
                      body: "Looks credits are sold as one-time consumable in-app purchases through Apple. Payment is charged to your Apple ID at the time of purchase. There are no subscriptions, no auto-renewals, and no recurring charges. Credits never expire and are used up as you generate looks."),
                .init(heading: "Refunds",
                      body: "Refund requests are handled by Apple through reportaproblem.apple.com. We do not process refunds directly. Unused credits from a refunded purchase are removed from your account."),
                .init(heading: "Intellectual property",
                      body: "Trimr's design, code, and AI models belong to Apex Labs Ltd. Photos and content you upload remain yours. By uploading, you grant us a limited licence to process and display them back to you."),
                .init(heading: "Limitation of liability",
                      body: "The app is provided \"as is\". To the maximum extent allowed by law, we're not liable for indirect damages, lost profits, or bad haircut decisions. Our total liability is capped at what you've paid us in the last 12 months."),
                .init(heading: "Governing law",
                      body: "These terms are governed by the laws of England and Wales. Any disputes will be handled in the courts of London, UK."),
            ]
        )
    }
}
