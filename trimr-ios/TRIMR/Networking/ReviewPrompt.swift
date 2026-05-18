import StoreKit
import UIKit

enum ReviewPrompt {
    private static let countKey = "trimr.reviewPrompt.successfulGenerations"
    private static let didPromptKey = "trimr.reviewPrompt.didPromptV1"

    static func recordSuccessfulGeneration() {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: countKey) + 1
        defaults.set(count, forKey: countKey)

        guard !defaults.bool(forKey: didPromptKey), count >= 2 else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            else { return }
            SKStoreReviewController.requestReview(in: scene)
            defaults.set(true, forKey: didPromptKey)
        }
    }
}
