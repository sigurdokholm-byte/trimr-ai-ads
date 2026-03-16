/**
 * Ad 3: "3 Steps" — Clean minimal process walkthrough
 * Hook: dead simple, removes objection of "this sounds complicated"
 */
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

const GOLD = "#C9A84C";
const BG = "#F7F5F0"; // Light background — contrast from the others
const DARK = "#0A0A0A";

const Step: React.FC<{
  number: string;
  icon: string;
  title: string;
  subtitle: string;
  delay: number;
  active: boolean;
}> = ({ number, icon, title, subtitle, delay, active }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const enter = spring({
    fps,
    frame: frame - delay,
    config: { damping: 70, stiffness: 200 },
    durationInFrames: 20,
  });

  const y = interpolate(enter, [0, 1], [50, 0]);
  const opacity = interpolate(enter, [0, 0.3, 1], [0, 0, 1], { extrapolateRight: "clamp" });

  return (
    <div style={{
      display: "flex",
      alignItems: "center",
      gap: 32,
      opacity,
      transform: `translateY(${y}px)`,
      padding: "28px 36px",
      borderRadius: 24,
      background: active ? "#fff" : "transparent",
      border: active ? `2px solid ${GOLD}` : "2px solid transparent",
      boxShadow: active ? "0 8px 32px rgba(0,0,0,0.08)" : "none",
    }}>
      <div style={{
        width: 80,
        height: 80,
        borderRadius: "50%",
        background: active ? GOLD : "#E8E3D8",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: 36,
        flexShrink: 0,
      }}>
        {active ? icon : <span style={{ fontSize: 28, fontWeight: 900, color: "#bbb", fontFamily: "sans-serif" }}>{number}</span>}
      </div>
      <div>
        <div style={{ fontSize: 32, fontWeight: 800, color: DARK, fontFamily: "sans-serif", lineHeight: 1.2 }}>{title}</div>
        <div style={{ fontSize: 22, color: "#888", fontFamily: "sans-serif", marginTop: 4 }}>{subtitle}</div>
      </div>
    </div>
  );
};

const STEPS = [
  { icon: "📸", title: "Upload a selfie", subtitle: "Any photo works fine" },
  { icon: "🤖", title: "AI reads your face", subtitle: "Shape, jaw, symmetry" },
  { icon: "✂️", title: "Get your 3 cuts", subtitle: "With AI images of you" },
];

const STEP_DURATION = 60;

export const Ad3_Steps: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const activeStep = Math.min(Math.floor(frame / STEP_DURATION), STEPS.length - 1);
  const stepsEnd = STEPS.length * STEP_DURATION;

  const titleEnter = spring({ fps, frame, config: { damping: 80 }, durationInFrames: 20 });
  const titleY = interpolate(titleEnter, [0, 1], [-30, 0]);

  const ctaEnter = spring({ fps, frame: frame - stepsEnd - 5, config: { damping: 80 }, durationInFrames: 20 });
  const ctaY = interpolate(ctaEnter, [0, 1], [30, 0]);

  // Progress dots
  const dotProgress = interpolate(frame, [0, stepsEnd], [0, 3], { extrapolateRight: "clamp" });

  return (
    <AbsoluteFill style={{
      background: BG,
      justifyContent: "center",
      alignItems: "center",
      flexDirection: "column",
      padding: "60px 60px",
      gap: 32,
    }}>
      {/* Header */}
      <div style={{
        opacity: titleEnter,
        transform: `translateY(${titleY}px)`,
        textAlign: "center",
        marginBottom: 8,
      }}>
        <div style={{ fontSize: 52, fontWeight: 900, color: DARK, fontFamily: "sans-serif", lineHeight: 1.1 }}>
          It takes <span style={{ color: GOLD }}>30 seconds.</span>
        </div>
        <div style={{ fontSize: 26, color: "#999", fontFamily: "sans-serif", marginTop: 12 }}>
          Here's how Trimr AI works
        </div>
      </div>

      {/* Steps */}
      <div style={{ width: "100%", display: "flex", flexDirection: "column", gap: 12 }}>
        {STEPS.map((step, i) => (
          <Step
            key={step.title}
            number={String(i + 1)}
            icon={step.icon}
            title={step.title}
            subtitle={step.subtitle}
            delay={i * STEP_DURATION}
            active={activeStep === i}
          />
        ))}
      </div>

      {/* Progress dots */}
      <div style={{ display: "flex", gap: 10 }}>
        {STEPS.map((_, i) => (
          <div key={i} style={{
            width: 12,
            height: 12,
            borderRadius: "50%",
            background: dotProgress >= i + 0.5 ? GOLD : "#D0C9BB",
          }} />
        ))}
      </div>

      {/* CTA */}
      {frame >= stepsEnd && (
        <div style={{
          opacity: ctaEnter,
          transform: `translateY(${ctaY}px)`,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 16,
          marginTop: 8,
        }}>
          <div style={{
            background: DARK,
            borderRadius: 50,
            padding: "22px 56px",
            fontSize: 30,
            fontWeight: 900,
            color: "#fff",
            fontFamily: "sans-serif",
            transform: `scale(${1 + Math.sin(frame * 0.15) * 0.02})`,
          }}>
            Try Trimr AI Free →
          </div>
          <div style={{ fontSize: 20, color: "#aaa", fontFamily: "sans-serif" }}>
            trimr-ai.app
          </div>
        </div>
      )}
    </AbsoluteFill>
  );
};
