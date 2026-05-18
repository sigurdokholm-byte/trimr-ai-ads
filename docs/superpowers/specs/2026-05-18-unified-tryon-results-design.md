# Unified Try-On Results — Design

Date: 2026-05-18
Status: Approved (pending written-spec review)

## Goal

The hairstyle try-on flow should land on the **same results page as hair
analysis** (`ResultView`), showing for the cut the user chose:

- A **rating** of how well that chosen cut suits their face (honest — may be low)
- A **barber brief** (copyable)
- **Styling tips**
- **Recommended products** (already wired via `BasedProductsBlock`)
- Before/after slider (their photo → generated try-on image)

Explicitly **omitted**: the "Why It Works" section. The user picked the cut, so
a rationale asserting it works would be dishonest when the rating is mediocre.

## Non-Goals

- No change to the analysis (recommendation) flow's behavior or output.
- No deletion of the `hairstyle-tryon` edge function (left in place, unused by app).
- No change to `ResultView` layout, the compatibility-breakdown block, or
  save-to-library schema.

## Backend — extend `analyze-hairstyle`

File: `headshot-hair-halo/supabase/functions/analyze-hairstyle/index.ts`
Deployed via Supabase MCP (project ref `svgsgmgksazhcpmzyhiu`; CLI is signed
into the wrong account — see project memory).

### New optional request fields

```ts
{
  image: string,                 // existing — user selfie data URL
  preferences?: {...},           // existing
  targetStyle?: string,          // NEW — chosen catalog cut name; omitted for custom uploads
  referenceUrl?: string          // NEW — reference image URL (catalog public URL or signed custom upload URL)
}
```

Presence of `referenceUrl` activates **try-on mode**.

### Try-on mode behavior

1. The LLM does **not recommend** a cut. It **scores the chosen cut**:
   - If `targetStyle` is provided, analyze that named cut.
   - If `targetStyle` is absent (custom upload), the model first
     describes/names the cut from the reference image, then scores it.
2. Produces, for that specific cut: `name`, `rating`, `fadeRecommendation`,
   `barberInstructions`, `stylingTips`, `products`.
3. `whyItWorks` is returned as **`null`** in try-on mode.
4. The "must not return the user's current hairstyle" ban is **disabled** in
   this mode (the user explicitly chose this cut).
5. Image generation uses the passed `referenceUrl` instead of the
   storage-name lookup keyed off the recommended cut.
6. Response shape is otherwise **unchanged** (`AnalyzeResponse`): same
   `faceShape`, `faceDescription`, `conclusion`, `recommendation {...}`,
   `imageGenerationFailed`.

Analysis mode (no `referenceUrl`) is byte-for-byte unchanged.

## iOS — route try-on to `ResultView`

Files: `trimr-ios/TRIMR/Screens/TryOnView.swift`,
`trimr-ios/TRIMR/Networking/Models/DTO.swift`.

- Add `targetStyle` / `referenceUrl` to the analyze request DTO (optional).
- `TryOnView.generate(image:)` calls `analyze-hairstyle` instead of
  `hairstyle-tryon`:
  - Catalog cut → `targetStyle = haircut.name`, `referenceUrl = haircut.referenceUrl`
  - Custom upload → `referenceUrl = <signed uploaded reference URL>` (existing
    `uploadCustomReference` path), no `targetStyle`
- On success, present the existing `ResultView` with the returned
  `AnalyzeResponse` and the user's photo as the before image — identical to the
  analysis flow's presentation.
- Remove the inline `resultCard` / before-after-only result path in `TryOnView`.
- Keep the existing credit gate (`profile.canTryOn`) and refresh after the call.
- Reuse the analyzing/loading + error UX.
- Because `whyItWorks` is `null`, `ResultView`'s existing
  hide-empty-section logic drops that block automatically — no iOS conditional.

Save-to-library uses `kind: "analysis"` (full detail persisted), matching the
data now available.

## Trade-off

Try-on becomes one LLM + image-generation call (≈ analysis cost/latency)
instead of an image-only call. Required to deliver the full results page;
accepted by product owner.

## Risks

- Custom-upload cut identification depends on the model reading the reference
  image; a vague reference yields a generic name. Acceptable.
- Prompt edits must be gated strictly on try-on mode so analysis output does
  not regress. Verify analysis mode unchanged after deploy.
