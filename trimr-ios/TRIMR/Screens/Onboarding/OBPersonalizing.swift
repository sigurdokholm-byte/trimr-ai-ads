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
