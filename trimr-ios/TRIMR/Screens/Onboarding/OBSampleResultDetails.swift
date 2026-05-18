import SwiftUI

/// Onboarding screen 2 of the standard result preview: the real in-app
/// `ResultView` rendered in `.details` mode (why it works, barber brief, how
/// to style, recommended products) with its built-in sample data, plus a
/// small headline and a Continue button to advance into the photo climax.
struct OBSampleResultDetails: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                OBHeader(progress: progress, onBack: onBack)

                VStack(alignment: .leading, spacing: 6) {
                    Text("the full breakdown")
                        .font(TFont.display(24))
                        .tracking(-0.5)
                        .foregroundStyle(Theme.text)
                    Text("why it works, your barber brief, styling & products")
                        .font(TFont.body(13))
                        .foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 6)

                ResultView(section: .details)
            }

            continueBar(onNext)
        }
        .background(Theme.bgDeep.ignoresSafeArea())
    }
}
