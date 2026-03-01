/**
 * Ad 1: "WRONG CUT" — Ultra-fast word flash
 * Hook: instant shock, 3-word punches, TikTok-native pacing
 */
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

const GOLD = "#C9A84C";
const RED = "#E8424A";
const BG = "#080808";

const FlashWord: React.FC<{
  word: string;
  color: string;
  size?: number;
  startFrame: number;
  endFrame: number;
}> = ({ word, color, size = 130, startFrame, endFrame }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const enter = spring({
    fps,
    frame: frame - startFrame,
    config: { damping: 60, stiffness: 500, mass: 0.3 },
    durationInFrames: 8,
  });

  const opacity = interpolate(
    frame,
    [startFrame, startFrame + 3, endFrame - 4, endFrame],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  const scale = interpolate(enter, [0, 1], [1.3, 1]);

  if (frame < startFrame || frame >= endFrame) return null;

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        opacity,
      }}
    >
      <div
        style={{
          fontSize: size,
          fontWeight: 900,
          color,
          fontFamily: "sans-serif",
          letterSpacing: -2,
          textAlign: "center",
          transform: `scale(${scale})`,
          textTransform: "uppercase",
          lineHeight: 1,
          padding: "0 40px",
        }}
      >
        {word}
      </div>
    </div>
  );
};

const PunchLine: React.FC<{
  line1: string;
  line2?: string;
  startFrame: number;
  endFrame: number;
  color1?: string;
  color2?: string;
}> = ({ line1, line2, startFrame, endFrame, color1 = "#fff", color2 = GOLD }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const enter = spring({
    fps,
    frame: frame - startFrame,
    config: { damping: 80, stiffness: 300 },
    durationInFrames: 12,
  });

  const opacity = interpolate(
    frame,
    [startFrame, startFrame + 4, endFrame - 5, endFrame],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  const translateY = interpolate(enter, [0, 1], [40, 0]);

  if (frame < startFrame || frame >= endFrame) return null;

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        flexDirection: "column",
        gap: 16,
        padding: "0 60px",
        opacity,
        transform: `translateY(${translateY}px)`,
      }}
    >
      <div style={{ fontSize: 72, fontWeight: 900, color: color1, fontFamily: "sans-serif", textAlign: "center", lineHeight: 1.1 }}>
        {line1}
      </div>
      {line2 && (
        <div style={{ fontSize: 72, fontWeight: 900, color: color2, fontFamily: "sans-serif", textAlign: "center", lineHeight: 1.1 }}>
          {line2}
        </div>
      )}
    </div>
  );
};

export const Ad1_Flash: React.FC = () => {
  const frame = useCurrentFrame();

  // Flashing red line accent
  const lineOpacity = Math.sin(frame * 0.8) * 0.5 + 0.5;

  return (
    <AbsoluteFill style={{ background: BG, overflow: "hidden" }}>
      {/* Accent line */}
      <div style={{
        position: "absolute",
        left: 0,
        top: "50%",
        width: "100%",
        height: 3,
        background: RED,
        opacity: lineOpacity * 0.3,
      }} />

      <FlashWord word="WRONG" color={RED} startFrame={0} endFrame={18} />
      <FlashWord word="HAIRCUT" color="#fff" size={110} startFrame={18} endFrame={36} />
      <FlashWord word="WRONG" color={RED} startFrame={36} endFrame={50} />
      <FlashWord word="VIBE." color="#fff" startFrame={50} endFrame={66} />
      <FlashWord word="WRONG" color={RED} startFrame={66} endFrame={78} />
      <FlashWord word="FIRST" color="#fff" size={110} startFrame={78} endFrame={90} />
      <FlashWord word="IMPRESSION." color="#fff" size={90} startFrame={90} endFrame={108} />

      <PunchLine
        line1="Trimr AI fixes that."
        line2="In 30 seconds."
        startFrame={108}
        endFrame={150}
        color1="#fff"
        color2={GOLD}
      />

      {/* CTA */}
      {frame >= 150 && (
        <AbsoluteFill style={{ justifyContent: "center", alignItems: "center", flexDirection: "column", gap: 24 }}>
          <div style={{
            background: GOLD,
            borderRadius: 50,
            padding: "22px 60px",
            fontSize: 34,
            fontWeight: 900,
            color: "#000",
            fontFamily: "sans-serif",
            transform: `scale(${1 + Math.sin(frame * 0.15) * 0.02})`,
          }}>
            Try Free → trimr-ai.app
          </div>
        </AbsoluteFill>
      )}
    </AbsoluteFill>
  );
};
