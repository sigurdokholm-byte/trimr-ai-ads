# Unified Try-On Results Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the hairstyle try-on flow land on the same `ResultView` as hair analysis, showing a rating + barber brief + styling tips + products for the cut the user chose (no "Why It Works").

**Architecture:** Extend the `analyze-hairstyle` edge function with an optional "try-on mode" (triggered by a `referenceUrl`) that scores a *chosen* cut instead of recommending one and generates the image from the passed reference. iOS `TryOnView` is refactored from an inline result card into a phase machine that calls `analyze-hairstyle` and presents the existing `ResultView`. `ResultView` gets a `showWhy` flag so the try-on path hides the "Why It Works" section.

**Tech Stack:** Supabase Deno edge function (TypeScript), Swift / SwiftUI (supabase-swift). No test runner exists in either project (documented in `headshot-hair-halo/CLAUDE.md`; iOS has no XCTest target). Verification is: MCP deploy success for the backend, and an `xcodebuild` build + simulator end-to-end run for iOS.

**Deploy note:** The Supabase CLI is signed into the wrong account for this project — deploy the edge function via the **Supabase MCP** (`mcp__supabase__deploy_edge_function`), project ref `svgsgmgksazhcpmzyhiu`. Do NOT use `supabase functions deploy`.

---

## File Structure

- `headshot-hair-halo/supabase/functions/analyze-hairstyle/index.ts` — modify: add try-on mode (request parsing, prompt branching, reference-driven image gen, null `whyItWorks`).
- `trimr-ios/TRIMR/Networking/Models/DTO.swift` — modify: add optional `targetStyle` / `referenceUrl` to `AnalyzeRequest`.
- `trimr-ios/TRIMR/Screens/ResultView.swift` — modify: add `showWhy` init param; gate the "why" section and the saved `whyItWorks`.
- `trimr-ios/TRIMR/Screens/TryOnView.swift` — modify: phase machine that calls `analyze-hairstyle` and presents `ResultView`; delete `resultCard`.

No new files → no `project.pbxproj` registration needed.

---

## Task 1: Backend — add try-on mode to `analyze-hairstyle`

**Files:**
- Modify: `headshot-hair-halo/supabase/functions/analyze-hairstyle/index.ts`

### Step 1: Accept `targetStyle` and `referenceUrl` in the request body

- [ ] In `index.ts`, find (≈ line 333):

```ts
    const { image, preferences = {} } = await req.json();
```

Replace with:

```ts
    const { image, preferences = {}, targetStyle, referenceUrl } = await req.json();

    const tryOnMode = typeof referenceUrl === "string" && referenceUrl.length > 0;
    const chosenStyle = typeof targetStyle === "string" && targetStyle.trim().length > 0
      ? targetStyle.trim()
      : null;
```

### Step 2: Add a try-on system prompt

- [ ] Immediately AFTER the `SYSTEM_PROMPT` const definition ends (the line ending with `${PREFERENCES_SECTION(preferences)}\`;` — currently line 280), add this new const:

```ts
const TRYON_SYSTEM_PROMPT = (chosenStyle: string | null) => `You are an expert barber, facial analyst, and AI hairstyle consultant for TRIMR. The user has ALREADY CHOSEN a specific hairstyle and wants an honest, personalised assessment of how well THAT cut suits them — you are NOT recommending a different style.

${chosenStyle
  ? `The user has chosen: **${chosenStyle}**. Evaluate THIS cut for them. \`recommendation.name\` MUST be exactly "${chosenStyle}".`
  : `The user uploaded a reference photo of a cut they want. Identify and name the cut from the reference, then evaluate THAT cut for them. Put the cut's name in \`recommendation.name\` (a short, human style name, e.g. "Textured Crop", "Slick Back").`}

## RULES

1. Do NOT recommend a different hairstyle. The user picked this cut on purpose — assess the cut they chose.
2. There is NO ban on their current hairstyle. If the chosen cut resembles what they already wear, that is fine — still assess it.
3. Be HONEST with the rating. If this cut is a poor match for their face shape, hair texture, or features, give it a LOW \`rating\` (it can be well below 50). Do not inflate the score to be agreeable — an honest low score is the whole point.
4. Still set \`currentHairstyle\` to the closest approved-pool name for what they currently wear (required field), but it does NOT constrain \`recommendation.name\`.

## STEP 1: FACE & HAIR MAPPING

Observe precisely: face length-vs-width ratio, forehead, cheekbones, jawline, chin, hairline, notable features; hair texture (straight/wavy/curly/coily, be specific), density, current length; apparent age range.

## STEP 2: FACE SHAPE CLASSIFICATION

Classify into exactly ONE: Oval, Round, Square, Oblong, Heart, Diamond.

## STEP 3: STYLING STRATEGY

Write 3-5 sentences (\`conclusion\`) on the person's key facial features and what hair should do for them, referencing their hair texture/density.

## STEP 4: ASSESS THE CHOSEN CUT

Score the chosen cut (\`rating\`, 1-100) honestly for THIS person's face shape, hair texture, density, and age. Provide:
- \`description\`: 2-3 sentences describing the chosen cut.
- \`whyItWorks\`: return an empty string "" — this field is intentionally unused for chosen-cut assessments.
- \`fadeRecommendation\`: the fade/finish that best executes this cut for their face shape.
- \`barberInstructions\`: a ready-to-use barber brief for the chosen cut — exact lengths, fade type, adjustments for their hair texture and density.
- \`stylingTips\`: 3-4 practical styling tips for the chosen cut and their hair texture.
- \`products\`: products needed to maintain/style the chosen cut.

You MUST respond using the suggest_hairstyles tool.${PREFERENCES_SECTION(preferences)}`;
```

### Step 3: Use the try-on prompt + user message when in try-on mode

- [ ] Find the analysis fetch body (≈ lines 423-437):

```ts
          messages: [
            { role: "system", content: SYSTEM_PROMPT(preferences) },
            {
              role: "user",
              content: [
                {
                  type: "text",
                  text: "Please perform a detailed face mapping analysis on my headshot and recommend the best hairstyles for my face shape.",
                },
                {
                  type: "image_url",
                  image_url: { url: `data:${mimeType};base64,${base64Data}` },
                },
              ],
            },
          ],
```

Replace with:

```ts
          messages: [
            {
              role: "system",
              content: tryOnMode ? TRYON_SYSTEM_PROMPT(chosenStyle) : SYSTEM_PROMPT(preferences),
            },
            {
              role: "user",
              content: [
                {
                  type: "text",
                  text: tryOnMode
                    ? (chosenStyle
                        ? `I want the "${chosenStyle}" hairstyle. Honestly assess how well it suits my face shape and hair, and give me a barber brief and styling tips for it.`
                        : "Identify the hairstyle in my reference photo, then honestly assess how well it suits my face shape and hair, and give me a barber brief and styling tips for it.")
                    : "Please perform a detailed face mapping analysis on my headshot and recommend the best hairstyles for my face shape.",
                },
                {
                  type: "image_url",
                  image_url: { url: `data:${mimeType};base64,${base64Data}` },
                },
              ],
            },
          ],
```

### Step 4: Pin the chosen name and skip the current-style warning in try-on mode

- [ ] Find (≈ lines 514-517):

```ts
    if (result.currentHairstyle && result.recommendation?.name &&
        String(result.currentHairstyle).toLowerCase().trim() === String(result.recommendation.name).toLowerCase().trim()) {
      console.warn(`Model returned recommendation matching currentHairstyle ("${result.currentHairstyle}") — prompt violation logged.`);
    }
```

Replace with:

```ts
    if (tryOnMode) {
      if (chosenStyle && result.recommendation) result.recommendation.name = chosenStyle;
    } else if (result.currentHairstyle && result.recommendation?.name &&
        String(result.currentHairstyle).toLowerCase().trim() === String(result.recommendation.name).toLowerCase().trim()) {
      console.warn(`Model returned recommendation matching currentHairstyle ("${result.currentHairstyle}") — prompt violation logged.`);
    }
```

### Step 5: Generate the image from the passed reference in try-on mode

- [ ] Change the `generateAndUploadImage` signature to accept an explicit reference URL override. Find (≈ lines 32-45):

```ts
async function generateAndUploadImage(
  falKey: string,
  supabase: any,
  imageDataUrl: string,
  hairstyleName: string,
  userId: string,
  index: number
): Promise<{ signedUrl: string; storagePath: string; error?: string } | null> {
  try {
    const ref = HAIRSTYLE_REFERENCES[hairstyleName];
    if (!ref) {
      console.error(`No reference image for "${hairstyleName}"`);
      return null;
    }
```

Replace with:

```ts
async function generateAndUploadImage(
  falKey: string,
  supabase: any,
  imageDataUrl: string,
  hairstyleName: string,
  userId: string,
  index: number,
  referenceUrlOverride?: string
): Promise<{ signedUrl: string; storagePath: string; error?: string } | null> {
  try {
    const refUrl = referenceUrlOverride ?? HAIRSTYLE_REFERENCES[hairstyleName]?.url;
    if (!refUrl) {
      console.error(`No reference image for "${hairstyleName}"`);
      return null;
    }
```

- [ ] In the same function, find the fal request body (≈ line 59):

```ts
        image_urls: [imageDataUrl, ref.url],
```

Replace with:

```ts
        image_urls: [imageDataUrl, refUrl],
```

- [ ] Update the call site. Find (≈ line 533):

```ts
    const img = await generateAndUploadImage(FAL_KEY, supabaseAdmin, userImageUrl, rec.name, userId, 0);
```

Replace with:

```ts
    const img = await generateAndUploadImage(
      FAL_KEY, supabaseAdmin, userImageUrl, rec.name, userId, 0,
      tryOnMode ? referenceUrl : undefined
    );
```

### Step 6: Null out `whyItWorks` in try-on mode before responding

- [ ] Find (≈ lines 546-550):

```ts
    result.recommendation = {
      ...rec,
      generatedImage: imageSucceeded ? img!.signedUrl : null,
      storagePath: imageSucceeded ? img!.storagePath : null,
    };
```

Replace with:

```ts
    result.recommendation = {
      ...rec,
      whyItWorks: tryOnMode ? null : rec.whyItWorks,
      generatedImage: imageSucceeded ? img!.signedUrl : null,
      storagePath: imageSucceeded ? img!.storagePath : null,
    };
```

### Step 7: Deploy via Supabase MCP

- [ ] Deploy the function using the MCP tool (NOT the CLI):

Call `mcp__supabase__deploy_edge_function` with `project_id: "svgsgmgksazhcpmzyhiu"`, function name `analyze-hairstyle`, and the full updated `index.ts` as the file entrypoint.

Expected: deploy returns success with the new version id.

### Step 8: Confirm the deployed code matches

- [ ] Call `mcp__supabase__get_edge_function` with `project_id: "svgsgmgksazhcpmzyhiu"`, slug `analyze-hairstyle`.

Expected: the returned source contains `tryOnMode` and `TRYON_SYSTEM_PROMPT`. If it does not, redeploy (Step 7).

### Step 9: Commit

```bash
cd /Users/sigurdokholm/Downloads/books/claudecode
git add headshot-hair-halo/supabase/functions/analyze-hairstyle/index.ts
git commit -m "feat(analyze-hairstyle): try-on mode — assess a chosen cut from a reference

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: iOS — add `targetStyle` / `referenceUrl` to `AnalyzeRequest`

**Files:**
- Modify: `trimr-ios/TRIMR/Networking/Models/DTO.swift:51-55`

### Step 1: Extend the DTO

- [ ] Find (lines 51-55):

```swift
struct AnalyzeRequest: Encodable {
    let image: String  // base64 data URL
    let preferences: [String: String]?
    let count: Int = 1
}
```

Replace with:

```swift
struct AnalyzeRequest: Encodable {
    let image: String  // base64 data URL
    let preferences: [String: String]?
    let count: Int = 1
    /// Try-on mode: the catalog cut the user chose (nil for custom-reference uploads).
    var targetStyle: String? = nil
    /// Try-on mode: reference hairstyle image URL. Presence switches the edge fn to assess-the-chosen-cut.
    var referenceUrl: String? = nil
}
```

Note: Swift's synthesized `Encodable` for optionals uses `encodeIfPresent`, so `nil` `targetStyle`/`referenceUrl` are omitted from the JSON — existing analysis callers (`AnalyzeView`) are byte-for-byte unchanged.

### Step 2: Build to verify it compiles

- [ ] Run a simulator build via XcodeBuildMCP. First call `mcp__xcodebuild__session_show_defaults`; if project/scheme/simulator are set, call `mcp__xcodebuild__build_sim` with empty args. Otherwise set defaults (scheme `TRIMR`) then build.

Expected: BUILD SUCCEEDED.

### Step 3: Commit

```bash
cd /Users/sigurdokholm/Downloads/books/claudecode
git add trimr-ios/TRIMR/Networking/Models/DTO.swift
git commit -m "feat(ios): AnalyzeRequest gains optional targetStyle/referenceUrl

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: iOS — add `showWhy` flag to `ResultView`

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/ResultView.swift` (init ≈ 11-24, `detailsSections` ≈ 242-266, `saveButton` ≈ 499-510)

### Step 1: Add the `showWhy` stored property + init param

- [ ] Find (lines 11-24):

```swift
    let response: AnalyzeResponse?
    let userImage: UIImage?
    let onReset: (() -> Void)?
    let sectionMode: Section

    init(response: AnalyzeResponse? = nil,
         userImage: UIImage? = nil,
         onReset: (() -> Void)? = nil,
         section: Section = .full) {
        self.response = response
        self.userImage = userImage
        self.onReset = onReset
        self.sectionMode = section
    }
```

Replace with:

```swift
    let response: AnalyzeResponse?
    let userImage: UIImage?
    let onReset: (() -> Void)?
    let sectionMode: Section
    /// When false (try-on of a user-chosen cut) the "Why It Works" section is
    /// hidden and not persisted — a rationale would be dishonest when the
    /// rating is mediocre.
    let showWhy: Bool

    init(response: AnalyzeResponse? = nil,
         userImage: UIImage? = nil,
         onReset: (() -> Void)? = nil,
         section: Section = .full,
         showWhy: Bool = true) {
        self.response = response
        self.userImage = userImage
        self.onReset = onReset
        self.sectionMode = section
        self.showWhy = showWhy
    }
```

### Step 2: Gate the "why" section render

- [ ] Find in `detailsSections` (lines 244-250):

```swift
            section(key: "why", icon: "lightbulb.fill", title: "WHY IT WORKS FOR YOU") {
                Text(why)
                    .font(TFont.body(13))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
```

Replace with:

```swift
            if showWhy {
                section(key: "why", icon: "lightbulb.fill", title: "WHY IT WORKS FOR YOU") {
                    Text(why)
                        .font(TFont.body(13))
                        .foregroundStyle(Theme.muted)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
```

### Step 3: Don't persist sample "why" when hidden

- [ ] Find in `saveButton` (line 505):

```swift
                        whyItWorks: why,
```

Replace with:

```swift
                        whyItWorks: showWhy ? why : nil,
```

### Step 4: Build to verify

- [ ] Run `mcp__xcodebuild__build_sim` (defaults already set from Task 2).

Expected: BUILD SUCCEEDED.

### Step 5: Commit

```bash
cd /Users/sigurdokholm/Downloads/books/claudecode
git add trimr-ios/TRIMR/Screens/ResultView.swift
git commit -m "feat(ios): ResultView showWhy flag to hide Why-It-Works for try-on

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: iOS — route try-on through `analyze-hairstyle` + `ResultView`

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/TryOnView.swift` (whole file restructured)

### Step 1: Replace state + add a phase machine

- [ ] Find (lines 4-25):

```swift
struct TryOnView: View {
    @State private var selected: Int? = nil
    @State private var customSelected: Bool = false
    @State private var customReferenceImage: UIImage?
    @State private var customRefSource: PhotoSource?
    @State private var showCustomRefChoice = false
    @State private var showUploadSheet = false
    @State private var resultUrl: String?
    @State private var beforePhoto: UIImage?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var saved = false
    @State private var saving = false
    @State private var saveError: String?

    @EnvironmentObject var app: AppState
    @EnvironmentObject var profile: ProfileStore
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var photoStore: TryOnPhotoStore

    private var filteredIndices: [Int] { Array(CatalogData.tryOnCuts.indices) }
    private var hasSelection: Bool { selected != nil || customSelected }
```

Replace with:

```swift
struct TryOnView: View {
    enum Phase { case picker, analyzing, results, error }
    @State private var phase: Phase = .picker
    @State private var selected: Int? = nil
    @State private var customSelected: Bool = false
    @State private var customReferenceImage: UIImage?
    @State private var customRefSource: PhotoSource?
    @State private var showCustomRefChoice = false
    @State private var showUploadSheet = false
    @State private var response: AnalyzeResponse?
    @State private var beforePhoto: UIImage?
    @State private var isGenerating = false
    @State private var errorMessage: String?

    @EnvironmentObject var app: AppState
    @EnvironmentObject var profile: ProfileStore
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var photoStore: TryOnPhotoStore

    private var filteredIndices: [Int] { Array(CatalogData.tryOnCuts.indices) }
    private var hasSelection: Bool { selected != nil || customSelected }
```

### Step 2: Restructure `body` into the phase machine

- [ ] Find the entire `var body: some View { ... }` (lines 44-124). Replace it with:

```swift
    var body: some View {
        ZStack {
            switch phase {
            case .picker:    pickerPhase
            case .analyzing: AnalyzingChecklistView()
            case .results:   resultsPhase
            case .error:     errorPhase
            }
        }
        .fullScreenCover(item: $customRefSource) { source in
            switch source {
            case .library:
                PhotoLibraryPicker(
                    onPicked: acceptCustomReference,
                    onCancel: { customRefSource = nil }
                )
            case .camera:
                CameraPicker(
                    onPicked: acceptCustomReference,
                    onCancel: { customRefSource = nil }
                )
                .ignoresSafeArea()
            }
        }
        .confirmationDialog("Upload your reference photo", isPresented: $showCustomRefChoice, titleVisibility: .visible) {
            Button("Take Photo") { customRefSource = .camera }
            Button("Choose from Library") { customRefSource = .library }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Try-on failed", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .fullScreenCover(isPresented: $showUploadSheet) {
            if hasSelection {
                PreviewUploadSheet(
                    title: "Try On",
                    itemName: selectedItemName,
                    swatchHex: nil,
                    thumbnailAsset: selectedThumbnailAsset,
                    thumbnailUIImage: customSelected ? customReferenceImage : nil,
                    headline: "Upload your photo to preview hairstyle",
                    subtitle: "We'll apply the hairstyle to your photo",
                    isGenerating: isGenerating,
                    canAfford: profile.canTryOn,
                    generateCostLabel: "Generate · 1 Look",
                    onGenerate: { cropped in generate(image: cropped) },
                    onClose: {
                        if !isGenerating { showUploadSheet = false }
                    },
                    onTopUp: {
                        showUploadSheet = false
                        app.push(.pricing)
                    }
                )
                .environmentObject(photoStore)
            }
        }
    }

    private var pickerPhase: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                let cols = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
                LazyVGrid(columns: cols, spacing: 10) {
                    customReferenceCard
                    ForEach(filteredIndices, id: \.self) { idx in
                        cutCard(idx: idx, cut: CatalogData.tryOnCuts[idx])
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer().frame(height: 120)
            }
        }
        .background(Theme.bgDeep.ignoresSafeArea())
    }

    private var resultsPhase: some View {
        ResultView(
            response: response,
            userImage: beforePhoto ?? photoStore.photo,
            onReset: {
                response = nil
                beforePhoto = nil
                selected = nil
                customSelected = false
                withAnimation { phase = .picker }
            },
            showWhy: false
        )
    }

    private var errorPhase: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.red)
            VStack(spacing: 8) {
                Text("Try-on failed")
                    .font(TFont.display(20))
                    .foregroundStyle(Theme.text)
                Text(errorMessage?.isEmpty == false ? errorMessage! : "Something went wrong. Please try again.")
                    .font(TFont.body(13))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            Button {
                response = nil
                withAnimation { phase = .picker }
            } label: {
                Text("Try Again")
                    .font(TFont.body(14, weight: .bold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .padding(.horizontal, 28).padding(.vertical, 14)
                    .background(Theme.goldGlow)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
    }
```

### Step 3: Rewrite `generate(image:)` to call `analyze-hairstyle`

- [ ] Find the entire `private func generate(image: UIImage) { ... }` (lines 137-195). Replace it with:

```swift
    private func generate(image: UIImage) {
        guard hasSelection else { return }
        beforePhoto = image
        guard profile.canTryOn else {
            showUploadSheet = false
            app.push(.pricing); return
        }
        isGenerating = true
        Task {
            defer { isGenerating = false }
            let encodingTask = Task.detached(priority: .userInitiated) {
                image.base64DataURL()
            }
            guard await FaceValidator.hasFace(in: image) else {
                encodingTask.cancel()
                errorMessage = "We couldn't find a face in that photo. Try a clear, front-facing selfie in good light."
                return
            }
            guard let base64 = await encodingTask.value else {
                errorMessage = "Couldn't read your photo."
                return
            }
            do {
                guard await auth.ensureSession() else {
                    errorMessage = "Please sign in again and try once more."
                    return
                }

                let referenceUrl: String
                let targetStyle: String?

                if customSelected, let custom = customReferenceImage {
                    referenceUrl = try await uploadCustomReference(image: custom)
                    targetStyle = nil
                } else if let idx = selected {
                    let cut = CatalogData.tryOnCuts[idx]
                    referenceUrl = cut.referenceUrl.absoluteString
                    targetStyle = cut.name
                } else {
                    return
                }

                let body = AnalyzeRequest(
                    image: base64,
                    preferences: nil,
                    targetStyle: targetStyle,
                    referenceUrl: referenceUrl
                )
                let result: AnalyzeResponse = try await Supa.client.functions
                    .invoke("analyze-hairstyle", options: .init(body: body))
                response = result
                showUploadSheet = false
                await profile.refresh()
                ReviewPrompt.recordSuccessfulGeneration()
                withAnimation { phase = .results }
            } catch {
                errorMessage = (error as NSError).localizedDescription
                showUploadSheet = false
                withAnimation { phase = .error }
            }
        }
    }
```

### Step 4: Delete the now-unused `resultCard` and stale state references

- [ ] Delete the entire `private func resultCard(url: String) -> some View { ... }` function (lines 366-414 in the original file).

- [ ] In `acceptCustomReference` (≈ line 128-135) find `resultUrl = nil` and replace with `response = nil`.

- [ ] In `customReferenceCard`'s `onTapGesture` (≈ line 304-313) find `resultUrl = nil` and replace with `response = nil`.

- [ ] In `cutCard`'s `onTapGesture` (≈ line 358-363) find `resultUrl = nil` and replace with `response = nil`.

- [ ] Search the file for any remaining references to `resultUrl`, `saved`, `saving`, `saveError`, or `resultStyleName`. There must be NONE left (save UI now lives in `ResultView`; `selectedItemName` / `selectedThumbnailAsset` are still used by the upload sheet and stay). Remove the `resultStyleName` computed property (≈ lines 38-42) — it is now unused.

Run: `grep -n "resultUrl\|resultStyleName\|\.saved\|saving\|saveError" trimr-ios/TRIMR/Screens/TryOnView.swift`
Expected: no matches (empty output).

### Step 5: Build

- [ ] Run `mcp__xcodebuild__build_sim`.

Expected: BUILD SUCCEEDED with no errors. (Warnings about unrelated SourceKit noise are expected per project memory.)

### Step 6: End-to-end runtime verification on simulator

- [ ] Run `mcp__xcodebuild__build_run_sim` to install and launch on the booted simulator. Then drive the UI (via computer-use, since XcodeBuildMCP UI automation is disabled per project memory):
  1. Sign in (or use existing session), navigate to the Try-On tab.
  2. Pick a catalog cut → upload/take a photo → Generate.
  3. Confirm the app transitions to the analyzing checklist, then to `ResultView` showing: face-shape badge, the chosen cut's name + a rating, before/after slider, BARBER BRIEF, HOW TO STYLE, RECOMMENDED PRODUCTS — and that there is **no** "WHY IT WORKS FOR YOU" section.
  4. Tap "SAVE TO LIBRARY" → confirm it succeeds (button shows SAVED).
  5. Repeat once with a custom uploaded reference photo (no catalog selection) → confirm the same results page renders with a named cut.

Expected: all steps pass. If the results page shows sample/placeholder text (e.g. the Curly Top sample brief) instead of real content, the edge function did not return a populated `recommendation` — re-check Task 1 Steps 3-6 and the deploy.

### Step 7: Commit

```bash
cd /Users/sigurdokholm/Downloads/books/claudecode
git add trimr-ios/TRIMR/Screens/TryOnView.swift
git commit -m "feat(ios): try-on routes to unified ResultView via analyze-hairstyle

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage:**
- Backend `targetStyle`/`referenceUrl` + try-on mode → Task 1 Steps 1-6. ✓
- Disable current-style ban / pin chosen name → Task 1 Steps 2, 4. ✓
- Custom upload analyzed (model names cut) → Task 1 Step 2 (no-`chosenStyle` branch), Task 4 Step 3. ✓
- Image gen uses passed reference → Task 1 Step 5. ✓
- `whyItWorks` null in try-on mode → Task 1 Step 6. ✓
- Response shape unchanged → no DTO change to `AnalyzeResponse`; only `AnalyzeRequest` extended (Task 2). ✓
- iOS routes to `ResultView`, removes inline card → Task 4. ✓
- "Why It Works" hidden (spec-corrected: explicit flag, not auto-hide) → Task 3 + Task 4 Step 2 (`showWhy: false`). ✓
- Save uses `kind: .analysis` → already the behavior of `ResultView.saveButton` (verified, unchanged). ✓
- Credit gate (`profile.canTryOn`) retained → Task 4 Step 3. ✓
- `hairstyle-tryon` left in place, unused → no task deletes it. ✓

**Placeholder scan:** No TBD/TODO; every code step contains full code. ✓

**Type consistency:** `AnalyzeRequest(image:preferences:targetStyle:referenceUrl:)` defined in Task 2 and called in Task 4 Step 3 with those exact labels. `ResultView(...)` `showWhy` param defined in Task 3 Step 1 and passed in Task 4 Step 2. `generateAndUploadImage` 7th param `referenceUrlOverride` defined and used in Task 1 Step 5. `Phase` enum cases (`picker/analyzing/results/error`) consistent across Task 4 Steps 1-2. ✓

**Scope:** Single feature, four ordered tasks, one plan. ✓
