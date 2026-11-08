# Animation Technique Comparison — Phase 1B

**Scope:** Five public HTMLhost template previews, captured 2026-11-08. This compares evidence and transferable implementation ideas; it does not claim a shared HTMLhost animation stack or identify proprietary implementation details.

## Evidence scale

- **VERIFIED / source:** public preview markup or style declares a mechanism.
- **VERIFIED / runtime:** the browser capture exposes the behavior or state directly.
- **INFERRED:** reasonable generalization, not proven as the source implementation.
- **UNKNOWN:** attribution or outcome is not established.

A declaration of GSAP, Swiper, Howler, or another package is not evidence that the library loaded or produced the recorded animation. Web Animations API entries identify sampled animation objects, not their authoring source. Keep the host shell separate from the preview iframe and both separate from a published generated site.

## Comparative matrix

| Technique | Phase 1B evidence | Strengths when independently implemented | Trade-offs and validation points |
|---|---|---|---|
| CSS keyframes / continuous loops | **VERIFIED:** Creative Playground sampled a 24 s linear marquee and 6 s orbit; Kinetica exposed staggered and longer-duration animation objects; Business Web Studio sampled a 40 s linear services track. Source declarations include additional keyframes. | Low-JS, easy to inspect, well suited to restrained ambient decoration. Prefer `transform` and `opacity` for frequent changes; keep loop count and duration intentional. | A moving background can distract, consume main-thread/compositor resources, or produce motion sensitivity. Pause or simplify under reduced motion; verify overflow at narrow widths and keyboard focus around moving content. |
| CSS transitions for UI state | **VERIFIED:** Business FAQ used a 500 ms `grid-template-rows` transition and a shorter plus/minus transition; Portfolio's sampled testimonial transition was 300 ms. | Natural for discrete open/close, selected/hover/focus states; keeps state changes small and CSS-driven. | Capture endpoints after transitions settle. A panel sampled at 4.2 px during closing is not a stable final state. Preserve semantic state independently from visual transition. |
| IntersectionObserver reveals | **VERIFIED / source:** Phase 1A source review found declared reveal observers in selected previews. Phase 1B did not directly measure their threshold crossings or timings. | Efficient visibility trigger for one-time section entrances; separates visibility detection from CSS presentation. | Avoid hiding essential content if JS fails. Respect reduced motion, do not animate every line, and avoid delaying focusable controls. The supplied scroll-reveal experiment demonstrates an independent pattern, not verified HTMLhost code. |
| Web Animations API inventory | **VERIFIED / measurement:** `document.getAnimations()` exposed counts/states/durations in sampled preview frames, and Kinetica's motion control paused/resumed the inventory. | Useful diagnostic surface for identifying active and paused CSS/WAAPI animation objects during a controlled test. | It does not identify the authoring library, GPU path, or JS RAF loop; snapshot results depend on sample time. A count is not a performance score. |
| Page-level pause/resume control | **VERIFIED:** Kinetica's accessible control updated its visible label, `aria-label`, and `aria-pressed`, paused 21 sampled objects, then resumed to four running/17 paused. | Gives users explicit agency over motion-heavy pages. Synchronize visual label and ARIA state with actual animation state. | Pausing page motion is distinct from `prefers-reduced-motion`. Test both; do not falsely announce resume if one loop remains paused or a control failed. |
| Pointer-based direct manipulation | **VERIFIED:** One Creative Playground shape moved under a pointer drag. Public source declares further keyboard and bounded behavior. Futuristic Dark's canvas-targeted pointer result is **UNKNOWN**. | Direct, low-latency manipulation can make an object feel responsive. Pointer Events plus pointer capture cover mouse/touch/pen; clamp movement to a meaningful region. | Ensure touch gestures do not trap page scrolling unintentionally. Add keyboard-equivalent movement, visible focus, clear bounds, and reduced-motion-safe feedback. Test pointer delivery on the intended target—not just an ancestor. |
| requestAnimationFrame | **VERIFIED / source and callback sample:** Futuristic Dark declares RAF; selected captures recorded callback counts/intervals. Business source declares RAF counters. | Useful for state updates tied to a frame; can coordinate imperative canvas work. | Callback cadence is not display FPS. Avoid unnecessary work when hidden; cap DPR and handle resize; observe visibility and reduced motion. Profile CPU/GPU and presentation separately. |
| Canvas / WebGL shader field | **VERIFIED:** Futuristic Dark rendered a full-frame canvas; source declares WebGL shaders, noise texture, DPR limit, reduced still render, and CSS fallback. **UNKNOWN:** which renderer path produced the captures. | Can create rich procedural imagery without many DOM nodes or external image assets; can scale to an art-directed visual field. | GPU support, context loss, battery, high-DPR cost, pointer routing, and fallback behavior must be tested. A visible canvas is not proof WebGL initialized. Provide a static/fallback path and accessible page content outside the canvas. |
| Carousel / slider library | **VERIFIED / declaration:** Swiper appears in some public source/metadata. Runtime library attribution is **UNKNOWN**. Portfolio's Next result is disputed between primary and focused captures. | A carousel can coordinate touch, keyboard, pagination, and transitions when its state model is deterministic. | Do not infer interaction order from an inconsistent capture. Test reduced motion, focus behavior, announcements, and no-JS/static content. Use a library only when its accessible behavior is validated. |
| Reduced-motion preference | **VERIFIED:** observed outcomes varied: Creative zero sampled objects; Kinetica 21 paused; Futuristic static identical samples; Portfolio still had two running preloader objects; Business zero baseline objects. | Allows a page to preserve content and function while reducing nonessential motion. | Not one universal behavior. Test each animation and interactive state with the preference enabled; do not infer full compliance from one screenshot or count. |

## Cross-template patterns

1. **Motion and content are separate layers.** The underlying heading, image, form, or disclosure should remain usable if its animation is paused or removed.
2. **State semantics matter.** The strongest tested interaction, Kinetica's pause/resume control, kept visible, accessible, and browser-observed state in sync. Business's FAQ similarly coordinated `aria-expanded` with its controlled region.
3. **The implementation is heterogeneous.** Source evidence includes CSS, DOM interactions, canvas, RAF, and public library declarations; there is no evidence of one common runtime or animation library.
4. **Reduced motion is not a brand-wide toggle proven by one template.** Each route's behavior must be checked independently; Portfolio's running preloader is a concrete area to re-test.
5. **Instrumentation has boundaries.** WAAPI inventory, screenshots, RAF samples, LCP/CLS entries, and Resource Timing each answer different questions. None alone measures overall quality or production performance.

## Practical selection guide

- Use a **CSS transition** for short state changes such as a panel or icon when its endpoints can be represented clearly.
- Use **CSS keyframes** for simple ambient loops, with a deliberate pause/reduced-motion path and no layout-affecting animation.
- Use **IntersectionObserver** only to decide when an entrance may occur; CSS should remain responsible for the simple visual change.
- Use **Pointer Events and pointer capture** for direct manipulation, with clamping, keyboard support, and an accessible status only when useful.
- Use **requestAnimationFrame/canvas** only when a continuous procedural visual warrants the extra work; pause when hidden and measure on target devices.
- Use a **third-party motion/slider library** only after runtime loading, interaction, accessibility, and reduced-motion behavior have been directly validated; declarations alone are insufficient.

## Evidence references

- `PHASE_1B_MOTION_DEEP_AUDIT.md` — per-template findings and evidence labels.
- `PHASE_1B_PERFORMANCE_BENCHMARK.md` — bounded runtime matrix and performance caveats.
- `phase1b-experiments/01-scroll-reveal.html`, `02-pointer-drag.html`, and `03-accessible-disclosure.html` — original standalone demonstrations.
- `PHASE_1A_PUBLIC_CORPUS_BASELINE.md` — source-level declarations and visual context.
