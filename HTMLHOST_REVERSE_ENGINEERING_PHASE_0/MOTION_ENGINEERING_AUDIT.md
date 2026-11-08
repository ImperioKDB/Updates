# Motion Engineering Audit — Phase 1A

## Platform frontend — VERIFIED / UNKNOWN

The public platform shell exposes a responsive mobile navigation region with state classes for hidden/open behavior, opacity, pointer events, height, transition duration, and reduced-motion handling. The exact host animation library and easing implementation are UNKNOWN. The public preview wrapper also provides desktop/phone presentation transitions, but its internal choreography was not fully isolated from the template content.

## Template/preview frontend — VERIFIED

The five previews use different motion mechanisms:

- **Creative Playground:** GSAP entrances/resets, IntersectionObserver scroll reveals, pointer and keyboard drag, bounded shape movement, rotation/squish feedback, Swiper carousel, smooth scrolling, form feedback, and reduced-motion fallback. Public source declares GSAP, Swiper, Lucide, canvas-confetti, and JustValidate.
- **Kinetica:** seven keyframe rules, explicit animation/transform/transition declarations, moving typography, sound/motion controls, carousel/FAQ/try-it content, and public declarations for GSAP, ScrollTrigger, SplitText, Swiper, Howler, Lucide, and Tailwind browser.
- **Futuristic Dark:** custom WebGL shader animation driven by requestAnimationFrame, pointer/touch input, normalized pointer easing, ambient drift, procedural noise, page-visibility pause, canvas DPR cap, CSS fallback, and reduced-motion still render.
- **Full-Stack Portfolio:** inline CSS keyframes including shine, marquee, float, expReveal, menuSlideIn, pulse-glow, and spin, with inline JavaScript event listeners. Active Three.js rendering is UNKNOWN despite metadata/markers because the inspected Home source had no canvas or external script source.
- **Business Web Studio:** mobile menu, FAQ accordions, scroll-state header, IntersectionObserver reveals, requestAnimationFrame counters, theme toggle/localStorage, current-year update, Lucide initialization, and reduced-motion rules.

## Evidence classification

Source declarations verify that mechanisms exist in the public preview documents. They do not verify frame rate, perceived smoothness, exact easing curves, or successful execution of every optional dependency.

## UNKNOWN

No quantitative FPS, long-task, animation timing, CPU/GPU, or real-device smoothness measurement was collected. No form submission, download, copy, editor launch, or publish interaction was executed.

## Next safe motion investigation

After review, replay one reversible interaction per template—menu, accordion, carousel, pointer effect, or reduced-motion toggle—while collecting before/after DOM attributes, computed styles, and screenshots. Keep the generated-site column separate.


## Phase 1B runtime addendum — 2026-11-08

Phase 1B directly sampled public, sandboxed preview runtime state at 1440×900 under both motion preferences, plus 390×844 on Creative Playground, Kinetica, and Futuristic Dark. The observations below supplement, but do not upgrade, Phase 1A source declarations. Detailed records are in `PHASE_1B_MOTION_DEEP_AUDIT.md` and `phase1b-evidence/`.

### VERIFIED runtime findings

- **Creative Playground:** two sampled no-preference loops ran (24 s linear marquee and 6 s orbit); one orange-shape pointer drag moved its recorded position. At desktop reduce, zero animation objects were sampled versus two running in no-preference. The 390 px capture reported iframe document width 1041 px and viewport width 390 px.
- **Kinetica:** 21 desktop animation objects (4 running/17 paused), 23 mobile objects (6 running/17 paused). Its tested pause/resume button synchronized visible text, accessible name, `aria-pressed`, and sampled animation states. Reduce paused all 21 desktop objects.
- **Futuristic Dark:** canvas visible, zero Web Animations API objects, and source-declared RAF/WebGL/fallback behavior. RAF callback samples do not establish FPS. The dedicated reduced-motion pointer test saw no pointer events and identical before/idle/after images; focused follow-up saw window events targeting header/nav/div/main, not the canvas. Canvas-specific event delivery and visible response remain UNKNOWN.
- **Full-Stack Portfolio:** spinner and icon animations remained running in the reduced-motion capture. Focused follow-up sampled a 300 ms testimonial transition and slide change, but the primary Next capture reports no change; deterministic Next behavior remains unresolved.
- **Business Web Studio:** one 40 s linear services-label track ran at baseline; the FAQ used a 500 ms grid-row transition and `aria-expanded` false→true→false. The close sample differed (4.2 px versus 0 px) between the primary and focused captures; final geometry/timing is not fully settled. Desktop reduce sampled zero baseline animations.

### Evidence limits

Source-level library declarations do not prove runtime use or attribution. `document.getAnimations()` does not enumerate every JS animation loop; RAF callbacks are not compositor FPS. These are sampled preview states, not published-site observations or complete reduced-motion certifications. Portfolio's disputed slide result and Business's differing FAQ close measurements remain explicitly unresolved.

See `ANIMATION_TECHNIQUE_COMPARISON.md` and `FRONTEND_MOTION_ENGINEERING_GUIDE.md` for independent engineering implications, and `INTERACTION_EXPERIMENTS.md` for three original technique demonstrations.
