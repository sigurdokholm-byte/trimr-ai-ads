/**
 * TRIMR AI — Creator Image Pack
 * 5 static compositions (render as PNG with: remotionb still <id> --frame=0)
 *
 * 1. HowItWorksImage     1080×1920  — 3-step process infographic
 * 2. ScoreExplainerImage  1080×1080  — What each criterion means
 * 3. FaceShapeGuideImage  1080×1920  — 6 shapes + ideal cut styles
 * 4. WhatYouGetImage      1080×1080  — Full feature breakdown grid
 * 5. BarberBriefImage     1080×1920  — "Show this to your barber" card
 */

import { AbsoluteFill } from "remotion";

// ─── Tokens ───────────────────────────────────────────────────────────────────
const BG = "#0a0a0a";
const SURFACE = "#141414";
const SURFACE2 = "#111111";
const BORDER = "#1f1f1f";
const BORDER2 = "#2a2a2a";
const GOLD = "#C9A84C";
const GOLD_LIGHT = "#E8C96A";
const GOLD_DIM = "rgba(201,168,76,0.12)";
const GOLD_BORDER = "rgba(201,168,76,0.3)";
const WHITE = "#ffffff";
const OFF_WHITE = "#e8e8e8";
const MUTED = "#888888";
const MUTED2 = "#555555";
const RED = "#e84747";
const YELLOW = "#f0d060";
const GREEN = "#4ecb71";

// ─── Shared primitives ────────────────────────────────────────────────────────
const F = "Helvetica Neue, Arial, sans-serif";

const scoreColor = (s: number) => (s <= 40 ? RED : s <= 70 ? YELLOW : GREEN);

const GoldDivider: React.FC<{ width?: number | string; height?: number }> = ({
  width = 80,
  height = 3,
}) => (
  <div
    style={{
      width,
      height,
      background: `linear-gradient(90deg, ${GOLD}, ${GOLD_LIGHT})`,
      borderRadius: 2,
    }}
  />
);

const Tag: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div
    style={{
      fontFamily: F,
      fontSize: 14,
      fontWeight: 700,
      letterSpacing: 4,
      textTransform: "uppercase" as const,
      color: GOLD,
      marginBottom: 16,
    }}
  >
    {children}
  </div>
);

const TrimrLogo: React.FC<{ size?: number }> = ({ size = 32 }) => (
  <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
    <span
      style={{
        fontFamily: F,
        fontWeight: 900,
        fontSize: size,
        letterSpacing: -1,
        color: WHITE,
        lineHeight: 1,
      }}
    >
      TRIM<span style={{ color: GOLD }}>R</span>
    </span>
    <span style={{ fontFamily: F, fontSize: size * 0.55, color: MUTED, fontWeight: 400 }}>AI</span>
  </div>
);

// ═══════════════════════════════════════════════════════════════════════════════
// IMAGE 1 — How It Works   1080 × 1920
// Use: Instagram Stories, TikTok cover, onboarding slide
// ═══════════════════════════════════════════════════════════════════════════════
export const HowItWorksImage: React.FC = () => {
  const steps = [
    {
      num: "01",
      icon: "📸",
      title: "Upload Your Selfie",
      body: "Take a clear front-facing photo. No filter, no hat — just your face. The AI does the rest.",
      detail: ["Good lighting helps", "Front facing", "Neutral expression"],
    },
    {
      num: "02",
      icon: "🧠",
      title: "AI Reads Your Face",
      body: "Our model maps 12 facial landmarks — jaw width, forehead ratio, chin shape and more — to pinpoint your exact face shape.",
      detail: ["12 landmarks measured", "Face shape detected", "Hair texture noted"],
    },
    {
      num: "03",
      icon: "✂️",
      title: "Get Your Top 3 Cuts",
      body: "Each style is scored 0–100 across 5 criteria specific to your face. You get AI photos, barber instructions, and styling tips.",
      detail: ["Scored 0–100", "AI-generated photos", "Barber brief included"],
    },
  ];

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(ellipse at 50% 0%, #1a1508 0%, ${BG} 55%)`,
        fontFamily: F,
      }}
    >
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          height: "100%",
          padding: "80px 72px 72px",
        }}
      >
        {/* Header */}
        <div style={{ marginBottom: 16 }}>
          <TrimrLogo size={28} />
        </div>

        <div style={{ marginBottom: 56 }}>
          <Tag>How It Works</Tag>
          <div
            style={{
              fontSize: 72,
              fontWeight: 900,
              color: WHITE,
              letterSpacing: -3,
              lineHeight: 1.05,
              marginBottom: 20,
            }}
          >
            Three steps to your
            <br />
            <span style={{ color: GOLD }}>perfect cut.</span>
          </div>
          <div style={{ fontSize: 24, color: MUTED, fontWeight: 300, lineHeight: 1.6, maxWidth: 800 }}>
            No guessing. No wasted appointments. Just data-matched haircut recommendations built around your face.
          </div>
        </div>

        <GoldDivider width="100%" height={1} />

        {/* Steps */}
        <div style={{ display: "flex", flexDirection: "column", gap: 0, flex: 1, marginTop: 48 }}>
          {steps.map((s, i) => (
            <div
              key={s.num}
              style={{
                display: "flex",
                gap: 32,
                paddingBottom: i < steps.length - 1 ? 48 : 0,
                marginBottom: i < steps.length - 1 ? 48 : 0,
                borderBottom: i < steps.length - 1 ? `1px solid ${BORDER}` : "none",
              }}
            >
              {/* Left: number + connector */}
              <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 0 }}>
                <div
                  style={{
                    width: 72,
                    height: 72,
                    borderRadius: "50%",
                    background: `linear-gradient(135deg, ${GOLD_DIM}, rgba(201,168,76,0.04))`,
                    border: `1px solid ${GOLD_BORDER}`,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontWeight: 900,
                    fontSize: 26,
                    color: GOLD,
                    letterSpacing: -1,
                    flexShrink: 0,
                  }}
                >
                  {s.num}
                </div>
              </div>

              {/* Right: content */}
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 44, marginBottom: 12 }}>{s.icon}</div>
                <div
                  style={{
                    fontSize: 38,
                    fontWeight: 900,
                    color: WHITE,
                    letterSpacing: -1,
                    marginBottom: 12,
                  }}
                >
                  {s.title}
                </div>
                <div
                  style={{
                    fontSize: 22,
                    color: MUTED,
                    fontWeight: 300,
                    lineHeight: 1.6,
                    marginBottom: 20,
                  }}
                >
                  {s.body}
                </div>
                <div style={{ display: "flex", gap: 10, flexWrap: "wrap" as const }}>
                  {s.detail.map((d) => (
                    <div
                      key={d}
                      style={{
                        padding: "6px 16px",
                        borderRadius: 40,
                        border: `1px solid ${BORDER2}`,
                        fontSize: 16,
                        color: MUTED2,
                        background: SURFACE2,
                      }}
                    >
                      ✓ {d}
                    </div>
                  ))}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Footer */}
        <div
          style={{
            marginTop: "auto",
            paddingTop: 40,
            borderTop: `1px solid ${BORDER}`,
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <div style={{ fontSize: 20, color: MUTED }}>trimr.ai</div>
          <div style={{ fontSize: 18, color: MUTED2 }}>AI Hairstyle Matching</div>
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ═══════════════════════════════════════════════════════════════════════════════
// IMAGE 2 — Score Explainer   1080 × 1080
// Use: Instagram feed, Twitter/X, LinkedIn — educational post
// ═══════════════════════════════════════════════════════════════════════════════
export const ScoreExplainerImage: React.FC = () => {
  const criteria = [
    {
      icon: "🎯",
      label: "Face Shape Match",
      score: 95,
      desc: "How well the cut's geometry complements the proportions of your specific face shape.",
    },
    {
      icon: "👤",
      label: "Age Appropriateness",
      score: 88,
      desc: "Whether the style flatters your features and hair texture at your current life stage.",
    },
    {
      icon: "⏱️",
      label: "Maintenance Level",
      score: 76,
      desc: "How much daily effort and salon frequency the cut requires to stay looking sharp.",
    },
    {
      icon: "🔥",
      label: "Trend Score",
      score: 91,
      desc: "How current the style is across global barbershop and editorial trends right now.",
    },
    {
      icon: "✂️",
      label: "Styling Difficulty",
      score: 82,
      desc: "How easy it is for you to recreate the look at home without professional tools.",
    },
  ];

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(ellipse at 70% 10%, #1a1508 0%, ${BG} 60%)`,
        fontFamily: F,
      }}
    >
      <div style={{ display: "flex", flexDirection: "column", height: "100%", padding: 64 }}>
        {/* Top bar */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            marginBottom: 48,
          }}
        >
          <TrimrLogo size={30} />
          <div
            style={{
              padding: "8px 20px",
              borderRadius: 40,
              border: `1px solid ${GOLD_BORDER}`,
              fontSize: 16,
              color: GOLD,
              fontWeight: 600,
              letterSpacing: 2,
              textTransform: "uppercase" as const,
            }}
          >
            Score Guide
          </div>
        </div>

        {/* Headline */}
        <div style={{ marginBottom: 16 }}>
          <div style={{ fontSize: 52, fontWeight: 900, color: WHITE, letterSpacing: -2, lineHeight: 1.05, marginBottom: 12 }}>
            Your score is built
            <br />
            from <span style={{ color: GOLD }}>5 criteria.</span>
          </div>
          <div style={{ fontSize: 20, color: MUTED, fontWeight: 300, lineHeight: 1.5 }}>
            Each haircut is rated against your specific face — not a generic template.
          </div>
        </div>

        <div style={{ marginBottom: 32 }}>
          <GoldDivider width={60} />
        </div>

        {/* Criteria rows */}
        <div style={{ display: "flex", flexDirection: "column", gap: 20, flex: 1 }}>
          {criteria.map((c) => {
            const col = scoreColor(c.score);
            return (
              <div
                key={c.label}
                style={{
                  display: "flex",
                  gap: 20,
                  padding: "18px 20px",
                  background: SURFACE,
                  border: `1px solid ${BORDER}`,
                  borderRadius: 16,
                  alignItems: "center",
                }}
              >
                {/* Icon */}
                <div style={{ fontSize: 32, flexShrink: 0 }}>{c.icon}</div>

                {/* Label + desc */}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 20, fontWeight: 700, color: WHITE, marginBottom: 4 }}>
                    {c.label}
                  </div>
                  <div style={{ fontSize: 15, color: MUTED, fontWeight: 300, lineHeight: 1.4 }}>
                    {c.desc}
                  </div>
                </div>

                {/* Score + bar */}
                <div style={{ flexShrink: 0, textAlign: "right" as const }}>
                  <div style={{ fontSize: 28, fontWeight: 900, color: col, letterSpacing: -1, lineHeight: 1, marginBottom: 6 }}>
                    {c.score}
                  </div>
                  <div style={{ width: 80, height: 5, background: "#1a1a1a", borderRadius: 3, overflow: "hidden" }}>
                    <div style={{ height: "100%", borderRadius: 3, background: col, width: `${c.score}%` }} />
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Overall */}
        <div
          style={{
            marginTop: 24,
            padding: "20px 24px",
            background: `linear-gradient(135deg, ${GOLD_DIM}, rgba(201,168,76,0.04))`,
            border: `1px solid ${GOLD_BORDER}`,
            borderRadius: 16,
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <div>
            <div style={{ fontSize: 16, color: MUTED, letterSpacing: 2, textTransform: "uppercase" as const, marginBottom: 4 }}>Overall Match Score</div>
            <div style={{ fontSize: 16, color: MUTED, fontWeight: 300 }}>Weighted average across all 5 criteria</div>
          </div>
          <div style={{ fontSize: 60, fontWeight: 900, color: GREEN, letterSpacing: -3 }}>
            92<span style={{ fontSize: 24, color: MUTED, fontWeight: 400 }}>/100</span>
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ═══════════════════════════════════════════════════════════════════════════════
// IMAGE 3 — Face Shape Guide   1080 × 1920
// Use: Stories, educational Reel cover, Pinterest
// ═══════════════════════════════════════════════════════════════════════════════
export const FaceShapeGuideImage: React.FC = () => {
  const shapes = [
    {
      icon: "⬭",
      name: "Oval",
      desc: "Balanced proportions. The most versatile shape.",
      cuts: ["Textured Fringe", "Quiff", "Side Part", "Buzz Cut"],
      avoid: "Very long, flat styles",
    },
    {
      icon: "▢",
      name: "Square",
      desc: "Strong jaw. Angular, defined features.",
      cuts: ["Faux Hawk", "Pompadour", "Textured Crop"],
      avoid: "Box-shaped cuts that mirror the jaw",
    },
    {
      icon: "◯",
      name: "Round",
      desc: "Soft, full cheeks. Equal width and length.",
      cuts: ["High Fade + Volume Top", "Angular Fringe"],
      avoid: "Round, curly or bowl cuts",
    },
    {
      icon: "♡",
      name: "Heart",
      desc: "Wider forehead, narrower chin.",
      cuts: ["Side Swept Fringe", "Textured Waves"],
      avoid: "Styles that add width to the top",
    },
    {
      icon: "◇",
      name: "Diamond",
      desc: "Wide cheekbones, narrow forehead and chin.",
      cuts: ["Side Part", "Slicked Back"],
      avoid: "Extra volume at the cheeks",
    },
    {
      icon: "⬮",
      name: "Oblong",
      desc: "Long and narrow. Tall forehead.",
      cuts: ["Textured Quiff", "Messy Fringe"],
      avoid: "Styles with added height on top",
    },
  ];

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(ellipse at 50% 5%, #1a1508 0%, ${BG} 50%)`,
        fontFamily: F,
      }}
    >
      <div style={{ display: "flex", flexDirection: "column", height: "100%", padding: "72px 64px 64px" }}>
        {/* Header */}
        <div style={{ marginBottom: 12 }}>
          <TrimrLogo size={26} />
        </div>

        <div style={{ marginBottom: 40 }}>
          <Tag>Face Shape Guide</Tag>
          <div style={{ fontSize: 62, fontWeight: 900, color: WHITE, letterSpacing: -2.5, lineHeight: 1.05, marginBottom: 14 }}>
            Find your shape.<br />
            <span style={{ color: GOLD }}>Own your cut.</span>
          </div>
          <div style={{ fontSize: 21, color: MUTED, fontWeight: 300, lineHeight: 1.5 }}>
            TRIMR AI detects your face shape automatically — here's what each shape means for your ideal hairstyle.
          </div>
        </div>

        <GoldDivider width="100%" height={1} />
        <div style={{ marginTop: 36 }} />

        {/* Shape grid — 2 columns */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1fr 1fr",
            gap: 20,
            flex: 1,
          }}
        >
          {shapes.map((s) => (
            <div
              key={s.name}
              style={{
                background: SURFACE,
                border: `1px solid ${BORDER}`,
                borderRadius: 20,
                padding: "24px 22px",
                display: "flex",
                flexDirection: "column",
                gap: 10,
              }}
            >
              {/* Icon + name */}
              <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                <div
                  style={{
                    width: 52,
                    height: 52,
                    borderRadius: 14,
                    background: GOLD_DIM,
                    border: `1px solid ${GOLD_BORDER}`,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontSize: 26,
                    flexShrink: 0,
                  }}
                >
                  {s.icon}
                </div>
                <div>
                  <div style={{ fontSize: 26, fontWeight: 900, color: GOLD, letterSpacing: -0.5 }}>{s.name}</div>
                </div>
              </div>

              {/* Desc */}
              <div style={{ fontSize: 15, color: MUTED, fontWeight: 300, lineHeight: 1.4 }}>{s.desc}</div>

              {/* Best cuts */}
              <div>
                <div style={{ fontSize: 11, color: MUTED2, letterSpacing: 2, textTransform: "uppercase" as const, marginBottom: 8 }}>Works well</div>
                <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
                  {s.cuts.slice(0, 2).map((c) => (
                    <div key={c} style={{ fontSize: 14, color: OFF_WHITE, display: "flex", alignItems: "center", gap: 6 }}>
                      <span style={{ color: GREEN, fontSize: 10 }}>●</span> {c}
                    </div>
                  ))}
                </div>
              </div>

              {/* Avoid */}
              <div style={{ fontSize: 13, color: MUTED2, borderTop: `1px solid ${BORDER}`, paddingTop: 10 }}>
                <span style={{ color: RED, fontSize: 10 }}>●</span>{" "}
                <span style={{ color: MUTED2 }}>Avoid: </span>
                {s.avoid}
              </div>
            </div>
          ))}
        </div>

        {/* Footer */}
        <div
          style={{
            marginTop: 36,
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            borderTop: `1px solid ${BORDER}`,
            paddingTop: 28,
          }}
        >
          <div style={{ fontSize: 18, color: MUTED }}>trimr.ai — AI Hairstyle Matching</div>
          <div style={{ fontSize: 16, color: MUTED2 }}>Scan to find yours →</div>
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ═══════════════════════════════════════════════════════════════════════════════
// IMAGE 4 — What You Get   1080 × 1080
// Use: Instagram feed, Twitter/X — feature overview
// ═══════════════════════════════════════════════════════════════════════════════
export const WhatYouGetImage: React.FC = () => {
  const features = [
    {
      icon: "🎯",
      title: "Face Shape Detection",
      desc: "AI maps 12 facial landmarks to identify your exact face shape with precision.",
      tier: "Free",
    },
    {
      icon: "✂️",
      title: "Top 3 Cut Recommendations",
      desc: "Ranked by compatibility score — each matched specifically to your face.",
      tier: "Free",
    },
    {
      icon: "📸",
      title: "AI-Generated Photos",
      desc: "See yourself in each recommended hairstyle before committing to the chair.",
      tier: "Pro",
    },
    {
      icon: "💬",
      title: "Barber Instructions",
      desc: "Word-for-word script to hand to your barber. No more miscommunication.",
      tier: "Pro",
    },
    {
      icon: "🧴",
      title: "Styling Tips",
      desc: "Step-by-step guide to recreate the look at home with product recommendations.",
      tier: "Pro",
    },
    {
      icon: "📚",
      title: "Saved Library",
      desc: "Save your favourite recommendations and revisit them before every appointment.",
      tier: "Pro",
    },
  ];

  const tierColor = (t: string) => (t === "Free" ? GREEN : GOLD);

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(ellipse at 30% 0%, #1a1508 0%, ${BG} 55%)`,
        fontFamily: F,
      }}
    >
      <div style={{ display: "flex", flexDirection: "column", height: "100%", padding: 60 }}>
        {/* Top bar */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 44 }}>
          <TrimrLogo size={28} />
          <div style={{ fontSize: 16, color: MUTED }}>What's included</div>
        </div>

        {/* Headline */}
        <div style={{ marginBottom: 36 }}>
          <div style={{ fontSize: 54, fontWeight: 900, color: WHITE, letterSpacing: -2, lineHeight: 1.05, marginBottom: 10 }}>
            Everything you need
            <br />
            for the <span style={{ color: GOLD }}>perfect cut.</span>
          </div>
        </div>

        {/* Feature grid — 2×3 */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16, flex: 1 }}>
          {features.map((f) => (
            <div
              key={f.title}
              style={{
                background: SURFACE,
                border: `1px solid ${BORDER}`,
                borderRadius: 20,
                padding: "22px 20px",
                display: "flex",
                flexDirection: "column",
                gap: 8,
                position: "relative" as const,
              }}
            >
              {/* Tier badge */}
              <div
                style={{
                  position: "absolute" as const,
                  top: 14,
                  right: 14,
                  fontSize: 11,
                  fontWeight: 700,
                  letterSpacing: 1.5,
                  textTransform: "uppercase" as const,
                  color: tierColor(f.tier),
                  background: f.tier === "Free"
                    ? "rgba(78,203,113,0.1)"
                    : GOLD_DIM,
                  border: `1px solid ${f.tier === "Free" ? "rgba(78,203,113,0.3)" : GOLD_BORDER}`,
                  padding: "3px 10px",
                  borderRadius: 40,
                }}
              >
                {f.tier}
              </div>

              <div style={{ fontSize: 34 }}>{f.icon}</div>
              <div style={{ fontSize: 18, fontWeight: 700, color: WHITE, lineHeight: 1.2, paddingRight: 48 }}>
                {f.title}
              </div>
              <div style={{ fontSize: 13, color: MUTED, fontWeight: 300, lineHeight: 1.5 }}>{f.desc}</div>
            </div>
          ))}
        </div>

        {/* CTA strip */}
        <div
          style={{
            marginTop: 20,
            padding: "16px 24px",
            background: GOLD_DIM,
            border: `1px solid ${GOLD_BORDER}`,
            borderRadius: 14,
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <div style={{ fontSize: 16, color: OFF_WHITE, fontWeight: 300 }}>
            Start free · Upgrade anytime
          </div>
          <div style={{ fontSize: 16, color: GOLD, fontWeight: 700 }}>trimr.ai →</div>
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ═══════════════════════════════════════════════════════════════════════════════
// IMAGE 5 — Barber Brief   1080 × 1920
// Use: "Show this to your barber" shareable card — Stories, DMs
// ═══════════════════════════════════════════════════════════════════════════════
export const BarberBriefImage: React.FC = () => {
  const briefData = {
    name: "Alex",
    faceShape: "Oval",
    haircutName: "Textured Fringe",
    score: 92,
    instructions: [
      "Leave 3–4 inches on top, cut with texture scissors for movement",
      "Taper the sides — medium fade starting around the temples",
      "Blend the fade into the natural hairline at the back",
      "Fringe should fall naturally — no hard blunt line",
      "Finish with light thinning on bulk areas to reduce weight",
    ],
    products: ["Matt clay (light hold)", "Sea salt spray for texture"],
    note: "Reference photo sent via link. Please match the overall volume and fringe direction.",
  };

  return (
    <AbsoluteFill
      style={{
        background: BG,
        fontFamily: F,
      }}
    >
      {/* Gold top bar */}
      <div
        style={{
          height: 6,
          background: `linear-gradient(90deg, ${GOLD}, ${GOLD_LIGHT}, ${GOLD})`,
        }}
      />

      <div style={{ display: "flex", flexDirection: "column", height: "calc(100% - 6px)", padding: "64px 72px 64px" }}>
        {/* Header */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "flex-start",
            marginBottom: 48,
          }}
        >
          <div>
            <div style={{ fontSize: 16, color: MUTED, letterSpacing: 3, textTransform: "uppercase" as const, marginBottom: 8 }}>
              TRIMR AI — Barber Brief
            </div>
            <div style={{ fontSize: 52, fontWeight: 900, color: WHITE, letterSpacing: -2, lineHeight: 1 }}>
              Show this to
              <br />
              <span style={{ color: GOLD }}>your barber.</span>
            </div>
          </div>
          <TrimrLogo size={24} />
        </div>

        {/* Client + cut info */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1fr 1fr 1fr",
            gap: 16,
            marginBottom: 40,
          }}
        >
          {[
            { label: "Client", value: briefData.name },
            { label: "Face Shape", value: briefData.faceShape },
            { label: "Match Score", value: `${briefData.score}/100`, gold: true },
          ].map((item) => (
            <div
              key={item.label}
              style={{
                background: SURFACE,
                border: `1px solid ${item.gold ? GOLD_BORDER : BORDER}`,
                borderRadius: 14,
                padding: "16px 18px",
              }}
            >
              <div style={{ fontSize: 12, color: MUTED, letterSpacing: 2, textTransform: "uppercase" as const, marginBottom: 6 }}>
                {item.label}
              </div>
              <div
                style={{
                  fontSize: 24,
                  fontWeight: 900,
                  color: item.gold ? GOLD : WHITE,
                  letterSpacing: -0.5,
                }}
              >
                {item.value}
              </div>
            </div>
          ))}
        </div>

        {/* Cut name */}
        <div
          style={{
            background: `linear-gradient(135deg, ${GOLD_DIM}, rgba(201,168,76,0.03))`,
            border: `1px solid ${GOLD_BORDER}`,
            borderRadius: 20,
            padding: "28px 32px",
            marginBottom: 32,
          }}
        >
          <div style={{ fontSize: 14, color: GOLD, letterSpacing: 3, textTransform: "uppercase" as const, marginBottom: 10 }}>
            Recommended Haircut
          </div>
          <div style={{ fontSize: 52, fontWeight: 900, color: WHITE, letterSpacing: -2, lineHeight: 1 }}>
            {briefData.haircutName}
          </div>
        </div>

        {/* Instructions */}
        <div
          style={{
            background: SURFACE,
            border: `1px solid ${BORDER}`,
            borderRadius: 20,
            padding: "28px 32px",
            marginBottom: 24,
            flex: 1,
          }}
        >
          <div style={{ fontSize: 14, color: MUTED, letterSpacing: 3, textTransform: "uppercase" as const, marginBottom: 20 }}>
            ✂️ Cutting Instructions
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            {briefData.instructions.map((inst, i) => (
              <div key={i} style={{ display: "flex", gap: 16, alignItems: "flex-start" }}>
                <div
                  style={{
                    width: 28,
                    height: 28,
                    borderRadius: "50%",
                    background: GOLD_DIM,
                    border: `1px solid ${GOLD_BORDER}`,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontSize: 13,
                    fontWeight: 900,
                    color: GOLD,
                    flexShrink: 0,
                    marginTop: 2,
                  }}
                >
                  {i + 1}
                </div>
                <div style={{ fontSize: 22, color: OFF_WHITE, lineHeight: 1.4, fontWeight: 300 }}>{inst}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Products */}
        <div
          style={{
            background: SURFACE2,
            border: `1px solid ${BORDER}`,
            borderRadius: 16,
            padding: "20px 24px",
            marginBottom: 20,
          }}
        >
          <div style={{ fontSize: 13, color: MUTED, letterSpacing: 2, textTransform: "uppercase" as const, marginBottom: 12 }}>
            🧴 Product Finish
          </div>
          <div style={{ display: "flex", gap: 12 }}>
            {briefData.products.map((p) => (
              <div
                key={p}
                style={{
                  padding: "8px 18px",
                  borderRadius: 40,
                  border: `1px solid ${BORDER2}`,
                  fontSize: 17,
                  color: OFF_WHITE,
                  background: SURFACE,
                }}
              >
                {p}
              </div>
            ))}
          </div>
        </div>

        {/* Note */}
        <div style={{ fontSize: 18, color: MUTED, fontStyle: "italic", lineHeight: 1.5, marginBottom: 32 }}>
          "{briefData.note}"
        </div>

        {/* Footer */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            borderTop: `1px solid ${BORDER}`,
            paddingTop: 24,
          }}
        >
          <div style={{ fontSize: 17, color: MUTED }}>Generated by TRIMR AI · trimr.ai</div>
          <div
            style={{
              padding: "8px 20px",
              borderRadius: 40,
              background: GOLD_DIM,
              border: `1px solid ${GOLD_BORDER}`,
              fontSize: 15,
              color: GOLD,
              fontWeight: 600,
            }}
          >
            AI-Matched
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};
