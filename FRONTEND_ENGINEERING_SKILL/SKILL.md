---
name: premium-frontend-engineering
description: Plan, design, implement, and review high-quality frontend experiences in existing repositories. Use for frontend pages, design systems, responsive UI, interaction design, motion, accessibility, performance, SEO, or visual refinement when the work must be production-conscious rather than generic.
---

# Premium Frontend Engineering

Use this skill to produce deliberate, accessible, responsive frontend work without forcing every project into the same visual style.

## When to activate

Activate before building or materially redesigning frontend pages, routes, components, design systems, interaction patterns, motion, or visual polish. Activate for reviews when the task asks whether a frontend is production-ready. Do not activate for backend-only work, copy-only edits, or a narrowly mechanical CSS fix unless the change affects the broader interface contract.

## Required workflow

### 1. Understand before building

- Inspect the repository before editing. Identify the framework, router, rendering model, styling approach, component conventions, data boundaries, tests, CI, and deployment path.
- Read the product brief, relevant route specs, existing design/audit reports, and nearby components.
- Identify target users, primary tasks, content states, device constraints, browser support, and non-negotiable boundaries.
- Separate verified facts, reasonable inferences, proposals, and unknowns. Do not invent routes, fields, APIs, libraries, or permissions.
- Search for existing components and tokens before creating new ones. Reuse only when the contract and visual role genuinely match.
- Define the change boundary. Preserve unrelated systems and stop to report a missing dependency rather than fabricating it.

### 2. Establish a visual direction

Before implementation, write a compact visual concept for the work:

- the user problem and the page’s compositional purpose;
- the visual hierarchy and what should be noticed first;
- typography roles and reading measures;
- surface, border, accent, and image treatment;
- layout rhythm, container widths, and responsive recomposition;
- what is intentionally omitted to avoid generic aesthetics.

Use references as inspiration for principles, not as source material to copy. Do not default to dashboard cards, purple gradients, neon, glassmorphism, gratuitous rounded rectangles, or decorative motion. Let the product’s existing identity and content determine the direction. Every page should have a distinct reason for its composition.

### 3. Define the design system

Create or extend semantic tokens for:

- surfaces and text contrast;
- borders, focus, and status accents;
- typography families, sizes, weights, line heights, and measure;
- spacing rhythm, containers, radii, shadows, and z-index layers;
- motion durations and easing.

Use existing tokens as the source of truth where available. Introduce aliases before introducing new raw values. Document the minimum token set needed for the change. Keep components composable and avoid a configurable mega-component when two focused components communicate intent better.

### 4. Design page and state architecture

For each route, specify:

- purpose and primary action;
- above-the-fold hierarchy;
- primary and secondary content;
- responsive composition;
- loading, empty, error, unavailable, and not-found states;
- data fields and source boundary;
- navigation and next-step links;
- accessibility semantics.

Make content, interaction state, and motion presentation separate concerns. Keep server-rendered content crawler-visible when SEO or first paint matters. Keep privileged data and write actions on the server. Do not create a UI for an unapproved backend contract.

### 5. Engineer interactions deliberately

For every meaningful interaction, document and implement:

- trigger;
- authoritative state;
- initial, active, and exit states;
- timing and easing;
- reduced-motion behavior;
- keyboard and touch paths;
- focus behavior and ARIA relationships;
- mobile behavior;
- performance cost and failure fallback.

Use the smallest mechanism that satisfies the effect:

- native controls plus CSS transitions for local state;
- CSS keyframes for restrained ambient loops;
- `IntersectionObserver` plus CSS for one-time reveals, with visible fallback;
- Pointer Events with capture and clamped bounds for direct manipulation;
- a small deterministic state machine for carousels;
- GSAP only when complex sequencing materially improves maintainability;
- canvas/WebGL only for a justified decorative visual with a tested fallback.

Update semantic state synchronously. Never infer ARIA state from an animation transform or wait for a transition to complete before making the control usable. Do not hijack scroll, block interaction during animation, or make hover essential.

### 6. Build responsive interfaces intentionally

Design mobile and desktop as related compositions, not a desktop layout scaled down.

- Test at 320, 360, 375, 390, 414, 430, 768, 1024, 1280, and 1440 px when relevant.
- Use fluid widths, `minmax(0, 1fr)`, `min-width: 0`, wrapping labels, bounded images, and local overflow regions.
- Keep controls at least 44 px where touch is expected.
- Stack or recompose navigation, metadata, sidebars, cards, and actions deliberately.
- Assert `scrollWidth <= viewport width` unless overflow is explicitly part of a labelled local control.
- Fix the wider child; never use root `overflow-x: hidden` to conceal overflow.
- Check focus order and tap targets after every breakpoint change.

### 7. Build accessibility and SEO into the structure

Use semantic HTML, one meaningful `h1`, logical headings, descriptive links, visible focus, native buttons, and stable IDs. Pair `aria-expanded` with `aria-controls`; use `inert` or an equivalent strategy for hidden interactive content. Handle Escape and focus return for modal navigation. Do not communicate essential meaning through color, hover, animation, icon, or canvas alone.

Provide meaningful alt text for informative images and empty alt for decorative images. Preserve keyboard operation and reduced-motion semantics. For searchable or filterable interfaces, define labels, feedback, no-results state, and URL/crawl behavior before implementation.

For public content, generate metadata from the same approved record as the page. Use canonical URLs, semantic headings, crawlable anchors, appropriate structured data, correct publication/modification dates, and stable image dimensions. Keep drafts and previews out of public metadata and sitemaps.

### 8. Optimise and measure

- Minimise JavaScript and dependencies.
- Keep critical content server-rendered where possible.
- Optimise responsive images and fonts.
- Reserve media geometry to prevent CLS.
- Lazy-load below-fold media without hiding content from assistive technology.
- Avoid layout animation and unnecessary continuous work.
- Pause loops when hidden; cap DPR for procedural visuals.
- Bound data queries and avoid N+1 reads.
- Treat Lighthouse as a diagnostic, not a universal benchmark.

Measure the question you actually need answered: source declarations, active animation, JavaScript work, browser presentation, transferred bytes, or user experience. Record browser, viewport, DPR, network/cache conditions, and sample count for repeatable checks.

### 9. Work safely in existing repositories

- Inspect before editing and confirm the target branch.
- Preserve the existing architecture unless a change is justified by a verified need.
- Make focused, reversible changes.
- Do not modify unrelated auth, data, security, deployment, or product systems.
- Do not add a dependency for an effect that CSS or existing primitives can provide.
- Do not bypass approved data projections or move secrets/privileged clients into browser code.
- Never create migration, permission, publication, payment, or external-action behavior from a visual request alone.
- Validate every important change and report exact modified files.
- Stop and report when a required contract, asset, permission, or environment is unavailable.

### 10. Review like a senior frontend engineer

Before declaring completion, inspect the result at route level and component level. Rendering without errors is not sufficient.

- **Visual quality:** hierarchy, composition, typography, spacing, image treatment, contrast, and consistency.
- **Layout:** required widths, intermediate widths, overflow, reserved media geometry, and safe-area behavior.
- **Interaction:** deterministic state, fresh-load first action, keyboard, touch, focus, Escape, outside close, settled geometry, and error paths.
- **Motion:** trigger, timing, reduced motion, hidden-tab behavior, no scroll hijack, no essential hover-only content.
- **Accessibility:** semantic structure, names, labels, focus visibility, ARIA relationships, target sizes, alt text, and contrast.
- **Performance:** JavaScript cost, image/font behavior, layout stability, long tasks, and representative Web Vitals.
- **SEO:** metadata, canonical, structured data, headings, internal links, sitemap/robots behavior, and no draft leakage.
- **Browser health:** console errors, hydration warnings, failed resources, and broken routes.
- **Regression safety:** typecheck, tests, build, and nearby product flows.

Explicitly prohibit declaring work complete solely because the page renders.

## Expected completion report

Report:

1. The design decisions and page/component scope.
2. Verified existing architecture and any proposed changes.
3. Exact modified files and any intentionally untouched systems.
4. Verification evidence, including commands, browsers, viewports, and sample conditions.
5. Accessibility, responsive, motion, performance, SEO, and regression results.
6. Remaining unknowns, waivers, or decisions requiring product/security input.
7. Any failure or limitation that prevents a claim of completion.

Keep the report factual. Distinguish measured results from acceptance targets and recommendations.
