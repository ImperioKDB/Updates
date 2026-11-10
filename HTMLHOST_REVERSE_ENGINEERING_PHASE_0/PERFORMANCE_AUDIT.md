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


## Phase 1B controlled diagnostic addendum — 2026-11-08

A saved Playwright harness produced 13 headless Chromium records: five public sandboxed template previews at 1440×900 under both `no-preference` and `reduce`, plus three 390×844 no-preference captures. All primary iframe bodies became visible; the values remain single-run diagnostics, not a performance ranking. The complete matrix, run conditions, and limitations are in `PHASE_1B_PERFORMANCE_BENCHMARK.md`.

### Direct observations

- Recorded elapsed time to iframe body visibility ranged from 5.635 to 9.826 seconds; this includes host navigation, explicit stabilization waits, and iframe readiness, so it is not template-only load time.
- Captured iframe CLS entries ranged from 0 to 0.18 and LCP candidates from 156 to 1120 ms. The harness warns about observer timing; these are not field or validated Core Web Vitals.
- Resource Timing known transfer bytes ranged from zero/opaque records to 237,607 bytes. Cross-origin/TAO-restricted resources may be omitted; zero known bytes do not mean zero traffic.
- Image counters were snapshots shortly after body visibility and frequently reported zero loaded elements despite source/DOM images; they do not establish eventual load failure. Portfolio's reduced-motion run included one `/auth` request aborted (`net::ERR_ABORTED`) with no page error or HTTP error; its cause is UNKNOWN.
- RAF callback samples varied significantly, especially the Futuristic Dark canvas samples. These are callback cadence observations, not compositor/GPU frame rates or perceived smoothness.
- Creative Playground's 390 px iframe reported 1041 px scroll width, indicating overflow that warrants follow-up.

### Tool and benchmark limits

Lighthouse was not installed in the environment and no Lighthouse lab run, repeated-run statistics, field vitals, real-device test, browser performance trace, or CPU/GPU profile was collected. Published generated-site behavior remains UNKNOWN. The Phase 1A next safe investigation—bounded public preview performance measurement—was partially performed, but requires repeated loads and a trace/Lighthouse follow-up before any quality conclusion.
