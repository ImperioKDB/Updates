# Reconstruction Knowledge Base — Phase 1A

## Purpose

This knowledge base translates public evidence into implementation-neutral principles an independent frontend engineer could reproduce without copying HTMLhost proprietary code, branding, or source.

## Platform shell principles — VERIFIED

A premium hosting/editor shell can combine a sticky navigation system, large editorial hero, high-contrast surface hierarchy, responsive device controls, import/generate entry points, template cards, and a preview workspace. Keep shell assets, typography, and route behavior separate from the embedded website runtime.

## Template runtime principles — VERIFIED

A public template runtime can remain plain HTML/CSS/JavaScript while still supporting high visual quality. The evidence shows that quality can come from strong type pairing, role-based color tokens, constrained grids, explicit responsive rules, semantic forms, inline SVG/CSS artwork, procedural canvas/WebGL visuals, CSS keyframes, IntersectionObserver reveals, requestAnimationFrame counters, Swiper, and reduced-motion branches.

The exact implementation can vary. Creative Playground and Business Web Studio show interaction-rich DOM/CSS/JS. Futuristic Dark shows a custom shader route. Kinetica combines typography, sound, and motion declarations. Portfolio shows image-heavy inline content and extensive CSS motion. No common framework is required by the evidence.

## Responsive principles — VERIFIED

Use at least three tested layout states: desktop, tablet, and phone. Treat the preview wrapper’s frame transformation as separate from the embedded page’s own responsive CSS. Use explicit breakpoints only when layout behavior supports them. Reserve image dimensions where possible, lazy-load noncritical imagery, and provide reduced-motion alternatives.

## Evidence-safe reconstruction rules

Do not call a library “used” merely because a marketing page names it. Confirm public source declarations and, where possible, observable behavior. Do not assume preview source equals published output. Do not infer a customer-site framework from HTMLhost’s host shell. Keep unknown deployment, asset transformation, form backend, and performance details explicitly open.

## Current unknowns

The public corpus does not establish published generated-site HTML, headers, CSP, asset URLs, runtime dependencies, post-generation modifications, or quantitative performance. Those questions require a verified public customer site or separately authorized test publication.


## Phase 1B runtime principles — VERIFIED within sampled public previews

### Motion is template-specific

Do not assume a common animation stack. The sampled previews combined simple CSS loops, stateful animation objects, a declared canvas/RAF path, preloader motion, and a long marquee/FAQ transition. Public source declarations of GSAP, Swiper, Howler, or other packages do not verify that those libraries loaded or authored observed behavior. The visible canvas does not prove the WebGL branch ran; zero Web Animations API entries do not rule out a JavaScript RAF loop.

### Synchronize interaction state and accessibility state

Kinetica's tested pause/resume control changed its visible state, accessible name, and `aria-pressed` value along with the sampled animation states. Business Web Studio's FAQ used a button/controlled region and `aria-expanded` false→true→false. An independent reconstruction should keep the DOM state authoritative and let CSS supply the transition. For sliders, implement deterministic next/previous state and test it; the Portfolio test records disagree on one Next outcome.

### Make reduced motion a per-effect requirement

The sampled desktop behavior varied: Creative Playground had zero sampled animation objects; Kinetica had 21 paused; Futuristic Dark showed identical screenshots but unknown canvas input/render behavior; Portfolio still had two running preloader animations; Business Web Studio had zero baseline animation objects. Implement and test reduced-motion behavior for each animation family and interactive state rather than assuming one media rule proves full support.

### Direct manipulation needs a complete input path

One Creative Playground shape drag was directly observed. Source declared further pointer/keyboard behavior, but those paths were not all exercised. A general reconstruction should support pointer capture, bounded motion, keyboard-equivalent movement, clear focus, and an optional status. The Futuristic Dark focused follow-up saw pointer events on page ancestors, not the canvas, so canvas-specific delivery remains UNKNOWN.

## Phase 1B performance and responsive principles

The saved matrix covers one headless Chromium run per cell; it is not a comparative performance benchmark. Treat reported CLS/LCP as provisional single-run entries, Resource Timing bytes as incomplete known bytes, image counters as early snapshots, elapsed-to-body-visible as host-plus-wait time, and RAF callback intervals as non-FPS. No Lighthouse, field Web Vitals, CPU/GPU trace, real-device test, or repeated-run statistical sample was available. Published-site performance remains UNKNOWN.

At 390 px, Creative Playground's preview iframe reported 1041 px document scroll width. Add overflow checks to mobile validation and do not reproduce the overflow as an intentional design feature. Kinetica and Futuristic Dark phone captures remained at 390 px document width; those observations do not validate all intermediate breakpoints.

## Current evidence gaps carried forward

- **UNKNOWN:** Published generated-site markup, runtime, responsive behavior, resource delivery, and field performance.
- **UNKNOWN:** Runtime use of declared optional libraries and the exact execution paths behind several animations.
- **UNKNOWN:** Reliable frame pacing, GPU/CPU cost, real-device touch latency, complete bytes including TAO-restricted resources, and repeated-run variability.
- **UNKNOWN:** Futuristic Dark's WebGL versus fallback path and canvas-targeted input response; Portfolio testimonial sequence; Business Web Studio's FAQ final geometry/timing discrepancy.
- **UNKNOWN:** Unexercised forms, menu/theme state, counters, keyboard paths, and reduced-motion interactive states.

See `PHASE_1B_MOTION_DEEP_AUDIT.md`, `PHASE_1B_PERFORMANCE_BENCHMARK.md`, `ANIMATION_TECHNIQUE_COMPARISON.md`, and `FRONTEND_MOTION_ENGINEERING_GUIDE.md` for evidence and implementation-neutral detail.


## Phase 1C targeted-validation addendum

### Deterministic interaction state — VERIFIED recommendation

The Portfolio follow-up produced 1/5 no-preference and 1/5 reduced-motion first activations that remained on slide 0, with the other four repetitions reaching slide 2. The internal cause is UNKNOWN. An independent reconstruction should not copy this ambiguity: keep the active index authoritative, process a valid activation once, and test the first activation from a fresh context after any automatic timers have been considered.

### Canvas renderer and input boundary — VERIFIED / UNKNOWN

Futuristic Dark's canvas returned a WebGL context in the tested Chromium environment, while WebGL2 and 2D returned false. This verifies context creation in one environment, not production GPU acceleration or a universal renderer. The canvas pointer probe recorded no canvas-targeted event; reduced-motion ancestor events reached window/body with non-canvas targets, and reduced screenshots were identical. Canvas input delivery and visible pointer response therefore remain UNKNOWN.

### Accessible disclosure closure — VERIFIED

Business Web Studio's FAQ used a native button with `aria-controls="f1"` controlling a `role="region"` with `id="f1"`. Ten repetitions using both keyboard and click activation produced false→true→false `aria-expanded` transitions without page errors. The settled panel was approximately 109.56 px open and zero closed. Immediate normal-motion close measurements can represent in-transition geometry; validate after the declared duration plus a margin.

### Performance evidence boundary — VERIFIED limitation

Phase 1C added Lighthouse route diagnostics but not an isolated iframe or published-site benchmark. The homepage scored 0.80 and the Futuristic template route 0.79 in single runs. Keep shell, preview, and published-site measurements separate. RAF callback counts remain callback samples rather than FPS.

See `PHASE_1C_TARGETED_VALIDATION.md`, `PHASE_1C_PERFORMANCE_TRACE_REPORT.md`, and `HTMLHOST_FRONTEND_ENGINEERING_SPECIFICATION.md` for the detailed evidence and independent implementation guidance.
