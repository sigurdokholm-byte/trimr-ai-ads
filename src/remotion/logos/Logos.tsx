/**
 * TRIMR AI — Logo Animations
 *
 * Logo_Wordmark  — letter-by-letter wipe reveal, gold underline sweep (3s)
 * Logo_Mark      — three diagonal slash lines draw in, wordmark rises (3.5s)
 * Logo_Badge     — circular ring draws clockwise, badge content scales in (3.7s)
 */
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

const GOLD = "#C9A84C";
const BG = "#080808";
const WHITE = "#F0EDE8";
const DIM = "#1c1c1c";

// ─────────────────────────────────────────────────────────────────────────────
// LOGO 1 — WORDMARK
// ─────────────────────────────────────────────────────────────────────────────

const WipeLetter: React.FC<{ char: string; delay: number; color?: string; size?: number }> = ({
  char, delay, color = WHITE, size = 148,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const enter = spring({ fps, frame: frame - delay, config: { damping: 72, stiffness: 260, mass: 0.6 }, durationInFrames: 12 });
  return (
    <div style={{ overflow: "hidden", display: "inline-block", lineHeight: 1 }}>
      <span style={{
        display: "inline-block",
        transform: `translateY(${interpolate(enter, [0, 1], [size, 0])}px)`,
        color,
        fontFamily: "'Archivo Black', sans-serif",
        fontSize: size,
        fontWeight: 900,
        letterSpacing: -3,
        lineHeight: 1,
      }}>{char}</span>
    </div>
  );
};

export const Logo_Wordmark: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const lineEnter = spring({ fps, frame: frame - 36, config: { damping: 80, stiffness: 60 }, durationInFrames: 28 });
  const lineW = interpolate(lineEnter, [0, 1], [0, 100]);

  const tagOp = interpolate(frame, [58, 72], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  // "AI" slides up from below (same mechanic, delayed)
  const aiEnter = spring({ fps, frame: frame - 28, config: { damping: 72, stiffness: 260, mass: 0.6 }, durationInFrames: 12 });
  const aiY = interpolate(aiEnter, [0, 1], [148, 0]);

  return (
    <AbsoluteFill style={{ background: BG, alignItems: "center", justifyContent: "center", flexDirection: "column" }}>

      {/* Wordmark row */}
      <div style={{ display: "flex", alignItems: "baseline", gap: 0 }}>
        {"TRIMR".split("").map((ch, i) => (
          <WipeLetter key={i} char={ch} delay={i * 5} />
        ))}

        <div style={{ width: 22 }} />

        {/* AI in gold */}
        <div style={{ overflow: "hidden", display: "inline-block", lineHeight: 1 }}>
          <span style={{
            display: "inline-block",
            transform: `translateY(${aiY}px)`,
            color: GOLD,
            fontFamily: "'Archivo Black', sans-serif",
            fontSize: 148,
            fontWeight: 900,
            letterSpacing: -3,
            lineHeight: 1,
          }}>AI</span>
        </div>
      </div>

      {/* Gold underline sweeps right */}
      <div style={{ width: 660, height: 2, background: DIM, marginTop: 10, position: "relative", overflow: "hidden", borderRadius: 1 }}>
        <div style={{ position: "absolute", inset: 0, right: `${100 - lineW}%`, background: GOLD }} />
      </div>

      {/* Tagline */}
      <div style={{
        marginTop: 20,
        opacity: tagOp,
        fontFamily: "'DM Mono', monospace",
        fontSize: 13,
        letterSpacing: 6,
        textTransform: "uppercase",
        color: "#3a3a3a",
      }}>
        Hairstyle Intelligence
      </div>
    </AbsoluteFill>
  );
};

// ─────────────────────────────────────────────────────────────────────────────
// LOGO 2 — MARK  (three slash lines + wordmark)
// ─────────────────────────────────────────────────────────────────────────────

// SVG path length for a line from (0,260) to (140,0) ≈ 298px
const SLASH_LEN = 298;

const Slash: React.FC<{ x: number; delay: number; color?: string }> = ({ x, delay, color = WHITE }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const p = spring({ fps, frame: frame - delay, config: { damping: 80, stiffness: 65 }, durationInFrames: 26 });
  const offset = interpolate(p, [0, 1], [SLASH_LEN, 0]);
  return (
    <line
      x1={x} y1={260}
      x2={x + 140} y2={0}
      stroke={color}
      strokeWidth={5}
      strokeLinecap="round"
      strokeDasharray={SLASH_LEN}
      strokeDashoffset={offset}
    />
  );
};

export const Logo_Mark: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Gold crossbar
  const barEnter = spring({ fps, frame: frame - 38, config: { damping: 80, stiffness: 75 }, durationInFrames: 24 });
  const barW = interpolate(barEnter, [0, 1], [0, 280]);

  // Wordmark rise
  const wordEnter = spring({ fps, frame: frame - 55, config: { damping: 80, stiffness: 90 }, durationInFrames: 20 });
  const wordY = interpolate(wordEnter, [0, 1], [28, 0]);

  // Dot blink in
  const dotOp = interpolate(frame, [72, 82], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  return (
    <AbsoluteFill style={{ background: BG, alignItems: "center", justifyContent: "center", flexDirection: "column" }}>

      {/* Mark — three diagonal slashes */}
      <svg width={320} height={280} viewBox="0 0 320 280" style={{ overflow: "visible" }}>
        <Slash x={10}  delay={0}  />
        <Slash x={90}  delay={10} />
        <Slash x={170} delay={20} />

        {/* Gold horizontal bar sweeps right */}
        <rect x={10} y={254} width={barW} height={3} fill={GOLD} rx={1.5} />
      </svg>

      {/* Wordmark */}
      <div style={{
        opacity: wordEnter,
        transform: `translateY(${wordY}px)`,
        display: "flex",
        alignItems: "baseline",
        gap: 14,
        marginTop: 20,
      }}>
        <span style={{ fontFamily: "'Archivo Black', sans-serif", fontSize: 64, fontWeight: 900, color: WHITE, letterSpacing: -1.5, lineHeight: 1 }}>
          TRIMR
        </span>
        <span style={{ fontFamily: "'Archivo Black', sans-serif", fontSize: 64, fontWeight: 900, color: GOLD, letterSpacing: -1.5, lineHeight: 1 }}>
          AI
        </span>
      </div>

      {/* Accent dot */}
      <div style={{ width: 7, height: 7, borderRadius: "50%", background: GOLD, marginTop: 18, opacity: dotOp }} />
    </AbsoluteFill>
  );
};

// ─────────────────────────────────────────────────────────────────────────────
// LOGO 3 — BADGE  (ring draws in, center content scales up)
// ─────────────────────────────────────────────────────────────────────────────

const R = 230;
const CIRC = 2 * Math.PI * R;

export const Logo_Badge: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Outer ring draw
  const ringEnter = spring({ fps, frame: frame - 0, config: { damping: 80, stiffness: 35 }, durationInFrames: 50 });
  const ringOffset = interpolate(ringEnter, [0, 1], [CIRC, 0]);

  // Inner ring (slightly smaller, dim)
  const innerEnter = spring({ fps, frame: frame - 8, config: { damping: 80, stiffness: 35 }, durationInFrames: 50 });
  const innerOffset = interpolate(innerEnter, [0, 1], [CIRC * (200 / R), 0]);

  // Center text scale-in
  const textEnter = spring({ fps, frame: frame - 42, config: { damping: 68, stiffness: 120 }, durationInFrames: 22 });
  const textScale = interpolate(textEnter, [0, 0.55, 1], [0.82, 1.05, 1]);

  // "AI" mono tag
  const aiOp = interpolate(frame, [64, 76], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  // Bottom tagline
  const tagOp = interpolate(frame, [76, 88], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  // 4 tick marks appear after ring
  const tickOp = interpolate(frame, [46, 58], [0, 0.45], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  return (
    <AbsoluteFill style={{ background: BG, alignItems: "center", justifyContent: "center" }}>

      {/* Ring SVG */}
      <svg width={560} height={560} viewBox="-280 -280 560 560" style={{ position: "absolute" }}>

        {/* Dim track rings */}
        <circle cx={0} cy={0} r={R} fill="none" stroke={DIM} strokeWidth={1} />
        <circle cx={0} cy={0} r={200} fill="none" stroke={DIM} strokeWidth={1} opacity={0.6} />

        {/* Animated outer ring */}
        <circle
          cx={0} cy={0} r={R}
          fill="none"
          stroke={GOLD}
          strokeWidth={2}
          strokeLinecap="round"
          strokeDasharray={CIRC}
          strokeDashoffset={ringOffset}
          transform="rotate(-90)"
        />

        {/* Animated inner ring (slightly behind) */}
        <circle
          cx={0} cy={0} r={200}
          fill="none"
          stroke={GOLD}
          strokeWidth={1}
          strokeOpacity={0.3}
          strokeLinecap="round"
          strokeDasharray={CIRC * (200 / R)}
          strokeDashoffset={innerOffset}
          transform="rotate(-90)"
        />

        {/* 4 tick marks at cardinal points */}
        {[0, 90, 180, 270].map((angle) => {
          const rad = (angle * Math.PI) / 180;
          return (
            <line
              key={angle}
              x1={Math.cos(rad) * 208}
              y1={Math.sin(rad) * 208}
              x2={Math.cos(rad) * 222}
              y2={Math.sin(rad) * 222}
              stroke={GOLD}
              strokeWidth={1.5}
              opacity={tickOp}
            />
          );
        })}
      </svg>

      {/* Center content */}
      <div style={{
        opacity: textEnter,
        transform: `scale(${textScale})`,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 0,
      }}>
        {/* TRIMR */}
        <div style={{
          fontFamily: "'Archivo Black', sans-serif",
          fontSize: 112,
          fontWeight: 900,
          color: WHITE,
          letterSpacing: -2,
          lineHeight: 1,
        }}>
          TRIMR
        </div>

        {/* Divider */}
        <div style={{ width: 72, height: 1, background: GOLD, opacity: 0.5, margin: "8px 0 10px" }} />

        {/* AI mono tag */}
        <div style={{
          opacity: aiOp,
          fontFamily: "'DM Mono', monospace",
          fontSize: 20,
          letterSpacing: 8,
          color: GOLD,
          textTransform: "uppercase",
        }}>
          AI
        </div>
      </div>

      {/* Bottom tagline outside ring */}
      <div style={{
        position: "absolute",
        bottom: 148,
        opacity: tagOp,
        fontFamily: "'DM Mono', monospace",
        fontSize: 11,
        letterSpacing: 7,
        textTransform: "uppercase",
        color: "#2e2e2e",
      }}>
        Hairstyle Intelligence
      </div>
    </AbsoluteFill>
  );
};

// ─────────────────────────────────────────────────────────────────────────────
// STATIC IMAGE LOGOS  (durationInFrames: 1 — rendered as PNG)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * LogoImage_Horizontal — wide wordmark on black, 1920×1080
 * Use for: YouTube channel art, video thumbnails, email headers
 */
export const LogoImage_Horizontal: React.FC = () => (
  <AbsoluteFill style={{ background: BG, alignItems: "center", justifyContent: "center", flexDirection: "column" }}>
    <div style={{ display: "flex", alignItems: "baseline", gap: 0 }}>
      <span style={{ fontFamily: "'Archivo Black', sans-serif", fontSize: 160, fontWeight: 900, color: WHITE, letterSpacing: -4, lineHeight: 1 }}>
        TRIMR
      </span>
      <div style={{ width: 24 }} />
      <span style={{ fontFamily: "'Archivo Black', sans-serif", fontSize: 160, fontWeight: 900, color: GOLD, letterSpacing: -4, lineHeight: 1 }}>
        AI
      </span>
    </div>
    <div style={{ width: 720, height: 2, background: GOLD, opacity: 0.7, marginTop: 12, borderRadius: 1 }} />
    <div style={{ marginTop: 20, fontFamily: "'DM Mono', monospace", fontSize: 14, letterSpacing: 6, textTransform: "uppercase", color: "#3a3a3a" }}>
      Hairstyle Intelligence
    </div>
  </AbsoluteFill>
);

/**
 * LogoImage_Square — slash mark + stacked wordmark, 1080×1080
 * Use for: profile pictures, social avatar, watermark
 */
export const LogoImage_Square: React.FC = () => (
  <AbsoluteFill style={{ background: BG, alignItems: "center", justifyContent: "center", flexDirection: "column" }}>
    <svg width={300} height={260} viewBox="0 0 300 260" style={{ overflow: "visible", marginBottom: 28 }}>
      {[0, 80, 160].map((x) => (
        <line key={x} x1={x + 10} y1={250} x2={x + 140} y2={10} stroke={WHITE} strokeWidth={5} strokeLinecap="round" />
      ))}
      <rect x={10} y={244} width={280} height={3} fill={GOLD} rx={1.5} />
    </svg>
    <div style={{ display: "flex", alignItems: "baseline", gap: 16 }}>
      <span style={{ fontFamily: "'Archivo Black', sans-serif", fontSize: 80, fontWeight: 900, color: WHITE, letterSpacing: -2, lineHeight: 1 }}>TRIMR</span>
      <span style={{ fontFamily: "'Archivo Black', sans-serif", fontSize: 80, fontWeight: 900, color: GOLD, letterSpacing: -2, lineHeight: 1 }}>AI</span>
    </div>
    <div style={{ marginTop: 14, fontFamily: "'DM Mono', monospace", fontSize: 12, letterSpacing: 5, textTransform: "uppercase", color: "#333" }}>
      Hairstyle Intelligence
    </div>
  </AbsoluteFill>
);

/**
 * LogoImage_Icon — T lettermark inside a partial gold ring, 1080×1080
 * Use for: favicon, app icon, small-format badge
 */
export const LogoImage_Icon: React.FC = () => {
  const RI = 310;
  const CIRC_I = 2 * Math.PI * RI;
  return (
    <AbsoluteFill style={{ background: BG, alignItems: "center", justifyContent: "center" }}>
      <svg width={720} height={720} viewBox="-360 -360 720 720" style={{ position: "absolute" }}>
        <circle cx={0} cy={0} r={RI} fill="none" stroke={DIM} strokeWidth={1.5} />
        <circle cx={0} cy={0} r={RI} fill="none" stroke={GOLD} strokeWidth={2.5}
          strokeDasharray={`${CIRC_I * 0.72} ${CIRC_I * 0.28}`}
          transform="rotate(-90)" strokeLinecap="round"
        />
        {[0, 90, 180, 270].map((angle) => {
          const rad = (angle * Math.PI) / 180;
          return (
            <line key={angle}
              x1={Math.cos(rad) * (RI - 10)} y1={Math.sin(rad) * (RI - 10)}
              x2={Math.cos(rad) * (RI + 10)} y2={Math.sin(rad) * (RI + 10)}
              stroke={GOLD} strokeWidth={1.5} opacity={0.5}
            />
          );
        })}
      </svg>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
        <span style={{ fontFamily: "'Archivo Black', sans-serif", fontSize: 220, fontWeight: 900, color: WHITE, letterSpacing: -6, lineHeight: 1 }}>T</span>
        <div style={{ width: 60, height: 2, background: GOLD, borderRadius: 1, opacity: 0.8 }} />
        <div style={{ fontFamily: "'DM Mono', monospace", fontSize: 18, letterSpacing: 8, color: GOLD }}>AI</div>
      </div>
    </AbsoluteFill>
  );
};
