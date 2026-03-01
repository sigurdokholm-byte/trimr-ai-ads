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
