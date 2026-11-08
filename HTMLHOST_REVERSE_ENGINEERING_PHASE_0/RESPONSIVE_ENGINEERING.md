# Responsive Engineering — Phase 1A

## Capture baseline

All approved targets were captured at 1440×900, 768×1024, and 390×844 using Chromium/Playwright. The capture produced 21 JSON records and 81 PNG screenshots.

## Platform frontend — VERIFIED

The public HTMLhost shell stayed within the tested viewport widths. The homepage and editor document scroll heights increased substantially at tablet/mobile widths while document width matched the viewport. Earlier DOM inspection found a mobile navigation region with a breakpoint around `max-[1199px]`, state classes, transitions, and reduced-motion behavior.

## Template/preview frontend — VERIFIED

Each template advertises phone support and exposes public desktop/phone presentation frames. The embedded phone frame is approximately 390 CSS pixels wide in the public wrapper. The template source supplies additional breakpoints and transformations:

- **Creative Playground:** source thresholds at 760px, 400px, and 1500px; Swiper changes around 540px and 900px; phone preview visibly reflows hero/navigation/playground.
- **Kinetica:** source thresholds at 1440px, 1100px, 900px, 680px, plus smaller component rules; `hover: none` and reduced-motion branches; phone-ready stacked content.
- **Futuristic Dark:** canvas resizes with the viewport; phone presentation retains navigation, hero, CTAs, stats, generated background, and footer; exact breakpoint values remain UNKNOWN.
- **Full-Stack Portfolio:** source thresholds at 480px, 768px, 992px, and 1024px; phone Home reflows into a narrow vertical hero with menu, portrait, CTA, copy, and logo cards.
- **Business Web Studio:** source thresholds at 980px, 860px, 760px, and 620px; <=860px one-column hero and mobile overlay menu; hero image changes from 16:8 to 4:3; later images use lazy loading.

## Two responsive layers

### VERIFIED

The public wrapper controls the preview frame, desktop/phone presentation, iframe sizing, and host overlay. The template document independently controls its own internal layout, typography, media, navigation, and interactions.

### UNKNOWN

Intermediate breakpoint behavior between the three captured widths, real-device touch behavior, accessibility focus transitions, and published-site responsive output remain incomplete or unknown.
