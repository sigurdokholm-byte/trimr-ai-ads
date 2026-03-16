/**
 * Organic 2: "Barber Brief" — Shows the barber script feature
 * Style: Relatable problem → satisfying typewriter solution
 * Hook: "telling your barber what you want be like 💀"
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
const MUTED = "#666";
const BORDER = "#222";

const BARBER_SCRIPT =
  `Ask for a textured crop with a skin fade — start at a #1 on the sides and blend up naturally. Leave 3–4 inches on top and ask for scissor texture work through the crown. Finish with a matte clay for that clean, lived-in look.`;

// ── Helpers ───────────────────────────────────────────────────────────────────

const StatusBar: React.FC = () => (
  <div style={{ height: 52, background: BG, display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 36px", flexShrink: 0 }}>
    <span style={{ color: "#fff", fontSize: 18, fontWeight: 700, fontFamily: "sans-serif" }}>9:41</span>
    <span style={{ color: "#fff", fontSize: 15, fontFamily: "sans-serif" }}>●●●● 5G 🔋</span>
  </div>
);

const TypewriterText: React.FC<{ text: string; startFrame: number; speed?: number }> = ({ text, startFrame, speed = 0.8 }) => {
  const frame = useCurrentFrame();
  const n = Math.min(text.length, Math.floor(Math.max(0, frame - startFrame) * speed));
  const showCursor = n < text.length || Math.floor(frame / 14) % 2 === 0;
  return (
    <span style={{ fontSize: 17, color: "#d0b860", fontFamily: "sans-serif", lineHeight: 1.65 }}>
      {text.slice(0, n)}
      {showCursor && n <= text.length && <span style={{ opacity: showCursor ? 1 : 0, color: GOLD }}>|</span>}
    </span>
  );
};

const ScoreBar: React.FC<{ delay: number; score: number }> = ({ delay, score }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const p = spring({ fps, frame: frame - delay, config: { damping: 80, stiffness: 55 }, durationInFrames: 28 });
  return (
    <div style={{ flex: 1, height: 5, background: "#1e1e1e", borderRadius: 3, overflow: "hidden" }}>
      <div style={{ width: `${interpolate(p, [0, 1], [0, score])}%`, height: "100%", background: GOLD, borderRadius: 3 }} />
    </div>
  );
};

// ── Main ──────────────────────────────────────────────────────────────────────

export const Organic_BarberBrief: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const appSlide = spring({ fps, frame: frame - 78, config: { damping: 80, stiffness: 90 }, durationInFrames: 25 });
  const appY = interpolate(appSlide, [0, 1], [120, 0]);
  const appOp = interpolate(frame, [78, 96], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  const ctaEnter = spring({ fps, frame: frame - 300, config: { damping: 80 }, durationInFrames: 20 });

  const copyBtnOp = interpolate(frame, [276, 290], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const copyPulse = frame >= 276 ? 1 + Math.sin((frame - 276) * 0.25) * 0.03 : 1;

  const c = (s: number, e: number) =>
    interpolate(frame, [s, s + 7, e - 7, e], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  return (
    <AbsoluteFill style={{ background: BG }}>

      {/* ── Phase 1: Hook (0–44) ── */}
      {frame < 44 && (
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 70px" }}>
          <div style={{ opacity: c(0, 44), fontSize: 52, fontWeight: 900, color: "#fff", fontFamily: "sans-serif", lineHeight: 1.25, textAlign: "center" }}>
            telling your barber<br />what you want:
          </div>
        </div>
      )}

      {/* ── Phase 2: Chaos quotes (44–78) ── */}
      {frame >= 44 && frame < 78 && (
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 70px", gap: 12 }}>
          {[
            { text: '"uh... shorter on the sides?"', delay: 44, size: 40 },
            { text: '"like... you know... that thing"', delay: 52, size: 36 },
            { text: '"whatever looks good I guess"', delay: 60, size: 32 },
          ].map(({ text, delay, size }) => (
            <div key={text} style={{
              opacity: interpolate(frame, [delay, delay + 5, 76, 78], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }),
              fontSize: size, fontWeight: 700, color: frame < 65 ? "#fff" : "#888",
              fontFamily: "sans-serif", fontStyle: "italic", textAlign: "center",
            }}>
              {text}
            </div>
          ))}
        </div>
      )}

      {/* Transition caption (68–95) */}
      {frame >= 68 && frame < 100 && (
        <div style={{
          position: "absolute", bottom: 160, left: 0, right: 0, textAlign: "center",
          opacity: interpolate(frame, [68, 78, 92, 100], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }),
          fontSize: 36, fontWeight: 900, color: GOLD, fontFamily: "sans-serif",
        }}>
          Trimr AI writes the script ✂️
        </div>
      )}

      {/* ── Phase 3: App UI (78+) ── */}
      {frame >= 78 && (
        <div style={{ position: "absolute", inset: 0, opacity: appOp, transform: `translateY(${appY}px)`, display: "flex", flexDirection: "column" }}>
          <StatusBar />

          {/* Nav bar */}
          <div style={{ padding: "16px 36px 14px", borderBottom: `1px solid ${BORDER}`, display: "flex", alignItems: "center", gap: 12, background: BG, flexShrink: 0 }}>
            <span style={{ fontSize: 18, color: MUTED, fontFamily: "sans-serif" }}>←</span>
            <span style={{ fontSize: 22, fontWeight: 900, color: GOLD, fontFamily: "sans-serif", letterSpacing: 1 }}>TRIMR</span>
            <span style={{ fontSize: 15, color: MUTED, fontFamily: "sans-serif" }}>AI</span>
          </div>

          {/* Cut context header */}
          <div style={{ padding: "20px 36px 16px", borderBottom: `1px solid ${BORDER}`, flexShrink: 0 }}>
            <div style={{ fontSize: 13, color: MUTED, fontFamily: "sans-serif", letterSpacing: 1.5, textTransform: "uppercase", marginBottom: 5 }}>
              01 · Best Match
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end" }}>
              <div>
                <div style={{ fontSize: 26, fontWeight: 900, color: "#fff", fontFamily: "sans-serif" }}>Textured Crop</div>
                <div style={{ fontSize: 14, color: MUTED, fontFamily: "sans-serif", marginTop: 3 }}>Oval face · AI analyzed</div>
              </div>
              <div style={{ textAlign: "right" }}>
                <div style={{ fontSize: 38, fontWeight: 900, color: GOLD, fontFamily: "sans-serif", lineHeight: 1 }}>92</div>
                <div style={{ fontSize: 12, color: MUTED, fontFamily: "sans-serif" }}>score</div>
              </div>
            </div>
            {/* Mini score bar */}
            <div style={{ display: "flex", alignItems: "center", gap: 10, marginTop: 10 }}>
              <ScoreBar delay={92} score={92} />
            </div>
          </div>

          {/* Barber Brief card */}
          <div style={{ flex: 1, padding: "20px 28px", overflow: "hidden" }}>
            {frame >= 108 && (
              <div style={{
                background: "linear-gradient(145deg, #1a1400 0%, #2c2000 100%)",
                border: `1.5px solid ${GOLD}45`,
                borderRadius: 22,
                padding: "24px 26px",
                opacity: interpolate(frame, [108, 126], [0, 1], { extrapolateRight: "clamp" }),
              }}>
                {/* Section title */}
                <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 18 }}>
                  <span style={{ fontSize: 20 }}>✂️</span>
                  <span style={{ fontSize: 17, fontWeight: 900, color: GOLD, fontFamily: "sans-serif", letterSpacing: 0.5 }}>Barber Brief</span>
                  <span style={{ fontSize: 13, color: "#555", fontFamily: "sans-serif" }}>· show this to your barber</span>
                </div>

                {/* Gold script box */}
                <div style={{ background: "#0d0b00", border: `1px solid ${GOLD}28`, borderRadius: 14, padding: "18px 20px", marginBottom: 18 }}>
                  {frame >= 126
                    ? <TypewriterText text={BARBER_SCRIPT} startFrame={126} speed={0.72} />
                    : null
                  }
                </div>

                {/* Copy button */}
                {frame >= 276 && (
                  <div style={{
                    background: GOLD, borderRadius: 14, padding: "14px 0", textAlign: "center",
                    transform: `scale(${copyPulse})`, opacity: copyBtnOp,
                  }}>
                    <span style={{ fontSize: 16, fontWeight: 900, color: "#000", fontFamily: "sans-serif", letterSpacing: 0.5 }}>
                      📋 Copy to clipboard
                    </span>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      )}

      {/* ── CTA (300+) ── */}
      {frame >= 300 && (
        <div style={{
          position: "absolute", bottom: 80, left: 0, right: 0,
          display: "flex", flexDirection: "column", alignItems: "center", gap: 14,
          opacity: ctaEnter,
          transform: `translateY(${interpolate(ctaEnter, [0, 1], [24, 0])}px)`,
        }}>
          <div style={{ background: GOLD, borderRadius: 60, padding: "20px 64px", fontSize: 26, fontWeight: 900, color: "#000", fontFamily: "sans-serif" }}>
            Get Your Script Free →
          </div>
          <div style={{ fontSize: 16, color: "#444", fontFamily: "sans-serif", letterSpacing: 1.5 }}>trimr-ai.app</div>
        </div>
      )}
    </AbsoluteFill>
  );
};
