/**
 * Organic 1: "App Flow" — Full user journey in 10 seconds
 * Style: Screen-recording feel — face shape reveal moment
 * Hook: "POV: you finally know your face shape"
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

// ── Shared helpers ────────────────────────────────────────────────────────────

const fadeSlide = (
  frame: number,
  fps: number,
  startFrame: number,
  damping = 80,
  stiffness = 120,
) => {
  const s = spring({ fps, frame: frame - startFrame, config: { damping, stiffness }, durationInFrames: 20 });
  return { opacity: s, y: interpolate(s, [0, 1], [28, 0]) };
};

// ── Sub-components ────────────────────────────────────────────────────────────

const StatusBar: React.FC = () => (
  <div style={{ height: 52, background: BG, display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 36px", flexShrink: 0 }}>
    <span style={{ color: "#fff", fontSize: 18, fontWeight: 700, fontFamily: "sans-serif" }}>9:41</span>
    <span style={{ color: "#fff", fontSize: 15, fontFamily: "sans-serif" }}>●●●● 5G 🔋</span>
  </div>
);

const AppHeader: React.FC = () => (
  <div style={{ padding: "16px 40px 14px", borderBottom: `1px solid ${BORDER}`, display: "flex", alignItems: "center", gap: 10, background: BG, flexShrink: 0 }}>
    <span style={{ fontSize: 22, fontWeight: 900, color: GOLD, fontFamily: "sans-serif", letterSpacing: 1 }}>TRIMR</span>
    <span style={{ fontSize: 15, color: MUTED, fontFamily: "sans-serif" }}>AI</span>
  </div>
);

const LoadingDots: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
      {[0, 1, 2].map((i) => {
        const phase = ((frame + i * 10) % 30) / 30;
        const op = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
        return (
          <div key={i} style={{ width: 12, height: 12, borderRadius: "50%", background: GOLD, opacity: 0.25 + op * 0.75 }} />
        );
      })}
    </div>
  );
};

const FaceShapeBadge: React.FC<{ delay: number }> = ({ delay }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const enter = spring({ fps, frame: frame - delay, config: { damping: 65, stiffness: 180 }, durationInFrames: 22 });
  const scale = interpolate(enter, [0, 0.55, 1], [0.82, 1.06, 1]);

  return (
    <div style={{
      opacity: enter,
      transform: `scale(${scale})`,
      background: "linear-gradient(145deg, #1c1600 0%, #2e2200 100%)",
      border: `1.5px solid ${GOLD}45`,
      borderRadius: 28,
      padding: "36px 40px",
      margin: "0 32px",
      textAlign: "center",
      position: "relative",
    }}>
      <div style={{ position: "absolute", top: 20, right: 20, background: GOLD, borderRadius: 24, padding: "5px 16px", fontFamily: "sans-serif", fontSize: 16, fontWeight: 900, color: "#000" }}>
        92
      </div>
      <div style={{ fontSize: 64, marginBottom: 10 }}>⬭</div>
      <div style={{ fontSize: 13, color: MUTED, fontFamily: "sans-serif", letterSpacing: 3, marginBottom: 8, textTransform: "uppercase" }}>Your Face Shape</div>
      <div style={{ fontSize: 46, fontWeight: 900, color: GOLD, fontFamily: "sans-serif", letterSpacing: -1, marginBottom: 10 }}>OVAL</div>
      <div style={{ fontSize: 16, color: "#777", fontFamily: "sans-serif", lineHeight: 1.5 }}>
        Well-proportioned with balanced features.{"\n"}Almost any hairstyle works for you.
      </div>
    </div>
  );
};

const CutCard: React.FC<{ rank: string; name: string; score: number; delay: number }> = ({ rank, name, score, delay }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const { opacity, y } = fadeSlide(frame, fps, delay, 70, 110);
  const barProgress = spring({ fps, frame: frame - (delay + 12), config: { damping: 80, stiffness: 55 }, durationInFrames: 30 });
  const barW = interpolate(barProgress, [0, 1], [0, score]);
  const barColor = score >= 88 ? GOLD : "#7AC74F";

  return (
    <div style={{ opacity, transform: `translateY(${y}px)`, background: CARD, border: `1px solid ${BORDER}`, borderRadius: 20, padding: "18px 24px", margin: "0 32px 14px", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 12, color: GOLD, fontFamily: "sans-serif", fontWeight: 700, letterSpacing: 1.5, marginBottom: 4 }}>{rank}</div>
        <div style={{ fontSize: 20, fontWeight: 900, color: "#fff", fontFamily: "sans-serif", marginBottom: 8 }}>{name}</div>
        <div style={{ width: 160, height: 5, background: "#1e1e1e", borderRadius: 3, overflow: "hidden" }}>
          <div style={{ width: `${barW}%`, height: "100%", background: barColor, borderRadius: 3 }} />
        </div>
      </div>
      <div style={{ fontSize: 36, fontWeight: 900, color: barColor, fontFamily: "sans-serif", marginLeft: 16 }}>{score}</div>
    </div>
  );
};

// ── Main component ────────────────────────────────────────────────────────────

export const Organic_AppFlow: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const ctaEnter = spring({ fps, frame: frame - 272, config: { damping: 80 }, durationInFrames: 22 });

  // Caption helpers
  const cap = (s: number, e: number) =>
    interpolate(frame, [s, s + 7, e - 7, e], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  const appSlide = spring({ fps, frame: frame - 52, config: { damping: 80, stiffness: 90 }, durationInFrames: 25 });
  const appY = interpolate(appSlide, [0, 1], [120, 0]);
  const appOp = interpolate(frame, [52, 70], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  return (
    <AbsoluteFill style={{ background: BG }}>

      {/* ── Phase 1: Hook captions (0–52) ── */}
      {frame < 52 && (
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 70px", gap: 14 }}>
          <div style={{ opacity: cap(0, 30), fontSize: 58, fontWeight: 900, color: "#fff", fontFamily: "sans-serif", lineHeight: 1.2, textAlign: "center" }}>
            POV: you've had the<br />
            <span style={{ color: GOLD }}>same haircut</span> for years
          </div>
          <div style={{ opacity: cap(30, 52), position: "absolute", fontSize: 48, fontWeight: 900, color: "#aaa", fontFamily: "sans-serif", lineHeight: 1.2, textAlign: "center" }}>
            and never questioned it 💀
          </div>
        </div>
      )}

      {/* ── Phase 2–4: App UI (frame 52+) ── */}
      {frame >= 52 && (
        <div style={{
          position: "absolute", inset: 0,
          opacity: appOp,
          transform: `translateY(${appY}px)`,
          display: "flex", flexDirection: "column",
        }}>
          <StatusBar />
          <AppHeader />

          {/* Loading state (52–138) */}
          {frame < 138 && (
            <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 24 }}>
              <div style={{ fontSize: 64 }}>🔍</div>
              <div style={{ fontSize: 24, fontWeight: 800, color: "#fff", fontFamily: "sans-serif" }}>Analyzing your face...</div>
              <LoadingDots />
              <div style={{ fontSize: 16, color: MUTED, fontFamily: "sans-serif", textAlign: "center", lineHeight: 1.6, marginTop: 8 }}>
                Mapping face shape · jaw · symmetry
              </div>
              {/* Progress text cycling */}
              <div style={{ fontSize: 14, color: "#444", fontFamily: "sans-serif", opacity: interpolate(frame, [80, 90], [0, 1], { extrapolateRight: "clamp" }) }}>
                {frame < 100 ? "Reading facial geometry..." : frame < 118 ? "Comparing 500K+ profiles..." : "Ranking your top cuts..."}
              </div>
            </div>
          )}

          {/* Results (138+) */}
          {frame >= 138 && (
            <div style={{ flex: 1, overflow: "hidden" }}>
              {/* Results header */}
              <div style={{ padding: "20px 36px 14px", opacity: interpolate(frame, [138, 154], [0, 1], { extrapolateRight: "clamp" }) }}>
                <div style={{ fontSize: 14, color: MUTED, fontFamily: "sans-serif", marginBottom: 4 }}>Your results are in</div>
                <div style={{ fontSize: 28, fontWeight: 900, color: "#fff", fontFamily: "sans-serif" }}>Your Top Cuts.</div>
                <div style={{ fontSize: 15, color: "#555", fontFamily: "sans-serif" }}>AI-analyzed and ranked by compatibility</div>
              </div>

              {/* Face shape badge */}
              {frame >= 145 && <FaceShapeBadge delay={145} />}

              {/* Cut cards */}
              {frame >= 210 && (
                <div style={{ marginTop: 18 }}>
                  <div style={{ fontSize: 13, color: MUTED, fontFamily: "sans-serif", padding: "0 36px 10px", letterSpacing: 1.5, textTransform: "uppercase" }}>
                    AI-ranked recommendations
                  </div>
                  <CutCard rank="01 · BEST MATCH" name="Textured Fringe" score={92} delay={212} />
                  <CutCard rank="02 · GREAT MATCH" name="Mid Fade" score={86} delay={228} />
                  <CutCard rank="03 · GOOD MATCH" name="Side Part" score={79} delay={244} />
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* ── Phase 5: CTA (272+) ── */}
      {frame >= 272 && (
        <div style={{
          position: "absolute", bottom: 80, left: 0, right: 0,
          display: "flex", flexDirection: "column", alignItems: "center", gap: 14,
          opacity: ctaEnter,
          transform: `translateY(${interpolate(ctaEnter, [0, 1], [24, 0])}px)`,
        }}>
          <div style={{ background: GOLD, borderRadius: 60, padding: "20px 64px", fontSize: 26, fontWeight: 900, color: "#000", fontFamily: "sans-serif" }}>
            Try Trimr AI Free →
          </div>
          <div style={{ fontSize: 16, color: "#444", fontFamily: "sans-serif", letterSpacing: 1.5 }}>trimr-ai.app</div>
        </div>
      )}
    </AbsoluteFill>
  );
};
