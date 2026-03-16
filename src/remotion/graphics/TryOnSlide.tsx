/**
 * TRIMR AI — Try-On Slideshow Slide
 * Static 1080×1920 PNG for TikTok slideshow
 * Render: npx remotion still TryOnSlide --frame=0 --output=out/TryOnSlide.png
 *
 * Drop your 5 try-on result images into public/:
 *   public/tryon-1.jpg  (Textured Fringe)
 *   public/tryon-2.jpg  (Edgar Cut)
 *   public/tryon-3.jpg  (Fluffy Hair)  ← center / hero
 *   public/tryon-4.jpg  (Slick Back)
 *   public/tryon-5.jpg  (Buzz Cut)
 */

import { AbsoluteFill, Img } from "remotion";

const GOLD = "#C9A84C";
const GOLD_LIGHT = "#E8C547";
const F_SERIF = "Georgia, 'Times New Roman', serif";

// ── Leather background ───────────────────────────────────────────────────────
const LeatherBg: React.FC = () => (
  <AbsoluteFill
    style={{
      background:
        "radial-gradient(ellipse at 30% 20%, #3a2a1a 0%, #1e1208 40%, #0d0804 100%)",
    }}
  >
    {/* Grain overlay — inline SVG to avoid background-image */}
    <AbsoluteFill style={{ opacity: 0.9 }}>
      <svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
        <filter id="grain-noise">
          <feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="4" stitchTiles="stitch" />
          <feColorMatrix type="saturate" values="0" />
        </filter>
        <rect width="100%" height="100%" filter="url(#grain-noise)" opacity="0.18" />
      </svg>
    </AbsoluteFill>
    {/* Vignette */}
    <AbsoluteFill
      style={{
        background:
          "radial-gradient(ellipse at 50% 50%, transparent 30%, rgba(0,0,0,0.7) 100%)",
      }}
    />
  </AbsoluteFill>
);

// ── Logo ─────────────────────────────────────────────────────────────────────
const Logo: React.FC = () => (
  <div
    style={{
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      gap: 20,
      width: "100%",
    }}
  >
    {/* Left line */}
    <div
      style={{
        flex: 1,
        height: 1,
        background: `linear-gradient(90deg, transparent, ${GOLD})`,
        maxWidth: 160,
      }}
    />
    {/* Wordmark */}
    <div style={{ textAlign: "center" }}>
      <div
        style={{
          fontFamily: F_SERIF,
          fontSize: 62,
          fontWeight: 700,
          letterSpacing: 4,
          color: GOLD,
          lineHeight: 1,
          textShadow: `0 2px 24px rgba(201,168,76,0.4)`,
        }}
      >
        TrimrAI
        <span style={{ fontSize: 36, fontWeight: 400, color: GOLD_LIGHT }}>
          .com
        </span>
      </div>
    </div>
    {/* Right line */}
    <div
      style={{
        flex: 1,
        height: 1,
        background: `linear-gradient(90deg, ${GOLD}, transparent)`,
        maxWidth: 160,
      }}
    />
  </div>
);

// ── Photo card ────────────────────────────────────────────────────────────────
const PhotoCard: React.FC<{
  src: string;
  label: string;
  hero?: boolean;
  width: number;
  height: number;
}> = ({ src, label, hero = false, width, height }) => (
  <div
    style={{
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      gap: 14,
    }}
  >
    <div
      style={{
        width,
        height,
        borderRadius: 8,
        border: hero
          ? `3px solid ${GOLD_LIGHT}`
          : `1.5px solid rgba(201,168,76,0.45)`,
        boxShadow: hero
          ? `0 0 32px rgba(201,168,76,0.55), 0 0 8px rgba(201,168,76,0.3), inset 0 0 12px rgba(201,168,76,0.08)`
          : `0 4px 20px rgba(0,0,0,0.5)`,
        overflow: "hidden",
        position: "relative",
        flexShrink: 0,
        background: "#1a1008",
      }}
    >
      <Img
        src={src}
        style={{
          width: "100%",
          height: "100%",
          objectFit: "cover",
          objectPosition: "top center",
        }}
      />
      {/* Inner gold glow on hero */}
      {hero && (
        <div
          style={{
            position: "absolute",
            inset: 0,
            boxShadow: `inset 0 0 20px rgba(201,168,76,0.2)`,
          }}
        />
      )}
    </div>
    <div
      style={{
        fontFamily: F_SERIF,
        fontSize: hero ? 24 : 20,
        color: hero ? GOLD_LIGHT : "rgba(255,255,255,0.75)",
        letterSpacing: 0.5,
        fontStyle: "italic",
        textShadow: hero ? `0 0 12px rgba(201,168,76,0.4)` : "none",
      }}
    >
      {label}
    </div>
  </div>
);

// ── Gold diamond divider ──────────────────────────────────────────────────────
const GoldDivider: React.FC = () => (
  <div
    style={{
      display: "flex",
      alignItems: "center",
      gap: 12,
      width: 320,
    }}
  >
    <div
      style={{
        flex: 1,
        height: 1,
        background: `linear-gradient(90deg, transparent, ${GOLD})`,
      }}
    />
    <div
      style={{
        width: 8,
        height: 8,
        background: GOLD,
        transform: "rotate(45deg)",
      }}
    />
    <div
      style={{
        flex: 1,
        height: 1,
        background: `linear-gradient(90deg, ${GOLD}, transparent)`,
      }}
    />
  </div>
);

// ── Main slide ────────────────────────────────────────────────────────────────
export const TryOnSlide: React.FC = () => {
  const HERO_W = 196;
  const HERO_H = 280;
  const SIDE_W = 162;
  const SIDE_H = 240;

  const cuts = [
    { src: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=560&fit=crop&crop=top", label: "Textured Fringe", hero: false },
    { src: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=560&fit=crop&crop=top", label: "Edgar Cut", hero: false },
    { src: "https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400&h=560&fit=crop&crop=top", label: "Fluffy Hair", hero: true },
    { src: "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=400&h=560&fit=crop&crop=top", label: "Slick Back", hero: false },
    { src: "https://images.unsplash.com/photo-1504257432389-52343af06ae3?w=400&h=560&fit=crop&crop=top", label: "Buzz Cut", hero: false },
  ];

  return (
    <AbsoluteFill style={{ background: "#0d0804" }}>
      <LeatherBg />

      <AbsoluteFill>
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            width: "100%",
            height: "100%",
            paddingTop: 100,
            paddingBottom: 80,
            boxSizing: "border-box",
          }}
        >
          {/* Logo */}
          <Logo />

          {/* Photo row */}
          <div
            style={{
              display: "flex",
              flexDirection: "row",
              alignItems: "flex-end",
              justifyContent: "center",
              gap: 10,
              marginTop: 72,
              width: "100%",
              paddingLeft: 24,
              paddingRight: 24,
              boxSizing: "border-box",
            }}
          >
            {cuts.map((cut, i) => (
              <PhotoCard
                key={i}
                src={cut.src}
                label={cut.label}
                hero={cut.hero}
                width={cut.hero ? HERO_W : SIDE_W}
                height={cut.hero ? HERO_H : SIDE_H}
              />
            ))}
          </div>

          {/* Spacer */}
          <div style={{ flex: 1 }} />

          {/* Headline */}
          <div
            style={{
              textAlign: "center",
              paddingLeft: 60,
              paddingRight: 60,
            }}
          >
            <div
              style={{
                fontFamily: F_SERIF,
                fontSize: 76,
                fontWeight: 700,
                color: GOLD_LIGHT,
                lineHeight: 1.1,
                letterSpacing: -1,
                textShadow: `0 4px 32px rgba(201,168,76,0.25)`,
                marginBottom: 32,
              }}
            >
              Try Hairstyles{" "}
              <span style={{ fontStyle: "italic", color: GOLD }}>on</span>
              <br />
              Your Real Face.
            </div>

            <GoldDivider />

            <div
              style={{
                fontFamily: F_SERIF,
                fontSize: 30,
                fontStyle: "italic",
                color: "rgba(232,197,100,0.75)",
                lineHeight: 1.6,
                marginTop: 28,
                letterSpacing: 0.3,
              }}
            >
              Instantly see which cuts suit your face shape.
              <br />
              AI-powered analysis in 30 seconds.
            </div>
          </div>

          <div style={{ flex: 1 }} />
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
