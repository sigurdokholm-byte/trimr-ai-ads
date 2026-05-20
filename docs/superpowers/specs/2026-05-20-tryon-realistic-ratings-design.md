# Realistic Try-On Ratings via Computed Sub-Score Average

**Date:** 2026-05-20
**Branch:** `halo-update`
**Status:** Design approved, awaiting plan

## Problem

In try-on mode, the AI inflates the headline `rating` (1–100). Even cuts that
are obviously wrong for the user's face shape or hair texture score 80+. The
existing `TRYON_SYSTEM_PROMPT` instructs the model to "be honest, give low
scores when warranted," but LLMs are notoriously bad at criticism and inflate
anyway.

A secondary issue, discovered while scoping: the "compatibility breakdown"
bars on `ResultView` (`Face Shape Match: 95`, `Maintenance: 90`, …) are
**hardcoded sample values** — the AI doesn't actually return per-dimension
scores. This is a quiet form of dishonesty in the analysis flow.

## Approach (selected: C — rubric + computed headline)

Replace the LLM-generated freehand `rating` with a **server-computed weighted
mean** of six sub-scores. Each sub-score is produced by the AI but anchored
to an explicit rubric in the system prompt. The model loses the ability to
pick the headline number freehand — it can only move the headline by honestly
moving the components.

Side-effect: the breakdown bars on `ResultView` become real instead of fake.

Alternatives considered and rejected:

- **A — Prompt-only rubric.** Cheaper, but LLMs inflate even with rubrics.
  Improvement, not a fix.
- **B — Sub-scores without rubric.** Solves the structural problem but
  leaves each sub-score uncalibrated; aggregate is more honest but still
  drifts high over time.
- **Two-pass critic.** Doubles cost and latency. Overkill.
- **Different model.** This is not a model-capability issue.

## Scope

Both modes (try-on AND analysis) — they share one edge function, one tool
schema, and would otherwise diverge unnecessarily. Analysis ratings will
naturally stay high (the AI picks the best cut from the eligible pool, so
the cut is well-matched), but the rubric prevents 95+ inflation and the
breakdown bars become truthful.

## Components

### 1. Rubric (added to both `SYSTEM_PROMPT` and `TRYON_SYSTEM_PROMPT`)

Inserted **immediately before** the `You MUST respond using the
suggest_hairstyles tool` sentence at the end of each prompt, and before the
`${PREFERENCES_SECTION(preferences)}` interpolation. This places the rubric
right next to the tool call instruction so it stays salient.

```
## SCORING RUBRIC — APPLIES TO EVERY SUB-SCORE BELOW

  90–100  Genuinely exceptional. Rare. Provably ideal match.
  70–89   Good. Works for them, no major issues.
  50–69   Acceptable. Wearable but with specific identifiable drawbacks.
  30–49   Poor. Actively works against face / texture / lifestyle.
   1–29   Bad. Physically wrong (e.g. straight-only cut on curly hair,
          severe length-vs-face mismatch).

CALIBRATION:
- Most cuts on most people fall in the 50–70 band.
- The full 1–100 range MUST be used. If every score you produce is above 60,
  you are not being honest.

ADVERSARIAL CHECK (do this BEFORE scoring):
- Write 3 concrete reasons this cut might NOT work for them.
- Then score. If you cannot find at least one drawback, you have not looked
  hard enough — every cut has at least one.
```

### 2. Tool-schema change in `analyze-hairstyle/index.ts`

Add `compatibilityBreakdown` to `recommendation` as **required**:

```ts
compatibilityBreakdown: {
  type: "object",
  properties: {
    faceShapeMatch:      { type: "integer", description: "0–100 per rubric. Silhouette match to detected face shape. Score purely on face geometry." },
    hairTextureMatch:    { type: "integer", description: "0–100. How achievable the cut is given natural texture/density. Slick back on coarse curly hair = ~20, not 60." },
    ageAppropriateness:  { type: "integer", description: "0–100. Edgar cut at 45 = lower. Side part at 16 = lower." },
    maintenance:         { type: "integer", description: "0–100. How sustainable for THIS user — high-maintenance cut on someone signalling minimal effort scores lower." },
    stylingDifficulty:   { type: "integer", description: "0–100. Higher = easier. Buzz = 95, slick back = 35." },
    trendScore:          { type: "integer", description: "0–100. How current in 2026. Mod Cut peaked decades ago." },
  },
  required: ["faceShapeMatch", "hairTextureMatch", "ageAppropriateness", "maintenance", "stylingDifficulty", "trendScore"],
  additionalProperties: false,
},
```

Append `"compatibilityBreakdown"` to the existing `recommendation.required`
array (currently `["name", "rating", "description", "whyItWorks",
"fadeRecommendation", "barberInstructions", "stylingTips", "products"]`).

Keep `rating` in the schema (the model still produces one for logging /
fallback), but overwrite it server-side after the AI returns.

### 3. Server-side headline computation

Added **after** the existing `result.recommendation = { ...rec, … }` block
(currently lines 607–612) and **before** the final `return new Response(...)`:

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

function computeRating(b: Record<string, number> | null | undefined): number | null {
  if (!b) return null;
  let sum = 0;
  for (const [key, w] of Object.entries(RATING_WEIGHTS)) {
    const raw = typeof b[key] === "number" ? b[key] : 50; // missing → neutral
    sum += clamp(raw, 0, 100) * w;
  }
  return Math.round(sum);
}

const computed = computeRating(result.recommendation.compatibilityBreakdown);
if (computed !== null) {
  result.recommendation.rating = computed;
  console.log(`Computed rating ${computed} from breakdown for "${result.recommendation.name}"`);
} else {
  console.warn(`No compatibilityBreakdown returned by model — keeping AI rating ${result.recommendation.rating}`);
}
```

Helpers (`RATING_WEIGHTS`, `clamp`, `computeRating`) defined once at module
scope, alongside the existing `HAIRSTYLE_REFERENCES` constant.

If the model omitted the breakdown entirely, leave the AI's `rating` as-is
and log a warning. The schema marks the field required so this should be
rare.

### 4. iOS change — `ResultView.swift`

Today: `compat: [CompatRow]` is a hardcoded array (lines 49–55). The bars
always show those values regardless of the AnalyzeResponse.

Change: introduce a computed `compatRows` that prefers the real breakdown:

```swift
private var compatRows: [CompatRow] {
    if let b = response?.recommendation.compatibilityBreakdown {
        return [
            .init(icon: "brain.head.profile",     label: "Face Shape Match",   value: b.faceShapeMatch ?? 50),
            .init(icon: "person.fill",            label: "Age Appropriate",    value: b.ageAppropriateness ?? 50),
            .init(icon: "wrench.adjustable.fill", label: "Maintenance",        value: b.maintenance ?? 50),
            .init(icon: "flame.fill",             label: "Trend Score",        value: b.trendScore ?? 50),
            .init(icon: "scissors",               label: "Styling Difficulty", value: b.stylingDifficulty ?? 50),
        ]
    }
    return compat   // existing static sample — used for #Preview and onboarding sample paths
}
```

Then `compatBreakdown` iterates `compatRows` instead of `compat`. The
`saveButton` save path is unchanged: it already prefers
`response?.recommendation.compatibilityBreakdown` and falls back to the
static array.

The static `compat` array is preserved (not deleted) so previews and the
no-response onboarding sample card still render real-looking bars without
depending on a backend round-trip.

## Data flow

```
User photo + target style
  → analyze-hairstyle (try-on or analysis)
  → Gemini 2.5 Flash with SYSTEM_PROMPT or TRYON_SYSTEM_PROMPT (now with rubric)
  → AI tool call: recommendation { name, …, rating, compatibilityBreakdown { 6 sub-scores } }
  → Edge fn computes headline = weighted_mean(sub-scores)
  → Edge fn overwrites recommendation.rating
  → Response → iOS
  → ResultView renders headline (real) + breakdown bars (real)
  → Save path persists real breakdown to saved_haircuts.compatibility_breakdown
```

## Error handling

| Failure | Behaviour |
|---|---|
| Model omits `compatibilityBreakdown` | Log warning; leave AI's own `rating` untouched. Display falls back to static bars. |
| Individual sub-score missing | Treat as 50 (neutral) when computing. |
| Sub-score out of [0, 100] | Clamp before weighting. |
| Sub-score not a number | Treat as 50. |

## Out of scope (YAGNI)

- Two-pass critic call (expensive, rubric + structural lock are sufficient).
- Switching models (this is a prompting problem, not a model problem).
- New DB migration — `compatibility_breakdown jsonb` already exists from
  `20260328000002_add_compatibility_breakdown.sql`.
- New Swift DTO fields — `CompatibilityBreakdown` already declared in
  `Models.swift:32` with all six fields.
- Adjusting the weighting after launch — start with the proposed weights,
  tune only if real-world results justify it.
- Removing `trendScore` — kept for parity with existing struct + UI.

## Files touched

1. `headshot-hair-halo/supabase/functions/analyze-hairstyle/index.ts`
   - Add `SCORING RUBRIC` block to both system prompts.
   - Add `compatibilityBreakdown` to tool schema (required).
   - Add `RATING_WEIGHTS`, `clamp`, `computeRating` helpers.
   - After the existing `result.recommendation = { … }` assembly, run
     `computeRating` and overwrite `rating` when breakdown is present.

2. `trimr-ios/TRIMR/Screens/ResultView.swift`
   - Replace `ForEach(Array(compat.enumerated()), …)` with `compatRows`.
   - Add the `compatRows` computed property.
   - Keep static `compat` for preview / sample fallback.

No PBX project change. No DB migration. No Swift DTO change.

## Verification

No test runner. Manual verification path:

1. Deploy edge fn via Supabase MCP (per `project_supabase_deploy.md`).
2. **Bad-cut try-on** — pick Slick Back, upload a curly-hair selfie.
   Headline should land **30–55**. Breakdown should show `hairTextureMatch` low.
3. **Good-cut try-on** — pick a cut that genuinely suits the user.
   Headline **75–88**.
4. **Analysis happy-path** — run a normal analysis on a clear selfie.
   Best-match cuts stay **70–90** (the AI picks well-matched cuts; rubric
   prevents 95+ inflation).
5. **Saved library** — open a saved cut. Bars should match what was shown
   on the result screen.
6. **Preview & onboarding** — confirm `#Preview("ResultView – sample data")`
   and the onboarding sample-result split (`section: .card` / `.details`)
   still render bars (via static fallback).

## Open ops items

- This piles a 4th unpushed commit on the `headshot-hair-halo` submodule
  (existing memory `project_ios_tryon_unified.md`: 3 unpushed). The submodule
  push triggers Lovable. Coordinate with user before pushing.
- Outer-repo submodule gitlink will need bumping after the submodule push.

## Risks

- **Sub-score inflation** still possible. The rubric narrows it; we'll see
  the real spread after deploy. If sub-scores all cluster 70+, escalate to
  the adversarial-list step running on a second model call (would be a
  follow-up, not part of this work).
- **User shock** at lower scores. The score is supposed to be honest —
  this is a feature, not a bug — but if too many cuts now show 40–50, we
  may want a UX nuance (e.g. "Honest match" label). Out of scope for now.
- **Weight tuning.** First-pass weights are reasonable but not calibrated
  against real data. We'll iterate after seeing rating distributions.
