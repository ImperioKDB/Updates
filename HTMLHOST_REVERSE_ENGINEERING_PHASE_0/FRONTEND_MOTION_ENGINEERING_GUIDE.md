# Frontend Motion Engineering Guide — Phase 1B

**Purpose:** Translate the public-preview research into reusable implementation guidance for an independent engineer. This is not a copy of HTMLhost code, brand assets, or a claim about a shared HTMLhost stack.

## 1. Start with an evidence and runtime boundary

The inspected website preview was a public sandboxed `srcdoc` document inside an HTMLhost platform page. Keep three layers separate in your own work:

1. **Host shell:** navigation, preview frame, device controls, host fonts and styles.
2. **Preview/site document:** page markup, tokens, animation code, external assets and template-specific interactions.
3. **Published generated site:** not observed in this research; do not infer its runtime, headers, asset delivery, or performance from the preview.

When researching or rebuilding a public example, label source declarations separately from directly observed browser behavior. A declared library does not prove it loaded or authored an effect. The runtime animation inventory does not identify a library or a JS loop. Use evidence labels in code comments or an implementation note when the behavior is still inferred.

## 2. Choose the smallest motion mechanism that fits

### Discrete state changes

For a disclosure, menu, selection, or small layout state, prefer a semantic control plus a short CSS transition. Keep the state authoritative in JavaScript or native HTML and let CSS render it. The Business Web Studio FAQ supplied a direct example of a 500 ms grid-row disclosure; its close-state measurement also showed why tests must wait for the transition to settle.

### One-time section entrances

Use IntersectionObserver as a visibility trigger, not as a per-frame animation loop. Observe a small number of section-level elements, set a visible state once, then unobserve. Keep default content visible when JavaScript is unavailable, and make reduced motion immediate. Avoid long stagger sequences and never make essential content depend on entering the viewport.

### Ambient motion

Use CSS keyframes for simple loops such as a marquee or rotating label when they add context and can be paused. Prefer transforms/opacity over properties that trigger layout on every frame. Avoid adding multiple loops by default. Provide a clear reduced-motion alternative, and test the exact loop under the preference rather than relying on a global CSS block that may miss JS-driven motion.

### Direct manipulation

Use Pointer Events for mouse, pen, and touch. Capture the pointer on drag start, compute position relative to a containing surface, and clamp it to the parent's bounds. Remove transitions while following the pointer so the object does not lag behind; use a short settle transition only for discrete repositioning. Add a keyboard path with predictable increments, a visible focus ring, clear instructions, and an accessible status when it is useful.

### Canvas and procedural visuals

Use a continuous RAF/WebGL effect only when the visual goal benefits from procedural rendering. Keep page content and controls outside the canvas. Handle resize and DPR, page visibility, context/fallback, pointer routing, reduced motion, and battery/GPU cost. Do not claim a canvas is using WebGL simply because a canvas is visible or source declares a WebGL path; verify the active context and fallback separately.

## 3. Reduced-motion engineering

Treat `prefers-reduced-motion` as a first-class state, not a last-minute stylesheet. For each motion family, specify what happens:

- **Decorative loop:** pause, remove, or replace it with a still state.
- **Entrance reveal:** show the final content immediately.
- **Direct manipulation:** preserve the interaction but remove nonessential wobble/overshoot.
- **Disclosure or navigation:** keep the exact same control/state behavior; shorten or remove the transition.
- **Canvas:** show a stable frame or low-cost static composition and verify which branch runs.
- **Preloader:** do not leave an endless spinner; consider skipping purely decorative motion.

The Phase 1B samples did not show a universal policy: Creative Playground had zero sampled animations; Kinetica paused its 21 sampled objects; Futuristic Dark had identical reduced-motion images but unknown canvas input/render path; Portfolio still sampled two running preloader animations; Business Web Studio had zero baseline animation objects. A per-template check is therefore necessary.

For controls that pause motion, keep all state in sync: visible text, `aria-label`, `aria-pressed`, and actual animation state. Do not announce a pause or resume that did not happen.

## 4. Accessibility and interaction state

- Use a native `<button>` for a control; do not emulate button semantics with a clickable `<div>`.
- For a disclosure, give the button an `aria-controls` reference to its panel, keep `aria-expanded` current, label the panel, and remove collapsed content from tab order (for example with `inert`).
- For drag, provide a keyboard alternative and text instructions. Make bounds discoverable and preserve focus after movement.
- For a carousel, make the active slide deterministic, support keyboard operation, label previous/next controls, and test announcements/focus. The Portfolio capture had conflicting Next-slide outcomes, so its intended sequence is unknown.
- Keep hover effects additive; do not hide necessary actions until hover, particularly on touch screens.
- Test keyboard focus with transitions in progress and with reduced motion.

## 5. Performance and measurement discipline

Separate the question you are measuring:

- **Was an animation declared?** Inspect public source/style.
- **Was an animation object active at this instant?** Sample `document.getAnimations()` and record time/state.
- **Did JavaScript callbacks occur?** Sample RAF or use a trace, but do not call that display FPS.
- **Did the interaction update state?** Capture DOM attributes, computed style, and before/after screenshots.
- **What transferred?** Record Resource Timing and response data, noting cross-origin/TAO gaps.
- **What did the browser render?** Use complete LCP/CLS instrumentation and repeat runs; a late observer may miss events.
- **Was it smooth on a target device?** Use a browser performance trace and real-device testing, not a single headless run.

The Phase 1B matrix used one headless Chromium observation per viewport/preference cell. `body-visible` elapsed includes host setup/waits. Reported CLS/LCP are provisional observations; known Resource Timing bytes can be incomplete; image counters were captured early; RAF cadence is not compositor presentation. No cross-template speed ranking is justified.

## 6. Recommended test sequence

1. Record route, document layer, viewport, browser build, locale, color scheme, reduced-motion setting, cache state, and readiness rule.
2. Take a stable baseline screenshot and DOM/style snapshot.
3. Run one reversible interaction; collect control attributes and relevant computed properties before, during if needed, and after the transition settles.
4. Repeat under `prefers-reduced-motion: reduce`; compare state and content, not only pixel identity.
5. Repeat at mobile and desktop sizes, verifying horizontal overflow, focus, touch, and target bounds.
6. Run repeated loads and a browser performance trace if performance conclusions are needed. State the sample size and uncertainty.
7. Keep host-shell network and iframe document network separate; do not imply public preview data represents a published site.

## 7. Independent example implementations

Three dependency-free, original demonstrations are included under `phase1b-experiments/`:

- `01-scroll-reveal.html` — IntersectionObserver reveal with CSS transitions, visible fallback, and reduced-motion behavior.
- `02-pointer-drag.html` — bounded Pointer Events drag with capture, keyboard movement, and discrete settling.
- `03-accessible-disclosure.html` — stateful button/panel relationship with `aria-expanded`, `aria-controls`, `inert`, grid-row transition, and reduced-motion behavior.

They demonstrate general techniques, not HTMLhost code. Each passed a local smoke test in the system Chromium. Test results and implementation rationale are in `INTERACTION_EXPERIMENTS.md`.
