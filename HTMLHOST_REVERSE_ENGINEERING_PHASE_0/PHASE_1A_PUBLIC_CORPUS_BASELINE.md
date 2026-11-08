# Phase 1A Public Corpus Baseline

**Project:** HTMLhost Reverse Engineering Lab
**Phase:** 1A — Public Corpus Baseline
**Date:** 2026-11-08
**Status:** Complete; submitted for review

## Scope and method

Phase 1A inspected the HTMLhost homepage, editor page, and five public template pages at controlled desktop, tablet, and mobile viewport sizes. The five templates were Creative Playground Landing, Kinetica Motion Typography, Futuristic Dark Landing, Full-Stack Designer Portfolio, and Business Web Studio.

A reproducible Playwright capture used Chromium at `/usr/bin/chromium` with viewport sizes:

- desktop: 1440×900;
- tablet: 768×1024; and
- mobile: 390×844.

For each target, the capture recorded the page screenshot, DOM headings, computed body style, document dimensions, public resource timing entries, console/page errors, and page timing. For templates, it opened the public `Live preview` state and recorded the preview wrapper plus each iframe’s bounding box, text/HTML size, image/form/button counts, canvas presence, and iframe screenshot.

The capture produced **21 JSON capture records and 81 PNG screenshots**. The capture index is `/home/ubuntu/rea-phase1a/capture-index.json`; the screenshots are under `/home/ubuntu/rea-phase1a/screenshots/`; and the reproducible script is `/home/ubuntu/rea-phase1a-capture.py`.

No sign-in, upload, publication, form submission, private-site enumeration, token extraction, undocumented authenticated endpoint, or editor mutation was performed.

## Evidence labels

- **VERIFIED:** directly supported by captured DOM, computed style, public source, iframe structure, rendered behavior, resource record, or public documentation.
- **INFERRED:** strongly supported by multiple observations but not directly proven as internal implementation.
- **UNKNOWN:** insufficient public evidence.

## Executive findings

### VERIFIED — the platform shell and template runtime are different evidence domains

The public HTMLhost homepage, editor, and template detail pages are delivered through a platform shell with Next.js-style static chunks, host navigation, host-level typography, and Vercel/Next.js response signals. In the captures, the host body consistently computed to a near-black background (`rgb(10, 10, 11)`), light text (`rgb(242, 242, 243)`), and a Figtree-based stack.

When `Live preview` was opened, each template rendered through three inline iframe documents. The preview iframe content had its own HTML/CSS/JavaScript, template-specific fonts, CSS variables, images or canvas, forms, controls, and responsive rules. The iframe documents were delivered as inline `srcdoc` under a sandboxed iframe rather than as a discovered standalone URL.

The host shell and preview content must therefore be analyzed as separate systems. Host-page fonts, Next.js chunks, host body colors, host navigation, preview controls, and modal/frame layout are not evidence of the generated template runtime.

### VERIFIED — public previews are actual rendered websites, not only descriptions

All five selected template pages exposed a public `Live preview` state without authentication. The capture opened each preview at all three viewport sizes. The preview DOM contained rendered content and, depending on the template, forms, images, canvas, buttons, source-level CSS animations, and responsive layout behavior.

This is stronger evidence than the template descriptions alone, but it remains evidence of HTMLhost’s public template/preview presentation. It is not evidence that a customer published a customized generated site.

### VERIFIED — no published generated website was publicly established

No selected template exposed a verified customer-published site URL. All observed preview URLs remained on the HTMLhost template page with a `#preview` state. The generated-site category remains **UNKNOWN** for runtime architecture, deployment behavior, post-generation asset transformation, and production performance.

### VERIFIED — responsive preview framing is standardized at the host layer

The public preview wrapper commonly exposed three iframes: a full preview, a desktop presentation frame, and a phone presentation frame. The phone presentation frame was approximately 390 CSS pixels wide in the captured desktop/tablet contexts. The outer preview wrapper itself reflowed at the tested page viewport sizes, while the embedded template source supplied its own internal responsive rules.

This creates two responsive layers: the HTMLhost preview/presentation shell and the template’s own website layout. They must not be conflated.

## Comparative architecture matrix

| Domain | A. HTMLhost platform frontend | B. Template/preview frontend | C. Published generated websites |
|---|---|---|---|
| Evidence target | Homepage, editor, template detail pages, preview controls and wrapper | Inline sandboxed preview iframe `srcdoc` and rendered content | No verified customer-published site in this phase |
| Delivery signals | VERIFIED: Next.js-style `/_next/static/` chunks; public headers previously returned Vercel, Next.js, prerender and cache signals | VERIFIED: inline `srcdoc`; sandboxed iframe; template-specific inline source and CDN/font declarations | UNKNOWN |
| Typography | VERIFIED: host pages compute to Figtree-based stack; host also loads Gochi Hand and JetBrains Mono resources | VERIFIED: Creative uses Bricolage Grotesque/Inter; Kinetica uses Instrument Sans/Instrument Serif/Inter Tight; Futuristic names Manrope; Portfolio uses Atyp; Business uses Bricolage Grotesque/Instrument Serif/JetBrains Mono | UNKNOWN |
| Color/tokens | VERIFIED: dark host shell with light text and lime/green accent language | VERIFIED: each preview has distinct palettes and CSS variables/tokens; examples include Kinetica `--void`, `--bone`, `--acid`, `--ash`, `--ink`, `--line` and Business cream/black/lime variables | UNKNOWN |
| DOM/CSS | VERIFIED: host navigation, tabs, editor/marketing sections, FAQ and preview wrapper | VERIFIED: plain HTML/CSS/JavaScript source in preview; semantic sections, forms, CSS variables, media queries, inline SVG/canvas or image DOM depending on template | UNKNOWN |
| Framework/library evidence | VERIFIED: public shell exposes Next.js/Vercel delivery signals; exact internal component framework remains UNKNOWN | VERIFIED: varies by template. Creative: GSAP, Swiper, Lucide, canvas-confetti, JustValidate. Kinetica: Swiper, GSAP/ScrollTrigger/SplitText, Howler, Lucide, Tailwind browser declarations. Futuristic: custom WebGL/RAF; no named library proven. Portfolio: Three.js metadata/markers but active runtime UNKNOWN. Business: Lucide plus inline JavaScript | UNKNOWN |
| Motion | VERIFIED: host mobile navigation and preview wrapper expose transition/state classes; exact host animation system remains UNKNOWN | VERIFIED: template-specific CSS keyframes, GSAP, Swiper, pointer drag, IntersectionObserver, WebGL shader animation, requestAnimationFrame, accordions, counters and theme toggles | UNKNOWN |
| Responsive behavior | VERIFIED: host wrapper and page shell reflow at tested viewport sizes; mobile navigation region exists | VERIFIED: each template provides phone-ready behavior and internal media queries; exact breakpoints vary | UNKNOWN |
| Assets/fonts | VERIFIED: host static media resources and host page resource timing | VERIFIED: template-specific Google Fonts, htmlhost photo endpoints, inline SVG/CSS artwork, canvas/WebGL, or many image resources | UNKNOWN |
| Performance evidence | VERIFIED: public capture recorded resources and page errors; homepage had two 401 resource errors and network-idle timeout but rendered; editor had no captured errors | UNKNOWN/partial: source-level accommodations such as lazy images, reduced motion, visibility pause and DPR cap observed; no Web Vitals/FPS/waterfall benchmark | UNKNOWN |
| Publication state | VERIFIED: preview, template metadata, and host controls only | VERIFIED: preview source and rendered public presentation | UNKNOWN: no published customer output accessed |

## Template comparison

### Creative Playground Landing

**VERIFIED — design and runtime.** The preview rendered a warm off-white canvas, near-black type, oversized `MAKE IDEAS MOVE.` hero, rounded controls, colorful artwork, and a blue grid playground with draggable geometric shapes. The preview source used semantic sections, inline SVG/CSS artwork, a waitlist form, and CSS variables. No external image URLs were observed in the preview source.

**VERIFIED — motion and interaction.** Source evidence included GSAP entrance/reset behavior, pointer-based drag, keyboard arrow movement for focusable shapes, bounded positioning, rotation/squish feedback, IntersectionObserver reveals, smooth scrolling, Swiper process cards, form validation, and reduced-motion handling. Public declarations included GSAP 3.12.7, Swiper 11.2.10, Lucide 0.468.0, canvas-confetti 1.9.3, and JustValidate 4.3.0.

**VERIFIED — responsive behavior.** Source media queries included 760px, 400px, and 1500px thresholds. Swiper changed from approximately 1.08 slides to 2 at 540px and 3 at 900px. The public phone preview visibly reflowed navigation, hero controls, and the playground.

**UNKNOWN.** Exact computed typography metrics, font timing, transfer size, FPS, Web Vitals, cache behavior, and all interaction outcomes were not measured. No form or download/copy/publish operation was executed.

### Kinetica Motion Typography

**VERIFIED — design and runtime.** The preview source declared `--void:#0a0a0a`, `--bone:#f4f1ea`, `--acid:#c8ff3d`, `--ash:#96958e`, `--ink:#161616`, `--line:#292929`, a 22px radius, and responsive gutter logic. The preview contained approximately 485–487 elements, 30 headings, 36 buttons, one form, five inputs, and four images.

**VERIFIED — motion and libraries.** Source included seven keyframe rules, seven animation declarations, 39 transform declarations, 10 transition declarations, and a reduced-motion block. Public source declared Google Fonts, four htmlhost photo URLs, Swiper 11.2.10, GSAP 3.13.0 with ScrollTrigger/SplitText, Howler 2.2.4, Lucide 0.468.0, and Tailwind browser 4.1.3. The page metadata and preview content described type motion, sound selectors, replay, a filterable carousel, FAQ, try-it fields, and a contact form.

**VERIFIED — responsive behavior.** Source breakpoints included 1440px, 1100px, 900px, 680px, and smaller component-specific thresholds. The public preview exposed desktop and phone frames, with observed presentation sizes around 1440×900 and 390×792.

**UNKNOWN.** Actual runtime success of every optional CDN library, animation FPS, image loading timing, font fallback, quantitative performance, and exhaustive interaction outcomes were not established. Pro-only source download/copy actions were not used.

### Futuristic Dark Landing

**VERIFIED — design and runtime.** The preview rendered a near-black landing page with white Manrope typography, pale accent treatment, navigation, hero, CTAs, stats, generated flame-like field, and footer. The source had a canvas, CSS `backdrop-filter`, no image elements, and inline WebGL shader code.

**VERIFIED — motion mechanism.** The preview source requested WebGL/experimental WebGL, compiled inline vertex/fragment shaders, generated a fixed-seed 256×256 noise texture, drew a full-screen triangle, and handled pointer/touch input. It used `requestAnimationFrame`, pointer easing, ambient drift, visibility pause/resume, DPR-limited canvas sizing, and a reduced-motion still-render path. A CSS fallback was present.

**VERIFIED — responsive behavior.** The public preview exposed desktop and phone modes. The phone presentation retained navigation, hero, buttons, stats, generated background, and footer in a narrow layout.

**UNKNOWN.** Exact breakpoint values, font-file loading, WebGL fallback activation, GPU/CPU cost, FPS, LCP, and accessibility behavior were not measured. No named third-party template library was proven.

### Full-Stack Designer Portfolio

**VERIFIED — design and runtime.** The public metadata described a Pro, 16-page portfolio with near-black, magenta, violet, and white styling, Atyp typography, and pages including Home, About, blog/article pages, Gallery, Projects, Privacy, and Start a project. The public phone preview rendered the Home hero with portrait, large headline, menu label, CTA, supporting copy, and software-logo cards.

**VERIFIED — source evidence.** The Home preview source contained 43 image elements, 82 links, 11 inline scripts, no canvas elements in the inspected source, and extensive transition/transform declarations. Keyframes included shine, marquee, float, expReveal, menuSlideIn, pulse-glow, and spin. The source declared Atyp font faces and many `/m/<UUID>`-style image resources.

**INFERRED/UNKNOWN — Three.js.** The template page named Three.js and the source contained THREE markers, but the inspected Home source had no canvas and no external `script[src]`. Active Three.js rendering and its role are therefore UNKNOWN, not verified.

**VERIFIED — responsive behavior.** Preview source included 480px, 768px, 992px, and 1024px media queries. Phone rendering reorganized the Home hero into a narrow vertical composition.

**UNKNOWN.** Whether the desktop preview’s initial loading spinner resolves consistently, all-page behavior, image/font timing, library execution, quantitative performance, and exact hover/navigation choreography remain open.

### Business Web Studio

**VERIFIED — design and runtime.** The preview rendered a cream/near-black/lime agency site with large display typography, italic serif accents, rounded image treatment, dark contact/footer regions, and sections for services, work, studio, process, testimonials, FAQ, and enquiry.

**VERIFIED — DOM/CSS/JavaScript.** The inline preview source contained semantic sections/forms, grid/flex layouts, CSS variables, media queries, transitions, keyframes, and IDs/classes for services, work, about, process, contact, menu, and FAQ. It loaded Bricolage Grotesque, Instrument Serif, JetBrains Mono, and Lucide 0.468.0. JavaScript implemented a mobile menu, FAQ accordions, scroll-state header, IntersectionObserver reveals, requestAnimationFrame counters, theme toggle/localStorage, and a current-year update.

**VERIFIED — assets and responsive behavior.** The hero image had explicit 1600×800 dimensions; later images had explicit dimensions and `loading="lazy"`. Source media queries included 980px, 860px, 760px, and 620px, with one-column hero behavior, mobile navigation overlay, and a 4:3 mobile hero ratio. The public phone preview rendered the narrow state.

**UNKNOWN.** Image formats/transfer sizes, font fallback, Web Vitals, cache behavior, exact real-device performance, and `/__hh/form` backend behavior were not tested.

## Platform frontend findings

### VERIFIED

- The homepage and editor render in the same dark HTMLhost shell with Figtree-based body typography, light text, responsive width behavior, and long scrolling page structure.
- The platform page exposes a sticky navigation and a mobile navigation region. Earlier DOM inspection showed transition duration, opacity, pointer-event, `max-h-0`, and reduced-motion classes on the mobile navigation region.
- The public homepage loaded Next.js-style static CSS/JavaScript chunks and host fonts. Public headers previously returned Vercel and Next.js signals, including prerender/cache indicators.
- The public capture recorded 219 resource entries for the desktop homepage, 196 for the mobile editor, and 198 for the desktop Business template detail page. These counts include host shell assets and are not template bundle sizes.
- The homepage capture rendered but reached a 60-second network-idle timeout and recorded two 401 resource errors. The editor capture completed without captured console/page errors. The 401s are evidence of public-page resource behavior in this test, not proof of a platform defect.

### UNKNOWN

- Exact private component framework, source organization, data-fetching architecture, editor implementation, preview orchestration, and publication pipeline.
- Whether the platform shell, preview wrapper, and generated published websites share any runtime dependencies.
- Core Web Vitals, route transition timings, layout-shift values, and real-device performance.

## Generated published website boundary

### UNKNOWN — no customer-generated runtime was accessed

The public corpus produced template-page previews only. The preview URL remained on the template page with `#preview`, and the actual template content was delivered as an inline sandboxed document. No published customer site, customized generated output, or post-publication asset graph was verified.

The correct current conclusion is not that generated websites use the preview stack. The correct conclusion is that generated-site architecture remains UNKNOWN until a publicly accessible published site is found or a separately authorized, non-authenticated test publication is approved.

## Evidence inventory

- Reproducible script: `/home/ubuntu/rea-phase1a-capture.py`
- Capture index: `/home/ubuntu/rea-phase1a/capture-index.json`
- Screenshot directory: `/home/ubuntu/rea-phase1a/screenshots/`
- 21 JSON records: one per target × viewport
- 81 PNG screenshots: page, preview wrapper, and iframe captures

## Phase 1A conclusion

Phase 1A establishes a defensible separation between three systems. The platform frontend is a Next.js/Vercel-signaled HTMLhost application shell. The template/preview frontend is a heterogeneous set of plain HTML/CSS/JavaScript documents delivered through public sandboxed `srcdoc` iframes, with template-specific typography, tokens, assets, and motion mechanisms. Published generated websites were not publicly established and remain UNKNOWN.

The strongest next investigation, after review, is not to assume a shared stack. It is to locate and inspect a small number of publicly linked published HTMLhost subdomain sites, if available, and compare their delivered HTML, headers, asset URLs, CSP, fonts, and runtime behavior against the preview documents. If no such public sites are available, the generated-site column must remain UNKNOWN rather than being filled by inference.

## References

[1]: https://htmlhost.co/ "HTMLhost official homepage"
[2]: https://htmlhost.co/editor "HTMLhost AI HTML Editor"
[3]: https://htmlhost.co/templates/creative-playground-landing "Creative Playground Landing"
[4]: https://htmlhost.co/templates/kinetica-motion-typography "Kinetica Motion Typography"
[5]: https://htmlhost.co/templates/futuristic-dark-landing "Futuristic Dark Landing"
[6]: https://htmlhost.co/templates/full-stack-designer-portfolio "Full-Stack Designer Portfolio"
[7]: https://htmlhost.co/templates/business-web-studio "Business Web Studio"
[8]: https://htmlhost.co/templates/creative-playground-landing#preview "Creative Playground public preview state"
[9]: https://htmlhost.co/templates/kinetica-motion-typography#preview "Kinetica public preview state"
[10]: https://htmlhost.co/templates/futuristic-dark-landing#preview "Futuristic Dark public preview state"
[11]: https://htmlhost.co/templates/full-stack-designer-portfolio#preview "Portfolio public preview state"
[12]: https://htmlhost.co/templates/business-web-studio#preview "Business Web Studio public preview state"
