import SwiftUI

struct OBSplash: View {
    let onNext: () -> Void
    var onLogin: (() -> Void)? = nil
    @EnvironmentObject var app: AppState
    @State private var dragX: CGFloat = 0
    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false

    private let knob: CGFloat = 64

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Before / after reveal
                ZStack {
                    Image("Middlepart")
                        .resizable().scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                    let trackWidth = geo.size.width - 48
                    let p = trackWidth > 0 ? max(0, min(1, dragX / max(trackWidth - knob, 1))) : 0
                    Image("Fluffyhair")
                        .resizable().scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .mask(
                            HStack(spacing: 0) {
                                Spacer().frame(width: geo.size.width * p)
                                Rectangle().frame(width: geo.size.width * (1 - p))
                            }
                        )
                    Rectangle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 2)
                        .shadow(color: .white.opacity(0.45), radius: 12)
                        .offset(x: geo.size.width * (p - 0.5))
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .ignoresSafeArea()

// Bottom card
                VStack(spacing: 0) {
                    (Text("TRIM").foregroundStyle(Theme.text) + Text("R").foregroundStyle(Theme.gold))
                        .font(TFont.display(40))
                        .tracking(4)
                        .padding(.bottom, 12)
                    Text("See Your Perfect Haircut—Before You Cut")
                        .font(TFont.body(15))
                        .tracking(-0.1)
                        .foregroundStyle(Theme.text)
                        .padding(.bottom, 22)

                    slider(trackWidth: geo.size.width - 48)

                    HStack(spacing: 8) {
                        Button { showTerms = true } label: {
                            Text("Terms of Use").underline()
                        }
                        .buttonStyle(.plain)
                        Text("·")
                        Button { showPrivacy = true } label: {
                            Text("Privacy Policy").underline()
                        }
                        .buttonStyle(.plain)
                        if onLogin != nil {
                            Text("·")
                            Button { onLogin?() } label: {
                                Text("Log in").underline()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .font(TFont.body(11.5))
                    .foregroundStyle(Theme.text.opacity(0.45))
                    .padding(.top, 18)

                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)
                .background(Color(hex: 0x0A0804))
                .clipShape(.rect(topLeadingRadius: 32, topTrailingRadius: 32))
            }
        }
        .background(Color(hex: 0x0A0804).ignoresSafeArea())
        .sheet(isPresented: $showTerms) {
            NavigationStack {
                TermsOfServiceView()
                    .navigationTitle("Terms of Service")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showTerms = false }
                                .foregroundStyle(Theme.gold)
                        }
                    }
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack {
                PrivacyPolicyView()
                    .navigationTitle("Privacy Policy")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showPrivacy = false }
                                .foregroundStyle(Theme.gold)
                        }
                    }
            }
            .presentationDragIndicator(.visible)
        }
    }

    private func slider(trackWidth: CGFloat) -> some View {
        let maxX = max(trackWidth - knob, 1)
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.08))
                .overlay(Capsule().stroke(Color.white.opacity(0.12)))
                .frame(height: knob)
            Text("Slide to start")
                .font(TFont.body(15, weight: .medium))
                .tracking(0.3)
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(maxWidth: .infinity)
                .padding(.leading, 40)
            Circle()
                .fill(Color.white)
                .frame(width: knob, height: knob)
                .overlay(
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: 0x0A0804))
                )
                .shadow(color: .black.opacity(0.3), radius: 5, y: 2)
                .offset(x: dragX)
                .gesture(
                    DragGesture()
                        .onChanged { v in
                            dragX = max(0, min(maxX, v.translation.width + lastCommitted))
                        }
                        .onEnded { _ in
                            if dragX >= maxX - 2 {
                                dragX = maxX
                                onNext()
                            }
                            lastCommitted = dragX
                        }
                )
        }
    }

    @State private var lastCommitted: CGFloat = 0
}
