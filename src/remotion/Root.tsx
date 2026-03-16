import React from "react";
import { Composition } from "remotion";
import {
  COMP_NAME,
  defaultMyCompProps,
  DURATION_IN_FRAMES,
  VIDEO_FPS,
  VIDEO_HEIGHT,
  VIDEO_WIDTH,
} from "../../types/constants";
import { Main } from "./MyComp/Main";
import { NextLogo } from "./MyComp/NextLogo";
import { HairHaloAd } from "./HairHaloAd/HairHaloAd";
import { Ad1_Flash } from "./ads/Ad1_Flash";
import { Ad2_WordCarousel } from "./ads/Ad2_WordCarousel";
import { Ad3_Steps } from "./ads/Ad3_Steps";
import { Ad4_SocialProof } from "./ads/Ad4_SocialProof";
import { Ad5_Cinematic } from "./ads/Ad5_Cinematic";
import { Logo_Wordmark, Logo_Mark, Logo_Badge, LogoImage_Horizontal, LogoImage_Square, LogoImage_Icon } from "./logos/Logos";
import { Organic_AppFlow } from "./ads/Organic_AppFlow";
import { Organic_BarberBrief } from "./ads/Organic_BarberBrief";
import { Organic_CompatibilityBreakdown } from "./ads/Organic_CompatibilityBreakdown";
import {
  ScoreReveal,
  HaircutCard,
  BeforeAfterStory,
  LowerThird,
  FeedSquare,
} from "./graphics/GraphicPack";
import {
  HowItWorksImage,
  ScoreExplainerImage,
  FaceShapeGuideImage,
  WhatYouGetImage,
  BarberBriefImage,
} from "./graphics/ImagePack";
import { TryOnSlide } from "./graphics/TryOnSlide";

/* eslint-disable @typescript-eslint/no-explicit-any */
const ScoreRevealC = ScoreReveal as any;
const HaircutCardC = HaircutCard as any;
const BeforeAfterStoryC = BeforeAfterStory as any;
const LowerThirdC = LowerThird as any;
const FeedSquareC = FeedSquare as any;
/* eslint-enable @typescript-eslint/no-explicit-any */

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="HairHaloAd"
        component={HairHaloAd}
        durationInFrames={351}
        fps={30}
        width={1080}
        height={1920}
      />
      {/* 5 Trimr AI Ads */}
      <Composition id="Ad1Flash" component={Ad1_Flash} durationInFrames={195} fps={30} width={1080} height={1920} />
      <Composition id="Ad2WordCarousel" component={Ad2_WordCarousel} durationInFrames={340} fps={30} width={1080} height={1920} />
      <Composition id="Ad3Steps" component={Ad3_Steps} durationInFrames={310} fps={30} width={1080} height={1920} />
      <Composition id="Ad4SocialProof" component={Ad4_SocialProof} durationInFrames={270} fps={30} width={1080} height={1920} />
      <Composition id="Ad5Cinematic" component={Ad5_Cinematic} durationInFrames={360} fps={30} width={1080} height={1920} />

      {/* ── Logos ─────────────────────────────────────────────────────────── */}
      {/* 1. Wordmark — letter-by-letter wipe + gold underline (3s) */}
      <Composition id="LogoWordmark" component={Logo_Wordmark} durationInFrames={90} fps={30} width={1080} height={1080} />
      {/* 2. Mark — three slash lines draw in + wordmark (3.5s) */}
      <Composition id="LogoMark" component={Logo_Mark} durationInFrames={105} fps={30} width={1080} height={1080} />
      {/* 3. Badge — ring draws clockwise + badge center scales in (3.7s) */}
      <Composition id="LogoBadge" component={Logo_Badge} durationInFrames={112} fps={30} width={1080} height={1080} />

      {/* ── Logo Images — static PNG exports ──────────────────────────────── */}
      {/* Render: remotion still <id> --frame=0 --output=out/<id>.png        */}
      <Composition id="LogoImageHorizontal" component={LogoImage_Horizontal as React.ComponentType<Record<string, never>>} durationInFrames={1} fps={30} width={1920} height={1080} />
      <Composition id="LogoImageSquare"     component={LogoImage_Square     as React.ComponentType<Record<string, never>>} durationInFrames={1} fps={30} width={1080} height={1080} />
      <Composition id="LogoImageIcon"       component={LogoImage_Icon       as React.ComponentType<Record<string, never>>} durationInFrames={1} fps={30} width={1080} height={1080} />

      {/* ── Organic Videos — app UI screen-recording style ─────────────────── */}
      {/* 1. App Flow — face shape reveal + top 3 cuts (10s) */}
      <Composition id="Organic1AppFlow" component={Organic_AppFlow} durationInFrames={300} fps={30} width={1080} height={1920} />
      {/* 2. Barber Brief — typewriter script reveal (11s) */}
      <Composition id="Organic2BarberBrief" component={Organic_BarberBrief} durationInFrames={330} fps={30} width={1080} height={1920} />
      {/* 3. Compatibility Breakdown — 5 score bars animate in (10.7s) */}
      <Composition id="Organic3CompatibilityBreakdown" component={Organic_CompatibilityBreakdown} durationInFrames={320} fps={30} width={1080} height={1920} />

      {/* ── Graphic Pack — content creator templates ──────────────────────── */}
      {/*
        1. ScoreReveal — portrait 9:16 — 7s
           "My TRIMR results" reel: face shape badge + all 5 animated score bars.
      */}
      <Composition
        id="ScoreReveal"
        component={ScoreRevealC}
        durationInFrames={210}
        fps={30}
        width={1080}
        height={1920}
        defaultProps={{
          name: "Alex",
          faceShape: "Oval",
          overallScore: 92,
          faceShapeMatch: 95,
          ageAppropriateness: 90,
          maintenance: 85,
          trendScore: 90,
          stylingDifficulty: 80,
        }}
      />
      {/*
        2. HaircutCard — portrait 9:16 — 6s
           Full recommendation card: name slam, score, why-it-works, 2 tips.
      */}
      <Composition
        id="HaircutCard"
        component={HaircutCardC}
        durationInFrames={180}
        fps={30}
        width={1080}
        height={1920}
        defaultProps={{
          rank: 1,
          haircutName: "Textured Fringe",
          score: 92,
          faceShape: "Oval",
          whyItWorks:
            "The soft fringe balances your forehead width and adds natural dimension to your face.",
          tip1: "Ask for 3–4 inches on top with tapered sides and a skin fade.",
          tip2: "Use a small amount of clay to define the fringe — avoid heavy pomades.",
        }}
      />
      {/*
        3. BeforeAfterStory — portrait 9:16 — 9s
           Wipe reveal from "no plan" silhouette to styled face with score pop.
      */}
      <Composition
        id="BeforeAfterStory"
        component={BeforeAfterStoryC}
        durationInFrames={270}
        fps={30}
        width={1080}
        height={1920}
        defaultProps={{
          haircutName: "Textured Fringe",
          score: 92,
          faceShape: "Oval",
          username: "yourname",
        }}
      />
      {/*
        4. LowerThird — landscape 16:9 — 5s
           Branded overlay for YouTube / Twitch / talking-head videos.
      */}
      <Composition
        id="LowerThird"
        component={LowerThirdC}
        durationInFrames={150}
        fps={30}
        width={1920}
        height={1080}
        defaultProps={{
          title: "Textured Fringe · 92/100",
          subtitle: "Oval face · Best match",
          score: 92,
        }}
      />
      {/*
        5. FeedSquare — square 1:1 — 5s
           Animated post for Instagram / Twitter / LinkedIn.
      */}
      <Composition
        id="FeedSquare"
        component={FeedSquareC}
        durationInFrames={150}
        fps={30}
        width={1080}
        height={1080}
        defaultProps={{
          faceShape: "Oval",
          haircutName: "Textured Fringe",
          score: 92,
          username: "yourname",
          tip: "Ask for 3–4 inches on top, tapered sides with a skin fade to blend cleanly.",
        }}
      />

      {/* ── Image Pack — static PNG exports ──────────────────────────────── */}
      {/* Render any of these as a PNG with: remotionb still <id> --frame=0 --output=out/<id>.png */}

      {/* 1. How It Works — 1080×1920 portrait infographic */}
      <Composition id="HowItWorksImage" component={HowItWorksImage as React.ComponentType<Record<string, never>>} durationInFrames={1} fps={30} width={1080} height={1920} />

      {/* 2. Score Explainer — 1080×1080 square, explains each criterion */}
      <Composition id="ScoreExplainerImage" component={ScoreExplainerImage as React.ComponentType<Record<string, never>>} durationInFrames={1} fps={30} width={1080} height={1080} />

      {/* 3. Face Shape Guide — 1080×1920 portrait, all 6 shapes + ideal cuts */}
      <Composition id="FaceShapeGuideImage" component={FaceShapeGuideImage as React.ComponentType<Record<string, never>>} durationInFrames={1} fps={30} width={1080} height={1920} />

      {/* 4. What You Get — 1080×1080 square, full feature grid */}
      <Composition id="WhatYouGetImage" component={WhatYouGetImage as React.ComponentType<Record<string, never>>} durationInFrames={1} fps={30} width={1080} height={1080} />

      {/* 5. Barber Brief — 1080×1920 portrait, "show this to your barber" */}
      <Composition id="BarberBriefImage" component={BarberBriefImage as React.ComponentType<Record<string, never>>} durationInFrames={1} fps={30} width={1080} height={1920} />

      {/* 6. Try-On Slide — 1080×1920 portrait, TikTok slideshow mid-slide */}
      <Composition id="TryOnSlide" component={TryOnSlide as React.ComponentType<Record<string, never>>} durationInFrames={1} fps={30} width={1080} height={1920} />

      <Composition
        id={COMP_NAME}
        component={Main}
        durationInFrames={DURATION_IN_FRAMES}
        fps={VIDEO_FPS}
        width={VIDEO_WIDTH}
        height={VIDEO_HEIGHT}
        defaultProps={defaultMyCompProps}
      />
      <Composition
        id="NextLogo"
        component={NextLogo}
        durationInFrames={300}
        fps={30}
        width={140}
        height={140}
        defaultProps={{
          outProgress: 0,
        }}
      />
    </>
  );
};
