# Scholars Resource Center — Frontend Design and Engineering Brief

**Status:** Authoritative design/specification artifact; no implementation authorization.  
**Repository inspected:** `ImperioKDB/Scholars` at `cf3682ce35912df7b9b9352193630fc404427c7c`  
**Research repository:** `ImperioKDB/Updates` at `0f1bc532121cd0fd9c22d5bc90a0c0dd6f914a3b`  
**Public site inspected:** `https://scholars.com.ng/` and `https://scholars.com.ng/resources`  
**Scope:** Public frontend design and engineering. Editorial writes, CMS actions, migrations, deployment, and Scholars source changes are out of scope.

## 1. Product and experience strategy

### Purpose

The Resource Center is the knowledge and preparation layer of Scholars. It should help a student understand how opportunities work, make better application decisions, and move from uncertainty to an informed next step. It is not a second scholarship catalogue, a generic blog, or an authenticated dashboard.

The public site currently positions Scholars around eligibility-matched opportunities for students in Nigeria. The existing `/resources` route truthfully presents the center as “Useful guidance for the next opportunity” and currently shows a reviewed-content empty state. The new experience must preserve that honesty: no sample articles, invented counts, fabricated authors, or unverified deadlines should appear in production. [1] [2]

### Relationship with Scholars

The Resource Center belongs inside the existing Scholars application at `/resources`. It should share the existing logo, local Fraunces and Manrope fonts, color tokens, focus treatment, footer, canonical URL configuration, server-side Supabase access, and CI conventions. It should remain a public App Router route tree outside protected route groups. [3] [4]

Its relationship is sequential:

1. **Resource Center:** explain, prepare, and build confidence.
2. **Scholars public catalogue:** let the reader inspect verified opportunities.
3. **Scholars profile/matching flow:** let a student create a profile and discover opportunities assessed against actual eligibility.

A guide may link to a verified scholarship or opportunity detail page, but article content must not write to, impersonate, or become an input to eligibility matching. The center must not reuse scholarship, application, profile, notification, discovery, or discussion tables as an article system. [3] [5]

### Primary audiences

- **First-time applicants:** need plain explanations, vocabulary, checklists, and confidence about where to begin.
- **Active applicants:** need application strategy, document preparation, deadlines, essays, interviews, and quality checks.
- **Students evaluating an opportunity:** need help judging fit, credibility, requirements, and next steps without being promised an award.
- **Returning readers:** need a dependable publication rhythm, related reading, and clear paths back to current opportunities.
- **Internationally curious students:** may need study-abroad and cross-border funding context, but only when the editorial team has approved source and scope.

Authors and reviewers are a trust audience too. They need visible, bounded publication metadata and a future editorial workflow, but no dashboard or authoring interaction is approved by this brief.

### Core journeys

**Orient.** A student lands on the homepage, understands what the publication is for, sees subjects, and chooses a featured story or guide.

**Prepare.** A student reads an application guide, scans headings or the table of contents, follows a checklist, and leaves with one concrete action.

**Evaluate.** A student reads an opportunity or funding explainer, follows source links where appropriate, and moves to a verified Scholars listing or official provider source.

**Continue.** An article ends with related reading based on real category relationships or a bounded latest-article fallback. It never displays fabricated “recommended” counts.

**Convert with integrity.** A concise bridge invites the reader to explore Scholars opportunities or build a profile. It must say what the destination does and must not imply that reading creates eligibility or guarantees an award.

### Experience principles

1. **Editorial before interface:** compose sections around questions and decisions, not interchangeable card grids.
2. **Clarity is access:** use plain language, visible hierarchy, and real metadata.
3. **Trust is a product feature:** show publication and review dates when available; distinguish advice, fact, and source.
4. **One next step:** each page should make the next useful action obvious without becoming sales-led.
5. **Mobile is a composition:** recompose at 320–430 px rather than shrinking desktop.
6. **Motion serves comprehension:** state changes, hierarchy, and continuity only; never decorate a weak information structure.
7. **Truthful absence:** loading, empty, unavailable, and not-found states describe the actual state.
8. **Separate layers:** content, interaction state, and visual motion remain independently understandable.

### What makes it different from a conventional blog

The center should feel like a field guide: structured around student decisions, categories with editorial meaning, last-reviewed signals for time-sensitive guidance, bounded connections to verified opportunities, and a publication voice that is warm but precise. It should not imitate a news feed, use a date-only reverse chronology as its entire information architecture, or add newsletter, bookmark, ad, search, or recommendation features without approved contracts.

## 2. Visual direction

### Existing brand to preserve

The checked-out Scholars application already establishes a warm editorial identity: parchment background `#F7F5EF`, deep navy `#0B1E3D`, emerald `#15705A`, amber `#966216`, muted red `#A63A35`, warm hairline `#E4E1D8`, local Fraunces display type, Manrope body type, large-type footer, and a restrained shadow. These are existing brand values, not new Resource Center inventions. [6]

### Recommended direction

**A warm, Nigerian-rooted field guide for ambitious students.** Use generous parchment space, deep navy structure, emerald as a calm action/focus accent, amber for editorial framing, and typography as the primary visual instrument. Let photography or approved editorial imagery provide human context, but do not use generic stock-photo mosaics, decorative gradients, or glossy UI effects.

The design should be premium and contemporary through composition, measure, rhythm, and editorial confidence—not through expensive-looking effects.

### Color tokens

| Role | Existing token/value | Use and constraint |
|---|---|---|
| `surface.canvas` | `#F7F5EF` | Main reading background |
| `surface.raised` | `#FFFFFF` | Masthead, article header, bounded cards |
| `text.strong` | `#0B1E3D` | Headings, primary actions, structural rules |
| `text.body` | `#10151F` | Long-form copy |
| `text.muted` | Existing `navy-light` | Metadata and secondary copy |
| `accent.action` | `#15705A` | Links, eyebrows, focus ring, positive accent |
| `accent.field` | `#966216` | Field-guide/review labels; never sole status signal |
| `accent.caution` | `#A63A35` | Errors/caution with text or icon support |
| `border.subtle` | `#E4E1D8` | Hairlines and separators |

Do not add purple gradients, neon, glassmorphism, arbitrary brand colors, or white text on insufficiently contrasting accents. Validate combinations against WCAG AA.

### Typography

Use the bundled local fonts. Do not fetch a remote font or introduce a second type family.

- **Display hero:** Fraunces 56–72 px desktop; 42–52 px tablet; 38–44 px mobile; 600–700 weight; line-height 0.98–1.05.
- **Page title:** Fraunces 48–64 px desktop; 38–48 px tablet; 36–42 px mobile; line-height 1.02–1.08.
- **Article title:** `clamp(2.5rem, 6vw, 4.5rem)` with natural wrapping; never force a single line.
- **Section title:** Fraunces 32–44 px; line-height 1.08–1.15.
- **Card title:** Fraunces 22–30 px; line-height 1.1–1.2.
- **Body:** Manrope 16–18 px; line-height 1.65–1.8.
- **Article body:** Manrope 18 px desktop, 17 px mobile, line-height about 1.75, 65–75 characters per line.
- **Labels:** Manrope or existing mono utility, 10–12 px uppercase, letter-spacing 0.14–0.18 em.
- **Metadata:** Manrope 12–14 px, line-height 1.4.

### Layout and spacing

Use a centered shell with `--rc-content-max: 72rem`, `--rc-reading-max: 46rem`, and `--rc-gutter: clamp(1rem, 3vw, 3rem)` as semantic aliases. Use a four-point rhythm. Typical section spacing is 48 px mobile, 72 px tablet, and 104–128 px desktop. Use 16–24 px gaps for cards and editorial lists.

At 320–430 px, use 16–20 px gutters, stack hero actions, wrap metadata, and keep any horizontal scrolling local to an explicitly labelled subject list. At 768 px, add columns selectively. At 1024 px and above, use the full editorial frame. At 1280–1440 px, increase whitespace and image scale, not body line length. Every grid track must allow `min-width: 0`; document horizontal overflow is prohibited.

### Surfaces, borders, and imagery

Prefer parchment, white, and hairline rules over shadows. Use rounded corners only for bounded panels, controls, or existing seal treatments. Reserve image aspect ratio before load. A meaningful image needs approved editorial alt text; a decorative image uses empty alt. If `featured_image_path` cannot resolve through an approved public storage strategy, use a quiet editorial surface rather than a broken image or invented asset.

### Iconography and illustration

Use the existing icon conventions and simple line icons. Icons support a label; they never carry essential meaning alone. Avoid an illustration system unless real content needs it. Editorial photography should be documentary, contextual, and approved—not a repeated collection of generic student portraits.

### Motion language

Use native scrolling and CSS-first motion. Major sections may reveal once with 6–12 px upward translation and opacity over 320–380 ms. Mobile navigation uses opacity and 4–8 px translation over 180–240 ms. Button press feedback remains the existing 100–160 ms treatment. Reduced motion renders content immediately and removes nonessential transform/loop motion. These choices transfer engineering principles from HTMLhost research; they do not reproduce HTMLhost source or branding. [7] [8]

## 3. Page architecture

### Shared public shell

Every public Resource Center route uses:

- semantic `header` with Scholars mark and Resource Center identity;
- primary publication navigation;
- a clear `Explore Scholars` destination;
- labelled mobile disclosure/dialog;
- `main` content with one meaningful `h1`;
- existing footer with Resource Center and Scholars links;
- visible breadcrumbs where they aid orientation;
- no authenticated gate and no CMS controls.

Recommended navigation labels are **Discover**, **Scholarship Guides**, **Applications**, **Student Life**, and **Opportunities**, but a label is only shipped when its real category exists. The route must not display dead links.

### Homepage — `/resources`

**Purpose:** establish the publication point of view and offer several trustworthy entry points.

**Above the fold:** masthead, editorial eyebrow, short field-guide framing, a large Fraunces headline, explanatory deck, and one featured editorial image or quiet image field. Primary action: browse guides. Secondary action: explore Scholars.

**Primary hierarchy:** one real featured story; then an editorial desk with two or three real latest items; then subject navigation; then a practical library; then an opportunity bridge. Do not create a hero from a nonexistent featured flag. If no published article exists, preserve the current truthful “first guides are being prepared” state.

**Responsive:** stack image below copy on phones; stack desk items; keep actions full-width or in a two-row stack; make subject navigation wrap or locally scroll.

**Conversion:** the final bridge leads to a verified public Scholars opportunity route. It explains that reading prepares a student and Scholars helps them explore fit.

### Article detail — `/resources/[slug]`

**Above the fold:** breadcrumbs, article type/category, optional field-guide identifier, title, excerpt, author, publication date, last-reviewed date when present, and read time. Metadata wraps on mobile.

**Body:** a bounded 65–75-character reading column, semantic headings, visible links, lists, blockquotes, and labelled callouts only when supported by the content format. Existing `ResourceArticleBody` is a verified starting point but currently implements a narrow paragraph/heading/list parser; a future implementation must preserve safety and either improve the renderer deliberately or remain within the approved Markdown contract.

**Supporting content:** optional reading progress, table of contents for articles with enough headings, author block, related articles from real category relations or bounded latest fallback, and one concise Scholars bridge. Do not add bookmarking, newsletter capture, or per-article analytics without approved contracts.

**Responsive:** move side content below the article; make the table of contents a disclosure; keep share controls secondary; never let a sticky rail reduce the reading measure.

### Category archive — `/resources/category/[slug]`

**Above the fold:** breadcrumb, category title, description, and subject navigation.

**Composition:** a featured article only if a real editorial selection rule exists; otherwise begin with a reading list. Every item uses its actual slug and exposes article type, title, excerpt, author, date/read time where available.

**Empty state:** say that no published guides exist in the category and offer adjacent real categories or the Resource Center home. Never display prototype counts or sample records.

**Responsive:** single-column list on phones; two columns only when it improves scanning; category tabs wrap or use a labelled local scroller. Do not add unbounded client-side fetching.

### Search results

Search is **not approved for this phase**. The current public projections and planning records do not establish a search contract. Do not add a search field that implies functionality. If later approved, define query semantics, indexing, pagination, no-result copy, keyboard behavior, and crawl strategy before designing the surface.

### Editorial dashboard — future visual reference only

The dashboard may eventually contain Overview, Content queue, Calendar, and Editorial standards. The visual direction may be documented, but live metrics, draft creation, status transitions, publishing, scheduling, review, and revision actions remain blocked. It must not use sample metrics or pretend the current scholarship admin is an editorial CMS. [5] [9]

### Author/contributor profile

No standalone public author route is required in the first phase. Show a bounded author identity block on articles using approved display fields only. A profile route should be added only when the product has an approved public identity contract, privacy review, canonical URL, and enough content to justify discovery.

### Related articles and recommendation surfaces

Use real category relationships. If there are too few related rows, use a bounded latest-article fallback or omit the module. Do not call content “recommended,” “featured,” or “most read” without a verified field or query. Related links must be crawlable anchors with actual slugs.

### Loading, empty, error, and not-found states

- **Loading:** reserve card and image geometry; keep essential landmarks and headings visible where possible.
- **Empty:** explain the state in editorial language and offer one useful next step.
- **Error:** state that content could not be loaded, omit database details, and provide retry/home links when applicable.
- **Not found:** use the application’s not-found route semantics, identify the missing article/category, and offer `/resources` and verified Scholars destinations.
- **Unavailable image:** preserve the layout with a quiet surface and meaningful adjacent metadata.

## 4. Component and design-system architecture

### Shared components

Refine or create small components with explicit contracts:

- `ResourceMasthead` and `ResourceMobileNav`
- `EditorialEyebrow` and `FieldGuideLabel`
- `FeaturedStory`, `EditorialDesk`, `ResourceCard`, and `GuideCard`
- `SubjectNav`
- `ResourceArticleHeader`, `FeaturedImage`, and `ResourceArticleBody`
- `ArticleTableOfContents`, `ReadingProgress`, and `ArticleShareRail`
- `AuthorBio`, `RelatedArticles`, and `OpportunityBridge`
- `ResourceEmptyState`, `ResourceErrorState`, and skeletons
- existing `Logo`, `Footer`, `Breadcrumbs`/`SeoJsonLd`, `ScrollReveal`, and `ShareButton` where their contracts remain valid.

### Component boundaries

Shared components own semantic markup, states, accessibility, and visual tokens. Routes own data loading, page-specific composition, and metadata. Keep editorial sections page-specific when their composition communicates a distinct purpose. Do not abstract every card into a configurable mega-component.

The public component contract may consume only verified projection fields: identity, slug, title, excerpt, Markdown content, article type, canonical URL, image path, reading time, publication/review dates, approved author display fields, category identity/description/order, and real display order. `featured`, `recommended`, newsletter, bookmarks, analytics, and editor-only fields are not part of the verified public contract. [5]

### Data and architecture boundary

The public routes should use the existing `resource_public_*` projections through server-side Supabase access and select only needed columns with bounded result sets. Do not query protected base tables from browser code, do not use the service-role client in public rendering, and do not bypass the fixed projections. The existing projections are owner-context views rather than `security_invoker=true`; any future schema/view changes require a security regression review. [5]

## 5. Motion and interaction engineering

Each interaction must have an authoritative semantic state. Animation may present that state but never define it.

### Mobile navigation

- **Trigger:** labelled menu button.
- **Initial:** closed, `aria-expanded="false"`, controlled region hidden/inert.
- **Active:** open panel, focus moved into the panel when modal behavior is used.
- **Exit:** close button, Escape, or outside action; return focus to trigger.
- **Timing:** 180–240 ms opacity/4–8 px transform.
- **Reduced motion:** state changes immediately.
- **Mobile/accessibility:** safe-area padding, no clipped links, 44 px controls, visible focus, correct `aria-controls`.
- **Performance:** transform/opacity only; no document-width animation.

### Section reveal

- **Trigger:** first intersection with a generous root margin.
- **Initial:** visible fallback until the observer is attached; then optional 6–12 px offset and opacity.
- **Active/exit:** reveal once and remain visible.
- **Timing:** 320–380 ms restrained ease-out; no large stagger.
- **Reduced motion:** final state immediately.
- **Accessibility/performance:** never hide essential focusable content; one observer per section group is sufficient.

### Article table of contents

- **Trigger:** user toggles the disclosure or activates an anchor.
- **State:** deterministic open/closed state with stable IDs.
- **Timing:** 150–220 ms if layout remains stable; otherwise instant.
- **Mobile:** disclosure before the body; desktop may use a sticky side rail.
- **Accessibility:** button semantics, `aria-expanded`, `aria-controls`, focusable headings or `scroll-margin-top`, and visible focus.
- **Reduced motion:** instant.

### Reading progress

- **Trigger:** scroll position within the article container.
- **Initial/active:** decorative thin indicator only after a stable article height exists.
- **Exit:** stop at completion; do not obscure content.
- **Accessibility:** `aria-hidden="true"` unless paired with a textual equivalent. It must never be the only indication of reading position.
- **Performance:** use a passive observer or scheduled update; do not trigger layout reads on every unthrottled event.

### Image load

Reserve the final aspect ratio before the image request. Fade the decoded image over 180–240 ms only when it does not delay content. At reduced motion, show it immediately. Do not animate dimensions or cause layout shift.

### Share feedback

Use the existing `ShareButton` only if its current API is compatible. State changes should be text/icon feedback under 200 ms with an accessible status. Sharing is secondary to reading and must still work by keyboard.

### Pointer, canvas, GSAP, and scroll policy

No canvas/WebGL is justified for the Resource Center’s semantic content. If a future decorative visual is approved, it must have a static fallback, DPR cap, hidden-tab pause, context-loss handling, local `touch-action`, tested pointer delivery, reduced-motion branch, and content outside the canvas. GSAP is not a default dependency; use it only when a multi-step timeline materially improves maintainability after CSS has been ruled out. Do not hijack scrolling or add Lenis/Locomotive-style smooth scrolling. These guardrails come from the completed HTMLhost research and its explicit evidence boundaries. [7] [8]

## 6. Responsive engineering

Test the exact widths 320, 360, 375, 390, 414, 430, 768, 1024, 1280, and 1440 px, plus an intermediate width around 1180 px.

- **Small Android phones:** 16 px gutters, stacked hero, wrapped metadata, 44 px controls, no clipped title or nav, local subject scroller only when needed.
- **Larger phones:** 20 px gutters, slightly larger title measure, two-row action group when useful, single-column article/cards.
- **Tablets:** two-column editorial composition only where content remains readable; move article side content below when the reading column would narrow.
- **Laptops:** full editorial grid, bounded reading column, optional sticky TOC/author rail.
- **Large desktop:** more whitespace and larger approved imagery, never longer body lines or decorative empty columns.

Use `minmax(0, 1fr)`, `min-width: 0`, bounded media, wrapping labels, and local overflow regions. Assert `document.documentElement.scrollWidth <= window.innerWidth` on every required route and width. Do not use `overflow-x: hidden` to hide a root cause.

## 7. Accessibility

Use semantic `header`, `nav`, `main`, `article`, `aside`, `section`, and `footer`. Maintain one meaningful `h1`, logical heading order, descriptive link names, and a visible emerald focus ring. Use native buttons for disclosures. Pair `aria-expanded` with a stable `aria-controls`; use `inert` or an equivalent strategy when hidden interactive content would otherwise remain reachable.

All interactive controls are at least 44 px high. Essential information cannot depend on hover, color, motion, a canvas, or an icon alone. Article links remain visually distinguishable without hover. Image alt text comes from approved editorial content. Dates use machine-readable `dateTime`. Form/search feedback requirements apply if those features are approved later.

Reduced motion must preserve semantics: reveals become visible, menus still open/close, disclosures still change state, direct manipulation remains functional without decorative wobble, and continuous effects pause or become a stable frame.

## 8. Performance and SEO

### Performance requirements

- Server-render public page bodies; do not client-fetch the primary article content.
- Select only required projection columns and bound every result set.
- Avoid N+1 category/article queries; use bounded relation reads or an approved query shape.
- Reserve image dimensions; use responsive sources and lazy-load below-fold media.
- Keep fonts local and use `font-display: swap` as already established.
- Keep JavaScript for stateful interaction only; no animation dependency by default.
- Avoid third-party scripts in the initial phase. Ads, newsletter providers, and analytics events need separate approval.
- Preserve layout stability and avoid animation of width, height, or document flow for ordinary reveals.

Proposed acceptance targets—not current measurements—are Lighthouse Performance and Accessibility at least 90 on representative public pages where content permits, mobile LCP under 2.5 seconds, CLS under 0.1, and INP under 200 ms. These must be measured on representative routes and devices. The HTMLhost 0.80/0.79 single-run Lighthouse values are diagnostic evidence for different surfaces, not Scholars benchmarks or published-site claims. [8]

### SEO requirements

- `/resources` has a stable canonical URL and unique title/description.
- Articles use canonical URL from the approved record, unique metadata, Open Graph article metadata, `Article` JSON-LD, and `BreadcrumbList` JSON-LD matching visible breadcrumbs.
- Include `datePublished`, `dateModified`/last reviewed only from real fields, author display data, publisher data, and image only when real.
- Categories have unique metadata and are indexable only after the product decides whether empty categories should be indexed.
- Sitemap includes published articles and approved active category URLs. The current implementation reads published articles but is known to omit `/resources` from static paths and category URLs; this is an implementation-phase fix, not a planning assumption. [5] [9]
- Drafts, previews, future-scheduled rows, and admin routes are not public metadata or sitemap entries.
- Use crawlable anchors and meaningful internal links between related articles, categories, verified opportunity pages, and official provider sources.
- Do not claim AdSense readiness or add `ads.txt` in this phase.

## 9. Technical implementation guidance

### Verified existing architecture

The repository uses Next.js 14 App Router, React 18, TypeScript strict mode, Tailwind CSS, Supabase JS/SSR, Zod, Vitest, local Fraunces/Manrope fonts, and GitHub Actions CI that runs typecheck, tests, and build. The current public Resource Center routes are `app/resources/page.tsx`, `app/resources/[slug]/page.tsx`, and `app/resources/category/[slug]/page.tsx`. [3] [10]

Current routes already use server-side Supabase queries against `resource_public_articles`, `resource_public_categories`, and `resource_public_article_categories`. The article route emits canonical/Open Graph metadata and `Article` JSON-LD. Existing `ResourceArticleBody` renders a constrained Markdown-like subset. The root layout and Tailwind config establish the visual tokens and local fonts.

### Proposed frontend change boundary

A future implementation may refine the current route-local composition and add `components/resources/` and `lib/resources/` for typed queries, metadata, structured data, and small presentation primitives. It may adjust `app/sitemap.ts` after the category-index decision. It should avoid unrelated changes to auth, middleware, onboarding, matching, dashboard, application, notification, cron, Inngest, and scholarship verification systems.

The public projections and image URL strategy must be reverified on the implementation branch. If a public image bucket/transform path is not approved, omit images gracefully. Do not invent a storage URL or add a new dependency for a visual effect.

### Editorial dashboard boundary

The existing admin scholarship surfaces are not a general editorial CMS. A future `/admin/resources` surface requires explicit capability rules, author/reviewer identities, self-approval policy, state transitions, immutable revisions, audit events, and secure preview semantics. The security clarification identified live function grant drift and other unrelated operational findings; the Resource Center must not weaken those boundaries or solve them by broadening policies. [5] [11]

No schema migration, RLS change, grant, editor, publication action, content seed, or deployment is part of this brief.

## 10. Implementation sequence

### Phase 0 — approval and branch verification

- **Objective:** verify the implementation branch, public projection fields, image path, sitemap behavior, and security boundary.
- **Scope:** read-only inspection and test-plan confirmation.
- **Dependencies:** owner approval; live state is not inferred from migration history.
- **Deliverables:** signed-off field contract, image decision, category sitemap decision.
- **Acceptance:** no unsupported fields or routes remain in the plan.
- **Risks:** branch drift, view drift, hidden public storage assumptions.
- **Verification:** compare source, migration, and deployment metadata; run no writes.

### Phase 1 — shared public shell

- **Objective:** establish masthead, mobile nav, footer integration, containers, tokens, and breadcrumbs.
- **Scope:** public Resource Center routes only.
- **Dependencies:** Phase 0.
- **Deliverables:** responsive shell and keyboard-safe navigation.
- **Acceptance:** all widths fit; focus, Escape, outside close, and reduced motion pass.
- **Risks:** public navigation overflow or auth regression.
- **Verification:** route checks at ten widths, keyboard test, console/resource audit.

### Phase 2 — homepage and category composition

- **Objective:** make discovery editorial and truthful.
- **Scope:** featured/latest composition, subjects, practical library, category listing, empty/error states.
- **Dependencies:** published projections and route contracts.
- **Deliverables:** real-slug links, bounded queries, truthful no-content states.
- **Acceptance:** no sample data, no invented featured/recommended semantics, no unbounded fetch.
- **Risks:** generic card grid, N+1 reads, dead category links.
- **Verification:** fixture states for zero, one, few, and many published rows; sitemap review.

### Phase 3 — article reading experience

- **Objective:** improve comprehension and trust on article pages.
- **Scope:** header, image fallback, body measure, TOC/progress where justified, author, related, Scholars bridge.
- **Dependencies:** safe content renderer and image decision.
- **Deliverables:** accessible article layout and metadata parity.
- **Acceptance:** semantic headings, visible links, valid JSON-LD, 65–75 character measure, no layout shift.
- **Risks:** unsafe Markdown, fabricated related/author data, narrow desktop columns.
- **Verification:** long/short article fixtures, keyboard/reader review, metadata validation.

### Phase 4 — quality and performance verification

- **Objective:** prove public quality before release.
- **Scope:** accessibility, responsive, motion, SEO, performance, browser compatibility, loading/error/not-found states.
- **Dependencies:** Phases 1–3.
- **Deliverables:** evidence-backed QA record and resolved defects.
- **Acceptance:** all required checks pass or are explicitly waived.
- **Risks:** relying on a single Lighthouse run or visual-only review.
- **Verification:** CI typecheck/tests/build; repeated route diagnostics; representative mobile and desktop runs.

### Phase 5 — editorial operations decision

- **Objective:** decide whether to design CMS operations.
- **Scope:** documentation only until security approval.
- **Dependencies:** owner/security decisions on roles, transitions, revisions, audit, preview, and images.
- **Deliverables:** approved state machine and capability matrix, or an explicit decision to remain repository/ops-managed.
- **Acceptance:** no editor is implemented on visual approval alone.
- **Risks:** self-approval, draft leakage, privilege reuse.
- **Verification:** independent security review before any write path.

## 11. Quality assurance checklist

- Confirm all route links resolve to real slugs; no `/article` placeholder links.
- Confirm `/resources`, each article, and each approved category has canonical metadata.
- Validate Article and BreadcrumbList JSON-LD against visible content.
- Confirm only published, non-future content is public and indexable.
- Confirm empty, loading, error, unavailable-image, and not-found states are truthful.
- Test 320/360/375/390/414/430/768/1024/1280/1440 px and assert no unexpected horizontal overflow.
- Test keyboard tab order, focus visibility, mobile navigation, Escape, focus return, and TOC anchors.
- Test screen-reader names for navigation, cards, disclosure buttons, progress, share feedback, and images.
- Test normal and reduced motion, fresh-load first interactions, settled disclosure geometry, and hidden-tab behavior for loops.
- Inspect console errors, failed resources, hydration warnings, and broken URLs.
- Verify article body measure, heading order, link contrast, target sizes, and reserved image geometry.
- Run typecheck, unit tests, production build, and route-level checks under repository CI.
- Measure representative mobile Web Vitals and treat Lighthouse as a diagnostic, not a universal score.
- Confirm no public query uses a protected base table or service-role credential.
- Confirm no CMS write, schema, RLS, grant, seed, deployment, or unrelated refactor slipped into the change.

## 12. Final design decisions

### Recommended visual direction

A restrained, premium field guide using Scholars’ existing parchment, navy, emerald, amber, Fraunces, and Manrope system. Distinction comes from editorial composition, typography, field-guide framing, rules, and useful imagery—not gradients or dashboard decoration.

### Recommended page architecture

Use a publication homepage, article detail route, and category archive with a shared public shell. Keep search, newsletter, bookmarks, author routes, ads, and dashboard writes out until contracts exist. Use related content and opportunity bridges only from real, approved data.

### Recommended motion strategy

CSS-first, deterministic, low-amplitude motion: existing press feedback; 180–240 ms nav/disclosure transitions; 320–380 ms one-time section reveals; reserved image fades; no scroll hijacking, canvas, or heavy animation library by default. Reduced motion is a first-class acceptance path.

### Recommended component architecture

Small route-agnostic primitives for shell, masthead, mobile nav, editorial labels, story/card variants, article header/body, TOC/progress, author, related content, empty/error states, and opportunity bridge. Keep route data loading and page composition separate from presentation.

### Recommended implementation sequence

Verify branch/contracts first; build shell; compose homepage/category; improve article reading; then run broad QA. Do not start the editorial dashboard or CMS until security and editorial workflow decisions are approved.

### Important unresolved decisions

- Which public categories are approved for launch and whether empty categories are indexable.
- How `featured_image_path` resolves to a safe public browser URL and what image transformations are allowed.
- Whether “featured” means newest, editorial order, or a future schema field.
- Whether article content remains sanitized Markdown or moves to approved structured blocks.
- Whether an author identity should have a public profile route.
- Whether related content uses only category relationships or later editorial curation.
- Whether search, newsletter, bookmarks, analytics, and advertising are in scope; current evidence says they are not required.
- The final editorial capability matrix, self-approval policy, state machine, revision/audit rules, and preview security.
- Whether the owner accepts the current owner-context public projection model or requires a future security redesign.

### Decisions not to leave to the implementing agent

Do not choose new brand colors, remote fonts, generic card-grid composition, placeholder article data, unsupported fields, ad behavior, search semantics, publication workflow, image URL strategy, category indexability, author privacy model, content sanitation policy, or CMS permissions during implementation. Those decisions require product/security/editorial approval.

## References

[1]: https://scholars.com.ng/ "Scholars public homepage"
[2]: https://scholars.com.ng/resources "Scholars Resource Center public homepage"
[3]: https://github.com/ImperioKDB/Scholars/blob/main/app/resources/page.tsx "Current Resource Center homepage route"
[4]: https://github.com/ImperioKDB/Scholars/blob/main/app/layout.tsx "Scholars root layout and local fonts"
[5]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_RESOURCE_CENTER_PHASE_0_1_SECURITY_AND_SCHEMA_CLARIFICATION.md "Resource Center security and schema clarification"
[6]: https://github.com/ImperioKDB/Scholars/blob/main/tailwind.config.ts "Scholars visual tokens"
[7]: https://github.com/ImperioKDB/Updates/blob/main/HTMLHOST_REVERSE_ENGINEERING_PHASE_0/HTMLHOST_FRONTEND_ENGINEERING_SPECIFICATION.md "HTMLhost-derived independent frontend engineering principles"
[8]: https://github.com/ImperioKDB/Updates/blob/main/HTMLHOST_REVERSE_ENGINEERING_PHASE_0/HTMLHOST_RESEARCH_FINAL_SYNTHESIS.md "HTMLhost research final synthesis and evidence boundary"
[9]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_RESOURCE_CENTER_DESIGN_SYSTEM_AND_PRODUCTION_IMPLEMENTATION_SPEC_2026-11-07.md "Resource Center production implementation specification"
[10]: https://github.com/ImperioKDB/Scholars/blob/main/package.json "Scholars framework and dependency declarations"
[11]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_RESOURCE_CENTER_FRONTEND_IMPLEMENTATION_READINESS_2026-11-07.md "Resource Center frontend readiness assessment"
