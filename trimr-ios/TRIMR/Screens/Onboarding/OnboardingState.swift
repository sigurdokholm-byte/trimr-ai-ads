import SwiftUI
import UIKit

// MARK: - Step enum (drives router + progress bar)

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

// MARK: - Quiz value types

enum FaceShape: String, CaseIterable, Codable, Hashable {
    case oval, round, square, heart, long
}

enum HairType: String, CaseIterable, Codable, Hashable {
    case straight, wavy, curly, coily
}

enum StyleGoal: String, CaseIterable, Codable, Hashable {
    case professional, attractive, trendy, lowMaintenance
}

enum ProductCount: String, CaseIterable, Codable, Hashable {
    case none, one, twoOrThree, fourPlus
}

// MARK: - Onboarding state container

@MainActor
final class OnboardingState: ObservableObject {
    @Published var step: OnboardingStep = .splash
    @Published var name: String = ""
    @Published var intent: Int? = nil                      // existing OBGoal selection
    @Published var faceShape: FaceShape? = nil             // nil = "Let Trimr detect it"
    @Published var hairType: HairType? = nil
    @Published var productCount: ProductCount? = nil
    @Published var styleGoals: Set<StyleGoal> = []
    @Published var capturedImage: UIImage? = nil
    @Published var analysis: AnalyzeResponse? = nil
    @Published var purchasedPackProductId: String? = nil

    func goNext() { step = step.next() }
    func goBack() { step = step.previous() }
}
