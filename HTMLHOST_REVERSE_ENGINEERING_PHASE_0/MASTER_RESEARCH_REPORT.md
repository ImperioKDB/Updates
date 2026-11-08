# Master Research Report — Phase 1A

## Finding

Phase 1A establishes that HTMLhost’s platform frontend and its public template/preview frontends must be treated as separate systems. The platform shell is a Next.js/Vercel-signaled application surface. The templates render as heterogeneous inline sandboxed `srcdoc` documents with their own HTML/CSS/JavaScript, fonts, assets, and motion mechanisms. No customer-published generated site was verified, so the generated-site runtime remains UNKNOWN.

## Evidence basis

The homepage, editor, and five template pages were captured at 1440×900, 768×1024, and 390×844. All five public `Live preview` states opened without authentication. The capture produced 21 JSON records and 81 PNG screenshots. Each template preview exposed actual rendered content in iframe documents; examples included forms, images, canvas, responsive CSS, keyframes, libraries, and interactive source handlers.

The detailed comparative record is in `PHASE_1A_PUBLIC_CORPUS_BASELINE.md`. The raw capture index is `/home/ubuntu/rea-phase1a/capture-index.json`, with screenshots under `/home/ubuntu/rea-phase1a/screenshots/`.

## Architecture matrix conclusion

The platform shell owns public navigation, template detail pages, preview controls, device presentation frames, host-level typography, host assets, and likely editor/preview orchestration. The preview document owns template-specific page markup, design tokens, fonts, imagery or procedural visuals, forms, animation code, responsive breakpoints, and optional libraries. The published generated website layer is not observable from the selected public corpus.

A host Next.js chunk must not be used as proof that a template or generated site is Next.js. A template library declaration must not be used as proof that the HTMLhost shell uses that library. A public preview must not be used as proof of a published customer site.

## Cross-template findings

Creative Playground verifies a GSAP/Swiper/Lucide/validation-driven interactive landing with SVG/CSS artwork, draggable shapes, scroll reveals, and responsive slides. Kinetica verifies a type-led motion landing with multiple keyframes, external fonts/photos, GSAP/Swiper/Howler declarations, and many responsive breakpoints. Futuristic Dark verifies a custom WebGL/requestAnimationFrame visual field with pointer/touch input, visibility pause, DPR cap, and reduced-motion fallback. Full-Stack Portfolio verifies a multi-page image-heavy inline preview with extensive CSS motion; active Three.js is not proven. Business Web Studio verifies a semantic agency site with three fonts, Lucide, mobile menu, FAQ, counters, theme state, lazy images, and responsive overlay behavior.

These differences are evidence against assuming one template runtime stack.

## Performance conclusion

Only partial source-level and capture-level performance evidence exists. The public shell and preview pages rendered in the bounded capture, but the homepage reached a network-idle timeout and recorded two 401 resource errors. Template source shows useful accommodations—lazy images, explicit dimensions, reduced-motion handling, visibility pause, and DPR caps—but no quantitative quality conclusion is justified. Web Vitals, FPS, byte totals, and published-site behavior remain UNKNOWN.

## Review gate

Phase 1A is complete and should stop here for review. The next phase should only proceed after deciding whether to search for genuinely public HTMLhost subdomain sites. If no verified public generated sites can be found, the generated-site matrix column should remain UNKNOWN rather than being inferred from previews.


## Phase 1B — Runtime motion and controlled performance observations

Phase 1B expanded the evidence from Phase 1A source inspection to bounded runtime and reversible-interaction captures on five public, sandboxed `srcdoc` template previews. It did **not** access a published customer-generated site. The matrix contains 13 headless Chromium captures: five previews at desktop under both motion preferences, plus three phone-size captures. REA 6.8.0 performed one bounded observation-only capture of Creative Playground; Playwright supplied the cross-template runtime and interaction records.

### Cross-template conclusion

The five previews use heterogeneous motion patterns. Creative Playground sampled two continuous loops and one draggable-shape action; Kinetica exposed 21 desktop animation objects and a directly tested accessible pause/resume control; Futuristic Dark presented a full-frame canvas but its WebGL/fallback and canvas-pointer paths remain unknown; Portfolio sampled a running preloader and brief testimonial transition but the Next-slide captures disagree; Business Web Studio sampled a long linear services track and a semantic FAQ disclosure.

Reduced-motion behavior differed in the captured desktop states: Creative Playground sampled zero animation objects; Kinetica's 21 objects were paused; Futuristic Dark's reduced-motion images were byte-identical but the canvas pathway is unresolved; Portfolio still sampled two running preloader animations; Business Web Studio sampled zero baseline animations. These are local observations, not universal compliance conclusions.

### Performance and responsive caveats

The 13 runs are diagnostic captures, not a performance ranking. Body-visible elapsed times include host stabilization waits; Resource Timing may omit cross-origin/TAO-restricted bytes; image counters were sampled shortly after iframe visibility; LCP/CLS entries are single-run observations with observer caveats; and RAF callback cadence is not display FPS. No Lighthouse, field Web Vitals, repeated-run statistical test, real-device trace, or CPU/GPU profile was performed. Lighthouse was not installed in the environment.

One responsive issue is directly recorded: Creative Playground at a 390 px viewport reported 1041 px iframe document `scrollWidth`. Treat this as overflow to investigate, not a design pattern to recreate. Published generated-site performance and responsive behavior remain UNKNOWN.

### Phase 1B documents and evidence

- `PHASE_1B_MOTION_DEEP_AUDIT.md` — detailed per-template motion evidence, interaction outcomes, conflicts, and unknowns.
- `PHASE_1B_PERFORMANCE_BENCHMARK.md` — all 13 diagnostic records and measurement limits.
- `ANIMATION_TECHNIQUE_COMPARISON.md` and `FRONTEND_MOTION_ENGINEERING_GUIDE.md` — implementation-neutral synthesis.
- `INTERACTION_EXPERIMENTS.md` — three original standalone technique demos and smoke-test results.
- `phase1b-experiments/` — scroll reveal, bounded pointer drag, and accessible disclosure examples.
- `phase1b-evidence/` — runtime/interaction records, bounded REA output, and retained screenshot/hash manifest.

The Phase 1A architecture boundary remains intact: host shell, public preview document, and published generated website are separate evidence layers. Continue to leave the generated-site layer UNKNOWN unless a specific public published site is verified.
