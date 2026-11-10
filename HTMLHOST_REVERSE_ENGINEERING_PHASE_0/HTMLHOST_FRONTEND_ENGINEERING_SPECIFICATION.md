# HTMLhost Frontend Engineering Specification

**Purpose:** An implementation-neutral specification for building polished, responsive, motion-rich websites independently. It does not reproduce HTMLhost branding, proprietary source, or private architecture.

## Evidence boundary

The research covers three distinct layers:

1. **Platform shell:** the public HTMLhost application surface with Next.js/Vercel delivery signals.
2. **Public template previews:** heterogeneous sandboxed `srcdoc` documents containing template-specific HTML, CSS, JavaScript, canvas, assets, and controls.
3. **Published generated sites:** not verified. Their runtime, headers, asset pipeline, and performance remain UNKNOWN.

A declaration of GSAP, Swiper, Howler, or another package is not proof that it loaded or authored an observed effect. A Web Animations API inventory does not expose every JavaScript loop. A canvas does not prove WebGL until context initialization is checked.

## 1. Architecture

### Required structure

- Keep page content, interaction state, and motion presentation as separate concerns.
- Make the semantic DOM usable with JavaScript disabled or motion disabled.
- Put decorative canvas/WebGL behind content and controls rather than making it the only carrier of meaning.
- Isolate host-shell styles and assets from embedded or template runtime styles.
- Define role-based tokens for surfaces, text, borders, accents, focus, spacing, radii, and motion durations.

### Recommended state model

Use one authoritative state for each interaction: active slide index, disclosure open state, menu state, or drag position. Update the state in one place, then let CSS or a rendering layer present it. Do not infer state from an animation's current transform.

## 2. Motion selection

| Need | Default mechanism | Specification |
|---|---|---|
| Small state change | CSS transition | Native control; semantic state changes immediately; animate opacity/transform or a carefully bounded layout property. |
| Simple ambient loop | CSS keyframes | Use transform/opacity, intentional duration, pause/reduce branch, and overflow checks. |
| One-time reveal | IntersectionObserver + CSS | Observe section-level elements, reveal once, keep a visible fallback, do not hide essential focusable content. |
| Direct manipulation | Pointer Events + capture | Capture the pointer, clamp to bounds, remove lagging transitions during tracking, supply keyboard equivalence. |
| Procedural visual | Canvas/WebGL + RAF | Only when the visual benefit justifies cost; check context, fallback, DPR, visibility, input, reduced motion, and context loss. |
| Complex timeline | GSAP or another library | Add only when sequencing or orchestration materially improves maintainability; validate loading, accessibility, reduced motion, and performance. |
| Carousel | Small deterministic state machine or validated library | Test first activation, order, focus, announcements, keyboard, touch, and reduced motion. |

The public preview evidence supports these as technique families, not as a shared HTMLhost stack.

## 3. Timing and transitions

- Use short transitions for local UI state; the Business FAQ exposed a 500 ms `grid-template-rows` transition in normal motion.
- Test both immediate and settled states. A measurement taken immediately after a close activation may still show the open geometry.
- Use a consistent easing vocabulary: restrained ease-out for entrances, linear for marquees, and no unnecessary overshoot for accessibility-sensitive controls.
- Do not use transition completion as the source of truth for ARIA state.
- For a carousel, update the active index synchronously, then animate the outgoing/incoming visual states.

## 4. Accessibility

### Disclosures and menus

Use a native button with `aria-expanded` and `aria-controls`. The controlled region should have the referenced ID and an appropriate landmark/role when useful. Preserve keyboard activation and focus. If collapsed content contains interactive descendants, use `inert` or an equivalent robust strategy.

### Motion controls

For motion-heavy pages, an explicit pause/resume control can complement—not replace—`prefers-reduced-motion`. Keep visible text, accessible name, `aria-pressed`, and actual animation state synchronized.

### Drag and canvas

A pointer target needs a keyboard path, visible focus, bounded behavior, and instructions. `touch-action:none` should be local to the interaction surface, not applied to the whole page. Canvas visual effects must not be the only way to understand content.

### Carousel

Make the active slide deterministic, label controls, preserve focus, and announce changes only when useful. Test from a fresh load and after automatic timers have had a chance to run. Do not copy the Portfolio preview's observed inconsistent first-activation behavior.

## 5. Reduced-motion contract

Specify each effect's behavior explicitly:

- Decorative loops pause, disappear, or become still.
- Reveals show final content immediately.
- Direct manipulation remains functional but loses nonessential wobble/overshoot.
- Disclosures retain the same semantic state changes while transitions become zero-duration or short.
- Canvas shows a stable low-cost frame or a verified fallback.
- Preloaders do not run indefinitely when the motion is decorative.

The Phase 1B/1C evidence showed heterogeneous behavior across previews; there is no basis for assuming one global policy.

## 6. Canvas/WebGL contract

Before relying on a procedural effect:

1. Create a context and record success/failure.
2. Provide a CSS or static fallback.
3. Cap device-pixel-ratio scaling and resize safely.
4. Pause or reduce work when the document is hidden.
5. Define the pointer/touch coordinate space and test that events arrive at the intended target.
6. Test reduced motion separately from normal motion.
7. Keep controls and text outside the canvas.
8. Handle context loss and unsupported browsers.
9. Profile on target devices; RAF callback counts are not FPS.

Phase 1C directly verified WebGL context creation in Futuristic Dark's preview environment but did not verify canvas-targeted pointer delivery or production GPU behavior.

## 7. Responsive engineering

- Validate at desktop, tablet, and phone widths plus intermediate breakpoints.
- Treat an outer preview frame and the embedded document as separate responsive layers.
- Assert `scrollWidth <= viewport width` where horizontal overflow is not intentional.
- Reserve media dimensions, use lazy loading for noncritical imagery, and avoid layout-affecting motion.
- Verify focus order and tap targets after stacking or navigation changes.
- Do not assume a phone-ready marketing claim proves real-device touch behavior.

The Phase 1B Creative Playground capture reported 1041 px document width inside a 390 px viewport; this should be treated as a defect to diagnose, not a pattern to copy.

## 8. Performance discipline

Measure one question at a time:

- **Declared:** source/style inspection.
- **Active now:** animation inventory at a timestamp.
- **JavaScript work:** RAF/long-task/trace evidence.
- **Presented smoothly:** browser performance trace and target-device testing.
- **Transferred:** response/resource evidence with cross-origin caveats.
- **User experience:** repeated lab runs and field data where available.

Use Lighthouse as a diagnostic baseline, not a universal score. Phase 1C recorded route-level scores of 0.80 for the platform homepage and 0.79 for the Futuristic template route, but the latter combines shell and iframe work and neither is a published customer site.

## 9. Validation checklist

Before shipping a motion-rich route:

- Verify semantic state before, during, and after transitions.
- Repeat the first interaction from a fresh context.
- Test click, keyboard, and touch/pointer paths.
- Test normal and reduced motion.
- Inspect console errors and failed resources.
- Check mobile overflow and focus visibility.
- Test hidden-tab behavior for continuous loops.
- Record browser, viewport, DPR, cache, network, and sample count.
- Do not turn a single synthetic run into a performance ranking.

## Highest-value recommendations for Scholars

1. Build a small, deterministic interaction/state layer before adding animation.
2. Prefer CSS transitions and keyframes for local UI and ambient motion; use JavaScript or GSAP only for genuine orchestration needs.
3. Make reduced motion and keyboard behavior acceptance criteria from the first implementation.
4. Avoid canvas for semantic content; if used decoratively, ship a tested fallback and pause path.
5. Validate responsive overflow and settled geometry automatically.
6. Treat Lighthouse and trace output as repeatable diagnostics, not proof that a published site will perform the same way.
