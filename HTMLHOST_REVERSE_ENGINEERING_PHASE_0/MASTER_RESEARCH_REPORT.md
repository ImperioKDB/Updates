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
