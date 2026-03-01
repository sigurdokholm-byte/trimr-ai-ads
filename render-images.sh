#!/bin/bash
# TRIMR AI — Render Image Pack as PNG files
# Run with: bash render-images.sh

mkdir -p out/images

echo "Rendering TRIMR AI Image Pack..."

remotionb still HowItWorksImage     --frame=0 --output=out/images/01-how-it-works.png    --jpeg-quality=100
remotionb still ScoreExplainerImage --frame=0 --output=out/images/02-score-explainer.png --jpeg-quality=100
remotionb still FaceShapeGuideImage --frame=0 --output=out/images/03-face-shape-guide.png --jpeg-quality=100
remotionb still WhatYouGetImage     --frame=0 --output=out/images/04-what-you-get.png     --jpeg-quality=100
remotionb still BarberBriefImage    --frame=0 --output=out/images/05-barber-brief.png     --jpeg-quality=100

echo ""
echo "Done! Images saved to out/images/"
ls -lh out/images/
