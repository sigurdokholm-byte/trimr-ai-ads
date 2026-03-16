/**
 * Organic 3: "Compatibility Breakdown" — 5-metric score system
 * Style: Satisfying bar-fill animation — "wait till you see all 5 scores"
 * Hook: "this app literally rates your haircut options on 5 criteria"
 */
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

const GOLD = "#C9A84C";
const BG = "#0A0A0A";
const CARD = "#141414";
const MUTED = "#666";
const BORDER = "#222";
const GREEN = "#5DBB63";
const AMBER = "#F59E0B";

const METRICS = [
  { icon: "⬭", label: "Face Shape Match",       score: 94, color: GOLD,  delay: 105 },
  { icon: "🎂", label: "Age Appropriateness",    score: 88, color: GOLD,  delay: 138 },
  { icon: "🔧", label: "Maintenance Level",      score: 72, color: GREEN, delay: 171 },
  { icon: "📈", label: "Trend Score",            score: 91, color: GOLD,  delay: 204 },
  { icon: "✨", label: "Styling Difficulty",      score: 65, color: AMBER, delay: 237 },
] as const;

// ── Helpers ───────────────────────────────────────────────────────────────────

const StatusBar: React.FC = () => (
  <div style={{ height: 52, background: BG, display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 36px", flexShrink: 0 }}>
    <span style={{ color: "#fff", fontSize: 18, fontWeight: 700, fontFamily: "sans-serif" }}>9:41</span>
    <span style={{ color: "#fff", fontSize: 15, fontFamily: "sans-serif" }}>●●●● 5G 🔋</span>
  </div>
);

const MetricRow: React.FC<{ icon: string; label: string; score: number; color: string; delay: number }> = ({ icon, label, score, color, delay }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const cardIn = spring({ fps, frame: frame - delay, config: { damping: 75, stiffness: 110 }, durationInFrames: 18 });
  const barIn = spring({ fps, frame: frame - (delay + 14), config: { damping: 80, stiffness: 55 }, durationInFrames: 30 });
  const barW = interpolate(barIn, [0, 1], [0, score]);

  return (
    <div style={{
      opacity: cardIn,
      transform: `translateY(${interpolate(cardIn, [0, 1], [22, 0])}px)`,
      background: CARD, border: `1px solid ${BORDER}`, borderRadius: 18,
      padding: "16px 24px", margin: "0 28px 12px",
    }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 10 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <span style={{ fontSize: 20 }}>{icon}</span>
          <span style={{ fontSize: 15, fontWeight: 700, color: "#ccc", fontFamily: "sans-serif" }}>{label}</span>
        </div>
        <span style={{ fontSize: 22, fontWeight: 900, color, fontFamily: "sans-serif", minWidth: 36, textAlign: "right" }}>{score}</span>
      </div>
      <div style={{ height: 6, background: "#1a1a1a", borderRadius: 3, overflow: "hidden" }}>
        <div style={{ width: `${barW}%`, height: "100%", background: color, borderRadius: 3 }} />
      </div>
    </div>
  );
};

// ── Main ──────────────────────────────────────────────────────────────────────

export const Organic_CompatibilityBreakdown: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const appSlide = spring({ fps, frame: frame - 58, config: { damping: 80, stiffness: 88 }, durationInFrames: 24 });
  const appY = interpolate(appSlide, [0, 1], [120, 0]);
  const appOp = interpolate(frame, [58, 76], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  const ctaEnter = spring({ fps, frame: frame - 292, config: { damping: 80 }, durationInFrames: 20 });

  // Overall score counting up
  const overallCount = Math.floor(
    interpolate(frame, [270, 290], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }) * 82
  );
  const overallOp = interpolate(frame, [268, 282], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  const c = (s: number, e: number) =>
    interpolate(frame, [s, s + 7, e - 7, e], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  return (
    <AbsoluteFill style={{ background: BG }}>

      {/* ── Phase 1: Hook (0–55) ── */}
      {frame < 55 && (
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 70px", gap: 16 }}>
          <div style={{ opacity: c(0, 32), fontSize: 54, fontWeight: 900, color: "#fff", fontFamily: "sans-serif", lineHeight: 1.2, textAlign: "center" }}>
            this app scores your<br />
            <span style={{ color: GOLD }}>haircut compatibility</span>
          </div>
          <div style={{ opacity: c(32, 55), position: "absolute", textAlign: "center", fontSize: 44, fontWeight: 900, color: "#bbb", fontFamily: "sans-serif", lineHeight: 1.3 }}>
            on <span style={{ color: GOLD }}>5 different criteria</span> 📊
          </div>
        </div>
      )}

      {/* ── Phase 2–4: App UI (58+) ── */}
      {frame >= 58 && (
        <div style={{ position: "absolute", inset: 0, opacity: appOp, transform: `translateY(${appY}px)`, display: "flex", flexDirection: "column" }}>
          <StatusBar />

          {/* Nav */}
          <div style={{ padding: "16px 36px 14px", borderBottom: `1px solid ${BORDER}`, display: "flex", alignItems: "center", gap: 12, background: BG, flexShrink: 0 }}>
            <span style={{ fontSize: 18, color: MUTED, fontFamily: "sans-serif" }}>←</span>
            <span style={{ fontSize: 22, fontWeight: 900, color: GOLD, fontFamily: "sans-serif", letterSpacing: 1 }}>TRIMR</span>
            <span style={{ fontSize: 15, color: MUTED, fontFamily: "sans-serif" }}>AI</span>
          </div>

          {/* Cut header */}
          <div style={{ padding: "18px 32px 16px", borderBottom: `1px solid ${BORDER}`, flexShrink: 0 }}>
            <div style={{ fontSize: 12, color: MUTED, fontFamily: "sans-serif", letterSpacing: 1.5, textTransform: "uppercase", marginBottom: 5 }}>
              01 · Best Match
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end" }}>
              <div>
                <div style={{ fontSize: 26, fontWeight: 900, color: "#fff", fontFamily: "sans-serif" }}>Textured Crop</div>
                <div style={{ fontSize: 14, color: MUTED, fontFamily: "sans-serif", marginTop: 2 }}>Oval face · AI analyzed</div>
              </div>
              <div style={{ textAlign: "right" }}>
                <div style={{ fontSize: 40, fontWeight: 900, color: GOLD, fontFamily: "sans-serif", lineHeight: 1 }}>92</div>
                <div style={{ fontSize: 12, color: MUTED, fontFamily: "sans-serif" }}>overall</div>
              </div>
            </div>
          </div>

          {/* Section label */}
          {frame >= 92 && (
            <div style={{
              padding: "14px 32px 6px",
              opacity: interpolate(frame, [92, 104], [0, 1], { extrapolateRight: "clamp" }),
              display: "flex", alignItems: "center", gap: 8, flexShrink: 0,
            }}>
              <span style={{ fontSize: 14 }}>📊</span>
              <span style={{ fontSize: 13, fontWeight: 800, color: "#999", fontFamily: "sans-serif", letterSpacing: 1.5, textTransform: "uppercase" }}>
                Compatibility Breakdown
              </span>
            </div>
          )}

          {/* Metric bars */}
          <div style={{ flex: 1, paddingTop: 4, overflow: "hidden" }}>
            {METRICS.map((m) => frame >= m.delay ? <MetricRow key={m.label} {...m} /> : null)}

            {/* Overall composite */}
            {frame >= 268 && (
              <div style={{
                opacity: overallOp,
                margin: "4px 28px 0",
                padding: "18px 24px",
                background: "linear-gradient(145deg, #1c1600 0%, #2e2200 100%)",
                border: `1.5px solid ${GOLD}45`,
                borderRadius: 18,
                display: "flex", justifyContent: "space-between", alignItems: "center",
              }}>
                <div>
                  <div style={{ fontSize: 12, color: MUTED, fontFamily: "sans-serif", letterSpacing: 1.5, textTransform: "uppercase", marginBottom: 4 }}>Overall Score</div>
                  <div style={{ fontSize: 16, fontWeight: 800, color: GOLD, fontFamily: "sans-serif" }}>Textured Crop · Oval</div>
                </div>
                <div style={{ fontSize: 52, fontWeight: 900, color: GOLD, fontFamily: "sans-serif", lineHeight: 1 }}>{overallCount}</div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* ── CTA (292+) ── */}
      {frame >= 292 && (
        <div style={{
          position: "absolute", bottom: 80, left: 0, right: 0,
          display: "flex", flexDirection: "column", alignItems: "center", gap: 14,
          opacity: ctaEnter,
          transform: `translateY(${interpolate(ctaEnter, [0, 1], [24, 0])}px)`,
        }}>
          <div style={{ background: GOLD, borderRadius: 60, padding: "20px 64px", fontSize: 26, fontWeight: 900, color: "#000", fontFamily: "sans-serif" }}>
            Find Your Score Free →
          </div>
          <div style={{ fontSize: 16, color: "#444", fontFamily: "sans-serif", letterSpacing: 1.5 }}>trimr-ai.app</div>
        </div>
      )}
    </AbsoluteFill>
  );
};
