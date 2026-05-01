import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var state = OnboardingState()
    @State private var analyzeError: String? = nil

    private func finish() {
        app.userName = state.name
        app.onboardingComplete = true
    }

    var body: some View {
        ZStack {
            switch state.step {
            case .splash:
                OBSplash(onNext: state.goNext)

            // MARK: Act I — Introduction
            case .hello:
                OBHello(onNext: state.goNext)

            case .problem:
                OBProblem(onNext: state.goNext, onBack: state.goBack, progress: state.step.progress)

            case .solution:
                OBSolution(onNext: state.goNext, onBack: state.goBack, progress: state.step.progress)

            case .name:
                OBName(onNext: state.goNext, onBack: state.goBack, progress: state.step.progress, value: $state.name)

            case .age:
                OBAge(onNext: state.goNext, onBack: state.goBack, progress: state.step.progress, value: $state.age)

            case .satisfaction:
                OBSatisfaction(onNext: state.goNext, onBack: state.goBack, progress: state.step.progress, value: $state.satisfaction)

            case .bombshell:
                OBBombshell(
                    onNext: state.goNext,
                    progress: state.step.progress,
                    firstImpressions: state.firstImpressionsLeft,
                    firstStyleGoal: state.styleGoals.first?.rawValue
                )

            case .bridge:
                OBBridge(name: state.name, onNext: state.goNext, onBack: state.goBack, progress: state.step.progress)

            case .hairTypeQuiz:
                OBHairTypeQuiz(onNext: state.goNext, onBack: state.goBack, progress: state.step.progress, value: $state.hairType)

            case .reflection1:
                OBReflection1(hairType: state.hairType, onNext: state.goNext, onBack: state.goBack, progress: state.step.progress)

            case .styleGoalQuiz:
                OBStyleGoalQuiz(onNext: state.goNext, onBack: state.goBack, progress: state.step.progress, value: $state.styleGoals)

            case .productCountQuiz:
                OBProductCountQuiz(onNext: state.goNext, onBack: state.goBack, progress: state.step.progress, value: $state.productCount)

            case .intent:
                OBGoal(onNext: state.goNext, onBack: state.goBack, progress: state.step.progress, value: $state.intent)

            case .reflection2:
                OBReflection2(state: state, onNext: state.goNext, onBack: state.goBack, progress: state.step.progress)

            case .reviews:
                OBReviews(onNext: state.goNext, onBack: state.goBack, progress: state.step.progress)

            case .chart:
                OBChart(onNext: state.goNext, onBack: state.goBack, progress: state.step.progress)

            // MARK: Act II — Climax
            case .photoCapture:
                OBPhotoCapture(onNext: state.goNext, onBack: state.goBack, progress: state.step.progress, capturedImage: $state.capturedImage)

            case .analyzing:
                if let img = state.capturedImage {
                    if let err = analyzeError {
                        analyzeFailed(message: err)
                    } else {
                        OBAnalyzing(
                            onComplete: { resp in
                                state.analysis = resp
                                state.step = .freeReveal
                            },
                            onError: { msg in analyzeError = msg },
                            image: img,
                            preferences: buildPreferences()
                        )
                    }
                } else {
                    Color.clear.onAppear { state.step = .photoCapture }
                }

            case .freeReveal:
                OBFreeReveal(
                    name: state.name,
                    analysis: state.analysis,
                    userImage: state.capturedImage,
                    onContinue: { state.step = .day1 }
                )

            case .day1:
                OBDay1(
                    name: state.name,
                    onContinue: { state.step = .personalizing }
                )

            // MARK: Act III — Conclusion
            case .personalizing:
                OBPersonalizing(onComplete: { state.step = .summary })

            case .summary:
                OBSummary(state: state, onNext: state.goNext, onBack: state.goBack, progress: state.step.progress)

            case .commitment:
                OBCommitment(
                    onNext: state.goNext,
                    onBack: state.goBack,
                    progress: state.step.progress,
                    value: $state.commitmentLevel
                )

            case .snapshot:
                OBSnapshot(state: state, onNext: state.goNext, onBack: state.goBack, progress: state.step.progress)

            case .notifications:
                OBNotifications(
                    onNext: state.goNext,
                    onBack: state.goBack,
                    progress: state.step.progress,
                    granted: $state.notificationsGranted
                )

            case .socialProof:
                OBSocialProof(onNext: state.goNext, onBack: state.goBack, progress: state.step.progress)

            case .paywall:
                OBPaywall(
                    name: state.name,
                    onClose: { state.step = .freeReveal },
                    onPurchased: { pid in
                        state.purchasedPackProductId = pid.rawValue
                        state.step = .fullReveal
                    }
                )

            case .fullReveal:
                if let analysis = state.analysis {
                    OBFullReveal(
                        name: state.name,
                        analysis: analysis,
                        userImage: state.capturedImage,
                        onContinue: { state.step = .signIn }
                    )
                } else {
                    Color.clear.onAppear { state.step = .photoCapture }
                }

            case .signIn:
                OBSignIn(onDone: finish, allowSkip: true)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: state.step)
        #if DEBUG
        .onReceive(NotificationCenter.default.publisher(for: .devJumpOnboardingStep)) { note in
            if let step = note.object as? OnboardingStep {
                state.step = step
            }
        }
        #endif
    }

    private func buildPreferences() -> [String: String] {
        var prefs: [String: String] = [:]
        if let face = state.faceShape { prefs["faceShape"] = face.rawValue }
        if let hair = state.hairType { prefs["hairType"] = hair.rawValue }
        if let pc = state.productCount { prefs["productCount"] = pc.rawValue }
        if !state.styleGoals.isEmpty {
            prefs["styleGoals"] = state.styleGoals.map(\.rawValue).sorted().joined(separator: ",")
        }
        return prefs
    }

    private func analyzeFailed(message: String) -> some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Theme.gold)
            Text("Something went wrong")
                .font(TFont.display(22))
                .foregroundStyle(Theme.text)
            Text(message)
                .font(TFont.body(13))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button {
                analyzeError = nil
            } label: {
                Text("Try Again")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.gold).clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
    }
}

struct OBProductCountQuiz: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double
    @Binding var value: ProductCount?

    private struct Option { let count: ProductCount; let title: String }
    private let options: [Option] = [
        .init(count: .none,       title: "None"),
        .init(count: .one,        title: "1 product"),
        .init(count: .twoOrThree, title: "2–3 products"),
        .init(count: .fourPlus,   title: "4 or more"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 28) {
                Text("How many hair products\ndo you currently use?")
                    .font(TFont.display(24))
                    .tracking(-0.4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 36)

                VStack(spacing: 12) {
                    ForEach(options, id: \.count) { opt in
                        let selected = value == opt.count
                        Button { value = opt.count } label: {
                            Text(opt.title)
                                .font(TFont.body(15, weight: .medium))
                                .foregroundStyle(selected ? Theme.gold : Theme.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(selected ? Theme.gold.opacity(0.08) : Color(hex: 0x1C1812))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(selected ? Theme.gold.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1.5)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button { if value != nil { onNext() } } label: {
                Text("Next")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(value == nil ? Color(hex: 0x1A1610) : Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(value == nil ? Color(hex: 0x5A544A) : Theme.gold)
                    .clipShape(Capsule())
                    .opacity(value == nil ? 0.6 : 1)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
    }
}

struct OBHeader: View {
    let progress: Double
    let onBack: () -> Void
    var showBack: Bool = true

    var body: some View {
        HStack(spacing: 14) {
            if showBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.gold)
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(Theme.gold.opacity(0.55), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 34, height: 34)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: 0x2A2520))
                    Capsule()
                        .fill(Theme.goldGlow)
                        .frame(width: geo.size.width * progress)
                        .shadow(color: Theme.gold.opacity(0.35), radius: 8, y: 0)
                }
            }
            .frame(height: 6)
            .animation(.easeOut(duration: 0.35), value: progress)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}
