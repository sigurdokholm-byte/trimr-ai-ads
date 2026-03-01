import { AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";

// ─── Brand tokens ──────────────────────────────────────────────────────────────
const BG = "#0a0a0a";
const SURFACE = "#141414";
const BORDER = "#1f1f1f";
const GOLD = "#C9A84C";
const GOLD_LIGHT = "#E8C96A";
const WHITE = "#ffffff";
const MUTED = "#999999";
const RED = "#e84747";
const YELLOW = "#f0d060";
const GREEN = "#4ecb71";

// ─── Animation helpers ─────────────────────────────────────────────────────────
const clamp = { extrapolateLeft: "clamp" as const, extrapolateRight: "clamp" as const };

const fadeIn = (frame: number, start: number, dur = 15) =>
  interpolate(frame, [start, start + dur], [0, 1], clamp);

const slideUp = (frame: number, start: number, dur = 18, dist = 50) => ({
  opacity: fadeIn(frame, start, dur),
  transform: `translateY(${interpolate(frame, [start, start + dur], [dist, 0], clamp)}px)`,
});

const pop = (frame: number, fps: number, start: number) =>
  spring({ frame: frame - start, fps, config: { stiffness: 280, damping: 20, mass: 0.7 }, from: 0, to: 1 });

const growX = (frame: number, fps: number, start: number) =>
  spring({ frame: frame - start, fps, config: { stiffness: 180, damping: 26 }, from: 0, to: 1 });

const scoreColor = (s: number) => (s <= 40 ? RED : s <= 70 ? YELLOW : GREEN);

// ─── Shared sub-components ─────────────────────────────────────────────────────
const GoldBar: React.FC<{ width?: number; delay?: number; height?: number }> = ({
  width = 80,
  delay = 0,
  height = 3,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const sx = growX(frame, fps, delay);
  return (
    <div
      style={{
        width,
        height,
        background: `linear-gradient(90deg, ${GOLD}, ${GOLD_LIGHT})`,
        borderRadius: 2,
        transformOrigin: "left center",
        transform: `scaleX(${sx})`,
      }}
    />
  );
};

const TrimrBug: React.FC<{ size?: number }> = ({ size = 28 }) => (
  <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
    <div
      style={{
        fontFamily: "Helvetica Neue, Arial, sans-serif",
        fontWeight: 900,
        fontSize: size,
        letterSpacing: -1,
        color: WHITE,
        lineHeight: 1,
      }}
    >
      TRIM<span style={{ color: GOLD }}>R</span>
    </div>
    <div
      style={{
        fontFamily: "Helvetica Neue, Arial, sans-serif",
        fontSize: size * 0.6,
        color: MUTED,
        fontWeight: 400,
      }}
    >
      AI
    </div>
  </div>
);

const FACE_ICONS: Record<string, string> = {
  oval: "⬭",
  round: "◯",
  square: "▢",
  heart: "♡",
  oblong: "⬮",
  diamond: "◇",
};

// ═══════════════════════════════════════════════════════════════════════════════
// COMPOSITION 1 — Score Reveal   1080 × 1920   7s (210 frames)
// Use case: "My TRIMR results 👀" reel / TikTok
// ═══════════════════════════════════════════════════════════════════════════════
export interface ScoreRevealProps {
  name: string;
  faceShape: string;
  overallScore: number;
  faceShapeMatch: number;
  ageAppropriateness: number;
  maintenance: number;
  trendScore: number;
  stylingDifficulty: number;
}

export const ScoreReveal: React.FC<ScoreRevealProps> = ({
  name,
  faceShape,
  overallScore,
  faceShapeMatch,
  ageAppropriateness,
  maintenance,
  trendScore,
  stylingDifficulty,
}) => {
  const frame = useCurrentFrame();

  const criteria = [
    { label: "Face Shape Match", icon: "🎯", value: faceShapeMatch },
    { label: "Age Appropriateness", icon: "👤", value: ageAppropriateness },
    { label: "Maintenance Level", icon: "⏱️", value: maintenance },
    { label: "Trend Score", icon: "🔥", value: trendScore },
    { label: "Styling Difficulty", icon: "✂️", value: stylingDifficulty },
  ];

  const animatedOverall = Math.round(interpolate(frame, [65, 105], [0, overallScore], clamp));
  const overallBarW = interpolate(frame, [75, 115], [0, overallScore], clamp);
  const faceIcon = FACE_ICONS[faceShape.toLowerCase()] ?? "⬭";
  const col = scoreColor(overallScore);

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(ellipse at 50% 10%, #1a1508 0%, ${BG} 65%)`,
        fontFamily: "Helvetica Neue, Arial, sans-serif",
      }}
    >
      <AbsoluteFill
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          padding: "96px 64px 72px",
        }}
      >
        {/* Header */}
        <div style={{ ...slideUp(frame, 0), textAlign: "center", marginBottom: 32 }}>
          <div style={{ fontSize: 20, letterSpacing: 6, color: GOLD, textTransform: "uppercase", fontWeight: 600, marginBottom: 10 }}>
            TRIMR AI
          </div>
          <div style={{ fontSize: 56, fontWeight: 900, color: WHITE, letterSpacing: -2, lineHeight: 1.05 }}>
            {name}'s Results
          </div>
        </div>

        <div style={{ marginBottom: 36 }}>
          <GoldBar width={90} delay={8} />
        </div>

        {/* Face shape badge */}
        <div
          style={{
            ...slideUp(frame, 22, 20),
            background: `linear-gradient(135deg, rgba(201,168,76,0.14), rgba(201,168,76,0.04))`,
            border: `1px solid rgba(201,168,76,0.35)`,
            borderRadius: 28,
            padding: "24px 52px",
            textAlign: "center",
            marginBottom: 44,
            width: "100%",
          }}
        >
          <div style={{ fontSize: 72, marginBottom: 10 }}>{faceIcon}</div>
          <div style={{ fontSize: 17, color: MUTED, letterSpacing: 4, textTransform: "uppercase", marginBottom: 6 }}>Your Face Shape</div>
          <div style={{ fontSize: 52, fontWeight: 900, color: GOLD, letterSpacing: -1 }}>{faceShape.toUpperCase()}</div>
        </div>

        {/* Overall score */}
        <div style={{ textAlign: "center", marginBottom: 44 }}>
          <div style={{ ...slideUp(frame, 50, 16), fontSize: 20, color: MUTED, letterSpacing: 3, textTransform: "uppercase", marginBottom: 6 }}>
            Overall Match Score
          </div>
          <div style={{ ...slideUp(frame, 60, 16), fontSize: 112, fontWeight: 900, letterSpacing: -4, color: col, lineHeight: 1 }}>
            {animatedOverall}
            <span style={{ fontSize: 36, color: MUTED, fontWeight: 400 }}>/100</span>
          </div>
          <div style={{ ...slideUp(frame, 68), width: "100%", height: 12, background: "#1a1a1a", borderRadius: 6, overflow: "hidden", marginTop: 14 }}>
            <div style={{ height: "100%", borderRadius: 6, background: `linear-gradient(90deg, ${RED}, ${YELLOW}, ${GREEN})`, width: `${overallBarW}%` }} />
          </div>
        </div>

        {/* Criteria breakdown */}
        <div style={{ width: "100%", display: "flex", flexDirection: "column", gap: 20 }}>
          {criteria.map((c, i) => {
            const barStart = 100 + i * 16;
            const barW = interpolate(frame, [barStart, barStart + 28], [0, c.value], clamp);
            const color = scoreColor(c.value);
            return (
              <div key={c.label} style={{ ...slideUp(frame, barStart, 14, 24) }}>
                <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
                  <div style={{ fontSize: 24, color: WHITE, display: "flex", alignItems: "center", gap: 10 }}>
                    <span>{c.icon}</span> {c.label}
                  </div>
                  <div style={{ fontSize: 24, fontWeight: 700, color }}>{c.value}</div>
                </div>
                <div style={{ height: 8, background: BORDER, borderRadius: 4, overflow: "hidden" }}>
                  <div style={{ height: "100%", borderRadius: 4, background: color, width: `${barW}%` }} />
                </div>
              </div>
            );
          })}
        </div>

        <div style={{ marginTop: "auto", paddingTop: 36, opacity: fadeIn(frame, 190) }}>
          <TrimrBug size={30} />
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// ═══════════════════════════════════════════════════════════════════════════════
// COMPOSITION 2 — Haircut Card   1080 × 1920   6s (180 frames)
// Use case: "My AI recommended cut" reveal post / story
// ═══════════════════════════════════════════════════════════════════════════════
export interface HaircutCardProps {
  rank: number;
  haircutName: string;
  score: number;
  faceShape: string;
  whyItWorks: string;
  tip1: string;
  tip2: string;
}

export const HaircutCard: React.FC<HaircutCardProps> = ({
  rank,
  haircutName,
  score,
  faceShape,
  whyItWorks,
  tip1,
  tip2,
}) => {
  const frame = useCurrentFrame();

  const rankLabel = rank === 1 ? "01 · BEST MATCH" : rank === 2 ? "02 · RUNNER UP" : `0${rank} · MATCH`;
  const col = scoreColor(score);
  const animatedScore = Math.round(interpolate(frame, [48, 88], [0, score], clamp));
  const barW = interpolate(frame, [58, 100], [0, score], clamp);

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(ellipse at 25% 15%, #1a1508 0%, ${BG} 58%)`,
        fontFamily: "Helvetica Neue, Arial, sans-serif",
      }}
    >
      <AbsoluteFill style={{ display: "flex", flexDirection: "column", padding: "96px 72px 72px" }}>
        <div style={{ ...slideUp(frame, 0, 14), fontSize: 22, letterSpacing: 4, color: GOLD, textTransform: "uppercase", fontWeight: 700, marginBottom: 24 }}>
          {rankLabel}
        </div>

        <div
          style={{
            fontSize: haircutName.length > 12 ? 76 : 96,
            fontWeight: 900,
            letterSpacing: -3,
            color: WHITE,
            lineHeight: 1,
            marginBottom: 36,
            transform: `translateY(${interpolate(frame, [8, 28], [70, 0], clamp)}px) scale(${interpolate(frame, [8, 28], [0.88, 1], clamp)})`,
            opacity: fadeIn(frame, 8, 18),
          }}
        >
          {haircutName}
        </div>

        <div style={{ marginBottom: 40 }}>
          <GoldBar width={130} delay={24} height={4} />
        </div>

        <div style={{ ...slideUp(frame, 44, 16), display: "flex", alignItems: "baseline", gap: 10, marginBottom: 14 }}>
          <div style={{ fontSize: 96, fontWeight: 900, letterSpacing: -4, color: col, lineHeight: 1 }}>{animatedScore}</div>
          <div style={{ fontSize: 34, color: MUTED }}>/ 100</div>
        </div>

        <div style={{ height: 12, background: "#1a1a1a", borderRadius: 6, overflow: "hidden", marginBottom: 52, width: "100%" }}>
          <div style={{ height: "100%", borderRadius: 6, background: `linear-gradient(90deg, ${RED}, ${YELLOW}, ${GREEN})`, width: `${barW}%` }} />
        </div>

        <div style={{ ...slideUp(frame, 76, 18), background: SURFACE, border: `1px solid ${BORDER}`, borderRadius: 20, padding: "26px 30px", marginBottom: 22 }}>
          <div style={{ fontSize: 17, color: GOLD, letterSpacing: 2, textTransform: "uppercase", marginBottom: 10 }}>💡 Why It Works</div>
          <div style={{ fontSize: 27, color: WHITE, lineHeight: 1.45, fontWeight: 300 }}>{whyItWorks}</div>
        </div>

        {[tip1, tip2].map((tip, i) => (
          <div key={i} style={{ ...slideUp(frame, 98 + i * 12, 15), display: "flex", gap: 14, alignItems: "flex-start", marginBottom: 14 }}>
            <div style={{ fontSize: 22, fontWeight: 800, color: GOLD, minWidth: 24 }}>{i + 1}.</div>
            <div style={{ fontSize: 25, color: "#c0c0c0", lineHeight: 1.4 }}>{tip}</div>
          </div>
        ))}

        <div style={{ ...slideUp(frame, 128), marginTop: 28 }}>
          <div style={{ display: "inline-block", padding: "10px 26px", borderRadius: 40, border: `1px solid rgba(201,168,76,0.4)`, color: GOLD, fontSize: 22 }}>
            {faceShape} face
          </div>
        </div>

        <div style={{ marginTop: "auto", paddingTop: 36, opacity: fadeIn(frame, 148) }}>
          <TrimrBug size={28} />
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// ═══════════════════════════════════════════════════════════════════════════════
// COMPOSITION 3 — Before / After Story   1080 × 1920   9s (270 frames)
// Use case: Dramatic transformation story / reel opener
// ═══════════════════════════════════════════════════════════════════════════════
export interface BeforeAfterStoryProps {
  haircutName: string;
  score: number;
  faceShape: string;
  username: string;
}

export const BeforeAfterStory: React.FC<BeforeAfterStoryProps> = ({
  haircutName,
  score,
  faceShape,
  username,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const wipe = interpolate(frame, [72, 148], [0, 100], clamp);
  const dividerVisible = frame > 70 && frame < 158;
  const col = scoreColor(score);
  const animatedScore = Math.round(interpolate(frame, [148, 198], [0, score], clamp));

  return (
    <AbsoluteFill style={{ background: BG, overflow: "hidden", fontFamily: "Helvetica Neue, Arial, sans-serif" }}>
      {/* BEFORE panel */}
      <AbsoluteFill
        style={{
          background: "linear-gradient(160deg, #111 0%, #0a0a0a 100%)",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <div style={{ ...slideUp(frame, 0, 20), fontSize: 32, letterSpacing: 8, color: MUTED, textTransform: "uppercase", marginBottom: 56 }}>Before</div>
        <div style={{ width: 300, height: 380, background: "linear-gradient(180deg, #2a2a2a, #1a1a1a)", borderRadius: "50% 50% 45% 45%", border: "3px solid #222", opacity: fadeIn(frame, 6, 18), marginBottom: 56 }} />
        <div style={{ ...slideUp(frame, 14, 16), fontSize: 38, color: "#444", fontWeight: 300 }}>No plan. No idea.</div>
      </AbsoluteFill>

      {/* AFTER panel */}
      <AbsoluteFill
        style={{
          clipPath: `inset(0 ${100 - wipe}% 0 0)`,
          background: "linear-gradient(160deg, #1c1408 0%, #0a0802 100%)",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          padding: "80px 64px",
        }}
      >
        <div style={{ fontSize: 32, letterSpacing: 8, color: GOLD, textTransform: "uppercase", marginBottom: 44 }}>After TRIMR AI</div>

        <div style={{ position: "relative", width: 300, height: 380, marginBottom: 44 }}>
          <div style={{ width: 300, height: 380, background: "linear-gradient(180deg, #3a2e10, #1e1a08)", borderRadius: "50% 50% 45% 45%", border: `2px solid rgba(201,168,76,0.4)`, position: "relative", overflow: "visible" }}>
            <div style={{ position: "absolute", top: -56, left: -28, right: -28, height: 96, background: "#1a1208", borderRadius: "50% 50% 0 0" }} />
            <div style={{ position: "absolute", top: -28, left: -38, width: 46, height: 130, background: "#1a1208", borderRadius: "40% 0 0 40%" }} />
            <div style={{ position: "absolute", top: -28, right: -38, width: 46, height: 130, background: "#1a1208", borderRadius: "0 40% 40% 0" }} />
          </div>
          <div style={{ position: "absolute", inset: -10, borderRadius: "50% 50% 45% 45%", border: `2px solid rgba(201,168,76,0.25)`, opacity: interpolate(frame, [148, 168], [0, 1], clamp) }} />
        </div>

        <div style={{ textAlign: "center", marginBottom: 20 }}>
          <div style={{ fontSize: 28, color: MUTED, letterSpacing: 3, marginBottom: 6 }}>Match Score</div>
          <div style={{ fontSize: 112, fontWeight: 900, letterSpacing: -4, color: col, lineHeight: 1, transform: `scale(${pop(frame, fps, 148)})` }}>
            {animatedScore}
            <span style={{ fontSize: 44, color: MUTED, fontWeight: 400 }}>/100</span>
          </div>
        </div>

        <div style={{ fontSize: 48, fontWeight: 900, color: WHITE, letterSpacing: -1, textAlign: "center", marginBottom: 14, opacity: fadeIn(frame, 158, 16) }}>
          {haircutName}
        </div>
        <div style={{ fontSize: 26, color: MUTED, opacity: fadeIn(frame, 166, 16), marginBottom: 44 }}>
          {faceShape} face · @{username}
        </div>
        <div style={{ opacity: fadeIn(frame, 178, 16) }}>
          <TrimrBug size={30} />
        </div>
      </AbsoluteFill>

      {dividerVisible && (
        <>
          <div style={{ position: "absolute", top: 0, bottom: 0, left: `${wipe}%`, width: 4, background: WHITE, boxShadow: "0 0 24px rgba(255,255,255,0.85)" }} />
          <div style={{ position: "absolute", top: "50%", left: `${wipe}%`, transform: "translate(-50%, -50%)", width: 48, height: 48, borderRadius: "50%", background: WHITE, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 22, fontWeight: 900, color: BG, boxShadow: "0 0 20px rgba(255,255,255,0.6)" }}>
            ⇔
          </div>
        </>
      )}
    </AbsoluteFill>
  );
};

// ═══════════════════════════════════════════════════════════════════════════════
// COMPOSITION 4 — Lower Third   1920 × 1080   5s (150 frames)
// Use case: YouTube videos, Twitch streams, talking-head overlays
// ═══════════════════════════════════════════════════════════════════════════════
export interface LowerThirdProps {
  title: string;
  subtitle: string;
  score: number;
}

export const LowerThird: React.FC<LowerThirdProps> = ({ title, subtitle, score }) => {
  const frame = useCurrentFrame();
  const col = scoreColor(score);

  const slideY = interpolate(frame, [0, 22], [120, 0], clamp);
  const fadeOut = interpolate(frame, [118, 145], [1, 0], clamp);
  const barScaleY = interpolate(frame, [4, 28], [0, 1], clamp);

  return (
    <AbsoluteFill style={{ background: "transparent", fontFamily: "Helvetica Neue, Arial, sans-serif" }}>
      <div style={{ position: "absolute", bottom: 72, left: 72, transform: `translateY(${slideY}px)`, opacity: fadeOut }}>
        <div style={{ display: "inline-flex", alignItems: "stretch", background: "rgba(10,10,10,0.96)", border: `1px solid rgba(201,168,76,0.28)`, borderRadius: 16, overflow: "hidden", backdropFilter: "blur(8px)" }}>
          <div style={{ width: 6, background: `linear-gradient(180deg, ${GOLD}, ${GOLD_LIGHT})`, transformOrigin: "top center", transform: `scaleY(${barScaleY})` }} />
          <div style={{ padding: "18px 28px" }}>
            <div style={{ fontSize: 36, fontWeight: 900, color: WHITE, letterSpacing: -1, marginBottom: 5, opacity: interpolate(frame, [10, 26], [0, 1], clamp) }}>
              {title}
            </div>
            <div style={{ fontSize: 20, color: MUTED, letterSpacing: 0.5, opacity: interpolate(frame, [16, 30], [0, 1], clamp) }}>
              {subtitle} · Analyzed by <span style={{ color: GOLD, fontWeight: 700 }}>TRIMR AI</span>
            </div>
          </div>
          <div style={{ padding: "18px 32px", borderLeft: `1px solid rgba(201,168,76,0.2)`, background: `rgba(201,168,76,0.07)`, textAlign: "center", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", opacity: interpolate(frame, [22, 38], [0, 1], clamp) }}>
            <div style={{ fontSize: 44, fontWeight: 900, color: col, letterSpacing: -2, lineHeight: 1 }}>{score}</div>
            <div style={{ fontSize: 15, color: MUTED, letterSpacing: 1 }}>/100</div>
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ═══════════════════════════════════════════════════════════════════════════════
// COMPOSITION 5 — Feed Square Post   1080 × 1080   5s (150 frames)
// Use case: Instagram / Twitter / LinkedIn animated post
// ═══════════════════════════════════════════════════════════════════════════════
export interface FeedSquareProps {
  faceShape: string;
  haircutName: string;
  score: number;
  username: string;
  tip: string;
}

export const FeedSquare: React.FC<FeedSquareProps> = ({
  faceShape,
  haircutName,
  score,
  username,
  tip,
}) => {
  const frame = useCurrentFrame();

  const col = scoreColor(score);
  const faceIcon = FACE_ICONS[faceShape.toLowerCase()] ?? "⬭";
  const animatedScore = Math.round(interpolate(frame, [38, 80], [0, score], clamp));
  const barW = interpolate(frame, [48, 90], [0, score], clamp);

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(ellipse at 65% 0%, #1a1508 0%, ${BG} 68%)`,
        fontFamily: "Helvetica Neue, Arial, sans-serif",
      }}
    >
      <AbsoluteFill style={{ display: "flex", flexDirection: "column", padding: 60 }}>
        <div style={{ ...slideUp(frame, 0, 14), display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 44 }}>
          <TrimrBug size={30} />
          <div style={{ fontSize: 20, color: MUTED }}>@{username}</div>
        </div>

        <div style={{ display: "flex", gap: 20, marginBottom: 32 }}>
          <div style={{ ...slideUp(frame, 14, 16), flex: 1, background: `linear-gradient(135deg, rgba(201,168,76,0.12), rgba(201,168,76,0.04))`, border: `1px solid rgba(201,168,76,0.32)`, borderRadius: 20, padding: "22px 16px", textAlign: "center" }}>
            <div style={{ fontSize: 52, marginBottom: 6 }}>{faceIcon}</div>
            <div style={{ fontSize: 12, color: MUTED, letterSpacing: 3, textTransform: "uppercase", marginBottom: 5 }}>Face Shape</div>
            <div style={{ fontSize: 26, fontWeight: 900, color: GOLD }}>{faceShape}</div>
          </div>
          <div style={{ ...slideUp(frame, 20, 16), flex: 1, background: SURFACE, border: `1px solid ${BORDER}`, borderRadius: 20, padding: "22px 16px", textAlign: "center" }}>
            <div style={{ fontSize: 12, color: MUTED, letterSpacing: 3, textTransform: "uppercase", marginBottom: 6 }}>Match Score</div>
            <div style={{ fontSize: 58, fontWeight: 900, color: col, letterSpacing: -3, lineHeight: 1 }}>{animatedScore}</div>
            <div style={{ fontSize: 16, color: MUTED }}>/100</div>
          </div>
        </div>

        <div style={{ ...slideUp(frame, 32, 16), marginBottom: 12 }}>
          <div style={{ fontSize: 14, color: GOLD, letterSpacing: 3, textTransform: "uppercase", marginBottom: 6 }}>Your #1 Cut</div>
          <div style={{ fontSize: haircutName.length > 14 ? 56 : 68, fontWeight: 900, color: WHITE, letterSpacing: -2, lineHeight: 1 }}>
            {haircutName}
          </div>
        </div>

        <div style={{ height: 10, background: "#1a1a1a", borderRadius: 5, overflow: "hidden", marginBottom: 28 }}>
          <div style={{ height: "100%", borderRadius: 5, background: `linear-gradient(90deg, ${RED}, ${YELLOW}, ${GREEN})`, width: `${barW}%` }} />
        </div>

        <div style={{ ...slideUp(frame, 68, 16), background: SURFACE, border: `1px solid ${BORDER}`, borderRadius: 16, padding: "18px 22px", flex: 1 }}>
          <div style={{ fontSize: 13, color: GOLD, letterSpacing: 2, textTransform: "uppercase", marginBottom: 7 }}>Stylist Tip</div>
          <div style={{ fontSize: 24, color: WHITE, lineHeight: 1.45, fontWeight: 300 }}>{tip}</div>
        </div>

        <div style={{ ...slideUp(frame, 96), paddingTop: 24, marginTop: 20, borderTop: `1px solid ${BORDER}`, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div style={{ fontSize: 17, color: MUTED }}>trimr.ai</div>
          <GoldBar width={56} delay={96} height={2} />
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
