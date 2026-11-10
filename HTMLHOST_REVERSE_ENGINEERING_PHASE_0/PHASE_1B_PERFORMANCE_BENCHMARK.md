# Phase 1B Performance Benchmark

**Classification:** Controlled diagnostic capture matrix; **not** a comparative performance benchmark. **Capture date:** 2026-11-08. **Target:** Five public sandboxed template previews, not published generated sites.

## Executive conclusion

The 13 captures verify that the selected public previews reached a visible iframe body in this headless Chromium environment, but they do not support a performance ranking. All measured timings include the HTMLhost host page and explicit stabilization waits. Resource Timing can omit cross-origin bytes; the image counters were sampled shortly after iframe visibility and do not prove eventual load failure; the LCP/CLS observers are single-run observations with instrumentation caveats; and requestAnimationFrame cadence is not compositor FPS. Lighthouse was not installed (`lighthouse` executable unavailable), and no field data, real-device trace, CPU/GPU profile, or repeated-run statistical sample was collected.

## Method

- **Browser:** system Chromium at `/usr/bin/chromium`, controlled with Playwright Python in headless mode.
- **Context:** English locale, device scale factor 1, fresh browser context per capture; browser cache could persist only within that run's context.
- **Matrix:** five template previews at 1440×900 under both `no-preference` and `reduce` (10 records), plus Creative Playground, Kinetica, and Futuristic Dark at 390×844 under `no-preference` (three records), for 13 total.
- **Readiness rule:** `DOMContentLoaded`, a 1.0-second host-preview stabilization wait, then a 0.7-second wait after the primary iframe body became visible. The recorded “body-visible elapsed” includes navigation and those waits; it is **not** an isolated template load time.
- **Measurements:** iframe document size, `document.getAnimations()` inventory, sampled LCP/CLS entries, long-task entries, Resource Timing count/known bytes, image counters, font status, RAF callback samples, browser errors, and selected DOM controls.
- **Repeatability:** the saved harness can reproduce the method, but this report contains one observation per matrix cell, not repeated trials or statistics.

The full record is `phase1b-evidence/runtime-capture-2026-11-08.json`; the reproducible harness is `PHASE_1B_RUNTIME_CAPTURE.py`.

## Capture matrix

`CLS*` and `LCP*` are instrumented single-run entries, not formal field Core Web Vitals. “LCP candidate” shows the last recorded entry's time and element tag. “Known bytes” are Resource Timing values, potentially incomplete. Image counts are `loaded / elements counted` at the snapshot.

| Preview | Viewport / motion | Body-visible elapsed (s) | iframe scroll size (px) | Anim. objects | CLS* | Last LCP candidate* | Resource entries / sized; known transfer bytes | Images loaded / counted | Long tasks |
|---|---|---:|---:|---:|---:|---|---|---:|---:|
| Creative Playground | 1440×900 / no-preference | 6.787 | 1440×3160 | 2 | 0.01 | 192 ms / SPAN | 8 / 7; 174,333 B | 0 / 0 | 0 |
| Creative Playground | 1440×900 / reduce | 6.812 | 1440×3160 | 0 | 0.01 | 160 ms / SPAN | 8 / 7; 174,333 B | 0 / 0 | 0 |
| Kinetica | 1440×900 / no-preference | 7.550 | 1440×9249 | 21 | 0.01 | 240 ms / SPAN | 2 / 2; 6,315 B | 0 / 12 | 0 |
| Kinetica | 1440×900 / reduce | 5.635 | 1440×9247 | 21 | 0.09 | 156 ms / SPAN | 7 / 7; 237,607 B | 0 / 12 | 1 |
| Futuristic Dark | 1440×900 / no-preference | 9.520 | 1440×841 | 0 | 0 | 400 ms / H1 | 1 / 1; 1,027 B | 0 / 0 | 27 |
| Futuristic Dark | 1440×900 / reduce | 6.525 | 1440×841 | 0 | 0 | 272 ms / H1 | 1 / 1; 1,027 B | 0 / 0 | 0 |
| Full-Stack Portfolio | 1440×900 / no-preference | 8.331 | 1440×4618 | 3 | 0 | 1120 ms / H1 | 0 / 0; 0 B | 0 / 56 | 0 |
| Full-Stack Portfolio | 1440×900 / reduce | 7.535 | 1440×4618 | 3 | 0 | 1060 ms / H1 | 1 / 0; 0 B | 1 / 56 | 0 |
| Business Web Studio | 1440×900 / no-preference | 7.483 | 1440×9531 | 1 | 0.18 | 408 ms / H1 | 2 / 2; 84,823 B | 0 / 9 | 0 |
| Business Web Studio | 1440×900 / reduce | 6.397 | 1440×9531 | 0 | 0.18 | 220 ms / H1 | 2 / 2; 84,823 B | 0 / 9 | 0 |
| Creative Playground | 390×844 / no-preference | 7.854 | 1041×3041 | 2 | 0.02 | 168 ms / P | 8 / 7; 174,333 B | 0 / 0 | 0 |
| Kinetica | 390×844 / no-preference | 7.425 | 390×9642 | 23 | 0.04 | 180 ms / P | 9 / 9; 222,340 B | 0 / 12 | 1 |
| Futuristic Dark | 390×844 / no-preference | 9.826 | 390×744 | 0 | 0.12 | 192 ms / H1 | 1 / 1; 1,027 B | 0 / 0 | 7 |

### Interpretation constraints

1. **Body-visible elapsed is not page load speed.** It includes the host shell, preview setup, explicit waits, and iframe readiness. It must not be presented as template-only load latency.
2. **Resource Timing values are lower bounds/known bytes only.** Cross-origin resources without sufficient Timing-Allow-Origin exposure may contribute zero or opaque transfer values. A zero-byte record is not proof of zero network traffic.
3. **Image counters are snapshots, not download verdicts.** Several previews reported image elements with zero loaded and zero failed at the 0.7-second post-visibility sample. That does not prove the images never load, were not lazy, or were missing visually. Portfolio had one failed counter in each desktop setting and its reduce capture also recorded one `/auth` request aborted (`net::ERR_ABORTED`) without a page error or HTTP error; the cause is UNKNOWN.
4. **CLS/LCP are provisional.** They are single-run entries; the capture harness warns that the iframe observer may be late. Do not treat them as validated lab scores or field Web Vitals.
5. **Long-task entries are sparse run observations.** Futuristic Dark's 27 desktop no-preference entries and seven mobile entries warrant a better trace, but the record alone cannot establish the originating work or user impact.
6. **Creative Playground has a responsive issue.** At a 390 px viewport its iframe document reported 1041 px scroll width. This is horizontal overflow, not a positive performance result or a behavior to recreate.

## RAF callback sample — not FPS

| Preview / setting | Sample | Callback count | Interval observations |
|---|---|---:|---|
| Creative Playground, desktop & mobile, no-preference | Approximately 1 s each | 63 each | Median/p95 about 16.7 ms; maximum about 16.8 ms. |
| Kinetica, desktop, no-preference | Approximately 1.012 s | 62 | Median/p95 about 16.7 ms. |
| Kinetica, mobile, no-preference | Approximately 1.009 s | 121 | Median 0 ms; p95 about 16.7 ms; multiple callbacks/measurement artifacts are possible. |
| Futuristic Dark, desktop, no-preference | 1.143 s | 13 | Median 50 ms; p95 216.7 ms; max 250 ms. |
| Futuristic Dark, mobile, no-preference | 1.506 s | 20 | Median 16.7 ms; p95 316.7 ms; max 566.7 ms. |
| Full-Stack Portfolio, desktop, no-preference | 1.016 s | 183 | Reported p95 about 16.7 ms; zero-median samples indicate this is not a clean presentation cadence. |
| Business Web Studio, desktop, no-preference | Approximately 1.010 s | 62 | Median/p95 about 16.7 ms. |

These values are JavaScript callback samples. They do **not** measure compositor presents, GPU frame delivery, visual smoothness, or perceived responsiveness. In particular, an API inventory with zero entries does not disprove a JavaScript RAF animation loop.

## What is actually supported

- **VERIFIED:** The primary iframe body became visible in each of the 13 recorded captures; all preview responses in the matrix were HTTP 200. No page errors were reported. A single `/auth` request abort occurred in the Full-Stack Portfolio reduce capture as noted above.
- **VERIFIED:** Resource, image, font, animation, long-task, and timing values in the table are the measurements recorded at the stated capture point.
- **UNKNOWN:** Complete payload weight, cache-hit behavior across production traffic, eventual image/font readiness, repeat-run variation, user-perceived performance, field Web Vitals, mobile CPU/GPU cost, real-device frame pacing, and any published generated-site performance.
- **UNKNOWN:** Whether the sampled metrics are representative of a normal user session. No network throttling, device emulation profile beyond viewport/DPR, or authenticated/editor workflow was used.

## Tool limitation and recommended next measurement

No `lighthouse` executable was available in the environment, so Lighthouse was not run. A suitable next step is a separately scoped Chrome DevTools Lighthouse or installed Lighthouse CLI run over several clean/repeat loads, with the shell and iframe resources reported separately. For motion performance, use a browser performance trace and real-device/touch testing; do not substitute RAF callback count for frame metrics. Those extensions were not performed in this Phase 1B pass.

## Evidence

- Runtime capture: `phase1b-evidence/runtime-capture-2026-11-08.json`.
- Capture harness: `PHASE_1B_RUNTIME_CAPTURE.py`.
- Interaction captures and focused follow-ups: `phase1b-evidence/interaction-capture-2026-11-08.json` and `phase1b-evidence/follow-up-validation-2026-11-08.json`.
- Source-level baseline: `PHASE_1A_PUBLIC_CORPUS_BASELINE.md`.
- Screenshot/hash manifest: `phase1b-evidence/screenshot-manifest.json`.
