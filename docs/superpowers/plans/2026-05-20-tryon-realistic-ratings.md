# Realistic Try-On Ratings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the LLM's freehand try-on `rating` with a server-computed
weighted mean of six rubric-anchored sub-scores, and surface the real
per-dimension breakdown on the result page.

**Architecture:** Edge function `analyze-hairstyle` gains a `SCORING RUBRIC`
prompt block, a new required `compatibilityBreakdown` field on the tool
schema, and a post-AI step that computes the headline from the sub-scores.
iOS `ResultView` switches its breakdown bars from the hardcoded sample array
to the real values from the response, preserving the static array as preview
fallback only.

**Tech Stack:** Deno + Supabase Edge Functions (TypeScript) for the server
prompt and tool schema; SwiftUI for the iOS result view. Deployment via
Supabase MCP; iOS build via XcodeBuildMCP.

**Spec:** `docs/superpowers/specs/2026-05-20-tryon-realistic-ratings-design.md`

**Codebase note:** No automated test runner exists in either the web repo
(`headshot-hair-halo/CLAUDE.md`: "No test runner is configured") or the iOS
target. Verification uses `deno check` for TypeScript, `xcodebuild` /
XcodeBuildMCP `build_sim` for Swift, and live simulator runs against the
deployed edge function for behavioural checks.

---

## File Structure

| File | Role | Action |
|---|---|---|
| `headshot-hair-halo/supabase/functions/analyze-hairstyle/index.ts` | The edge fn that runs the AI call. Adds rubric, schema field, compute. | Modify |
| `trimr-ios/TRIMR/Screens/ResultView.swift` | The shared result view (analysis + try-on). Bars must read from real breakdown. | Modify |

No new files. No DB migration. No Swift DTO changes (`CompatibilityBreakdown`
already exists at `trimr-ios/TRIMR/Models.swift:32` with all six fields).

---

## Task 1: Edge function — helpers, schema, rubric, compute

**Files:**
- Modify: `headshot-hair-halo/supabase/functions/analyze-hairstyle/index.ts`

This is one atomic server change. The four sub-changes (helpers, schema,
rubric, compute) are functionally coupled — shipping any one without the
others is half-broken. Single commit.

- [ ] **Step 1: Read current state of index.ts around the targets**

Read the file. Confirm:
- Lines 16–30: `HAIRSTYLE_REFERENCES` constant (helpers go just below it).
- Lines 197–281: `SYSTEM_PROMPT` (rubric goes near the end, before "You MUST respond").
- Lines 283–318: `TRYON_SYSTEM_PROMPT` (rubric goes near the end, before "You MUST respond").
- Lines 508–533: `recommendation` tool schema (add `compatibilityBreakdown`).
- Line 531: `required: ["name", "rating", "description", "whyItWorks", "fadeRecommendation", "barberInstructions", "stylingTips", "products"]` (append `"compatibilityBreakdown"`).
- Lines 607–612: `result.recommendation = { ...rec, ... }` (compute goes immediately after this).

- [ ] **Step 2: Add module-level helpers**

Insert this block immediately after the `HAIRSTYLE_REFERENCES` const (line 30) and before `async function generateAndUploadImage`:

```ts
const RATING_WEIGHTS = {
  faceShapeMatch:     0.28,
  hairTextureMatch:   0.22,
  ageAppropriateness: 0.15,
  maintenance:        0.15,
  stylingDifficulty:  0.12,
  trendScore:         0.08,
} as const;

function clamp(n: number, lo: number, hi: number): number {
  return Math.max(lo, Math.min(hi, n));
}

function computeRating(b: Record<string, unknown> | null | undefined): number | null {
  if (!b || typeof b !== "object") return null;
  let sum = 0;
  for (const [key, w] of Object.entries(RATING_WEIGHTS)) {
    const raw = b[key];
    const value = typeof raw === "number" && Number.isFinite(raw) ? raw : 50;
    sum += clamp(value, 0, 100) * w;
  }
  return Math.round(sum);
}
```

- [ ] **Step 3: Add SCORING RUBRIC to SYSTEM_PROMPT**

Find this line near the end of `SYSTEM_PROMPT` (around line 281):

```ts
You MUST respond using the suggest_hairstyles tool. NEVER recommend a hairstyle not in the approved list above. NEVER set \`recommendation.name\` equal to \`currentHairstyle\`.${PREFERENCES_SECTION(preferences)}
```

Replace with:

```ts
## SCORING RUBRIC — APPLIES TO recommendation.rating AND EVERY SUB-SCORE IN compatibilityBreakdown

  90–100  Genuinely exceptional. Rare. Provably ideal match.
  70–89   Good. Works for them, no major issues.
  50–69   Acceptable. Wearable but with specific identifiable drawbacks.
  30–49   Poor. Actively works against face / texture / lifestyle.
   1–29   Bad. Physically wrong (e.g. straight-only cut on curly hair, severe length-vs-face mismatch).

CALIBRATION:
- Most cuts on most people fall in the 50–70 band.
- The full 1–100 range MUST be used. If every score you produce is above 60, you are not being honest.

ADVERSARIAL CHECK (do this BEFORE scoring):
- Write 3 concrete reasons this cut might NOT work for them.
- Then score. If you cannot find at least one drawback, you have not looked hard enough — every cut has at least one.

You MUST respond using the suggest_hairstyles tool. NEVER recommend a hairstyle not in the approved list above. NEVER set \`recommendation.name\` equal to \`currentHairstyle\`.${PREFERENCES_SECTION(preferences)}
```

- [ ] **Step 4: Add SCORING RUBRIC to TRYON_SYSTEM_PROMPT**

Find this line near the end of `TRYON_SYSTEM_PROMPT` (around line 318):

```ts
You MUST respond using the suggest_hairstyles tool.${PREFERENCES_SECTION(preferences)}
```

Replace with:

```ts
## SCORING RUBRIC — APPLIES TO recommendation.rating AND EVERY SUB-SCORE IN compatibilityBreakdown

  90–100  Genuinely exceptional. Rare. Provably ideal match.
  70–89   Good. Works for them, no major issues.
  50–69   Acceptable. Wearable but with specific identifiable drawbacks.
  30–49   Poor. Actively works against face / texture / lifestyle.
   1–29   Bad. Physically wrong (e.g. straight-only cut on curly hair, severe length-vs-face mismatch).

CALIBRATION:
- Most cuts on most people fall in the 50–70 band.
- The full 1–100 range MUST be used. If every score you produce is above 60, you are not being honest.
- This is a try-on of a cut the USER picked. They may have picked a poor match — give an honest low rating when warranted. Do not inflate to be agreeable.

ADVERSARIAL CHECK (do this BEFORE scoring):
- Write 3 concrete reasons this cut might NOT work for them.
- Then score. If you cannot find at least one drawback, you have not looked hard enough — every cut has at least one.

You MUST respond using the suggest_hairstyles tool.${PREFERENCES_SECTION(preferences)}
```

- [ ] **Step 5: Add `compatibilityBreakdown` to the tool schema**

In the `recommendation.properties` object (currently lines 510–530), immediately after the `products` property and before the closing brace + `required` array, insert:

```ts
                        compatibilityBreakdown: {
                          type: "object",
                          properties: {
                            faceShapeMatch:     { type: "integer", description: "0–100 per rubric. Silhouette match to the detected face shape. Score purely on face geometry — does the cut's shape complement the head shape?" },
                            hairTextureMatch:   { type: "integer", description: "0–100 per rubric. How achievable the cut is given the person's natural texture and density. A slick back on coarse curly hair is ~20, not 60." },
                            ageAppropriateness: { type: "integer", description: "0–100 per rubric. Does the cut suit their apparent age range? Edgar cut at 45 = lower. Side part on a teen = lower." },
                            maintenance:        { type: "integer", description: "0–100 per rubric. How sustainable is this cut for THIS user given apparent grooming investment? Score lower for high-maintenance cuts on minimal-effort users." },
                            stylingDifficulty:  { type: "integer", description: "0–100 per rubric. Higher = easier to style daily. Buzz cut = 95, slick back = 35." },
                            trendScore:         { type: "integer", description: "0–100 per rubric. How current is this cut in 2026? Buzz cut = evergreen high. Mod cut peaked decades ago." },
                          },
                          required: ["faceShapeMatch", "hairTextureMatch", "ageAppropriateness", "maintenance", "stylingDifficulty", "trendScore"],
                          additionalProperties: false,
                        },
```

- [ ] **Step 6: Append `"compatibilityBreakdown"` to the recommendation.required array**

Find the line:

```ts
                      required: ["name", "rating", "description", "whyItWorks", "fadeRecommendation", "barberInstructions", "stylingTips", "products"],
```

Replace with:

```ts
                      required: ["name", "rating", "description", "whyItWorks", "fadeRecommendation", "barberInstructions", "stylingTips", "products", "compatibilityBreakdown"],
```

- [ ] **Step 7: Insert the compute step after `result.recommendation` assembly**

Find this block (currently lines 607–612):

```ts
    result.recommendation = {
      ...rec,
      whyItWorks: tryOnMode ? null : rec.whyItWorks,
      generatedImage: imageSucceeded ? img!.signedUrl : null,
      storagePath: imageSucceeded ? img!.storagePath : null,
    };
```

Insert immediately after this block, before `return new Response(...)`:

```ts
    const computed = computeRating(result.recommendation.compatibilityBreakdown);
    if (computed !== null) {
      const aiRating = result.recommendation.rating;
      result.recommendation.rating = computed;
      console.log(`Computed rating ${computed} from breakdown for "${result.recommendation.name}" (AI said ${aiRating}, tryOn=${tryOnMode})`);
    } else {
      console.warn(`No compatibilityBreakdown returned by model for "${result.recommendation.name}" — keeping AI rating ${result.recommendation.rating}`);
    }
```

- [ ] **Step 8: Type-check the edge function**

Run from `headshot-hair-halo/`:

```bash
deno check supabase/functions/analyze-hairstyle/index.ts
```

Expected: exits 0 with no errors. If errors mention Deno std imports or
remote modules, also fine — those are warnings about cached remotes, not
type errors. Real errors will reference your inserted code.

If `deno` is not installed locally, skip this step — the Supabase MCP
`deploy_edge_function` will surface the same errors on deploy.

- [ ] **Step 9: Commit the edge function change**

```bash
cd headshot-hair-halo
git add supabase/functions/analyze-hairstyle/index.ts
git commit -m "feat(edge): compute rating from rubric-anchored sub-scores

Adds SCORING RUBRIC + adversarial-check block to both SYSTEM_PROMPT and
TRYON_SYSTEM_PROMPT. Requires compatibilityBreakdown in the tool schema
(six sub-scores). Headline recommendation.rating is now a server-computed
weighted mean of those sub-scores — the LLM can no longer pick the
headline number freehand. Applies to both analyze and try-on modes.

Spec: docs/superpowers/specs/2026-05-20-tryon-realistic-ratings-design.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

(Note: this commits inside the `headshot-hair-halo` submodule. The outer
`claudecode` repo's submodule gitlink will be stale until the user is
ready to bump it — that's intentional, per the spec's "Open ops items".)

---

## Task 2: iOS — wire ResultView to the real breakdown

**Files:**
- Modify: `trimr-ios/TRIMR/Screens/ResultView.swift`

- [ ] **Step 1: Confirm current state of compatBreakdown**

Read `trimr-ios/TRIMR/Screens/ResultView.swift` lines 48–55 and 396–425.

Expected line 48:
```swift
    private struct CompatRow { let icon: String; let label: String; let value: Int }
```

Expected lines 49–55 (the static sample array):
```swift
    private let compat: [CompatRow] = [
        .init(icon: "brain.head.profile", label: "Face Shape Match", value: 95),
        .init(icon: "person.fill", label: "Age Appropriate", value: 93),
        .init(icon: "wrench.adjustable.fill", label: "Maintenance", value: 90),
        .init(icon: "flame.fill", label: "Trend Score", value: 94),
        .init(icon: "scissors", label: "Styling Difficulty", value: 88),
    ]
```

Expected line 398 inside `compatBreakdown`:
```swift
            ForEach(Array(compat.enumerated()), id: \.offset) { _, r in
```

- [ ] **Step 2: Add `compatRows` computed property**

Insert this property immediately after the static `compat` array (after the
closing `]` of `compat`, before `@State private var open` on line 57):

```swift
    /// Bars to render: prefers the real breakdown from the AI response, falls
    /// back to the static sample for previews and the no-response onboarding
    /// sample card. Keeps the visual order matching the static `compat` so the
    /// view code below doesn't care which source is used.
    private var compatRows: [CompatRow] {
        guard let b = response?.recommendation.compatibilityBreakdown else {
            return compat
        }
        return [
            .init(icon: "brain.head.profile",     label: "Face Shape Match",   value: b.faceShapeMatch ?? 50),
            .init(icon: "person.fill",            label: "Age Appropriate",    value: b.ageAppropriateness ?? 50),
            .init(icon: "wrench.adjustable.fill", label: "Maintenance",        value: b.maintenance ?? 50),
            .init(icon: "flame.fill",             label: "Trend Score",        value: b.trendScore ?? 50),
            .init(icon: "scissors",               label: "Styling Difficulty", value: b.stylingDifficulty ?? 50),
        ]
    }
```

- [ ] **Step 3: Switch `compatBreakdown` to iterate `compatRows`**

In the `compatBreakdown` view body (around line 398), change:

```swift
            ForEach(Array(compat.enumerated()), id: \.offset) { _, r in
```

to:

```swift
            ForEach(Array(compatRows.enumerated()), id: \.offset) { _, r in
```

Leave the static `compat` array in place — it's still used by `compatRows`
(fallback) and by `saveButton` (line ~494 `compat.first(where:...)`).

- [ ] **Step 4: Build the iOS app on the simulator**

Use XcodeBuildMCP. First ensure session defaults are set (project, scheme,
simulator). Then:

```
mcp__xcodebuild__session_show_defaults
```

Expected: `TRIMR` scheme, an iPhone simulator selected. If not, configure
per `project_ios_xcodebuild` memory.

Then:

```
mcp__xcodebuild__build_sim
```

Expected: BUILD SUCCEEDED. If errors mention `compatRows` or the new code,
fix them inline. SourceKit-only "Cannot find type" errors that disappear
on a clean build are noise (per `project_ios_xcodebuild` memory).

- [ ] **Step 5: Commit the iOS change**

```bash
cd /Users/sigurdokholm/Downloads/books/claudecode
git add trimr-ios/TRIMR/Screens/ResultView.swift
git commit -m "feat(ios): render real compatibility breakdown on ResultView

Bars now read from response.recommendation.compatibilityBreakdown when
present (the new field the edge fn fills from the AI), falling back to
the static sample only for previews and the onboarding sample card.

Pairs with edge-fn change to compute rating from sub-scores. Save path
already prefers the real breakdown, so saved state matches displayed
state in all cases now.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Deploy + manual verification

**Files:** None modified. Behavioural verification only.

- [ ] **Step 1: Deploy the edge function via Supabase MCP**

Project ref: `svgsgmgksazhcpmzyhiu` (per memory `project_supabase_deploy`).

Use `mcp__supabase__deploy_edge_function` with:
- `project_id`: `svgsgmgksazhcpmzyhiu`
- function name: `analyze-hairstyle`
- entrypoint: contents of `headshot-hair-halo/supabase/functions/analyze-hairstyle/index.ts`

Expected: deployment success, new version number (current is v119 per memory
— expect v120+).

If MCP refuses (CLI is signed into the wrong account per memory), report the
exact error and stop — do not retry with the Supabase CLI.

- [ ] **Step 2: Run the app on the simulator**

```
mcp__xcodebuild__build_run_sim
```

Expected: app launches on the configured iPhone simulator.

- [ ] **Step 3: Bad-cut try-on test**

In the running app:
1. Navigate to Try On.
2. Pick a cut deliberately mismatched to your test selfie (e.g. **Slick Back** on a curly-hair selfie, or **Buzz Cut** on a face with strong forehead features that buzz cuts expose harshly).
3. Upload + generate.

Expected:
- Headline rating **30–55** (no longer 80+).
- "Compatibility Breakdown" bars show a clearly **low** `Face Shape Match`
  OR `Maintenance` OR `Styling Difficulty` for the obvious problem
  dimension. Bars should NOT all be 88–95.
- Barber Brief / styling tips still render normally.

If the rating is still 80+, capture the request body and response payload
for diagnosis (likely the edge fn didn't deploy or the rubric didn't take
effect).

- [ ] **Step 4: Good-cut try-on test**

Pick a cut that genuinely suits the test selfie (e.g. a Textured Fringe or
Curly Top on a face shape it complements).

Expected:
- Headline rating **70–88**.
- Bars predominantly in the high band, but at least one dimension is
  realistically lower (e.g. Maintenance or Styling Difficulty).

- [ ] **Step 5: Analysis happy-path**

Run a normal hair analysis (not try-on).

Expected:
- Best-match cut headline stays **70–90**.
- Bars now show *real* values (not the static 95/93/90/94/88 sample).
- No regressions in face shape badge, name, or barber brief sections.

- [ ] **Step 6: Saved library check**

Save the analysis result via "SAVE TO LIBRARY". Open the library, open that
saved cut.

Expected: bars on the saved-cut detail view match what was shown on the
result screen.

- [ ] **Step 7: Preview integrity check**

Open `ResultView.swift` in Xcode. Hit the `#Preview("ResultView – sample
data")` canvas (line 612).

Expected: bars render with the static sample values (95/93/90/94/88)
unchanged, because no `response` is passed and `compatRows` falls back
to `compat`.

No commit on this task — verification only. If everything passes, the work
is complete pending the user's decision about pushing the
`headshot-hair-halo` submodule (existing memory: 3 unpushed + this 4th).

---

## Self-Review (run after writing the plan)

**Spec coverage:**

| Spec section | Implemented by |
|---|---|
| Rubric in both prompts | Task 1, Steps 3 + 4 |
| `compatibilityBreakdown` in tool schema | Task 1, Step 5 |
| Appended to `required` array | Task 1, Step 6 |
| `RATING_WEIGHTS`, `clamp`, `computeRating` helpers | Task 1, Step 2 |
| Server-side compute + overwrite of `rating` | Task 1, Step 7 |
| Error handling (missing breakdown → keep AI rating; missing field → 50; clamp) | Task 1, Steps 2 + 7 |
| iOS: use real breakdown when present, fall back to sample | Task 2, Steps 2 + 3 |
| Static `compat` preserved for previews | Task 2, Step 3 (explicit) |
| Verification: bad-cut, good-cut, analysis, library, preview | Task 3, Steps 3–7 |
| Deploy via Supabase MCP | Task 3, Step 1 |

All spec items mapped. No gaps.

**Placeholder scan:** No TBDs, no "add appropriate handling", every code step
shows the actual code or exact diff target.

**Type consistency:**
- `computeRating` returns `number | null` everywhere it's used.
- `compatRows` returns `[CompatRow]` — same type as static `compat`.
- Sub-score field names match in three places: tool schema (Task 1 Step 5),
  prompt rubric description (Task 1 Steps 3–4 reference them by name),
  Swift `CompatibilityBreakdown` struct (`Models.swift:32`, unchanged).
- Field order in `compatRows` matches the visual order of the existing
  static `compat` array, so save-button label lookups (`compat.first(where:
  $0.label == "Face Shape Match")`) keep working.
