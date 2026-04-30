# iOS Onboarding Redesign — Mau Baron 3-Act Adaptation

**Date:** 2026-04-30
**Status:** Approved (sections 1–5)
**Source:** Mau Baron's Prayer Lock onboarding playbook (3% → 12-15% conversion lift)
**Target:** TRIMR iOS (SwiftUI, Xcode project at `trimr-ios/`)

## Goal

Restructure the existing 15-screen iOS onboarding into a 28-screen 3-act narrative arc (Introduction → Climax → Conclusion). Reuse all existing visual style, every existing onboarding screen file, and the existing paywall pipeline. Add only what's needed to capture the psychological beats Mau used to triple his conversion.

## Constraints (locked from brainstorming)

- **Style:** preserve the dark gold/black theme defined in `Theme.swift` (`bg #0E0B08`, `gold #F5C842`, pill CTAs, gold-glow progress bar). No new colors, no new fonts. Use `TFont.display` for headlines, `TFont.body` for body, `labelMono` for eyebrows.
- **Reuse:** every existing screen file used today is reused verbatim or with light tweaks. The only retired files are `OBValueProp.swift` and `OBBlurredReveal.swift`.
- **Scope (option B locked in):** full Mau-style narrative arc (~28 screens). Not surgical (option A). Not a 1:1 mirror with streak system (option C).

## Design decisions (from clarifying questions)

| Question | Answer |
|---|---|
| Bombshell math | Identity / first-impressions framing using `age × 365 × 5` |
| Climax & review prompt | Free-reveal one full cut + AI image, fire `SKStoreReviewController` on Day-1 celebration screen, paywall comes later |
| Commitment screen phrasing | Outcome commitment ("In 30 days, where do you want to be?") with 3 options + tailored response screen |
| Notifications ask | Yes — added near end, framed as "1 reminder before trial ends" |
| Drop any tactics? | None — keep all Mau elements (loading transition, chart, both reflection screens) |

---

## 1. Full screen list (28 screens, 3 acts)

Legend: **[NEW]** = new file · **[REUSE]** = existing file verbatim · **[REUSE+]** = light tweak · **[MOVED]** = existing file in new position

### Act I — Introduction (set up the problem, earn buy-in)

| # | Screen | File | Mau # |
|---|---|---|---|
| 1 | Splash | `OBSplash.swift` **[REUSE]** | 1 |
| 2 | Problem | `OBProblem.swift` **[NEW]** | 2 |
| 3 | Solution | `OBSolution.swift` **[NEW]** | 3 |
| 4 | Name capture | `OBName.swift` **[REUSE]** | 4 |
| 5 | Age picker | `OBAge.swift` **[NEW]** | 5 |
| 6 | Satisfaction slider (1-10) | `OBSatisfaction.swift` **[NEW]** | 6 |
| 7 | Bombshell — first-impressions stat | `OBBombshell.swift` **[NEW]** | 7 |
| 8 | Bridge | `OBBridge.swift` **[NEW]** | 8 |
| 9 | Quiz: hair type | `OBHairTypeQuiz.swift` **[REUSE]** | 9 |
| 10 | Reflection mirror #1 | `OBReflection1.swift` **[NEW]** | 10 |
| 11 | Quiz: style goal | `OBStyleGoalQuiz.swift` **[REUSE]** | 11 |
| 12 | Quiz: product count | `OBProductCountQuiz.swift` **[REUSE]** | 12 |
| 13 | Quiz: intent (existing OBGoal) | `OBGoal.swift` **[REUSE+MOVED]** | 13 |
| 14 | Final reflection (line-by-line fade) | `OBReflection2.swift` **[NEW]** | 14-15 |
| 15 | Reviews carousel | `OBReviews.swift` **[REUSE]** | 19 |
| 16 | Chart confirmation | `OBChart.swift` **[NEW]** | 19 |

### Act II — Climax (hands-on, peak emotion, review prompt)

| # | Screen | File | Mau # |
|---|---|---|---|
| 17 | Photo capture | `OBPhotoCapture.swift` **[REUSE]** | 20 |
| 18 | Analyzing (real backend) | `OBAnalyzing.swift` **[REUSE]** | 21 |
| 19 | Free reveal — 1 full cut + AI image | `OBFreeReveal.swift` **[NEW]** (replaces blurredReveal) | 22 |
| 20 | Day-1 celebration + review prompt | `OBDay1.swift` **[NEW]** | 23-24 |

### Act III — Conclusion (commit, configure, pay)

| # | Screen | File | Mau # |
|---|---|---|---|
| 21 | Personalizing (fake loader) | `OBPersonalizing.swift` **[NEW]** | 25-26 |
| 22 | Personalized summary | `OBSummary.swift` **[NEW]** | 27 |
| 23 | Outcome commitment | `OBCommitment.swift` **[NEW]** | 28-29 |
| 24 | Style snapshot (final reflection) | `OBSnapshot.swift` **[NEW]** | 30 |
| 25 | Notifications permission | `OBNotifications.swift` **[NEW]** | 31 |
| 26 | Big social proof | `OBSocialProof.swift` **[NEW]** | 33 |
| 27 | Paywall | `OBPaywall.swift` **[REUSE+]** | paywall |
| 28 | Sign-in | `OBSignIn.swift` **[REUSE]** | — |
| — | Post-purchase full reveal | `OBFullReveal.swift` **[REUSE]** | — |

**Reuse score:** 9 of 16 existing onboarding screens reused verbatim, 1 moved (`OBGoal`), 2 retired (`OBValueProp`, `OBBlurredReveal`), 13 new screens.

---

## 2. Data model

### `OnboardingStep` enum — replace existing 15 cases with 28

```swift
enum OnboardingStep: Int, CaseIterable {
    case splash = 0
    // Act I
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
    // Act II
    case photoCapture
    case analyzing
    case freeReveal
    case day1
    // Act III
    case personalizing
    case summary
    case commitment
    case snapshot
    case notifications
    case socialProof
    case paywall
    case fullReveal
    case signIn
}
```

Progress bar denominator excludes splash, analyzing, personalizing, freeReveal, day1, paywall, fullReveal, signIn (no header on those — same pattern current code uses for splash/signIn).

### New `@Published` fields on `OnboardingState`

```swift
@Published var age: Int? = nil                          // 13–80 picker
@Published var satisfaction: Int? = nil                 // 1–10 slider
@Published var commitmentLevel: CommitmentLevel? = nil
@Published var notificationsGranted: Bool? = nil        // nil = not asked
@Published var reviewPromptShown: Bool = false          // ensures one-shot fire
```

### New enum

```swift
enum CommitmentLevel: String, Codable {
    case new30Days        // "A new cut I love"
    case confidence       // "Confidence in any room"
    case curious          // "Just curious for now"
}
```

### Computed property (bombshell math)

```swift
var firstImpressionsLeft: Int {
    guard let age = age else { return 0 }
    let yearsLeft = max(80 - age, 1)
    return ((yearsLeft * 365 * 5) / 10_000) * 10_000
}
```

### Untouched fields

`name`, `intent`, `hairType`, `productCount`, `styleGoals`, `capturedImage`, `analysis`, `purchasedPackProductId`, `faceShape` — all stay as-is.

### Persistence

No new state needs to survive an app kill mid-onboarding (existing pattern). `notificationsGranted` is mirrored to `UNUserNotificationCenter` so re-asking is impossible per iOS rules.

---

## 3. Per-screen UX spec for 13 new screens

All new screens follow the existing pattern: `OBHeader(progress:, onBack:)` on top, content centered, gold pill `Next` CTA pinned bottom with `.padding(.bottom, 32)`. Background `Theme.bg.ignoresSafeArea()`. Headlines `TFont.display(24-28)` with `tracking(-0.4)`. Body `TFont.body(14-16)`.

### `OBProblem`
- **Headline:** *"Most men get the wrong haircut for their face."*
- **Sub:** *"Wrong cut → 6 weeks of regret in every mirror, every photo, every meeting."*
- **Visual:** muted-photo strip of 3 generic "bad cut" silhouettes, low opacity.
- **CTA:** `Continue`. No quiz state.

### `OBSolution`
- **Headline:** *"TRIMR fixes that in 90 seconds."*
- **3 numbered rows:**
  1. Scan your face shape
  2. Rank 3 cuts that match it
  3. See yourself in each cut before you book
- **CTA:** `Got it`.

### `OBAge`
- **Headline:** *"How old are you, {name}?"*
- iOS wheel `Picker` (13–80). Default 25. Same card-style container as quizzes.
- **CTA:** `Next` — disabled until value changes.

### `OBSatisfaction`
- **Headline:** *"How happy are you with your current haircut?"*
- 1–10 horizontal slider with gold-glow track. Numeric label updates live (`F2ECE0` → `Theme.gold` when ≥7).
- Below slider: emoji + word swaps with value (1-3: "Hate it", 4-6: "Meh", 7-9: "Pretty good", 10: "Perfect").
- **CTA:** `Next` — disabled until first interaction.

### `OBBombshell`
- **Eyebrow:** `labelMono` *"BASED ON YOUR ANSWERS"*.
- **Number:** `firstImpressionsLeft` formatted with comma separators, `TFont.display(72)` in `Theme.gold` with `goldGlow` shadow.
- **Sub:** *"first impressions left in your life."*
- **Body:** *"People judge your face in 7 seconds. Hair is 55% of that. You answered '{first style goal}' — let's make those impressions count."*
- **Animation:** number scales 0.8 → 1.0 with spring on appear; sub fades in after 0.6s.
- **CTA:** `I'm in`. Single button — hide back chevron in `OBHeader` for this step.

### `OBBridge`
- **Headline:** *"It doesn't have to be this way, {name}."*
- **Body:** *"Give us 5 minutes. We'll build your style plan."*
- **Visual:** small gold dot animating along a horizontal path on appear (the journey starts).
- **CTA:** `Let's build it`.

### `OBReflection1`
- **Headline:** *"So your hair is {hairType}…"*
- **Body:** hard-coded mapping per HairType case:
  - straight: *"Straight hair shows the cut perfectly — every detail matters."*
  - wavy: *"Wavy hair has the most range — the right cut transforms it."*
  - curly: *"Curly hair has the most styling range — most men just don't know how to use it."*
  - coily: *"Coily hair holds shape better than any other type — the cut decides everything."*
- **CTA:** `Continue`. Auto-advance fallback after 4s if untouched.

### `OBReflection2`
- **Lines fade in 0.4s apart:**
  1. *"You're {name}, {age}."*
  2. *"Your hair is {hairType}."*
  3. *"You want to look {styleGoals joined with ' and '}."*
  4. *"And you're tired of hoping the next cut works."*
- After all 4 visible, CTA `That's me` fades in.

### `OBChart`
- **Headline:** *"TRIMR works."*
- **Visual:** custom SwiftUI `Path`-drawn line chart, gold gradient stroke, animates left-to-right on appear (1.2s).
- **3 data points:** "Day 1 · Day 14 · Day 30", y-axis "Style confidence."
- **Quote:** *"90% of TRIMR users find a cut they keep within 30 days."* `labelMono` source line: *"— TRIMR internal data, 2026"*.
- **CTA:** `Next`.

### `OBFreeReveal` (climax — replaces `OBBlurredReveal`)
- **Eyebrow:** `labelMono` *"YOUR #1 MATCH"*.
- **Hero:** AI-generated image of user with cut #1 (FAL pipeline, real call).
- **Cut name:** `TFont.display(28)`, e.g. *"Textured Crop"*.
- **Match badge:** *"96% match for your {detected face shape}"*.
- **Below:** 2 locked cards (blurred thumbnails) — *"#2 + #3 unlock with Pro"*.
- **CTA:** `Continue` → advances to `OBDay1`. Paywall comes later, not here.
- **Cost note:** this is the only added FAL call vs current flow.

### `OBDay1`
- Big checkmark in gold, scale-bounce on appear.
- **Headline:** *"Saved to your library."*
- **Sub:** *"Day 1 of your style journey, {name}."*
- **Card:** small streak-style display `Day 1 · 🔥` (visual only, no real streak system).
- **After 1.2s:** `SKStoreReviewController.requestReview(in: scene)` fires (Apple gates to 3x/year automatically).
- **CTA:** `Continue`.

### `OBPersonalizing`
- Spinning circular gold-glow stroke (matches `OBAnalyzing` style).
- **Sequenced text** swaps every 0.6s:
  1. *"Building your style plan…"*
  2. *"Mapping your face shape to 200+ cuts…"*
  3. *"Personalizing your 30-day plan…"*
- Auto-advance after 2.4s. No user input.

### `OBSummary`
- **Headline:** *"Your 30-day style plan is ready, {name}."*
- **3 stat cards:**
  1. **Where you are:** *"Satisfaction: {satisfaction}/10"*
  2. **Where you're going:** *"Confident in any room — by Day 30"*
  3. **How:** *"3 ranked cuts + barber script + AI try-ons"*
- **Footer:** *"2 of your 3 cuts are still locked. Unlock them on the next screen."*
- **CTA:** `Show me`.

### `OBCommitment`
- **Phase 1 (selection):**
  - **Headline:** *"In 30 days, where do you want to be?"*
  - **3 options** (same card style as existing quizzes):
    - *"A new cut I love"* → `.new30Days`
    - *"Confidence in any room"* → `.confidence`
    - *"Just curious for now"* → `.curious`
- **Phase 2 (response — same screen, swap content on tap):**
  - `.new30Days`: *"Good. The men who get the cut they love are the ones who decide before they start."*
  - `.confidence`: *"That's the real ROI of a great cut. Let's get you there."*
  - `.curious`: *"Fair enough. Try it free — cancel anytime if it's not for you."*
- **CTA on Phase 2:** `Continue`.

### `OBSnapshot`
- **Headline:** *"Here's where you're headed:"*
- **Card:** *"{name}, age {age} — going from {satisfaction}/10 to confident in any room."*
- **Sub-line:** *"All you need is the right cut."*
- **CTA:** `I'm ready`.

### `OBNotifications`
- **Headline:** *"One last thing."*
- **Body:** *"We'll send you 1 reminder before your trial ends — no surprise charges."*
- **Lock-icon row:** *"That's the only push you'll ever get from us."*
- **Primary CTA:** `Allow notifications` → triggers `UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])`.
- **Skip link:** `Maybe later`.
- **On `.task`:** check authorization status; auto-advance if already determined.

### `OBSocialProof`
- 3 oversized stats stacked (gold numbers, muted labels):
  - **47,000+** — *men analyzed*
  - **4.9 ★** — *App Store rating*
  - **312** — *cuts in our database*
- **CTA:** `See my plan` → advances to `OBPaywall`.

### `OBPaywall` tweak
- Add a top line above existing pricing: *"{name}, your 2 locked cuts are right here →"* with a hairline image of the 2 blurred thumbnails from `OBFreeReveal`. Otherwise identical.

---

## 4. Routing, paywall flow, helpers, analytics

### Router (`OnboardingView.swift`)

The existing `switch state.step` pattern stays; expand to 28 cases.

**Routing nuances:**
1. **Bombshell hides back chevron.** Add a `showBack: Bool = true` parameter to `OBHeader`. Set `false` for `OBBombshell`, `OBDay1`, `OBPersonalizing`, `OBSocialProof`, `OBPaywall`.
2. **`OBNotifications` auto-advances** if iOS already prompted: check `getNotificationSettings().authorizationStatus != .notDetermined` in `.task`, call `state.goNext()` if true.
3. **`OBPaywall.onClose` now points to `freeReveal`** instead of `blurredReveal`.

### Paywall flow changes vs today

| Stage | Today | New |
|---|---|---|
| Full result before paywall? | No (blurred only) | Yes — 1 of 3 cuts fully revealed with AI image |
| Paywall position | Right after blurredReveal | After socialProof (~7 screens later) |
| Paywall closes to | blurredReveal | freeReveal |
| Paywall offer | Existing pack purchases | Same SKUs, framed as "unlock cuts #2 + #3 + unlimited try-ons" |

### `StoreKitManager` — review prompt helper

Add to `Networking/StoreKitManager.swift`:

```swift
import StoreKit
import UIKit

@MainActor
static func requestReviewIfAvailable() {
    guard let scene = UIApplication.shared.connectedScenes
        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
    else { return }
    SKStoreReviewController.requestReview(in: scene)
}
```

Called once from `OBDay1.swift` in `.task` after a 1.2s delay, gated by `state.reviewPromptShown`.

### Notifications helper — new file `Networking/PushPermission.swift`

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

Used by `OBNotifications` only. Local notifications only (no remote push system today). Trial-end reminder scheduling is out of scope of this onboarding work.

### Analytics

Track minimum events:
- `onboarding_step_view` `{step: String, position: Int}` on every screen `.onAppear`.
- `onboarding_step_back` when back chevron tapped.
- `onboarding_quiz_answered` `{question, answer}` on every quiz selection.
- `onboarding_bombshell_seen`, `onboarding_commitment_chosen`, `onboarding_review_prompted`, `onboarding_notifications_granted`.
- `onboarding_completed` at `signIn` finish.

Add `func track(event: String, props: [String: Any])` to `SupabaseClient` — v1 stub can just `print` to console; wire to a real `analytics-event` edge function later.

### `Info.plist`

No new keys required for this work. Camera/photos already declared. `NSUserTrackingUsageDescription` only needed if ATT is added later (out of scope).

### Files touched

- **Modified:** `OnboardingState.swift`, `OnboardingView.swift`, `OBPaywall.swift`, `Networking/StoreKitManager.swift`, `Networking/SupabaseClient.swift` (analytics).
- **New:** 13 new screen files in `Screens/Onboarding/` + `Networking/PushPermission.swift`.
- **Retired:** `OBValueProp.swift`, `OBBlurredReveal.swift` — delete to keep repo clean.
- **Untouched:** `Theme.swift`, `Components.swift`, `RootView.swift`, `TRIMRApp.swift`, all non-onboarding screens.

---

## 5. Implementation order, testing, rollout

### Build phases (each shippable to TestFlight)

**Phase 1 — State & router scaffold (foundation only).**
- Update `OnboardingStep` enum to 28 cases.
- Add new `@Published` fields, `CommitmentLevel` enum, `firstImpressionsLeft` computed property.
- Stub all 13 new screens as `Text("OBProblem placeholder")` views.
- Wire `OnboardingView` switch to all 28 cases.
- **Verify:** app builds, can tap through every step in simulator with placeholders.

**Phase 2 — Act I Introduction screens.**
- Build `OBProblem`, `OBSolution`, `OBAge`, `OBSatisfaction`, `OBBombshell`, `OBBridge`, `OBReflection1`, `OBReflection2`, `OBChart`.
- Move `OBGoal` to its new position after the quizzes.
- Retire `OBValueProp.swift` (delete).
- **Verify:** end-to-end run shows screens 1–16 with real copy + animations.

**Phase 3 — Act II Climax (free reveal + Day 1).**
- Build `OBFreeReveal`, wire FAL to generate one image with the top recommendation.
- Build `OBDay1` with checkmark bounce + streak-style card; trigger `SKStoreReviewController` after 1.2s, one-shot via `state.reviewPromptShown`.
- Add `requestReviewIfAvailable()` to `StoreKitManager`.
- Retire `OBBlurredReveal.swift` (delete).
- **Verify:** complete an analyze in TestFlight, confirm FAL generates, confirm review modal fires.

**Phase 4 — Act III Conclusion (commit, configure, pay).**
- Build `OBPersonalizing`, `OBSummary`, `OBCommitment`, `OBSnapshot`, `OBNotifications`, `OBSocialProof`.
- Add `Networking/PushPermission.swift`.
- Tweak `OBPaywall` for locked-cuts hairline + name personalization.
- **Verify:** full flow from splash to paywall works; notification permission asks once and persists; all CTAs route correctly.

**Phase 5 — Analytics + polish.**
- Add `Analytics.track(...)` calls to every new screen's `.onAppear`.
- Stub `analytics-event` edge function or wire to existing logging.
- Tighten animations: bombshell number scale, reflection2 fade cadence, day1 checkmark bounce.
- Add `UserDefaults` kill-switch flag (`onboarding_v2_enabled`, default true) to flip back to old flow if conversion drops.

### Manual test paths (no unit tests for SwiftUI screens)

1. Happy path: splash → all answers → photo → paywall → purchase → fullReveal → signIn.
2. Free path: splash → all answers → photo → paywall → close → signIn.
3. Back-button path: tap back from each screen, verify state preserved (especially `OBAge` picker and quiz selections).
4. Notifications already-granted: grant in iOS Settings, restart, confirm `OBNotifications` auto-advances.
5. Notifications denied: deny once, restart, confirm screen still appears but skip works.
6. Photo capture failure: dismiss camera, confirm no crash and state intact.
7. Analyzer failure: force network failure, confirm existing `analyzeFailed` retry still works.
8. Review prompt: confirm `SKStoreReviewController.requestReview` fires once on `OBDay1` and is silently no-op'd at Apple's 3x/year cap.

### Unit-testable bits (XCTest)

- `firstImpressionsLeft` math at age 18, 25, 40, 79, 80, edge cases.
- `OnboardingStep.next()` / `.previous()` boundary cases.
- `CommitmentLevel` decoding.

### Rollout

1. Phase 1+2 → TestFlight, dogfood 2 days.
2. Phase 3+4 → TestFlight, run yourself + 2-3 friends through it.
3. Submit App Store with `UserDefaults` kill-switch defaulting to NEW.
4. Watch first 200 users' funnel: splash → completed signup conversion vs baseline.
5. If new flow underperforms by ≥20% relative, flip the flag, debug, re-ship.

### Risk register

- **App Store review prompt fatigue.** Onboarding burns one of Apple's 3 yearly slots. Acceptable — Mau-style timing is the highest-value moment.
- **Free FAL cost.** Every onboarding completion now consumes one image generation regardless of conversion. Mitigation: cache image keyed by user_id so re-runs reuse it; cap free generations per device per day at the SupabaseClient layer.
- **Notification permission denial rate.** If rejected, you cannot re-prompt. Mitigation: copy explicitly limits scope to "1 reminder before trial ends — no surprises" to maximize allow rate.
- **Length fatigue.** 28 vs 15 screens. Mitigation: every new screen has either auto-advance (loaders) or single-tap CTAs; total tap count rises ~16 → ~25, in line with Mau's ratios.

---

## Open questions (none currently — all resolved during brainstorming)

## Out of scope

- Trial-end local notification scheduling (separate work; sets up via permission ask in this spec).
- Real `analytics-event` edge function (stub for v1).
- Streak system / "Day 2+" persistence (the Day-1 card is purely visual).
- Adaptive Trust UI (ATT) prompt.
- A/B test infrastructure beyond the simple kill-switch flag.
