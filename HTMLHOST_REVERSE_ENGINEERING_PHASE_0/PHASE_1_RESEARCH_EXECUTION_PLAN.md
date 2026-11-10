# Phase 1 Research Execution Plan

**Project:** HTMLhost Reverse Engineering Lab
**Phase:** 1 — Comparative public inspection and evidence capture
**Date:** 2026-11-08
**Status:** Proposed; wait for review before execution

## Phase 1 objective

Build the first comparative evidence set for HTMLhost’s public application and official template/preview surfaces. Phase 1 must explain observable design and engineering behavior without copying HTMLhost branding or claiming access to private implementation details.

The phase should answer:

- Which visual rules recur across official pages and templates?
- Which motion behaviors are observable, and what implementation techniques are supported by evidence?
- Which architecture signals belong to the public platform shell versus generated/template pages?
- How do layout, typography, interaction, and navigation transform across viewport sizes?
- Which loading, caching, and rendering signals are measurable without authenticated access?
- Which patterns look reusable as design-system primitives, and which are template-specific?

## Evidence protocol

Every significant claim will carry one of three labels:

- **VERIFIED:** directly observed in the DOM, computed style, browser behavior, network/resource record, public documentation, or a reproducible command result;
- **INFERRED:** strongly supported by multiple observations but not directly proven as internal implementation; or
- **UNKNOWN:** insufficient public evidence.

Each observation should record:

1. target URL and page type;
2. timestamp and viewport dimensions;
3. method used, such as browser DOM inspection, screenshot, console script, header request, or bounded interaction;
4. exact observation or measurement;
5. technical explanation separated from the observation;
6. confidence and evidence label; and
7. follow-up question or limitation.

Do not infer a framework or animation library from naming alone. A library claim requires a public script/resource, source map, documented template metadata, or behavior that is unusually specific and corroborated.

## Target corpus

Start with a small, diverse public corpus rather than assuming all HTMLhost pages share one design:

1. the official homepage;
2. the AI Editor page;
3. the Creative Playground Landing template;
4. the Kinetica Motion Typography template;
5. the Futuristic Dark Landing template;
6. one light business or portfolio template; and
7. one template with a dashboard or data-heavy layout, if publicly available.

For each target, record whether the page is platform marketing content, template metadata, a live preview, or a published user site. Do not combine these categories in one conclusion.

## Workstream A — visual design

### Questions

- What color roles recur: page background, elevated panel, border, muted text, primary text, accent, focus, success, warning?
- What font families and weights are loaded, and which roles do they serve?
- Are heading sizes fixed, fluid, or breakpoint-specific?
- What spacing rhythm, container widths, card radii, border weights, and shadow treatments recur?
- How are images cropped, masked, framed, or lazy-loaded?
- Which pages use editorial whitespace and which use dense functional layouts?
- Which patterns belong to HTMLhost’s shell and which belong to individual templates?

### Evidence collection

Use screenshots at 1440×900, 1024×768, 768×1024, and 390×844 where supported. Capture computed styles for representative headings, body text, buttons, cards, navigation, and form controls. Extract loaded font resources and publicly visible CSS custom properties. Record measured values with viewport context rather than describing them from memory.

### Deliverable linkage

Findings feed `VISUAL_DESIGN_AUDIT.md` and the cross-page sections of `REUSABLE_DESIGN_SYSTEM.md`.

## Workstream B — motion engineering

### Questions

- Does the public shell use scroll reveal, opacity/transform entrance, sticky transitions, or only static layout?
- How does the mobile navigation open and close? What duration, easing, height, opacity, and pointer-event states are observable?
- What happens on hover for template previews, cards, buttons, carousels, and pointer-following effects?
- Are interactions CSS transitions, Web Animations, requestAnimationFrame loops, GSAP/Swiper behavior, or unknown?
- Are animations disabled or changed under `prefers-reduced-motion`?
- Are loading states skeletons, spinners, blurred previews, progressive media, or route-level transitions?

### Evidence collection

Use short, reversible interactions only: open/close public accordions, switch public tabs, hover preview cards, open mobile navigation, and move over public preview controls. Capture before/after screenshots, DOM class/attribute changes, computed transition/animation styles, and console/network evidence. For any claim about a named library, identify a public script or template documentation line. The Kinetica page documents Swiper; the Creative Playground page documents GSAP, Swiper, and Lucide. Treat those as template metadata until the public preview bundle corroborates them.

### Deliverable linkage

Findings feed `MOTION_ENGINEERING_AUDIT.md` and the motion portions of `REUSABLE_DESIGN_SYSTEM.md`.

## Workstream C — frontend architecture

### Questions

- Which public pages are server-rendered or prerendered, and what headers support that claim?
- What framework and build signals are visible in public HTML, script paths, and response headers?
- How are fonts, CSS chunks, images, and scripts loaded?
- Are public templates plain HTML/CSS/JavaScript as documented, and does that differ from the HTMLhost app shell?
- Are forms, previews, and public page transitions client-side or server-driven?
- What accessibility landmarks, labels, focus states, reduced-motion hooks, and semantic controls are present?

### Evidence collection

Use raw HTML saved by the browser tool, `curl -I`, DOM inspection, resource timing, script/style URL inventories, public `robots.txt` and sitemap files, and safe inspection of public preview links. Do not download or decompile proprietary application code beyond what is publicly delivered to the browser and necessary for the research question. Do not access account-scoped endpoints.

### Deliverable linkage

Findings feed `FRONTEND_ARCHITECTURE.md` and `PLATFORM_OVERVIEW.md`.

## Workstream D — responsive engineering

### Questions

- Where do navigation, grid, typography, and control layouts transform?
- Is the mobile menu a separate DOM region, a CSS state, or a route/page change?
- How do sections stack, reorder, resize, or change alignment?
- Are typography values fluid through `clamp()` or discrete breakpoints?
- How do carousels, forms, media, and preview frames behave at phone and tablet widths?
- Are touch interactions supported, and what evidence shows this?

### Evidence collection

Use controlled screenshots and DOM/computed-style snapshots at desktop, tablet, and phone sizes. Record actual breakpoint-dependent class changes where visible. Test horizontal overflow, tap target sizes, focus visibility, content clipping, and readable line lengths. Avoid declaring a breakpoint from one class name alone; corroborate with layout change.

### Deliverable linkage

Findings feed `RESPONSIVE_ENGINEERING.md` and the responsive section of `REUSABLE_DESIGN_SYSTEM.md`.

## Workstream E — performance

### Questions

- Which resources dominate transfer size and timing?
- Which resources are cached, prerendered, deferred, lazy-loaded, or loaded only after interaction?
- Is layout stable during font/image load?
- Are there observable long tasks, console errors, failed resources, or layout shifts?
- How does the public shell behave on a cold load versus a repeated load?
- Which performance observations differ between the platform shell and template preview?

### Evidence collection

Record response headers, resource timing entries, navigation timing, paint timing where available, image loading attributes, font loading state, and console errors. Measure only within the browser session and public URLs. Do not claim Core Web Vitals from a single synthetic run; collect repeated measurements and state the test conditions. If browser tooling cannot expose a metric, label it UNKNOWN and identify an alternative such as Lighthouse in an isolated public-page run.

### Deliverable linkage

Findings feed `PERFORMANCE_AUDIT.md` and the performance section of `MASTER_RESEARCH_REPORT.md`.

## Workstream F — reusable design system

### Questions

- Which components recur across platform pages and templates?
- Are there shared patterns for navigation, tabs, cards, badges, forms, accordions, carousels, browser-frame previews, buttons, and responsive containers?
- Which tokens recur in color, spacing, typography, radius, border, and motion?
- Which patterns can be described abstractly without reproducing HTMLhost’s branding or proprietary code?

### Evidence collection

Create a cross-page matrix only after individual evidence records exist. Separate directly repeated values from conceptual similarity. Use role-based names such as `surface-elevated`, `text-muted`, or `accent-primary`, not HTMLhost-specific class names. Record variants and exceptions rather than flattening all templates into one system.

### Deliverable linkage

Findings feed `REUSABLE_DESIGN_SYSTEM.md` and `RECONSTRUCTION_KNOWLEDGE_BASE.md`.

## Tooling plan

The current sandbox can use:

- Manus browser navigation, page view, DOM/runtime console inspection, click/input where safe, screenshots, and public page HTML capture;
- Chromium and Playwright for controlled public-page checks;
- REA CLI 6.8.0 for bounded static JavaScript analysis, browser-capture experiments with a known input contract, web-page inspection, screenshots, and evidence comparison;
- `curl` for public response headers, robots policy, sitemap, and cache checks; and
- Python for deterministic parsing of saved HTML, JSON, and evidence artifacts.

Use the Manus browser first for stateful pages and screenshots. Use REA when its contract gives a bounded, reproducible operation. Do not install native reverse-engineering engines unless a later question actually requires them.

## Safety and access boundaries

Phase 1 may inspect public HTML, CSS, JavaScript, images, fonts, response headers, public template previews, and safe public interactions. It may not attempt to bypass authentication, enumerate private projects, guess unpublished site URLs at scale, extract bearer tokens, submit forms, publish sites, upload files, or use undocumented private APIs. Any authenticated or publication-based experiment requires a separate user decision and explicit scope.

## Phase 1 stopping criteria

Stop and report before moving to Phase 2 when:

- the selected public corpus has been inspected at all planned baseline viewports;
- each workstream has an evidence-backed initial set of findings and an explicit UNKNOWN list;
- platform-shell observations are separated from template/generated-site observations;
- no material claim depends solely on a search snippet or marketing statement;
- evidence files and screenshots have stable paths; and
- the review documents are ready to update without implementing a clone.

## Recommended exact next phase

After review approval, execute **Phase 1A: Public corpus baseline**. Inspect the homepage, editor page, and four diverse templates at desktop/tablet/phone sizes. Capture screenshots, DOM/computed-style snapshots, public asset inventories, header/resource timing data, and a small set of safe interactions. Update the six relevant research documents incrementally, then pause for a second review before any authenticated editor or generated-site investigation.

## References

[1]: https://github.com/morluto/rea "Official Reverse Engineer Anything repository"
[2]: https://rea.tools/guides/browser/ "REA browser observation guide"
[3]: https://htmlhost.co/ "HTMLhost official homepage"
[4]: https://htmlhost.co/editor "HTMLhost AI HTML Editor"
[5]: https://htmlhost.co/templates/kinetica-motion-typography "Kinetica Motion Typography template"
[6]: https://htmlhost.co/templates/creative-playground-landing "Creative Playground Landing template"


## Phase 1A completion record

Phase 1A was approved and executed with an explicit platform/template/generated-site boundary. The public corpus included the homepage, editor, Creative Playground Landing, Kinetica Motion Typography, Futuristic Dark Landing, Full-Stack Designer Portfolio, and Business Web Studio.

All seven targets were captured at 1440×900, 768×1024, and 390×844 with Chromium/Playwright. Five template `Live preview` states were opened. The run produced 21 JSON records and 81 PNG screenshots. The capture script, index, and screenshot directory are retained outside this report.

The strongest result is architectural separation: the HTMLhost platform shell exposes Next.js/Vercel delivery signals and host UI, while public template previews render as heterogeneous inline sandboxed `srcdoc` documents with template-specific HTML/CSS/JavaScript. No published customer-generated website was verified. Phase 1A is complete and paused for review as required.

See `PHASE_1A_PUBLIC_CORPUS_BASELINE.md` for the comparative matrix and evidence classification.


## Phase 1B completion record — 2026-11-08

**Status:** Phase 1B complete; stop for review before initiating another research phase. The approved scope covered bounded runtime motion, reversible interactions, and a single-run diagnostic performance matrix across five public template previews. It did not include authenticated editor actions, site publication, private endpoints, or published customer-site claims.

The work produced 13 headless Chromium records, one bounded REA observation-only capture of Creative Playground, five independent template evidence reviews with cross-template synthesis, and three original standalone motion demonstrations. The specific evidence boundary and limitations are recorded in `PHASE_1B_MOTION_DEEP_AUDIT.md`, `PHASE_1B_PERFORMANCE_BENCHMARK.md`, `ANIMATION_TECHNIQUE_COMPARISON.md`, `FRONTEND_MOTION_ENGINEERING_GUIDE.md`, and `INTERACTION_EXPERIMENTS.md`. Runtime and interaction scripts and raw evidence remain under this phase directory.

The phase leaves several targeted unknowns: Portfolio's inconsistent testimonial Next result, Futuristic Dark's canvas-specific pointer/render path, Business Web Studio's FAQ close measurement, incomplete resource totals, and a lack of repeated/real-device performance evidence. No published generated site was verified. A later phase should be separately scoped and should not infer customer-site behavior from these public preview results.
