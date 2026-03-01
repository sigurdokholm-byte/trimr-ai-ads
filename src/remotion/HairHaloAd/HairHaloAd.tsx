import {
  AbsoluteFill,
  Audio,
  Sequence,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
} from "remotion";

const GOLD = "#C9A84C";
const BG = "#0A0A0A";

const SlideUp: React.FC<{
  children: React.ReactNode;
  delay?: number;
  duration?: number;
}> = ({ children, delay = 0, duration = 20 }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const progress = spring({
    fps,
    frame,
    delay,
    config: { damping: 80, stiffness: 200, mass: 0.6 },
    durationInFrames: duration,
  });

  return (
    <div
      style={{
        transform: `translateY(${interpolate(progress, [0, 1], [60, 0])}px)`,
        opacity: progress,
      }}
    >
      {children}
    </div>
  );
};

const FadeIn: React.FC<{
  children: React.ReactNode;
  delay?: number;
}> = ({ children, delay = 0 }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const opacity = spring({
    fps,
    frame,
    delay,
    config: { damping: 60 },
    durationInFrames: 20,
  });

  return <div style={{ opacity }}>{children}</div>;
};

// Scene 1: Hook
const Scene1: React.FC = () => (
  <AbsoluteFill
    style={{
      background: BG,
      justifyContent: "center",
      alignItems: "center",
      flexDirection: "column",
      gap: 24,
      padding: "0 60px",
    }}
  >
    <SlideUp delay={0}>
      <div
        style={{
          fontSize: 52,
          color: GOLD,
          fontWeight: 900,
          textAlign: "center",
          letterSpacing: -1,
          lineHeight: 1.1,
          fontFamily: "sans-serif",
        }}
      >
        Still guessing which haircut suits you?
      </div>
    </SlideUp>
    <SlideUp delay={12}>
      <div
        style={{
          fontSize: 32,
          color: "#888",
          textAlign: "center",
          fontFamily: "sans-serif",
          fontWeight: 400,
        }}
      >
        Most guys just pick whatever. Don't be most guys.
      </div>
    </SlideUp>
  </AbsoluteFill>
);

// Scene 2: Upload step
const Scene2: React.FC = () => (
  <AbsoluteFill
    style={{
      background: BG,
      justifyContent: "center",
      alignItems: "center",
      flexDirection: "column",
      gap: 32,
      padding: "0 60px",
    }}
  >
    <SlideUp delay={0}>
      <div style={{ fontSize: 100, textAlign: "center" }}>📸</div>
    </SlideUp>
    <SlideUp delay={8}>
      <div
        style={{
          fontSize: 52,
          color: "#fff",
          fontWeight: 800,
          textAlign: "center",
          fontFamily: "sans-serif",
          lineHeight: 1.15,
        }}
      >
        Upload a photo of yourself
      </div>
    </SlideUp>
    <SlideUp delay={16}>
      <div
        style={{
          fontSize: 28,
          color: "#888",
          textAlign: "center",
          fontFamily: "sans-serif",
        }}
      >
        Our AI reads your face shape in seconds
      </div>
    </SlideUp>
  </AbsoluteFill>
);

// Scene 3: AI analysis
const Scene3: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const barWidth1 = interpolate(frame, [5, 30], [0, 100], {
    extrapolateRight: "clamp",
  });
  const barWidth2 = interpolate(frame, [15, 40], [0, 78], {
    extrapolateRight: "clamp",
  });
  const barWidth3 = interpolate(frame, [25, 50], [0, 91], {
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill
      style={{
        background: BG,
        justifyContent: "center",
        alignItems: "flex-start",
        flexDirection: "column",
        padding: "0 60px",
        gap: 40,
      }}
    >
      <SlideUp delay={0}>
        <div
          style={{
            fontSize: 48,
            color: "#fff",
            fontWeight: 800,
            fontFamily: "sans-serif",
            lineHeight: 1.2,
          }}
        >
          AI analyzes your
          <span style={{ color: GOLD }}> face shape</span>
        </div>
      </SlideUp>

      <FadeIn delay={10}>
        <div style={{ width: "100%", display: "flex", flexDirection: "column", gap: 20 }}>
          {[
            { label: "Jaw Structure", width: barWidth1 },
            { label: "Forehead Ratio", width: barWidth2 },
            { label: "Overall Symmetry", width: barWidth3 },
          ].map(({ label, width }) => (
            <div key={label}>
              <div
                style={{
                  fontSize: 22,
                  color: "#aaa",
                  fontFamily: "sans-serif",
                  marginBottom: 8,
                }}
              >
                {label}
              </div>
              <div
                style={{
                  height: 12,
                  background: "#1a1a1a",
                  borderRadius: 6,
                  width: 500,
                  overflow: "hidden",
                }}
              >
                <div
                  style={{
                    height: "100%",
                    width: `${width}%`,
                    background: `linear-gradient(90deg, ${GOLD}, #f0c060)`,
                    borderRadius: 6,
                    transition: "width 0.1s",
                  }}
                />
              </div>
            </div>
          ))}
        </div>
      </FadeIn>
    </AbsoluteFill>
  );
};

// Scene 4: 3 hairstyle results
const Scene4: React.FC = () => {
  const styles = ["Textured Crop", "Mid Fade", "French Crop"];

  return (
    <AbsoluteFill
      style={{
        background: BG,
        justifyContent: "center",
        alignItems: "center",
        flexDirection: "column",
        gap: 40,
        padding: "0 50px",
      }}
    >
      <SlideUp delay={0}>
        <div
          style={{
            fontSize: 42,
            color: "#fff",
            fontWeight: 800,
            textAlign: "center",
            fontFamily: "sans-serif",
          }}
        >
          Get{" "}
          <span style={{ color: GOLD }}>3 perfect hairstyles</span>
          {"\n"}matched to your face
        </div>
      </SlideUp>

      <div style={{ display: "flex", gap: 20 }}>
        {styles.map((style, i) => (
          <SlideUp key={style} delay={8 + i * 8}>
            <div
              style={{
                background: "#141414",
                border: `2px solid ${GOLD}33`,
                borderRadius: 20,
                padding: "28px 24px",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                gap: 12,
                width: 180,
              }}
            >
              <div style={{ fontSize: 48 }}>✂️</div>
              <div
                style={{
                  fontSize: 20,
                  color: "#fff",
                  fontWeight: 700,
                  textAlign: "center",
                  fontFamily: "sans-serif",
                }}
              >
                {style}
              </div>
              <div
                style={{
                  fontSize: 14,
                  color: GOLD,
                  fontFamily: "sans-serif",
                  fontWeight: 600,
                }}
              >
                AI Generated
              </div>
            </div>
          </SlideUp>
        ))}
      </div>
    </AbsoluteFill>
  );
};

// Scene 5: Benefits
const Scene5: React.FC = () => {
  const perks = [
    { icon: "🪒", text: "What to tell your barber" },
    { icon: "🛒", text: "Products to use" },
    { icon: "💡", text: "How to style it daily" },
  ];

  return (
    <AbsoluteFill
      style={{
        background: BG,
        justifyContent: "center",
        alignItems: "flex-start",
        flexDirection: "column",
        padding: "0 60px",
        gap: 36,
      }}
    >
      <SlideUp delay={0}>
        <div
          style={{
            fontSize: 44,
            color: "#fff",
            fontWeight: 800,
            fontFamily: "sans-serif",
            lineHeight: 1.2,
          }}
        >
          Everything you need
          <br />
          <span style={{ color: GOLD }}>to walk out fresh.</span>
        </div>
      </SlideUp>

      <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
        {perks.map((perk, i) => (
          <SlideUp key={perk.text} delay={10 + i * 8}>
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 20,
              }}
            >
              <span style={{ fontSize: 40 }}>{perk.icon}</span>
              <span
                style={{
                  fontSize: 28,
                  color: "#ddd",
                  fontFamily: "sans-serif",
                  fontWeight: 500,
                }}
              >
                {perk.text}
              </span>
            </div>
          </SlideUp>
        ))}
      </div>
    </AbsoluteFill>
  );
};

// Scene 6: CTA
const Scene6: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const pulse = Math.sin(frame / 8) * 0.03 + 1;

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(ellipse at center, #1a1200 0%, ${BG} 70%)`,
        justifyContent: "center",
        alignItems: "center",
        flexDirection: "column",
        gap: 32,
        padding: "0 60px",
      }}
    >
      <SlideUp delay={0}>
        <div
          style={{
            fontSize: 56,
            color: "#fff",
            fontWeight: 900,
            textAlign: "center",
            fontFamily: "sans-serif",
            lineHeight: 1.1,
          }}
        >
          Find your{" "}
          <span style={{ color: GOLD }}>perfect cut.</span>
        </div>
      </SlideUp>

      <SlideUp delay={10}>
        <div
          style={{
            background: GOLD,
            borderRadius: 50,
            padding: "20px 56px",
            transform: `scale(${pulse})`,
          }}
        >
          <div
            style={{
              fontSize: 30,
              color: "#000",
              fontWeight: 900,
              fontFamily: "sans-serif",
              letterSpacing: 0.5,
            }}
          >
            Try Trimr AI Free →
          </div>
        </div>
      </SlideUp>

      <SlideUp delay={18}>
        <div
          style={{
            fontSize: 22,
            color: "#555",
            fontFamily: "sans-serif",
            textAlign: "center",
          }}
        >
          trimr-ai.app
        </div>
      </SlideUp>
    </AbsoluteFill>
  );
};

// Main Ad
export const HairHaloAd: React.FC = () => {
  // Durations timed exactly to ElevenLabs audio length
  const scenes = [51, 47, 56, 54, 83, 60];
  const offsets = scenes.reduce<number[]>(
    (acc, _, i) => (i === 0 ? [0] : [...acc, acc[i - 1] + scenes[i - 1]]),
    []
  );

  return (
    <AbsoluteFill style={{ background: BG }}>
      <Sequence durationInFrames={scenes[0]}>
        <Audio src={staticFile("audio/scene1.mp3")} />
        <Scene1 />
      </Sequence>
      <Sequence from={offsets[1]} durationInFrames={scenes[1]}>
        <Audio src={staticFile("audio/scene2.mp3")} />
        <Scene2 />
      </Sequence>
      <Sequence from={offsets[2]} durationInFrames={scenes[2]}>
        <Audio src={staticFile("audio/scene3.mp3")} />
        <Scene3 />
      </Sequence>
      <Sequence from={offsets[3]} durationInFrames={scenes[3]}>
        <Audio src={staticFile("audio/scene4.mp3")} />
        <Scene4 />
      </Sequence>
      <Sequence from={offsets[4]} durationInFrames={scenes[4]}>
        <Audio src={staticFile("audio/scene5.mp3")} />
        <Scene5 />
      </Sequence>
      <Sequence from={offsets[5]} durationInFrames={scenes[5]}>
        <Audio src={staticFile("audio/scene6.mp3")} />
        <Scene6 />
      </Sequence>
    </AbsoluteFill>
  );
};
