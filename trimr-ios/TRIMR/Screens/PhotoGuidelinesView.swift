import SwiftUI

struct PhotoGuidelinesView: View {
    private struct Tip { let icon: String; let title: String; let sub: String; let good: Bool }

    private let tips: [Tip] = [
        .init(icon: "sun.max.fill",        title: "Bright, even lighting",        sub: "Natural daylight works best. Avoid harsh shadows across your face.",              good: true),
        .init(icon: "face.smiling.inverse",title: "Face the camera directly",     sub: "Eyes level with the lens. Keep your head straight — no tilt or angle.",         good: true),
        .init(icon: "eye.fill",            title: "Neutral expression",           sub: "Relaxed face, mouth closed, no smile. Helps the AI read geometry accurately.", good: true),
        .init(icon: "person.crop.rectangle.stack.fill", title: "Head and shoulders", sub: "Framing from collarbone up. No full-body, no tight crop of just eyes.",       good: true),

        .init(icon: "eyeglasses",          title: "Remove glasses & accessories", sub: "Hats, sunglasses, heavy earrings — take them off for this photo.",             good: false),
        .init(icon: "wind",                title: "Hair out of your face",        sub: "Push fringe aside so your forehead and jawline are fully visible.",            good: false),
        .init(icon: "moon.fill",           title: "Avoid dim rooms",              sub: "Low light blurs facial landmarks and produces weaker recommendations.",        good: false),
        .init(icon: "person.2.fill",       title: "Just you in frame",            sub: "No filters, no other people. Makeup is fine, filters distort the analysis.",  good: false),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                heroCard
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 22)

                SectionTitle(title: "Do this")
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                VStack(spacing: 10) {
                    ForEach(tips.filter { $0.good }.indices, id: \.self) { i in
                        tipRow(tips.filter { $0.good }[i], good: true)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 22)

                SectionTitle(title: "Avoid this")
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                VStack(spacing: 10) {
                    ForEach(tips.filter { !$0.good }.indices, id: \.self) { i in
                        tipRow(tips.filter { !$0.good }[i], good: false)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)

                privacyNote
                    .padding(.horizontal, 16)
                    .padding(.bottom, 110)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.gold.opacity(0.12))
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Theme.gold)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 6) {
                Text("One good photo =\nsharp recommendations.")
                    .font(TFont.display(22))
                    .tracking(-0.4)
                    .foregroundStyle(Theme.text)
                    .lineSpacing(2)
                Text("Trimr reads your face geometry — lighting and framing directly affect the cuts you're shown. Follow these tips for the best result.")
                    .font(TFont.body(13))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(4)
            }
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 22, trailing: 20))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .topTrailing) {
                Theme.card
                Circle().fill(Theme.gold.opacity(0.15)).frame(width: 180, height: 180)
                    .blur(radius: 80).offset(x: 70, y: -80)
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.gold.opacity(0.3), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func tipRow(_ t: Tip, good: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(good ? Theme.green.opacity(0.14) : Theme.red.opacity(0.14))
                Image(systemName: good ? "checkmark" : "xmark")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(good ? Theme.green : Theme.red)
            }
            .frame(width: 24, height: 24)

            Image(systemName: t.icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.text)
                .frame(width: 32)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(t.title)
                    .font(TFont.body(14, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Text(t.sub)
                    .font(TFont.body(12))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
        .padding(EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var privacyNote: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Theme.gold.opacity(0.14))
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.gold)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text("Your photo is private")
                    .font(TFont.body(13, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Text("Processed on secure servers, never sold, never used to train.")
                    .font(TFont.body(11))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
