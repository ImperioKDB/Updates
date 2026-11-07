# SCHOLARS RESOURCE CENTER — VISUAL ACCEPTANCE CHECKLIST

**Prepared:** 2026-11-07  
**Scope:** Public Resource Center routes only. CMS checks are visual-reference checks and are not implementation approval.

| Test | Expected result | How to verify | Severity |
|---|---|---|---|
| Required viewport set | Pages are checked at 320, 360, 375, 390, 414, 430, 768, 1024, 1280, and 1440px. | Browser/device emulation and screenshot comparison for `/resources`, category, and article. | Blocker |
| Document width | No unintended horizontal document overflow at any required width. | Inspect `document.documentElement.scrollWidth <= clientWidth`; manually swipe on touch viewport. | Blocker |
| Masthead navigation | Desktop nav is complete; mobile nav opens without clipping and exposes every destination. | Keyboard and touch through open/close, Escape, focus return, and route activation. | Blocker |
| Header controls | Every visible control is reachable and has at least a 44px touch target. | Measure computed boxes and test with keyboard/touch. | High |
| Hero composition | Headline, summary, and primary/secondary actions remain readable and stacked appropriately on mobile. | Compare screenshots at 320, 390, 768, 1440px. | High |
| Headline wrapping | Fraunces headings wrap naturally without clipping, overlap, or excessive orphaning. | Visual inspection plus long-title fixture. | High |
| Article reading measure | Main article body is approximately 65–75 characters per line on desktop. | Use a representative article at 1280/1440px; inspect line length and computed max width. | High |
| Mobile article body | Body text stays inside its container, remains at least comfortable 17px text, and does not create overflow. | Test long words, links, lists, blockquotes, and images at 320/390px. | Blocker |
| Article hierarchy | One meaningful `h1`; headings descend logically; metadata is visibly subordinate. | Accessibility tree and DOM inspection. | Blocker |
| Article header | Breadcrumb, category, title, summary, author, date, and read time use real data and wrap cleanly. | Test with missing optional excerpt/read time/author bio. | High |
| Featured image | Image reserves its aspect ratio, uses correct crop, loads without layout shift, and has correct alt behaviour. | Slow-network test and image audit at mobile/desktop. | High |
| Missing image | Missing image path produces a deliberate quiet surface, not a broken-image icon or fabricated image. | Article fixture with null image path. | Medium |
| Category links | Every card links to its actual article slug; no repeated prototype `/article` destination. | Crawl page links and click at least six records. | Blocker |
| Category navigation | Subject chips/tabs wrap or use a local labelled scroller; they never widen the document. | Test at 320, 390, 430px and keyboard horizontal navigation where applicable. | Blocker |
| Category empty state | Empty category explains the state and offers a useful next action without sample content. | Use category with zero published rows. | High |
| Homepage empty state | No published articles produces a truthful “being prepared” style state and valid navigation. | Use empty public projection fixture. | High |
| Loading state | Loading preserves card/image geometry and does not cause visible layout jump. | Throttle network and capture before/after load. | Medium |
| Error state | Supabase/read error shows a safe editorial message without stack traces or secrets. | Force projection failure in test environment. | High |
| Section rhythm | Page sections retain deliberate whitespace: roughly 48px mobile, 72px tablet, 104px+ desktop where appropriate. | Compare computed spacing and screenshots against design spec. | Medium |
| Cards and surfaces | No generic SaaS gradients, excessive shadows, neon colours, or excessive rounded cards. | Visual review against prototype and token list. | High |
| Colour contrast | Text and controls meet WCAG AA; status is not communicated by colour alone. | Automated contrast audit plus keyboard visual review. | Blocker |
| Focus visibility | Focus ring is visible on links, buttons, disclosures, chips, and share controls against both parchment and navy surfaces. | Keyboard-only pass with focus screenshots. | Blocker |
| Keyboard order | Tab order follows reading order; no keyboard trap outside an active modal. | Complete keyboard-only walkthrough of each route. | Blocker |
| Mobile menu/dialog | If modal, focus enters, remains contained, closes with Escape, and returns to trigger. | Keyboard and screen-reader smoke test. | Blocker |
| Table of contents | TOC appears only when useful, anchors correct headings, and sticky offset does not hide headings. | Test article with 0, 2, and 8 headings. | High |
| Reading progress | Progress indicator is non-obstructive and does not communicate essential information only through colour. | Scroll article with keyboard/touch and inspect accessibility tree. | Medium |
| Anchor navigation | Anchor links move to the correct section without scroll hijacking. | Activate TOC links at desktop/mobile and verify heading position. | High |
| Motion timing | Press feedback 100–160ms; ordinary reveals below 400ms; no blocked interactions. | Record interaction and inspect computed animations. | Medium |
| Reduced motion | `prefers-reduced-motion: reduce` removes non-essential transforms/animations and keeps content immediately usable. | Browser accessibility setting plus keyboard/touch walkthrough. | Blocker |
| Touch behaviour | No hover-only content; pressed states are clear but brief; touch scrolling remains native. | Real or emulated touch pass. | High |
| Share control | Share/copy state is announced or otherwise understandable, and failure does not break reading. | Test supported and unsupported share paths. | Medium |
| Author information | Real author name/bio/avatar only; missing optional fields collapse gracefully. | Article fixtures with complete and partial author projection data. | High |
| Related content | Related links resolve to distinct actual slugs and do not appear when no valid relation exists. | Click/crawl related section. | High |
| Metadata | Title, description, canonical, Open Graph, Article JSON-LD, dates, and publisher use real article values. | Inspect rendered head and JSON-LD for representative article/category. | Blocker |
| Breadcrumb JSON-LD | Structured breadcrumb matches visible breadcrumb labels and URLs. | Validate JSON-LD and compare DOM. | High |
| Sitemap | Public article routes and the approved set of category routes are present; drafts/future content absent. | Fetch sitemap and compare to published projection fixtures. | Blocker |
| Image SEO | Meaningful images have descriptive alt text, dimensions, and stable URLs. | Inspect DOM and run image audit. | High |
| Crawlability | Public content uses server-rendered semantic links, not click-only JS handlers. | Disable JS where practical; inspect HTML/crawl output. | High |
| Performance | LCP target under 2.5s, CLS under 0.1, INP under 200ms on representative mobile conditions. | Lighthouse/Web Vitals run on production-like build. | High |
| Query bounds | Public pages request only needed columns and bounded result sets. | Review route queries and network/server logs. | High |
| Footer | Footer links are valid, fit mobile width, and do not repeat unavailable sample resources. | Click/crawl footer at 320 and 1440px. | Medium |
| Dashboard visual reference | If a future shell is shown, it is labelled non-production/sample and has no write actions. | Review route behind approved access or static design capture. | Blocker for CMS work |
| Editor visual reference | Future editor fields have labels and responsive containment in design only; no save/publish/approve actions exist. | Review design artifact; confirm no network writes. | Blocker for CMS work |

## Release gate

A public implementation is not ready if any Blocker fails. High-severity failures require correction or an explicit product/design decision. Medium findings may be accepted only with a documented reason. This checklist must be rerun after any change to shared layout, public projections, image handling, metadata, or navigation.

## References

[1]: https://resource-center.htmlhost.co/ "Prototype visual reference"
[2]: https://github.com/ImperioKDB/Scholars/blob/main/app/globals.css "Existing motion and focus styles"
[3]: https://github.com/ImperioKDB/Scholars/blob/main/app/sitemap.ts "Existing sitemap implementation"
[4]: https://github.com/ImperioKDB/Scholars/blob/main/supabase/migrations/20261107130100_resource_center_schema.sql "Approved public projection boundary"
