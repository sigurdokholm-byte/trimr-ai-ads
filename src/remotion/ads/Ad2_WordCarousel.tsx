/**
 * Ad 2: "Word Carousel" — Rotating face shapes with blur crossfade
 * Hook: your specific face shape is covered, personalisation angle
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

const FACE_SHAPES = [
  { shape: "Round face?", emoji: "🔵", tip: "Textured crop adds length" },
  { shape: "Square face?", emoji: "🟦", tip: "Mid fade softens jaw" },
  { shape: "Oval face?", emoji: "🥚", tip: "Almost anything works" },
  { shape: "Diamond face?", emoji: "💎", tip: "Side part balances width" },
  { shape: "Heart face?", emoji: "🫀", tip: "Fringe reduces forehead" },
];

const FRAMES_PER = 50;
const HOLD = 35;
const FLIP = 15;

const BlurWord: React.FC<{ frame: number }> = ({ frame }) => {
  const totalSteps = FACE_SHAPES.length;
  const currentStep = Math.min(Math.floor(frame / FRAMES_PER), totalSteps - 1);
  const nextStep = Math.min(currentStep + 1, totalSteps - 1);
  const phase = frame % FRAMES_PER;
  const isFlipping = phase >= HOLD && currentStep < totalSteps - 1;
  const flipProgress = isFlipping ? (phase - HOLD) / FLIP : 0;

  const outOpacity = interpolate(flipProgress, [0, 1], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const inOpacity = interpolate(flipProgress, [0, 1], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const outBlur = interpolate(flipProgress, [0, 1], [0, 8], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const inBlur = interpolate(flipProgress, [0, 1], [8, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const outY = interpolate(flipProgress, [0, 1], [0, -30], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const inY = interpolate(flipProgress, [0, 1], [30, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  const curr = FACE_SHAPES[currentStep];
  const next = FACE_SHAPES[nextStep];

  return (
    <div style={{ position: "relative", height: 200, width: "100%" }}>
      {/* Current word */}
      <div style={{
        position: "absolute",
        width: "100%",
        textAlign: "center",
        opacity: outOpacity,
        filter: `blur(${outBlur}px)`,
        transform: `translateY(${outY}px)`,
      }}>
        <div style={{ fontSize: 80, marginBottom: 8 }}>{curr.emoji}</div>
        <div style={{ fontSize: 64, fontWeight: 900, color: "#fff", fontFamily: "sans-serif" }}>{curr.shape}</div>
        <div style={{ fontSize: 28, color: GOLD, fontFamily: "sans-serif", marginTop: 8 }}>{curr.tip}</div>
      </div>

      {/* Next word */}
      {isFlipping && (
        <div style={{
          position: "absolute",
          width: "100%",
          textAlign: "center",
          opacity: inOpacity,
          filter: `blur(${inBlur}px)`,
          transform: `translateY(${inY}px)`,
        }}>
          <div style={{ fontSize: 80, marginBottom: 8 }}>{next.emoji}</div>
          <div style={{ fontSize: 64, fontWeight: 900, color: "#fff", fontFamily: "sans-serif" }}>{next.shape}</div>
          <div style={{ fontSize: 28, color: GOLD, fontFamily: "sans-serif", marginTop: 8 }}>{next.tip}</div>
        </div>
      )}
    </div>
  );
};

export const Ad2_WordCarousel: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const carouselEnd = FACE_SHAPES.length * FRAMES_PER;

  const headerEnter = spring({ fps, frame, config: { damping: 80 }, durationInFrames: 20 });
  const ctaEnter = spring({ fps, frame: frame - carouselEnd - 5, config: { damping: 80 }, durationInFrames: 20 });

  const headerY = interpolate(headerEnter, [0, 1], [40, 0]);
  const ctaY = interpolate(ctaEnter, [0, 1], [40, 0]);

  return (
    <AbsoluteFill style={{ background: BG, justifyContent: "center", alignItems: "center", flexDirection: "column", padding: "0 60px", gap: 48 }}>

      {/* Header */}
      <div style={{
        opacity: headerEnter,
        transform: `translateY(${headerY}px)`,
        textAlign: "center",
      }}>
        <div style={{ fontSize: 36, color: "#666", fontFamily: "sans-serif", marginBottom: 8 }}>
          Trimr AI knows every face shape
        </div>
        <div style={{ width: 60, height: 3, background: GOLD, margin: "0 auto" }} />
      </div>

      {/* Carousel */}
      {frame < carouselEnd && <BlurWord frame={frame} />}

      {/* Final message */}
      {frame >= carouselEnd && (
        <div style={{ opacity: ctaEnter, transform: `translateY(${ctaY}px)`, textAlign: "center", display: "flex", flexDirection: "column", gap: 32, alignItems: "center" }}>
          <div style={{ fontSize: 60, fontWeight: 900, color: "#fff", fontFamily: "sans-serif", lineHeight: 1.15 }}>
            Which one<br />are <span style={{ color: GOLD }}>you?</span>
          </div>
          <div style={{ fontSize: 28, color: "#888", fontFamily: "sans-serif" }}>
            Upload a selfie. Find out in seconds.
          </div>
          <div style={{
            background: GOLD,
            borderRadius: 50,
            padding: "20px 52px",
            fontSize: 28,
            fontWeight: 900,
            color: "#000",
            fontFamily: "sans-serif",
            transform: `scale(${1 + Math.sin(frame * 0.15) * 0.025})`,
          }}>
            Try Trimr AI Free →
          </div>
        </div>
      )}
    </AbsoluteFill>
  );
};
