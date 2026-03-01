/**
 * Ad 4: "Social Proof" — Animated counter + star ratings
 * Hook: everyone's using it, FOMO-driven
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

const AnimatedCounter: React.FC<{ target: number; startFrame: number; endFrame: number }> = ({
  target, startFrame, endFrame,
}) => {
  const frame = useCurrentFrame();
  const progress = interpolate(frame, [startFrame, endFrame], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: (t) => 1 - Math.pow(1 - t, 3),
  });
  const value = Math.floor(progress * target);
  const formatted = value.toLocaleString();

  return (
    <div style={{
      fontSize: 140,
      fontWeight: 900,
      color: GOLD,
      fontFamily: "sans-serif",
      lineHeight: 1,
      letterSpacing: -4,
    }}>
      {formatted}
      <span style={{ fontSize: 70, color: "#fff" }}>+</span>
    </div>
  );
};

const Stars: React.FC<{ delay: number }> = ({ delay }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <div style={{ display: "flex", gap: 8 }}>
      {[0, 1, 2, 3, 4].map((i) => {
        const enter = spring({
          fps,
          frame: frame - delay - i * 6,
          config: { damping: 60, stiffness: 300, mass: 0.4 },
          durationInFrames: 12,
        });
        const scale = interpolate(enter, [0, 0.6, 1], [0, 1.4, 1]);
        return (
          <div key={i} style={{ fontSize: 48, transform: `scale(${scale})`, opacity: enter }}>
            ⭐
          </div>
        );
      })}
    </div>
  );
};

const Testimonial: React.FC<{
  text: string;
  name: string;
  delay: number;
}> = ({ text, name, delay }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const enter = spring({ fps, frame: frame - delay, config: { damping: 70 }, durationInFrames: 16 });
  const y = interpolate(enter, [0, 1], [20, 0]);

  return (
    <div style={{
      opacity: enter,
      transform: `translateY(${y}px)`,
      background: "#141414",
      borderRadius: 20,
      padding: "24px 28px",
      border: `1px solid #222`,
    }}>
      <div style={{ fontSize: 24, color: "#ddd", fontFamily: "sans-serif", lineHeight: 1.4, fontStyle: "italic" }}>
        "{text}"
      </div>
      <div style={{ fontSize: 18, color: GOLD, fontFamily: "sans-serif", marginTop: 10, fontWeight: 600 }}>
        — {name}
      </div>
    </div>
  );
};

export const Ad4_SocialProof: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const headerEnter = spring({ fps, frame, config: { damping: 80 }, durationInFrames: 20 });
  const headerY = interpolate(headerEnter, [0, 1], [30, 0]);

  const ctaEnter = spring({ fps, frame: frame - 210, config: { damping: 80 }, durationInFrames: 20 });
  const ctaY = interpolate(ctaEnter, [0, 1], [30, 0]);

  return (
    <AbsoluteFill style={{
      background: BG,
      justifyContent: "center",
      alignItems: "center",
      flexDirection: "column",
      padding: "0 60px",
      gap: 28,
    }}>
      {/* Header */}
      <div style={{ opacity: headerEnter, transform: `translateY(${headerY}px)`, textAlign: "center" }}>
        <div style={{ fontSize: 32, color: "#666", fontFamily: "sans-serif" }}>
          guys already found their cut
        </div>
      </div>

      {/* Counter */}
      <AnimatedCounter target={12500} startFrame={5} endFrame={90} />

      {/* Stars */}
      {frame >= 95 && <Stars delay={95} />}

      {/* Rating text */}
      {frame >= 125 && (
        <div style={{
          opacity: interpolate(frame, [125, 140], [0, 1], { extrapolateRight: "clamp" }),
          fontSize: 28,
          color: "#888",
          fontFamily: "sans-serif",
          textAlign: "center",
        }}>
          4.9 / 5 average rating
        </div>
      )}

      {/* Testimonials */}
      {frame >= 140 && (
        <div style={{ display: "flex", flexDirection: "column", gap: 14, width: "100%" }}>
          <Testimonial
            text="Got a mid fade based on my face. Best haircut of my life."
            name="Jake, 19"
            delay={140}
          />
          <Testimonial
            text="I literally showed my barber the AI image. He nailed it."
            name="Marcus, 22"
            delay={155}
          />
        </div>
      )}

      {/* CTA */}
      {frame >= 210 && (
        <div style={{
          opacity: ctaEnter,
          transform: `translateY(${ctaY}px)`,
          textAlign: "center",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 12,
        }}>
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
            Join them — Try Free →
          </div>
        </div>
      )}
    </AbsoluteFill>
  );
};
