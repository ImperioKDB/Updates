# Performance Audit — Phase 1A

## Measurement boundary

The Phase 1A capture recorded navigation duration, public resource timing entries, document dimensions, console/page errors, iframe source size, and asset counts. It did not run Lighthouse or claim Core Web Vitals, FPS, CPU/GPU, memory, or real-device performance.

## Platform frontend — VERIFIED

At the captured desktop viewport, the homepage recorded 219 public resource entries and a 60-second network-idle timeout; it still rendered and recorded two 401 resource errors. The editor mobile capture recorded 50 resource entries and no captured console/page errors. These are test-run observations, not generalized platform benchmarks.

The public shell uses static CSS/JavaScript chunks and font resources. Public response headers previously showed Vercel/Next.js prerender/cache signals. Exact transfer totals and cache-hit ratios were not measured by this pass.

## Template/preview frontend — VERIFIED source-level accommodations

- Creative Playground uses SVG/CSS artwork rather than observed raster image assets, reduced-motion handling, IntersectionObserver reveals, and Swiper overflow behavior. It also declares five CDN JavaScript dependencies.
- Kinetica declares Google Fonts, four photo assets, multiple CDN libraries, responsive CSS, and reduced-motion CSS.
- Futuristic Dark uses a fixed 256×256 noise texture, canvas DPR cap of 1.75, requestAnimationFrame, visibility pause, and reduced-motion still render. It has no template image elements in the inspected preview.
- Full-Stack Portfolio references many images and Atyp fonts and showed an initial loading spinner before phone content rendered. Active Three.js execution is UNKNOWN.
- Business Web Studio preconnects to Google Fonts, uses explicit image dimensions, marks later photos `loading="lazy"`, and disables animation/marquee under reduced motion.

## UNKNOWN

No reliable quantitative performance conclusion can be drawn for any template. Missing measurements include total bytes, resource waterfall, cache behavior, font-display/fallback, LCP, CLS, INP, long tasks, FPS, GPU/CPU cost, memory, and network variance. Published generated sites were not accessed, so their performance remains UNKNOWN.

## Next safe performance investigation

After review, run a bounded repeated-load test against the public preview pages with resource timing export and optional Lighthouse in a clean profile. Report conditions, repetitions, and uncertainty; keep host shell and iframe resources separate.
