/**
 * Ad 5: "Cinematic" — Slow, aspirational, lifestyle-driven
 * Hook: emotional resonance — "the guy who has it figured out"
 */
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

const GOLD = "#C9A84C";
const BG = "#050505";

const CineLine: React.FC<{
  text: string;
  startFrame: number;
  endFrame: number;
  size?: number;
  color?: string;
  align?: "left" | "center" | "right";
  x?: number;
  y?: number;
}> = ({
  text,
  startFrame,
  endFrame,
  size = 64,
  color = "#fff",
  align = "center",
  x = 0,
  y = 0,
}) => {
  const frame = useCurrentFrame();

  const fadeIn = interpolate(frame, [startFrame, startFrame + 25], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const fadeOut = interpolate(frame, [endFrame - 20, endFrame], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const opacity = Math.min(fadeIn, fadeOut);

  const slideIn = interpolate(frame, [startFrame, startFrame + 30], [18, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  if (frame < startFrame || frame > endFrame) return null;

  return (
    <div style={{
      position: "absolute",
      width: "100%",
      textAlign: align,
      padding: "0 80px",
      top: "50%",
      left: x,
      transform: `translateY(calc(-50% + ${y + slideIn}px))`,
      opacity,
    }}>
      <div style={{
        fontSize: size,
        fontWeight: 700,
        color,
        fontFamily: "Georgia, serif",
        lineHeight: 1.25,
        letterSpacing: 1,
      }}>
        {text}
      </div>
    </div>
  );
};

const GoldLine: React.FC<{ startFrame: number; endFrame: number; y?: number }> = ({
  startFrame, endFrame, y = 0
}) => {
  const frame = useCurrentFrame();
  const width = interpolate(frame, [startFrame, startFrame + 40], [0, 200], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const opacity = interpolate(frame, [endFrame - 15, endFrame], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  if (frame < startFrame || frame > endFrame) return null;

  return (
    <div style={{
      position: "absolute",
      left: "50%",
      top: `calc(50% + ${y}px)`,
      transform: "translateX(-50%)",
      width,
      height: 2,
      background: GOLD,
      opacity,
    }} />
  );
};

export const Ad5_Cinematic: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Vignette pulse
  const vignette = interpolate(Math.sin(frame * 0.03), [-1, 1], [0.7, 0.85]);

  const ctaEnter = spring({ fps, frame: frame - 290, config: { damping: 60 }, durationInFrames: 25 });
  const ctaY = interpolate(ctaEnter, [0, 1], [20, 0]);

  return (
    <AbsoluteFill style={{ background: BG, overflow: "hidden" }}>

      {/* Subtle grain texture via gradient */}
      <AbsoluteFill style={{
        background: `radial-gradient(ellipse at 50% 40%, #0d0800 0%, #050505 70%)`,
        opacity: vignette,
      }} />

      {/* Act 1: Problem */}
      <CineLine text="You've had the same haircut" startFrame={0} endFrame={70} size={58} color="#aaa" />
      <CineLine text="for years." startFrame={30} endFrame={80} size={58} color="#aaa" y={70} />
      <GoldLine startFrame={60} endFrame={90} y={110} />

      {/* Act 2: Insight */}
      <CineLine text="The right haircut" startFrame={90} endFrame={170} size={66} />
      <CineLine text="changes everything." startFrame={110} endFrame={180} size={66} color={GOLD} y={80} />

      {/* Act 3: Solution */}
      <CineLine text="Trimr AI analyzes" startFrame={185} endFrame={255} size={56} color="#aaa" y={-40} />
      <CineLine text="your face shape." startFrame={195} endFrame={260} size={56} color="#aaa" y={20} />
      <CineLine text="Then gives you your 3 best cuts." startFrame={210} endFrame={275} size={44} color={GOLD} y={82} />

      {/* Act 4: CTA */}
      {frame >= 285 && (
        <AbsoluteFill style={{
          justifyContent: "center",
          alignItems: "center",
          flexDirection: "column",
          gap: 28,
        }}>
          <div style={{
            opacity: ctaEnter,
            transform: `translateY(${ctaY}px)`,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 24,
          }}>
            <div style={{
              fontSize: 28,
              color: "#666",
              fontFamily: "Georgia, serif",
              letterSpacing: 4,
              textTransform: "uppercase",
            }}>
              Your face. Your style.
            </div>
            <div style={{
              fontSize: 68,
              fontWeight: 700,
              color: "#fff",
              fontFamily: "Georgia, serif",
              letterSpacing: 2,
              textAlign: "center",
            }}>
              Trimr <span style={{ color: GOLD }}>AI</span>
            </div>
            <div style={{
              background: "transparent",
              border: `2px solid ${GOLD}`,
              borderRadius: 50,
              padding: "18px 52px",
              fontSize: 26,
              fontWeight: 600,
              color: GOLD,
              fontFamily: "sans-serif",
              letterSpacing: 1,
              transform: `scale(${1 + Math.sin(frame * 0.12) * 0.02})`,
            }}>
              Find Your Cut →
            </div>
            <div style={{ fontSize: 18, color: "#444", fontFamily: "sans-serif", letterSpacing: 2 }}>
              TRIMR-AI.APP
            </div>
          </div>
        </AbsoluteFill>
      )}
    </AbsoluteFill>
  );
};
