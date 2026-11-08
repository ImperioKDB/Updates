# Phase 1C Performance Trace Report

**Capture date:** 2026-11-08  
**Classification:** Bounded diagnostic evidence, not a production benchmark or ranking.

## Scope

Phase 1C attempted a proportionate performance extension without repeating the 13-record Phase 1B matrix. Lighthouse 13.6.0 was invoked through `npx` against two public routes using system Chromium at `/usr/bin/chromium`:

1. HTMLhost platform homepage: `https://htmlhost.co/`
2. Futuristic Dark template route: `https://htmlhost.co/templates/futuristic-dark-landing#preview`

The second route contains the HTMLhost platform shell and a public sandboxed preview iframe. Lighthouse therefore measures the route as a whole; it does not isolate the iframe from the shell. Neither route is a published customer-generated website.

## Results

| Route | Lighthouse performance score | FCP | LCP | TBT | CLS |
|---|---:|---:|---:|---:|---:|
| Platform homepage | 0.80 | 2.1 s | 2.1 s | 410 ms | 0.001 |
| Futuristic template route | 0.79 | 2.1 s | 2.1 s | 430 ms | 0.007 |

**VERIFIED:** These are the values reported by the saved Lighthouse JSON files under `phase1c-evidence/lighthouse/`.  
**UNKNOWN:** Whether they represent a typical user session, whether the preview iframe is responsible for any portion of the route-level work, and how the values would change on real devices, repeated runs, different network conditions, or published sites.

## Futuristic Dark runtime diagnostic

The targeted browser validation added a separate runtime observation:

- `webgl` context creation returned true; `webgl2` and `2d` returned false in the tested Chromium environment.
- The canvas was 1440×841 CSS pixels and visible.
- A roughly one-second RAF callback sample recorded 9 callbacks under `no-preference` and 62 under `reduce`.
- These counts are **not FPS** and do not measure compositor presentation, GPU work, or visual smoothness. The difference is retained as raw evidence only.
- Under reduced motion, before/after pointer screenshots were byte-identical. Under normal motion, the screenshots differed after the timed wait, but the change cannot be attributed to pointer input.

The evidence suggests that a rendering path is active in this browser, but it does not establish production frame quality or a shared implementation approach.

## What this report does not claim

This report does not provide a performance ranking between HTMLhost templates. It does not establish field Core Web Vitals, real-device FPS, touch latency, CPU/GPU cost, complete transfer size, or published-site behavior. The route-level Lighthouse run combines host shell and preview work, while Resource Timing in the Phase 1B matrix could omit cross-origin or TAO-restricted bytes. Single-run values should not be used as acceptance thresholds.

The earlier Phase 1B warnings remain in force: `body-visible` elapsed time included host stabilization waits; image counters were early snapshots; LCP/CLS observations were instrumented single-run values; and RAF cadence was not FPS.

## Engineering use

Use Lighthouse here as a regression baseline for the public route shape only, not as evidence of HTMLhost's generated-site quality. For an independent frontend, a meaningful performance study should use repeated clean-context runs, explicit network/device conditions, an actual browser performance trace, separate shell and embedded-document accounting where possible, and target-device testing. Continuous canvas work should be paused or simplified when hidden and should have a verified reduced-motion branch.

## Evidence files

- `phase1c-evidence/lighthouse/platform-homepage.json`
- `phase1c-evidence/lighthouse/futuristic-template-route.json`
- `phase1c-evidence/targeted-validation-2026-11-08.json`
- `PHASE_1B_PERFORMANCE_BENCHMARK.md`
- `phase1b-evidence/runtime-capture-2026-11-08.json`
