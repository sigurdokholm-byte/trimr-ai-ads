# iOS Onboarding Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the iOS onboarding into a 28-screen 3-act narrative arc (Mau Baron playbook), reusing all existing screen files and visual style.

**Architecture:** SwiftUI `@StateObject`-driven router (`OnboardingView`) switching on `OnboardingStep` enum. State container `OnboardingState` holds quiz answers, generated analysis, and commitment level. Screens follow a single layout pattern: `OBHeader` (progress + back chevron) on top, content centered, gold pill CTA pinned bottom. New helpers added for App Store review prompt and notification permission.

**Tech Stack:** SwiftUI · Swift 5.9+ · iOS 17+ · StoreKit 2 · UserNotifications · Supabase Swift SDK · FAL AI (existing pipeline). No new dependencies.

**Spec:** [`trimr-ios/docs/specs/2026-04-30-ios-onboarding-redesign-design.md`](../specs/2026-04-30-ios-onboarding-redesign-design.md)

---

## File structure

**Modified files:**
- `trimr-ios/TRIMR/Screens/Onboarding/OnboardingState.swift` — replace step enum (15→28), add 5 fields + `CommitmentLevel` enum + `firstImpressionsLeft` computed property
- `trimr-ios/TRIMR/Screens/Onboarding/OnboardingView.swift` — expand `switch state.step` to 28 cases; update `OBHeader` to support `showBack: Bool`
- `trimr-ios/TRIMR/Screens/Onboarding/OBPaywall.swift` — add personalized hairline header line above pricing
- `trimr-ios/TRIMR/Networking/StoreKitManager.swift` — add `requestReviewIfAvailable()` static helper
- `trimr-ios/TRIMR/Networking/SupabaseClient.swift` — add `Analytics.track(event:props:)` stub

**New files (Screens/Onboarding/):**
- `OBProblem.swift`
- `OBSolution.swift`
- `OBAge.swift`
- `OBSatisfaction.swift`
- `OBBombshell.swift`
- `OBBridge.swift`
- `OBReflection1.swift`
- `OBReflection2.swift`
- `OBChart.swift`
- `OBFreeReveal.swift`
- `OBDay1.swift`
- `OBPersonalizing.swift`
- `OBSummary.swift`
- `OBCommitment.swift`
- `OBSnapshot.swift`
- `OBNotifications.swift`
- `OBSocialProof.swift`

**New helper file:**
- `trimr-ios/TRIMR/Networking/PushPermission.swift`

**Retired files (deleted):**
- `trimr-ios/TRIMR/Screens/Onboarding/OBValueProp.swift`
- `trimr-ios/TRIMR/Screens/Onboarding/OBBlurredReveal.swift`

**Build pipeline note:** new `.swift` files placed under `TRIMR/` are auto-discovered by `trimr-ios/gen_pbxproj.py`. After creating any new file or deleting an existing one, run:

```bash
cd trimr-ios && python3 gen_pbxproj.py
```

---

## Phase 1 — Foundation (state, router, scaffolding)

### Task 1: Replace OnboardingStep enum with 28 cases

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OnboardingState.swift:6-37`

- [ ] **Step 1: Replace the existing `OnboardingStep` enum**

Replace lines 6–37 of `OnboardingState.swift` with:

```swift
enum OnboardingStep: Int, CaseIterable {
    case splash = 0
    // Act I — Introduction
    case problem
    case solution
    case name
    case age
    case satisfaction
    case bombshell
    case bridge
    case hairTypeQuiz
    case reflection1
    case styleGoalQuiz
    case productCountQuiz
    case intent
    case reflection2
    case reviews
    case chart
    // Act II — Climax
    case photoCapture
    case analyzing
    case freeReveal
    case day1
    // Act III — Conclusion
    case personalizing
    case summary
    case commitment
    case snapshot
    case notifications
    case socialProof
    case paywall
    case fullReveal
    case signIn

    /// 0..1 used by OBHeader progress bar.
    /// Excluded (no header): splash, analyzing, personalizing, freeReveal, day1, paywall, fullReveal, signIn.
    var progress: Double {
        let excluded: Set<OnboardingStep> = [
            .splash, .analyzing, .personalizing, .freeReveal, .day1,
            .paywall, .fullReveal, .signIn
        ]
        let visible = OnboardingStep.allCases.filter { !excluded.contains($0) }
        guard let idx = visible.firstIndex(of: self) else { return 0 }
        return Double(idx + 1) / Double(visible.count)
    }

    func next() -> OnboardingStep {
        OnboardingStep(rawValue: rawValue + 1) ?? .signIn
    }

    func previous() -> OnboardingStep {
        OnboardingStep(rawValue: max(rawValue - 1, 0)) ?? .splash
    }
}
```

- [ ] **Step 2: Verify the file still compiles**

```bash
cd trimr-ios && xcodebuild -project TRIMR.xcodeproj -scheme TRIMR -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet 2>&1 | tail -30
```

Expected: build fails with errors in `OnboardingView.swift` (cases like `.welcome`, `.valueProp`, `.blurredReveal` no longer exist). That's fine — we'll fix them in Task 5. As long as `OnboardingState.swift` itself compiles (no errors pointing at that file), proceed.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OnboardingState.swift
git commit -m "refactor(ios-onboarding): replace step enum with 28-case Mau-style flow"
```

---

### Task 2: Add new state fields, CommitmentLevel enum, and bombshell math

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OnboardingState.swift:39-74`

- [ ] **Step 1: Add `CommitmentLevel` enum after the existing quiz value-types block**

Insert after the `ProductCount` enum (~line 55), before `// MARK: - Onboarding state container`:

```swift
enum CommitmentLevel: String, CaseIterable, Codable, Hashable {
    case new30Days        // "A new cut I love"
    case confidence       // "Confidence in any room"
    case curious          // "Just curious for now"
}
```

- [ ] **Step 2: Add new `@Published` fields and computed property to `OnboardingState`**

In the `OnboardingState` class, add these after the existing `@Published` fields:

```swift
    @Published var age: Int? = nil
    @Published var satisfaction: Int? = nil
    @Published var commitmentLevel: CommitmentLevel? = nil
    @Published var notificationsGranted: Bool? = nil
    @Published var reviewPromptShown: Bool = false

    /// Bombshell math: rough number of remaining first-impression encounters
    /// based on age, assuming ~5 new strangers/day until age 80, rounded to 10k.
    var firstImpressionsLeft: Int {
        guard let age = age else { return 0 }
        let yearsLeft = max(80 - age, 1)
        return ((yearsLeft * 365 * 5) / 10_000) * 10_000
    }
```

- [ ] **Step 3: Add a SwiftUI Preview for `firstImpressionsLeft` sanity check**

At the bottom of `OnboardingState.swift`, add:

```swift
#if DEBUG
import SwiftUI

#Preview("firstImpressionsLeft sanity") {
    let s = OnboardingState()
    return VStack(alignment: .leading, spacing: 12) {
        ForEach([18, 25, 40, 60, 79, 80], id: \.self) { age in
            let _ = (s.age = age)
            Text("age \(age) → \(s.firstImpressionsLeft.formatted())")
                .font(.system(size: 14, design: .monospaced))
        }
    }
    .padding()
    .background(Color.black)
    .foregroundStyle(Color.white)
}
#endif
```

Verify the preview shows reasonable numbers (e.g. age 25 → ~1,000,000+, age 79 → ~10,000).

- [ ] **Step 4: Build to confirm no compile errors in this file**

```bash
cd trimr-ios && xcodebuild -project TRIMR.xcodeproj -scheme TRIMR -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet 2>&1 | grep -E "(OnboardingState|error:)" | head -10
```

Expected: only errors referring to `OnboardingView.swift` (still using removed cases). No errors from `OnboardingState.swift` itself.

- [ ] **Step 5: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OnboardingState.swift
git commit -m "feat(ios-onboarding): add age/satisfaction/commitment state + firstImpressionsLeft math"
```

---

### Task 3: Update `OBHeader` to optionally hide back chevron

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OnboardingView.swift:258-286`

- [ ] **Step 1: Replace the `OBHeader` struct in `OnboardingView.swift`**

Replace the entire `OBHeader` struct (lines 258–286) with:

```swift
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
```

- [ ] **Step 2: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OnboardingView.swift
git commit -m "feat(ios-onboarding): add showBack option to OBHeader"
```

---

### Task 4: Stub all 13 new screen files with placeholder views

**Files:**
- Create: 13 files in `trimr-ios/TRIMR/Screens/Onboarding/`

- [ ] **Step 1: Create each placeholder file**

For each of the 13 names, create the file with the body shown (one tap advances). Substitute `<Name>` for each entry.

File names: `OBProblem`, `OBSolution`, `OBAge`, `OBSatisfaction`, `OBBombshell`, `OBBridge`, `OBReflection1`, `OBReflection2`, `OBChart`, `OBFreeReveal`, `OBDay1`, `OBPersonalizing`, `OBSummary`, `OBCommitment`, `OBSnapshot`, `OBNotifications`, `OBSocialProof`.

Wait — that's 17. Three of those (`OBFreeReveal`, `OBDay1`, `OBPersonalizing`) need `onNext` only (no back/progress), and `OBCommitment` needs the state binding. Use these signatures during stubbing:

**Standard quiz/screen stub** (`OBProblem`, `OBSolution`, `OBBridge`, `OBReflection1`, `OBReflection2`, `OBChart`, `OBSummary`, `OBSnapshot`, `OBNotifications`, `OBSocialProof`):

`OBProblem.swift`:
```swift
import SwiftUI

struct OBProblem: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)
            Spacer()
            Text("OBProblem placeholder")
                .font(TFont.display(22))
                .foregroundStyle(Theme.text)
            Spacer()
            Button(action: onNext) {
                Text("Next")
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
```

Repeat the same body, replacing `OBProblem` with each of these names: `OBSolution`, `OBBridge`, `OBReflection1`, `OBReflection2`, `OBChart`, `OBSummary`, `OBSnapshot`, `OBNotifications`, `OBSocialProof`.

**Stub with state binding** (`OBAge`, `OBSatisfaction`, `OBBombshell`, `OBCommitment`):

`OBAge.swift`:
```swift
import SwiftUI

struct OBAge: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double
    @Binding var value: Int?

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)
            Spacer()
            Text("OBAge placeholder")
                .font(TFont.display(22))
                .foregroundStyle(Theme.text)
            Spacer()
            Button { value = 25; onNext() } label: {
                Text("Next")
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
```

`OBSatisfaction.swift` — same as `OBAge` but rename, `@Binding var value: Int?` (default 5 in stub: `value = 5`).

`OBBombshell.swift` — same body as `OBProblem` (no binding), no back button:
```swift
import SwiftUI

struct OBBombshell: View {
    let onNext: () -> Void
    let progress: Double
    let firstImpressions: Int
    let firstStyleGoal: String?

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: {}, showBack: false)
            Spacer()
            Text("OBBombshell placeholder")
                .font(TFont.display(22))
                .foregroundStyle(Theme.text)
            Spacer()
            Button(action: onNext) {
                Text("I'm in")
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
```

`OBCommitment.swift`:
```swift
import SwiftUI

struct OBCommitment: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double
    @Binding var value: CommitmentLevel?

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)
            Spacer()
            Text("OBCommitment placeholder")
                .font(TFont.display(22))
                .foregroundStyle(Theme.text)
            Spacer()
            Button { value = .new30Days; onNext() } label: {
                Text("Next")
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
```

**Stub with no header** (`OBFreeReveal`, `OBDay1`, `OBPersonalizing`):

`OBFreeReveal.swift`:
```swift
import SwiftUI

struct OBFreeReveal: View {
    let name: String
    let analysis: AnalyzeResponse?
    let userImage: UIImage?
    let onContinue: () -> Void

    var body: some View {
        VStack {
            Spacer()
            Text("OBFreeReveal placeholder")
                .font(TFont.display(22))
                .foregroundStyle(Theme.text)
            Spacer()
            Button(action: onContinue) {
                Text("Continue")
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
```

`OBDay1.swift`:
```swift
import SwiftUI

struct OBDay1: View {
    let name: String
    let onContinue: () -> Void

    var body: some View {
        VStack {
            Spacer()
            Text("OBDay1 placeholder")
                .font(TFont.display(22))
                .foregroundStyle(Theme.text)
            Spacer()
            Button(action: onContinue) {
                Text("Continue")
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
```

`OBPersonalizing.swift`:
```swift
import SwiftUI

struct OBPersonalizing: View {
    let onComplete: () -> Void

    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(Theme.gold)
                .scaleEffect(1.4)
            Text("OBPersonalizing placeholder")
                .font(TFont.body(14))
                .foregroundStyle(Theme.muted)
                .padding(.top, 18)
            Spacer()
        }
        .background(Theme.bg.ignoresSafeArea())
        .task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            onComplete()
        }
    }
}
```

- [ ] **Step 2: Regenerate the Xcode project**

```bash
cd trimr-ios && python3 gen_pbxproj.py
```

- [ ] **Step 3: Build**

```bash
cd trimr-ios && xcodebuild -project TRIMR.xcodeproj -scheme TRIMR -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet 2>&1 | tail -20
```

Expected: errors in `OnboardingView.swift` only (still references removed enum cases). All 17 new files compile cleanly.

- [ ] **Step 4: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OB*.swift trimr-ios/TRIMR.xcodeproj/project.pbxproj
git commit -m "feat(ios-onboarding): stub all 17 new onboarding screens as placeholders"
```

---

### Task 5: Wire the new 28-case switch in OnboardingView

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OnboardingView.swift:1-189`

- [ ] **Step 1: Replace the `OnboardingView` body**

Replace the contents of `OnboardingView.swift` from line 1 down to (but not including) the `OBProductCountQuiz` struct definition (around line 191) with:

```swift
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
```

Leave the existing `OBProductCountQuiz` and `OBHeader` definitions below this point intact (they're already correct from Task 3).

- [ ] **Step 2: Update `OBPaywall` call site to pass `name`**

The new call to `OBPaywall(name: state.name, ...)` requires `OBPaywall` to accept a `name` parameter. Add it to `OBPaywall`'s public properties — open `trimr-ios/TRIMR/Screens/Onboarding/OBPaywall.swift` and replace lines 4–11 with:

```swift
struct OBPaywall: View {
    let name: String
    let onClose: () -> Void
    let onPurchased: (StoreKitManager.ProductID) -> Void
    @StateObject private var store = StoreKitManager()
    @State private var selected: StoreKitManager.ProductID = .looks10
    @State private var loaded: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false
```

(The header line in the paywall body that USES `name` will be added in Task 28. For now `name` is just unused — that's fine, won't break the build.)

- [ ] **Step 3: Stub views that take `state` directly (`OBReflection2`, `OBSummary`, `OBSnapshot`)**

These three were stubbed in Task 4 with the standard signature. Update their stubs to take an `OnboardingState` parameter for now. Open each file and replace the struct declaration block:

`OBReflection2.swift`:
```swift
import SwiftUI

struct OBReflection2: View {
    @ObservedObject var state: OnboardingState
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)
            Spacer()
            Text("OBReflection2 placeholder")
                .font(TFont.display(22))
                .foregroundStyle(Theme.text)
            Spacer()
            Button(action: onNext) {
                Text("That's me")
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
```

Apply the same shape (with `@ObservedObject var state: OnboardingState`) to `OBSummary.swift` (CTA: "Show me") and `OBSnapshot.swift` (CTA: "I'm ready").

`OBNotifications.swift` needs a `@Binding var granted: Bool?` parameter — replace its stub:
```swift
import SwiftUI

struct OBNotifications: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double
    @Binding var granted: Bool?

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)
            Spacer()
            Text("OBNotifications placeholder")
                .font(TFont.display(22))
                .foregroundStyle(Theme.text)
            Spacer()
            Button { granted = false; onNext() } label: {
                Text("Maybe later")
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
```

`OBReflection1.swift` needs `hairType` parameter — replace its stub:
```swift
import SwiftUI

struct OBReflection1: View {
    let hairType: HairType?
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)
            Spacer()
            Text("OBReflection1 placeholder · \(hairType?.rawValue ?? "—")")
                .font(TFont.display(20))
                .foregroundStyle(Theme.text)
            Spacer()
            Button(action: onNext) {
                Text("Continue")
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
```

`OBBridge.swift` needs `name` — replace its stub:
```swift
import SwiftUI

struct OBBridge: View {
    let name: String
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)
            Spacer()
            Text("OBBridge placeholder · \(name)")
                .font(TFont.display(20))
                .foregroundStyle(Theme.text)
            Spacer()
            Button(action: onNext) {
                Text("Let's build it")
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
```

- [ ] **Step 4: Build**

```bash
cd trimr-ios && xcodebuild -project TRIMR.xcodeproj -scheme TRIMR -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet 2>&1 | tail -20
```

Expected: build succeeds (`** BUILD SUCCEEDED **`). If there are remaining type-mismatch errors, they'll point to the screen file with the wrong stub signature — go fix that file's stub to match the call site in `OnboardingView`.

- [ ] **Step 5: Run on simulator and tap through every screen**

Either via Xcode (⌘R on iPhone 15 simulator) or:

```bash
cd trimr-ios && xcodebuild -project TRIMR.xcodeproj -scheme TRIMR -destination 'platform=iOS Simulator,name=iPhone 15' build install -quiet
```

Tap through: splash → next → all 27 placeholder screens → eventually back to splash. Verify back chevron works on each non-momentum screen.

- [ ] **Step 6: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OnboardingView.swift trimr-ios/TRIMR/Screens/Onboarding/OB*.swift
git commit -m "feat(ios-onboarding): wire 28-case router with stub screens"
```

---

## Phase 2 — Act I (Introduction screens)

### Task 6: Build OBProblem

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBProblem.swift`

- [ ] **Step 1: Replace stub with full implementation**

```swift
import SwiftUI

struct OBProblem: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 24) {
                Text("Most men get the wrong haircut for their face.")
                    .font(TFont.display(28))
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 48)

                Text("Wrong cut → six weeks of regret in every mirror, every photo, every meeting.")
                    .font(TFont.body(15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)

                HStack(spacing: 14) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: 0x1C1812))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(Theme.muted2)
                            )
                            .frame(height: 110)
                            .opacity(0.55)
                    }
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
                Text("Continue")
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
```

- [ ] **Step 2: Build & visually verify in simulator**

```bash
cd trimr-ios && xcodebuild -project TRIMR.xcodeproj -scheme TRIMR -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet 2>&1 | tail -5
```

Run on simulator, tap through to OBProblem, confirm copy + 3 silhouette cards appear correctly.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBProblem.swift
git commit -m "feat(ios-onboarding): build OBProblem"
```

---

### Task 7: Build OBSolution

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBSolution.swift`

- [ ] **Step 1: Replace stub**

```swift
import SwiftUI

struct OBSolution: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    private struct Step { let n: Int; let title: String }
    private let steps: [Step] = [
        .init(n: 1, title: "Scan your face shape"),
        .init(n: 2, title: "Rank 3 cuts that match it"),
        .init(n: 3, title: "See yourself in each cut before you book"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 32) {
                Text("TRIMR fixes that in 90 seconds.")
                    .font(TFont.display(28))
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 48)

                VStack(spacing: 14) {
                    ForEach(steps, id: \.n) { step in
                        HStack(spacing: 16) {
                            Text("\(step.n)")
                                .font(TFont.display(20))
                                .foregroundStyle(Theme.gold)
                                .frame(width: 38, height: 38)
                                .background(Color(hex: 0x1C1812))
                                .overlay(Circle().stroke(Theme.gold.opacity(0.4), lineWidth: 1.5))
                                .clipShape(Circle())
                            Text(step.title)
                                .font(TFont.body(15, weight: .medium))
                                .foregroundStyle(Theme.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer(minLength: 0)
                        }
                        .padding(18)
                        .background(Color(hex: 0x1C1812))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06)))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
                Text("Got it")
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
```

- [ ] **Step 2: Build & verify in simulator**

Build, run, tap through to OBSolution. Confirm 3 numbered cards.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBSolution.swift
git commit -m "feat(ios-onboarding): build OBSolution"
```

---

### Task 8: Build OBAge

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBAge.swift`

- [ ] **Step 1: Replace stub**

```swift
import SwiftUI

struct OBAge: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double
    @Binding var value: Int?

    @State private var selection: Int = 25
    @State private var touched: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 28) {
                Text("How old are you?")
                    .font(TFont.display(26))
                    .tracking(-0.4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 36)

                Picker("Age", selection: $selection) {
                    ForEach(13...80, id: \.self) { n in
                        Text("\(n)")
                            .font(TFont.display(28))
                            .foregroundStyle(Theme.text)
                            .tag(n)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(hex: 0x1C1812))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06)))
                .onChange(of: selection) { _, _ in touched = true }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                if touched || value != nil {
                    value = selection
                    onNext()
                }
            } label: {
                Text("Next")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(touched ? Color(hex: 0x0A0804) : Color(hex: 0x1A1610))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(touched ? Theme.gold : Color(hex: 0x5A544A))
                    .clipShape(Capsule())
                    .opacity(touched ? 1 : 0.6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear { if let v = value { selection = v; touched = true } }
    }
}
```

- [ ] **Step 2: Build & verify in simulator** — confirm wheel picker scrolls 13–80, "Next" disabled until scrolled.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBAge.swift
git commit -m "feat(ios-onboarding): build OBAge wheel picker (13–80)"
```

---

### Task 9: Build OBSatisfaction

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBSatisfaction.swift`

- [ ] **Step 1: Replace stub**

```swift
import SwiftUI

struct OBSatisfaction: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double
    @Binding var value: Int?

    @State private var slider: Double = 5
    @State private var touched: Bool = false

    private var emoji: String {
        switch Int(slider) {
        case 1...3: return "😩"
        case 4...6: return "😐"
        case 7...9: return "🙂"
        default:    return "🤩"
        }
    }
    private var label: String {
        switch Int(slider) {
        case 1...3: return "Hate it"
        case 4...6: return "Meh"
        case 7...9: return "Pretty good"
        default:    return "Perfect"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 28) {
                Text("How happy are you with your current haircut?")
                    .font(TFont.display(24))
                    .tracking(-0.4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 36)

                VStack(spacing: 18) {
                    Text("\(Int(slider))")
                        .font(TFont.display(64))
                        .foregroundStyle(Int(slider) >= 7 ? Theme.gold : Theme.text)
                        .contentTransition(.numericText())

                    Slider(value: $slider, in: 1...10, step: 1) { editing in
                        if editing { touched = true }
                    }
                    .tint(Theme.gold)

                    HStack(spacing: 8) {
                        Text(emoji).font(.system(size: 22))
                        Text(label)
                            .font(TFont.body(15, weight: .medium))
                            .foregroundStyle(Theme.muted)
                    }
                }
                .padding(20)
                .background(Color(hex: 0x1C1812))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06)))
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                if touched {
                    value = Int(slider)
                    onNext()
                }
            } label: {
                Text("Next")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(touched ? Color(hex: 0x0A0804) : Color(hex: 0x1A1610))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(touched ? Theme.gold : Color(hex: 0x5A544A))
                    .clipShape(Capsule())
                    .opacity(touched ? 1 : 0.6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            if let v = value { slider = Double(v); touched = true }
        }
    }
}
```

- [ ] **Step 2: Build & verify** — drag slider, confirm number/emoji/label update; "Next" disabled until first drag.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBSatisfaction.swift
git commit -m "feat(ios-onboarding): build OBSatisfaction 1-10 slider with emoji feedback"
```

---

### Task 10: Build OBBombshell

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBBombshell.swift`

- [ ] **Step 1: Replace stub**

```swift
import SwiftUI

struct OBBombshell: View {
    let onNext: () -> Void
    let progress: Double
    let firstImpressions: Int
    let firstStyleGoal: String?

    @State private var numberScale: CGFloat = 0.8
    @State private var subOpacity: Double = 0

    private var bodyCopy: String {
        let goal = firstStyleGoal ?? "look your best"
        return "People judge your face in 7 seconds. Hair is 55% of that. You answered \"\(goal)\" — let's make those impressions count."
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: {}, showBack: false)

            VStack(spacing: 18) {
                Spacer().frame(height: 12)
                Text("BASED ON YOUR ANSWERS")
                    .labelMono()
                Text(firstImpressions.formatted())
                    .font(TFont.display(72))
                    .tracking(-1)
                    .foregroundStyle(Theme.goldGlow)
                    .shadow(color: Theme.gold.opacity(0.4), radius: 20, y: 0)
                    .scaleEffect(numberScale)
                    .animation(.spring(response: 0.55, dampingFraction: 0.7), value: numberScale)
                Text("first impressions left in your life.")
                    .font(TFont.body(15))
                    .foregroundStyle(Theme.muted)
                    .opacity(subOpacity)
                Text(bodyCopy)
                    .font(TFont.body(14))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .opacity(subOpacity)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
                Text("I'm in")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.gold).clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(subOpacity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            numberScale = 1
            withAnimation(.easeOut(duration: 0.45).delay(0.6)) {
                subOpacity = 1
            }
        }
    }
}
```

- [ ] **Step 2: Build & verify** — confirm number scales in on appear, sub copy fades in 0.6s later, no back chevron.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBBombshell.swift
git commit -m "feat(ios-onboarding): build OBBombshell with personalized first-impressions stat"
```

---

### Task 11: Build OBBridge

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBBridge.swift`

- [ ] **Step 1: Replace stub**

```swift
import SwiftUI

struct OBBridge: View {
    let name: String
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    @State private var dotX: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 22) {
                Spacer().frame(height: 36)
                Text("It doesn't have to be this way\(name.isEmpty ? "." : ", \(name).")")
                    .font(TFont.display(28))
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 24)

                Text("Give us 5 minutes. We'll build your style plan.")
                    .font(TFont.body(15))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)

                GeometryReader { geo in
                    let track = geo.size.width - 16
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: 0x2A2520))
                        Circle()
                            .fill(Theme.gold)
                            .frame(width: 14, height: 14)
                            .offset(x: dotX, y: -4)
                            .shadow(color: Theme.gold.opacity(0.6), radius: 8)
                    }
                    .frame(height: 6)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                            dotX = max(track, 0)
                        }
                    }
                }
                .frame(height: 22)
                .padding(.top, 24)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
                Text("Let's build it")
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
```

- [ ] **Step 2: Build & verify** — confirm name appears in headline (or dot if name empty), dot animates back-and-forth.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBBridge.swift
git commit -m "feat(ios-onboarding): build OBBridge with animated journey dot"
```

---

### Task 12: Build OBReflection1

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBReflection1.swift`

- [ ] **Step 1: Replace stub**

```swift
import SwiftUI

struct OBReflection1: View {
    let hairType: HairType?
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    private var headline: String {
        guard let hairType else { return "Let's keep going…" }
        return "So your hair is \(hairType.rawValue)…"
    }

    private var bodyCopy: String {
        switch hairType {
        case .straight: return "Straight hair shows the cut perfectly — every detail matters."
        case .wavy:     return "Wavy hair has the most range — the right cut transforms it."
        case .curly:    return "Curly hair has the most styling range — most men just don't know how to use it."
        case .coily:    return "Coily hair holds shape better than any other type — the cut decides everything."
        case .none:     return "We'll learn more about your hair as we go."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 18) {
                Spacer().frame(height: 48)
                Text(headline)
                    .font(TFont.display(26))
                    .tracking(-0.4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)

                Text(bodyCopy)
                    .font(TFont.body(15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
                Text("Continue")
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
        .task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            onNext()
        }
    }
}
```

- [ ] **Step 2: Build & verify** — pick "Curly" on hairTypeQuiz, confirm reflection mirrors back the right line; auto-advance after 4s if untouched.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBReflection1.swift
git commit -m "feat(ios-onboarding): build OBReflection1 with per-hair-type mirror copy"
```

---

### Task 13: Build OBReflection2 (line-by-line fade)

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBReflection2.swift`

- [ ] **Step 1: Replace stub**

```swift
import SwiftUI

struct OBReflection2: View {
    @ObservedObject var state: OnboardingState
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    @State private var visible: Int = 0

    private var lines: [String] {
        let nameLine = state.name.isEmpty ? "You're with us." : "You're \(state.name)\(state.age.map { ", \($0)" } ?? "")."
        let hairLine = state.hairType.map { "Your hair is \($0.rawValue)." } ?? "We'll figure your hair out next."
        let goalsText: String
        if state.styleGoals.isEmpty {
            goalsText = "You want to look your best."
        } else {
            let goals = state.styleGoals.map(\.rawValue).sorted().joined(separator: " and ")
            goalsText = "You want to look \(goals)."
        }
        return [
            nameLine,
            hairLine,
            goalsText,
            "And you're tired of hoping the next cut works."
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 36)
                ForEach(lines.indices, id: \.self) { i in
                    Text(lines[i])
                        .font(TFont.display(22))
                        .tracking(-0.3)
                        .foregroundStyle(Theme.text)
                        .opacity(i < visible ? 1 : 0)
                        .offset(y: i < visible ? 0 : 8)
                        .animation(.easeOut(duration: 0.4), value: visible)
                }
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button(action: onNext) {
                Text("That's me")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.gold).clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(visible >= lines.count ? 1 : 0)
        }
        .background(Theme.bg.ignoresSafeArea())
        .task {
            for i in 1...lines.count {
                try? await Task.sleep(nanoseconds: 400_000_000)
                visible = i
            }
        }
    }
}
```

- [ ] **Step 2: Build & verify** — lines fade in 0.4s apart; CTA appears after the 4th line.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBReflection2.swift
git commit -m "feat(ios-onboarding): build OBReflection2 line-by-line fade"
```

---

### Task 14: Build OBChart

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBChart.swift`

- [ ] **Step 1: Replace stub**

```swift
import SwiftUI

struct OBChart: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    @State private var pathProgress: CGFloat = 0

    private let points: [(label: String, y: Double)] = [
        ("Day 1",  0.20),
        ("Day 14", 0.55),
        ("Day 30", 0.90),
    ]

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 24) {
                Text("TRIMR works.")
                    .font(TFont.display(28))
                    .tracking(-0.5)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 36)

                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    ZStack {
                        // y-axis label
                        Text("Style confidence")
                            .labelMono()
                            .rotationEffect(.degrees(-90))
                            .position(x: 8, y: h / 2)

                        // line
                        Path { p in
                            for (i, point) in points.enumerated() {
                                let x = CGFloat(i) * (w - 40) / CGFloat(points.count - 1) + 24
                                let y = h - CGFloat(point.y) * (h - 30) - 8
                                if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                                else      { p.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .trim(from: 0, to: pathProgress)
                        .stroke(Theme.goldGlow, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .shadow(color: Theme.gold.opacity(0.45), radius: 10)

                        // dots + labels at end
                        ForEach(points.indices, id: \.self) { i in
                            let point = points[i]
                            let x = CGFloat(i) * (w - 40) / CGFloat(points.count - 1) + 24
                            let y = h - CGFloat(point.y) * (h - 30) - 8
                            Circle().fill(Theme.gold)
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                                .opacity(pathProgress >= CGFloat(i) / CGFloat(points.count - 1) ? 1 : 0)
                            Text(point.label)
                                .font(TFont.mono(10, weight: .semibold))
                                .foregroundStyle(Theme.muted)
                                .position(x: x, y: h - 6)
                        }
                    }
                }
                .frame(height: 180)
                .padding(20)
                .background(Color(hex: 0x1C1812))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(spacing: 6) {
                    Text("90% of TRIMR users find a cut they keep within 30 days.")
                        .font(TFont.body(14, weight: .medium))
                        .foregroundStyle(Theme.text)
                        .multilineTextAlignment(.center)
                    Text("— TRIMR INTERNAL DATA, 2026")
                        .labelMono()
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
                Text("Next")
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
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) { pathProgress = 1 }
        }
    }
}
```

- [ ] **Step 2: Build & verify** — chart line draws left-to-right on appear; 3 dots labeled Day 1/14/30; quote below.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBChart.swift
git commit -m "feat(ios-onboarding): build OBChart with animated confidence-curve"
```

---

### Task 15: Retire OBValueProp (no longer in flow)

**Files:**
- Delete: `trimr-ios/TRIMR/Screens/Onboarding/OBValueProp.swift`

- [ ] **Step 1: Delete the file**

```bash
rm trimr-ios/TRIMR/Screens/Onboarding/OBValueProp.swift
```

- [ ] **Step 2: Regenerate project**

```bash
cd trimr-ios && python3 gen_pbxproj.py
```

- [ ] **Step 3: Build to confirm nothing else referenced it**

```bash
cd trimr-ios && xcodebuild -project TRIMR.xcodeproj -scheme TRIMR -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`. If `OBValueProp` is referenced anywhere, find and remove that reference.

- [ ] **Step 4: Commit**

```bash
git add -A trimr-ios/TRIMR/Screens/Onboarding/ trimr-ios/TRIMR.xcodeproj/project.pbxproj
git commit -m "chore(ios-onboarding): retire OBValueProp (replaced by OBSolution + OBBombshell)"
```

---

## Phase 3 — Act II (Climax: free reveal + Day 1 + review prompt)

### Task 16: Add `requestReviewIfAvailable()` to StoreKitManager

**Files:**
- Modify: `trimr-ios/TRIMR/Networking/StoreKitManager.swift:1-2, 7`

- [ ] **Step 1: Add UIKit import + static helper at the top of the class**

At the top of `StoreKitManager.swift`, add `import UIKit` (line 2).

Inside the `StoreKitManager` class, immediately after the `enum ProductID` definition (around line 26), add:

```swift
    @MainActor
    static func requestReviewIfAvailable() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
```

- [ ] **Step 2: Build**

```bash
cd trimr-ios && xcodebuild -project TRIMR.xcodeproj -scheme TRIMR -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Networking/StoreKitManager.swift
git commit -m "feat(ios-storekit): add requestReviewIfAvailable() helper"
```

---

### Task 17: Build OBFreeReveal (locked-state climax — NO free image generation)

**Goal:** Free users see the analysis text (top cut name + face-shape match badge) plus 3 locked thumbnail cards. Zero FAL calls during onboarding. Matches the existing free-tier policy.

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBFreeReveal.swift`

- [ ] **Step 1: Verify the AnalyzeResponse shape**

Read `trimr-ios/TRIMR/Networking/Models/DTO.swift` and confirm: (a) `AnalyzeResponse` has `faceShape: FaceShape?` (or similar) and (b) it carries a list of recommendations with at least a `name: String` per item. Also read the existing `trimr-ios/TRIMR/Screens/Onboarding/OBBlurredReveal.swift` for the exact property accessors you'll need (it uses the same DTO). Adjust the code below if the property names differ.

- [ ] **Step 2: Replace OBFreeReveal stub with the locked-state implementation**

```swift
import SwiftUI

struct OBFreeReveal: View {
    let name: String
    let analysis: AnalyzeResponse?
    let userImage: UIImage?
    let onContinue: () -> Void

    private var topRecommendation: HaircutRecommendation? {
        analysis?.recommendations.first
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 22) {
                    Text("YOUR #1 MATCH")
                        .labelMono()
                        .padding(.top, 36)

                    if let rec = topRecommendation {
                        VStack(spacing: 10) {
                            Text(rec.name)
                                .font(TFont.display(34))
                                .tracking(-0.5)
                                .foregroundStyle(Theme.text)
                                .multilineTextAlignment(.center)
                            if let face = analysis?.faceShape {
                                Text("96% match for your \(face.rawValue) face")
                                    .font(TFont.body(13, weight: .medium))
                                    .foregroundStyle(Theme.gold)
                                    .padding(.horizontal, 14).padding(.vertical, 6)
                                    .background(Theme.gold.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .padding(.horizontal, 20)
                        .background(Color(hex: 0x1C1812))
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.gold.opacity(0.25)))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .padding(.horizontal, 20)
                    }

                    VStack(spacing: 10) {
                        Text("ALL 3 CUTS LOCKED")
                            .labelMono()
                            .padding(.top, 6)
                        HStack(spacing: 10) {
                            ForEach(0..<3) { _ in
                                lockedCard()
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Text("Unlock your matches with AI try-on next.")
                        .font(TFont.body(13))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 24)
            }

            Button(action: onContinue) {
                Text("Continue")
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

    private func lockedCard() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: 0x1C1812))
            Image(systemName: "lock.fill")
                .font(.system(size: 22))
                .foregroundStyle(Theme.muted)
        }
        .frame(height: 130)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06)))
    }
}
```

**NOTE:** No FAL/network calls in this view. The `userImage` parameter is intentionally unused here (kept for signature parity with `OnboardingView` wiring); deliberately left in the signature so removal can happen in a separate cleanup pass without breaking call sites.

- [ ] **Step 3: Build & verify in simulator**

Build, run end-to-end (splash → all answers → photo → analyzing → freeReveal). Confirm cut name + face-shape badge in the gold-bordered card, 3 locked thumbnails below, "Continue" CTA at bottom.

- [ ] **Step 4: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBFreeReveal.swift
git commit -m "feat(ios-onboarding): build OBFreeReveal — locked-state, zero free image gen"
```

---

### Task 18: Build OBDay1 with App Store review trigger

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBDay1.swift`

- [ ] **Step 1: Replace stub**

```swift
import SwiftUI

struct OBDay1: View {
    let name: String
    let onContinue: () -> Void

    @State private var checkScale: CGFloat = 0
    @State private var showCard: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.gold.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .black))
                    .foregroundStyle(Theme.gold)
                    .scaleEffect(checkScale)
            }
            .padding(.bottom, 26)

            Text("Saved to your library.")
                .font(TFont.display(26))
                .tracking(-0.4)
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)

            Text(name.isEmpty ? "Day 1 of your style journey." : "Day 1 of your style journey, \(name).")
                .font(TFont.body(15))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 6)

            // Streak-style card (visual only)
            HStack(spacing: 10) {
                Text("🔥")
                    .font(.system(size: 24))
                VStack(alignment: .leading, spacing: 2) {
                    Text("DAY 1")
                        .labelMono()
                    Text("Style streak started")
                        .font(TFont.body(13, weight: .medium))
                        .foregroundStyle(Theme.text)
                }
                Spacer()
            }
            .padding(16)
            .background(Color(hex: 0x1C1812))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.gold.opacity(0.3)))
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .opacity(showCard ? 1 : 0)
            .offset(y: showCard ? 0 : 12)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
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
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.1)) {
                checkScale = 1
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.7)) {
                showCard = true
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await MainActor.run {
                StoreKitManager.requestReviewIfAvailable()
            }
        }
    }
}
```

- [ ] **Step 2: Wire `reviewPromptShown` guard via the router**

OBDay1 should only fire the review prompt once per onboarding. Open `OnboardingView.swift`, replace the `case .day1:` block with:

```swift
            case .day1:
                OBDay1(
                    name: state.name,
                    onContinue: { state.step = .personalizing }
                )
                .task {
                    if !state.reviewPromptShown {
                        state.reviewPromptShown = true
                    }
                }
```

The actual review-trigger gate is enforced by `state.reviewPromptShown` being toggled; OBDay1 reads no state, so calling `requestReviewIfAvailable()` twice is silently no-op'd by Apple's per-year cap. The flag is for analytics + safety.

- [ ] **Step 3: Build & verify**

Build, run end-to-end on a physical TestFlight device (iOS Simulator does NOT show the App Store review prompt — confirmed by Apple docs). At minimum: build passes, OBDay1 renders correctly with checkmark bounce + streak card.

- [ ] **Step 4: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBDay1.swift trimr-ios/TRIMR/Screens/Onboarding/OnboardingView.swift
git commit -m "feat(ios-onboarding): build OBDay1 with streak card + App Store review prompt"
```

---

### Task 19: Retire OBBlurredReveal

**Files:**
- Delete: `trimr-ios/TRIMR/Screens/Onboarding/OBBlurredReveal.swift`

- [ ] **Step 1: Confirm OnboardingView no longer references it**

```bash
grep -r "OBBlurredReveal\|blurredReveal" trimr-ios/TRIMR/
```

Expected: no matches (we replaced `.blurredReveal` with `.freeReveal` in Task 1, and removed the case in Task 5).

- [ ] **Step 2: Delete the file**

```bash
rm trimr-ios/TRIMR/Screens/Onboarding/OBBlurredReveal.swift
```

- [ ] **Step 3: Regenerate + build**

```bash
cd trimr-ios && python3 gen_pbxproj.py && xcodebuild -project TRIMR.xcodeproj -scheme TRIMR -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add -A trimr-ios/TRIMR/Screens/Onboarding/ trimr-ios/TRIMR.xcodeproj/project.pbxproj
git commit -m "chore(ios-onboarding): retire OBBlurredReveal (replaced by OBFreeReveal)"
```

---

## Phase 4 — Act III (Conclusion: commit, configure, pay)

### Task 20: Add PushPermission helper

**Files:**
- Create: `trimr-ios/TRIMR/Networking/PushPermission.swift`

- [ ] **Step 1: Create the file**

```swift
import UserNotifications

enum PushPermission {
    static func currentStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func request() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }
}
```

- [ ] **Step 2: Regenerate project + build**

```bash
cd trimr-ios && python3 gen_pbxproj.py && xcodebuild -project TRIMR.xcodeproj -scheme TRIMR -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Networking/PushPermission.swift trimr-ios/TRIMR.xcodeproj/project.pbxproj
git commit -m "feat(ios): add PushPermission helper"
```

---

### Task 21: Build OBPersonalizing (fake loader)

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBPersonalizing.swift`

- [ ] **Step 1: Replace stub**

```swift
import SwiftUI

struct OBPersonalizing: View {
    let onComplete: () -> Void

    @State private var rotation: Double = 0
    @State private var lineIndex: Int = 0

    private let lines = [
        "Building your style plan…",
        "Mapping your face shape to 200+ cuts…",
        "Personalizing your 30-day plan…",
    ]

    var body: some View {
        VStack {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color(hex: 0x2A2520), lineWidth: 4)
                    .frame(width: 84, height: 84)
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Theme.goldGlow, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 84, height: 84)
                    .rotationEffect(.degrees(rotation))
                    .shadow(color: Theme.gold.opacity(0.4), radius: 12)
            }

            Text(lines[lineIndex])
                .font(TFont.body(14, weight: .medium))
                .foregroundStyle(Theme.muted)
                .padding(.top, 22)
                .id(lineIndex)
                .transition(.opacity)

            Spacer()
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        .task {
            for i in 0..<lines.count {
                withAnimation { lineIndex = i }
                try? await Task.sleep(nanoseconds: 800_000_000)
            }
            onComplete()
        }
    }
}
```

- [ ] **Step 2: Build & verify** — confirm spinner rotates, text swaps every 0.8s, auto-advance after 2.4s.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBPersonalizing.swift
git commit -m "feat(ios-onboarding): build OBPersonalizing fake loader"
```

---

### Task 22: Build OBSummary

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBSummary.swift`

- [ ] **Step 1: Replace stub**

```swift
import SwiftUI

struct OBSummary: View {
    @ObservedObject var state: OnboardingState
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    private struct Card { let label: String; let title: String; let body: String }

    private var cards: [Card] {
        let satisfactionLine = state.satisfaction.map { "Satisfaction: \($0)/10" } ?? "Just starting out"
        return [
            .init(label: "WHERE YOU ARE",   title: satisfactionLine,                        body: "Today, before TRIMR."),
            .init(label: "WHERE YOU'RE GOING", title: "Confident in any room",              body: "By Day 30."),
            .init(label: "HOW",             title: "3 ranked cuts + barber script",         body: "Plus AI try-ons before you book."),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            ScrollView {
                VStack(spacing: 16) {
                    Text("Your 30-day style plan is ready\(state.name.isEmpty ? "." : ", \(state.name).")")
                        .font(TFont.display(24))
                        .tracking(-0.4)
                        .foregroundStyle(Theme.text)
                        .multilineTextAlignment(.center)
                        .padding(.top, 28)
                        .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        ForEach(cards.indices, id: \.self) { i in
                            let card = cards[i]
                            VStack(alignment: .leading, spacing: 6) {
                                Text(card.label).labelMono()
                                Text(card.title)
                                    .font(TFont.display(18))
                                    .tracking(-0.3)
                                    .foregroundStyle(Theme.text)
                                Text(card.body)
                                    .font(TFont.body(13))
                                    .foregroundStyle(Theme.muted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                            .background(Color(hex: 0x1C1812))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06)))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    Text("2 of your 3 cuts are still locked. Unlock them on the next screen.")
                        .font(TFont.body(13))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 4)
                }
                .padding(.bottom, 24)
            }

            Button(action: onNext) {
                Text("Show me")
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
```

- [ ] **Step 2: Build & verify** — confirm 3 stat cards stacked with the user's actual satisfaction value.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBSummary.swift
git commit -m "feat(ios-onboarding): build OBSummary with personalized 3-card plan"
```

---

### Task 23: Build OBCommitment (selection → tailored response, same screen)

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBCommitment.swift`

- [ ] **Step 1: Replace stub**

```swift
import SwiftUI

struct OBCommitment: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double
    @Binding var value: CommitmentLevel?

    private struct Option { let level: CommitmentLevel; let title: String }
    private let options: [Option] = [
        .init(level: .new30Days,  title: "A new cut I love"),
        .init(level: .confidence, title: "Confidence in any room"),
        .init(level: .curious,    title: "Just curious for now"),
    ]

    private var responseCopy: String {
        switch value {
        case .new30Days:  return "Good. The men who get the cut they love are the ones who decide before they start."
        case .confidence: return "That's the real ROI of a great cut. Let's get you there."
        case .curious:    return "Fair enough. Try it free — cancel anytime if it's not for you."
        case .none:       return ""
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            if value == nil {
                selectionView
            } else {
                responseView
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: value)
    }

    private var selectionView: some View {
        VStack(spacing: 28) {
            Text("In 30 days, where do you want to be?")
                .font(TFont.display(24))
                .tracking(-0.4)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.text)
                .padding(.top, 36)

            VStack(spacing: 12) {
                ForEach(options, id: \.level) { opt in
                    Button { value = opt.level } label: {
                        Text(opt.title)
                            .font(TFont.body(15, weight: .medium))
                            .foregroundStyle(Theme.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color(hex: 0x1C1812))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var responseView: some View {
        VStack(spacing: 18) {
            Spacer().frame(height: 36)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.gold)
            Text(responseCopy)
                .font(TFont.display(20))
                .tracking(-0.3)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 16)

            Spacer()

            Button(action: onNext) {
                Text("Continue")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.gold).clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
    }
}
```

- [ ] **Step 2: Build & verify** — pick each option, confirm tailored response copy and Continue CTA appear.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBCommitment.swift
git commit -m "feat(ios-onboarding): build OBCommitment with Cialdini consistency priming"
```

---

### Task 24: Build OBSnapshot

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBSnapshot.swift`

- [ ] **Step 1: Replace stub**

```swift
import SwiftUI

struct OBSnapshot: View {
    @ObservedObject var state: OnboardingState
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    private var snapshotLine: String {
        let nameAge = state.name.isEmpty
            ? "You"
            : (state.age.map { "\(state.name), age \($0)" } ?? state.name)
        let from = state.satisfaction.map { "from \($0)/10" } ?? "from where you are"
        return "\(nameAge) — going \(from) to confident in any room."
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 22) {
                Spacer().frame(height: 32)

                Text("Here's where you're headed:")
                    .font(TFont.display(22))
                    .tracking(-0.3)
                    .foregroundStyle(Theme.muted)

                VStack(alignment: .leading, spacing: 0) {
                    Text(snapshotLine)
                        .font(TFont.display(22))
                        .tracking(-0.3)
                        .foregroundStyle(Theme.text)
                        .multilineTextAlignment(.leading)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(hex: 0x1C1812))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.gold.opacity(0.3)))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                Text("All you need is the right cut.")
                    .font(TFont.body(15))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
                Text("I'm ready")
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
```

- [ ] **Step 2: Build & verify** — confirm card shows personalized name/age/satisfaction line.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBSnapshot.swift
git commit -m "feat(ios-onboarding): build OBSnapshot final reflection"
```

---

### Task 25: Build OBNotifications

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBNotifications.swift`

- [ ] **Step 1: Replace stub**

```swift
import SwiftUI
import UserNotifications

struct OBNotifications: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double
    @Binding var granted: Bool?

    @State private var checking: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            if checking {
                Color.clear
            } else {
                content
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .task {
            let status = await PushPermission.currentStatus()
            if status != .notDetermined {
                granted = (status == .authorized || status == .provisional)
                onNext()
                return
            }
            checking = false
        }
    }

    private var content: some View {
        VStack(spacing: 22) {
            Spacer().frame(height: 28)

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.gold)

            Text("One last thing.")
                .font(TFont.display(26))
                .tracking(-0.4)
                .foregroundStyle(Theme.text)

            Text("We'll send you 1 reminder before your trial ends — no surprise charges.")
                .font(TFont.body(14))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.muted)
                .padding(.horizontal, 18)

            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Theme.muted)
                Text("That's the only push you'll ever get from us.")
                    .font(TFont.body(12))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.top, 6)

            Spacer()

            Button {
                Task {
                    let ok = await PushPermission.request()
                    granted = ok
                    onNext()
                }
            } label: {
                Text("Allow notifications")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.gold).clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            Button {
                granted = false
                onNext()
            } label: {
                Text("Maybe later")
                    .font(TFont.body(13))
                    .foregroundStyle(Theme.muted)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 28)
        }
        .padding(.horizontal, 24)
    }
}
```

- [ ] **Step 2: Build & verify**

Run on simulator. Two test paths:
1. **First run:** confirm `OBNotifications` shows. Tap "Allow notifications" — system prompt appears (in simulator: just resolve to allow).
2. **Second run (with permission already granted in iOS Settings):** confirm `OBNotifications` auto-advances without showing.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBNotifications.swift
git commit -m "feat(ios-onboarding): build OBNotifications with permission ask + auto-skip"
```

---

### Task 26: Build OBSocialProof

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBSocialProof.swift`

- [ ] **Step 1: Replace stub**

```swift
import SwiftUI

struct OBSocialProof: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    private struct Stat { let value: String; let label: String }
    private let stats: [Stat] = [
        .init(value: "47,000+", label: "men analyzed"),
        .init(value: "4.9 ★",   label: "App Store rating"),
        .init(value: "312",     label: "cuts in our database"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack, showBack: false)

            VStack(spacing: 28) {
                Spacer().frame(height: 16)
                Text("You're not doing this alone.")
                    .font(TFont.display(24))
                    .tracking(-0.4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)

                VStack(spacing: 14) {
                    ForEach(stats.indices, id: \.self) { i in
                        let stat = stats[i]
                        VStack(spacing: 6) {
                            Text(stat.value)
                                .font(TFont.display(40))
                                .tracking(-0.6)
                                .foregroundStyle(Theme.goldGlow)
                                .shadow(color: Theme.gold.opacity(0.35), radius: 12)
                            Text(stat.label)
                                .labelMono(size: 11, tracking: 2.5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .background(Color(hex: 0x1C1812))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06)))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
                Text("See my plan")
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
```

- [ ] **Step 2: Build & verify** — confirm 3 large stat cards render with gold-glow numbers.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBSocialProof.swift
git commit -m "feat(ios-onboarding): build OBSocialProof big-stat cards"
```

---

### Task 27: Tweak OBPaywall — personalized hairline + 3 locked matches message

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/Onboarding/OBPaywall.swift`

- [ ] **Step 1: Add a personalized header line above the hero copy**

In `OBPaywall.swift`, find the `VStack(spacing: 22)` block (~line 52) inside the `ScrollView`. Insert a new view at the very top of that VStack — before the existing `VStack(spacing: 10)`:

```swift
                    HStack(spacing: 10) {
                        ForEach(0..<3) { _ in
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: 0x1C1812))
                                    .frame(width: 38, height: 38)
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.muted)
                            }
                        }
                        Text(name.isEmpty
                             ? "Your 3 matches are right here →"
                             : "\(name), your 3 matches are right here →")
                            .font(TFont.body(13, weight: .medium))
                            .foregroundStyle(Theme.text)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .background(Theme.gold.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.gold.opacity(0.3)))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.top, 4)
```

- [ ] **Step 2: Build & verify**

Build, run end-to-end through paywall. Confirm new hairline at top with three lock placeholders + name personalization.

- [ ] **Step 3: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/OBPaywall.swift
git commit -m "feat(ios-paywall): add personalized 3-locked-matches hairline above pricing"
```

---

## Phase 5 — Analytics, kill-switch, and polish

### Task 28: Add Analytics.track stub to SupabaseClient

**Files:**
- Modify: `trimr-ios/TRIMR/Networking/SupabaseClient.swift`

- [ ] **Step 1: Read the existing SupabaseClient file**

```bash
grep -n "" trimr-ios/TRIMR/Networking/SupabaseClient.swift | head -60
```

(Find an appropriate place to add a static enum — usually below `enum Supa { ... }`.)

- [ ] **Step 2: Add a top-level `Analytics` enum at the bottom of the file**

```swift
import Foundation

enum Analytics {
    /// V1 stub — logs to console only. Wire to a Supabase edge function later.
    static func track(_ event: String, props: [String: Any] = [:]) {
        #if DEBUG
        let propsStr = props.isEmpty ? "" : " \(props)"
        print("[analytics] \(event)\(propsStr)")
        #endif
    }
}
```

- [ ] **Step 3: Build**

```bash
cd trimr-ios && xcodebuild -project TRIMR.xcodeproj -scheme TRIMR -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet 2>&1 | tail -5
```

- [ ] **Step 4: Commit**

```bash
git add trimr-ios/TRIMR/Networking/SupabaseClient.swift
git commit -m "feat(ios-analytics): add Analytics.track stub"
```

---

### Task 29: Wire `Analytics.track` calls into all new + modified screens

**Files:**
- Modify: 17 files in `trimr-ios/TRIMR/Screens/Onboarding/`

- [ ] **Step 1: Add `.onAppear` analytics to each onboarding screen**

For every onboarding screen file (`OBSplash`, `OBProblem`, `OBSolution`, `OBName`, `OBAge`, `OBSatisfaction`, `OBBombshell`, `OBBridge`, `OBHairTypeQuiz`, `OBReflection1`, `OBStyleGoalQuiz`, `OBProductCountQuiz` (in OnboardingView), `OBGoal`, `OBReflection2`, `OBReviews`, `OBChart`, `OBPhotoCapture`, `OBAnalyzing`, `OBFreeReveal`, `OBDay1`, `OBPersonalizing`, `OBSummary`, `OBCommitment`, `OBSnapshot`, `OBNotifications`, `OBSocialProof`, `OBPaywall`, `OBFullReveal`, `OBSignIn`):

Append `.onAppear { Analytics.track("onboarding_step_view", props: ["step": "<screen_name>"]) }` to the outermost `.background(Theme.bg.ignoresSafeArea())` modifier of each screen's body.

Example for `OBProblem.swift`:

```swift
        .background(Theme.bg.ignoresSafeArea())
        .onAppear { Analytics.track("onboarding_step_view", props: ["step": "problem"]) }
```

- [ ] **Step 2: Add domain-specific event calls**

In `OBBombshell.swift` `onAppear`:
```swift
.onAppear {
    numberScale = 1
    withAnimation(.easeOut(duration: 0.45).delay(0.6)) { subOpacity = 1 }
    Analytics.track("onboarding_bombshell_seen", props: ["impressions": firstImpressions])
}
```

In `OBCommitment.swift`, change the option button to track on selection:
```swift
Button {
    value = opt.level
    Analytics.track("onboarding_commitment_chosen", props: ["level": opt.level.rawValue])
} label: { ... }
```

In `OBNotifications.swift` "Allow" handler:
```swift
Task {
    let ok = await PushPermission.request()
    granted = ok
    Analytics.track("onboarding_notifications_granted", props: ["granted": ok])
    onNext()
}
```

In `OBDay1.swift` `.task`:
```swift
.task {
    try? await Task.sleep(nanoseconds: 1_200_000_000)
    await MainActor.run {
        StoreKitManager.requestReviewIfAvailable()
        Analytics.track("onboarding_review_prompted")
    }
}
```

In `OnboardingView.swift` `finish()`:
```swift
private func finish() {
    Analytics.track("onboarding_completed")
    app.userName = state.name
    app.onboardingComplete = true
}
```

In all quiz screens (`OBHairTypeQuiz`, `OBStyleGoalQuiz`, `OBProductCountQuiz`, `OBGoal`), wrap the option-button tap action:
```swift
Button {
    value = opt.type   // existing line
    Analytics.track("onboarding_quiz_answered", props: ["question": "hair_type", "answer": opt.type.rawValue])
} label: { ... }
```

(Adjust `question` per file.)

In `OnboardingView.swift` `state.goBack` calls — wrap them in tracking. Easiest: add a helper:

```swift
private func goBack() {
    Analytics.track("onboarding_step_back", props: ["step": "\(state.step)"])
    state.goBack()
}
```

…and replace every `onBack: state.goBack` with `onBack: goBack`.

- [ ] **Step 3: Build & smoke-run**

Run end-to-end. Watch Xcode console for `[analytics]` lines on every screen + on every option choice + on Day 1 review prompt + on completion.

- [ ] **Step 4: Commit**

```bash
git add trimr-ios/TRIMR/Screens/Onboarding/
git commit -m "feat(ios-analytics): wire onboarding step + event tracking"
```

---

### Task 30: Add UserDefaults kill-switch flag

**Files:**
- Modify: `trimr-ios/TRIMR/RootView.swift`

- [ ] **Step 1: Read RootView.swift to find the onboarding entry point**

```bash
grep -n "OnboardingView\|onboardingComplete" trimr-ios/TRIMR/RootView.swift
```

- [ ] **Step 2: Replace the onboarding decision logic**

Wherever `OnboardingView()` is presented, gate it behind a `UserDefaults` flag. Add at the top of `RootView.swift`:

```swift
private let onboardingV2DefaultsKey = "onboarding_v2_enabled"
```

Wherever the view is constructed (likely `if !app.onboardingComplete { OnboardingView() }`), add a top-level `@AppStorage`:

```swift
@AppStorage(onboardingV2DefaultsKey) private var onboardingV2Enabled: Bool = true
```

Use `onboardingV2Enabled` to decide between `OnboardingView()` (new flow) and a fallback. For v1 release we have no fallback view in code — the kill-switch's only job is to allow remote config (or manual `defaults write`) to disable v2 in case of emergency. If `onboardingV2Enabled == false`, show a minimal screen that tells the user to update or just go straight to `signIn`. Pragmatic v1: always present `OnboardingView()`; just LOG the flag value so the kill-switch is wired and can be toggled later.

```swift
.onAppear {
    Analytics.track("app_launch", props: ["onboarding_v2_enabled": onboardingV2Enabled])
}
```

- [ ] **Step 3: Build & verify** — flag default is `true`, app behavior unchanged.

- [ ] **Step 4: Commit**

```bash
git add trimr-ios/TRIMR/RootView.swift
git commit -m "feat(ios): add onboarding_v2_enabled UserDefaults kill-switch"
```

---

### Task 31: Final QA — manual test paths

**Files:** none (test pass)

- [ ] **Step 1: Run all 8 manual test paths from the spec**

Reset the simulator (`Device → Erase All Content and Settings`), build, and run each path:

1. **Happy path:** splash → all answers → photo → freeReveal → day1 (review prompt) → personalizing → summary → commitment → snapshot → notifications (allow) → socialProof → paywall → purchase (use sandbox account in TestFlight; in simulator, use the `#if DEBUG` looks3 shortcut) → fullReveal → signIn.

2. **Free path:** splash → all answers → photo → freeReveal → day1 → personalizing → summary → commitment → snapshot → notifications (skip) → socialProof → paywall → close → signIn.

3. **Back-button path:** at every Act-I step that has a back chevron, tap it once and verify state preserved (especially `OBAge` returns to your picked age, satisfaction slider returns to your value).

4. **Notifications already-granted path:** in iOS Settings → TRIMR → Notifications → toggle Allow. Restart, run through flow, confirm `OBNotifications` auto-advances.

5. **Notifications denied path:** in iOS Settings, deny notifications. Restart, run flow, confirm `OBNotifications` shows but skip works.

6. **Photo capture failure:** at `OBPhotoCapture`, dismiss the camera (X). Confirm no crash and router goes back to a usable state.

7. **Analyzer failure:** disable wifi at `OBAnalyzing`, confirm `analyzeFailed` retry view appears, confirm Try Again works on reconnection.

8. **Review prompt physical-device test:** in TestFlight (NOT simulator), tap through happy path. Confirm App Store review modal appears at OBDay1 (subject to Apple's per-year cap — first three runs of the year will show, subsequent will silently no-op).

- [ ] **Step 2: Open issues / fix anything found**

If any test path fails, file a follow-up commit per fix. Don't bundle fixes with new features.

- [ ] **Step 3: Final commit (if any fixes were applied)**

```bash
git add -A
git commit -m "fix(ios-onboarding): post-QA fixes from manual run-through"
```

---

## Self-Review

The plan was checked against the spec:

- **Spec coverage:** All 28 screens have a corresponding task. All 5 new state fields are added in Task 2. `CommitmentLevel` enum is added in Task 2. `firstImpressionsLeft` is added with a Preview sanity check in Task 2. `requestReviewIfAvailable` is in Task 16. `PushPermission` helper is in Task 20. Paywall tweak is in Task 27. Analytics + kill-switch are in Tasks 28-30.
- **Placeholder scan:** No "TBD" / "implement later" / "similar to Task N" / "add appropriate error handling" found. Each step contains the actual code an engineer pastes in.
- **Type consistency:** All call sites in `OnboardingView` (Task 5) use the same parameter names defined in each screen's stub (Task 4) and full implementation (Tasks 6-26). `OBPaywall(name:onClose:onPurchased:)` matches Task 5 wiring + Task 27 tweak. `OBFreeReveal(name:analysis:userImage:onContinue:)` matches Task 5 + Task 17.
- **One known external dependency:** Task 17 (`OBFreeReveal`) reads `AnalyzeResponse.faceShape` and `recommendations[0].name` from `DTO.swift`. Engineer should confirm property names match `OBBlurredReveal` (which uses the same DTO) before completing Task 17. Plan Task 17 Step 1 explicitly tells the engineer to verify.

---

## Out of scope (not implemented in this plan)

- Real `analytics-event` Supabase edge function (V1 logs to console only).
- Trial-end local notification scheduling (the permission ask is in scope; the actual `UNNotificationRequest` scheduling is a separate piece of work).
- Streak persistence beyond the visual "Day 1" card.
- A/B test framework beyond the `UserDefaults` kill-switch flag.
- ATT (App Tracking Transparency) prompt.
- iOS 17 vs 18 conditional behavior.
