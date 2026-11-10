# SCHOLARS RESOURCE CENTER — DESIGN SYSTEM & PRODUCTION IMPLEMENTATION SPECIFICATION

**Status:** Planning specification; public frontend may proceed only after implementation review. CMS write functionality remains blocked.

**Prepared:** 2026-11-07

## 1. Executive summary

The Resource Center should become a credible editorial publication inside Scholars, not a second dashboard and not a generic blog. The htmlhost prototype establishes the right direction: warm parchment surfaces, deep navy structure, restrained emerald and amber accents, oversized Fraunces headlines, Manrope body copy, numbered field-guide framing, generous whitespace, editorial photography, and a clear bridge from reading to finding an opportunity on Scholars. The production implementation should preserve that character while using the existing Next.js App Router, local fonts, Tailwind tokens, Supabase public projection views, and existing SEO and motion utilities.

The public phase is **READY WITH CONDITIONS**. The three public routes already exist and read approved published content through `resource_public_*` projections. The next implementation phase can refine composition, article reading, navigation, image handling, metadata, and responsive behaviour without adding tables or changing the publication boundary. It must first verify the current branch, actual field availability, image URL strategy, shared shell conventions, and sitemap category coverage. The future editorial dashboard and editor are **BLOCKED** for implementation until the separate security review resolves authorisation, reviewer permissions, state transitions, revision integrity, and audit requirements.

This specification deliberately distinguishes observed prototype behaviour, verified repository facts, implementation recommendations, assumptions, and unresolved dependencies. It does not authorise application code, database, security, authentication, content seeding, or deployment changes.

## 2. Evidence and scope

The prototype was reviewed at its rendered homepage, article page, category page, and editorial dashboard. The homepage presents a masthead, “Make sense of the opportunities ahead” hero, editorial desk, subject navigation, practical library, opportunity-insight feature, Scholars CTA, reader-engagement section, and footer [1]. The article page uses a field-guide label, category, large serif headline, summary, author/date/read-time row, long-form article body, numbered sections, pull quotes, and inline images [2]. The category page uses a collection introduction, subject tabs, featured guide, reading list, empty state, habit callout, related subjects, and Scholars CTA [3]. The dashboard clearly labels itself as a demonstration workspace with sample data and temporary changes [4].

The public repository inspection verified App Router routes at `app/resources/page.tsx`, `app/resources/[slug]/page.tsx`, and `app/resources/category/[slug]/page.tsx`; local Fraunces and Manrope font files; `app/globals.css`, `app/motion.css`, `tailwind.config.ts`, `app/sitemap.ts`; `ResourceArticleBody`, `ScrollReveal`, `ShareButton`, `SeoJsonLd`, `Footer`, and `Logo`; Supabase server/public helpers; and tests including sitemap and public-pagination coverage. The Phase 1 migration defines editorial identities, categories, articles, article-category relationships, revisions, and four public projection views [5]–[12]. The source tree is the basis for this inspection; no claim is made about uncommitted local work.

## 3. Design principles

### Editorial before interface

Every visible element should help a student understand a question, judge relevance, or choose a next step. Prefer a composed editorial section to a grid of interchangeable product cards. Labels, numbering, and rules should create rhythm without becoming decoration.

### Clear, useful, and honest

The prototype’s editorial principle is “Clarity is a form of access.” Production content must distinguish confirmed facts from advice, avoid invented deadlines or eligibility claims, and use real article data. Empty, unavailable, and not-yet-approved states must say what is actually true.

### Scholars remains the destination for matching

The Resource Center is a discovery and preparation layer. Its main product CTA should lead to the public Scholars opportunity experience, not imply that reading alone creates a match. Use “Explore opportunities” or equivalent only where the destination is verified.

### Mobile is a first-class composition

Do not shrink a desktop canvas. Sections must recompose at 320–430px, with wrapped navigation, stacked metadata, fluid media, touch-sized controls, and no horizontal overflow. Tablet and desktop can add columns only where they improve scanning and reading.

### Motion supports comprehension

Use native scrolling. Animate only feedback, hierarchy, or spatial continuity. Prefer opacity and transforms, never scroll hijacking or layout animation for ordinary reveals. Every motion has a reduced-motion alternative.

## 4. Brand and visual tokens

Use the existing Scholars brand tokens as the source of truth and add only Resource Center semantic aliases where needed.

| Token | Value / recommendation | Use |
|---|---|---|
| Navy | `#0B1E3D` | Headlines, structural rules, primary actions |
| Parchment | `#F7F5EF` | Page background and reading canvas |
| Emerald | `#15705A` | Eyebrows, links, focus ring, positive editorial accent |
| Amber | `#966216` | “Field guide”, review, or attention labels; never sole status signal |
| Muted red | `#A63A35` | Errors or caution only, with text/icon support |
| Warm neutral | `#E4E1D8` | Hairlines, quiet fills, dividers |
| White | Existing white surface | Masthead, article header, cards where contrast is needed |
| Ink / navy-light | Existing repository aliases | Body text and secondary metadata |

The visual hierarchy should rely on contrast, type scale, whitespace, and rules rather than shadows. Use borders at one pixel with the existing hairline token. Rounded corners should be restrained: use the existing small “seal” treatment for chips and controls, and reserve larger radii for bounded panels or future dialogs. Do not introduce gradients, glass panels, neon colours, or a new brand palette.

### Typography

Use the existing local `Fraunces` variable font for display headings and `Manrope` for body, navigation, labels, metadata, and controls. The root layout already loads both locally through `next/font/local` [7]. Recommended semantic scale:

- Display hero: Fraunces, 56–72px desktop, 42–52px tablet, 38–44px mobile; weight 600–700; line-height 0.98–1.05.
- Page title: Fraunces, 48–64px desktop, 38–48px tablet, 36–42px mobile; line-height 1.02–1.08.
- Article title: Fraunces, clamp from 40px mobile to 72px desktop; line-height 1.02–1.08; allow natural wrapping.
- Section title: Fraunces, 32–44px; line-height 1.08–1.15.
- Card title: Fraunces, 22–30px; line-height 1.1–1.2.
- Body: Manrope, 16–18px; line-height 1.65–1.8.
- Article body: Manrope, 18px desktop and 17px mobile; line-height 1.75; measure 65–75 characters per line.
- Labels: Manrope or existing mono utility, 10–12px uppercase, letter-spacing 0.14–0.18em.
- Metadata: Manrope, 12–14px; line-height 1.4.

Avoid setting all headings to a fixed width. Use `max-width` values that preserve the intended measure while allowing wrapping at 320px. Do not use text as an image.

## 5. Layout and spacing system

Use the existing centered container approach. Recommended aliases are `--rc-content-max: 72rem`, `--rc-reading-max: 46rem`, and `--rc-gutter: clamp(1rem, 3vw, 3rem)`. The article body target is 65–75 characters per line, approximately 42–48rem depending on type metrics. The article page should use a wider shell around that reading column so the desktop view feels intentional rather than like a mobile column stretched onto a large screen.

Use a four-point base rhythm, with common section spacing of 48px mobile, 72px tablet, and 104–128px desktop. Card/grid gaps are 16–24px. Header and footer padding should be generous but not consume the first viewport. Keep all media and grids inside `minmax(0, 1fr)` tracks; never combine fixed content widths with unbounded labels.

At 320–430px, use 16–20px page gutters, stack hero actions, wrap or horizontally scroll only explicitly labelled chip lists, and keep the scrollbar/overflow local to the chip list rather than hiding document overflow. At 768px, allow two-column editorial arrangements. At 1024px and above, use the full editorial grid with a max-width container. At 1280–1440px, increase whitespace and image scale, not body line length.

## 6. Component inventory and reuse strategy

Reuse the verified `Logo`, `Footer`, `Breadcrumbs`/`SeoJsonLd`, `ResourceArticleBody`, `ScrollReveal`, and `ShareButton` where their current contracts meet this specification. Reuse existing global focus treatment, button press feedback, local fonts, Supabase server client, and public projection query approach. Existing resource route cards and category chips are starting points, but their current rounded-card presentation is not the final visual target.

Components that need to be designed or refined include `ResourceMasthead`, `ResourceMobileNav`, `EditorialEyebrow`, `FieldGuideLabel`, `FeaturedStory`, `EditorialDesk`, `SubjectNav`, `ResourceCard`, `GuideCard`, `OpportunityBridge`, `ReadingProgress`, `ArticleTableOfContents`, `ArticleCallout`, `ArticleShareRail`, `AuthorBio`, `RelatedArticles`, `ResourceEmptyState`, `ResourceErrorState`, and a future visual-only `EditorialWorkspaceShell`. These should be small, composable components rather than route-specific monoliths.

Do not create a CMS editor or dashboard write path in this phase. A visual shell may be documented for later, but no save, publish, approve, revision, or database action is approved.

## 7. Page specifications

### 7.1 Homepage — `/resources`

**Purpose and hierarchy.** Establish the publication’s point of view in one viewport, then offer several trustworthy ways to begin: featured story, subjects, practical guides, latest articles, and the Scholars next step. A visitor should understand that the center explains opportunities and applications, not merely lists them.

**Masthead.** Use the Scholars mark at left, a restrained primary nav for Discover, Scholarship Guides, Applications, Student Life, and Opportunities, and a clear “Explore Scholars” action. On mobile, collapse to a menu button with an accessible dialog or disclosure; do not let desktop links clip. Keep the masthead on parchment or white, with a navy bottom rule.

**Hero.** Use a two-part composition: editorial eyebrow and short “knowledge for the ambitious” framing above a large Fraunces headline on the left; editorial image or quiet image field on the right at desktop. At mobile, stack the image below the copy and place actions full width or in a two-row stack. Primary action is browse guides; secondary action is explore Scholars. Avoid invented statistics.

**Editorial desk.** Present one featured story with image, category, read time, title, summary, and a single clear read link. Beside or below it, show two to three smaller latest items. Every link must use its actual article slug. If no published article exists, show a truthful “first guides are being prepared” state using existing route behaviour.

**Subjects and practical library.** Use four editorial subject blocks such as Discover, Prepare, Build, and Thrive only when their corresponding real categories exist. Each block has a short explanatory line and route. The practical library is a three-item or responsive list of guides with category, read time, title, excerpt, and read action. Avoid displaying a card grid simply because it is easy to generate.

**Opportunity bridge and footer.** Use a navy or high-contrast section with a concise explanation that reading is a start and a profile-based Scholars match is the next step. Link to a verified public opportunity route. The footer should reuse the existing footer structure and include Resource Center, category links, and Scholars links without duplicating unavailable content.

**Motion.** Reveal major sections once as they enter the viewport with 6–12px upward translation and opacity, 320–380ms using the existing ease-out token. Do not stagger every card. Images may fade from a low-contrast placeholder to loaded state. At reduced motion, render all content immediately.

### 7.2 Article detail — `/resources/[slug]`

**Masthead.** Use breadcrumb, category label, field-guide identifier where available from real content, title, excerpt, author identity, published date, last-reviewed date when present, and read time. Keep the title readable at desktop without letting metadata create a long horizontal strip. On mobile stack metadata.

**Featured image.** Render only when `featured_image_path` resolves through the approved storage/public URL strategy. Use a stable aspect ratio and `object-fit: cover`; keep focal positioning configurable rather than hardcoded. If no image exists, use a quiet editorial surface rather than a broken or fabricated image.

**Reading body.** The article content is the primary experience. Keep the main column at approximately 65–75 characters per line. Use semantic headings generated from markdown, visible link styles, ordered and unordered lists, blockquotes, code only when content requires it, and callouts for practical warnings. Do not place author metadata in a narrow sidebar on mobile. Related content and the author block follow the article.

**Reading progress and contents.** A thin progress indicator may sit below the masthead or at the top edge of the viewport. It must be `aria-hidden` or paired with a text alternative and must not obscure content. A table of contents is appropriate for articles with enough headings; desktop can use a sticky side rail, while mobile uses a disclosure before the body. Anchor navigation must account for sticky header height.

**Share, bookmark, and CTA.** Reuse `ShareButton` if its current API is suitable. Sharing is lower priority than reading and must not displace the body. Bookmarking is not approved unless the product architecture and authenticated persistence are explicitly approved; otherwise omit it. End with a concise Scholars CTA and related articles based on actual category relationships or a safe latest-article fallback.

### 7.3 Category — `/resources/category/[slug]`

Use breadcrumb, category title, description, and a short editorial framing. Show a featured article only when a real published row exists. The listing must link each card to its own slug; the prototype’s repeated `/article` mock links are not acceptable for production. Cards should expose category, title, excerpt, author, date or read time where available, and a full-card or explicit-link target with keyboard focus.

Subject navigation should wrap at mobile or become a labelled local scroller; it must never force document width. Sorting is optional and should default to editorial recommendation or publication order. Do not add client-side sorting unless the data contract supports it. Pagination or load-more must preserve crawlable links and should be added only with a bounded query strategy; do not fetch unbounded rows into the page.

If a category exists with no published articles, use a clear empty state and offer adjacent categories. Do not show prototype sample counts. The category CTA should explain how Scholars can help a reader find opportunities that fit their profile.

### 7.4 Editorial dashboard — future visual reference only

The prototype dashboard uses a left or top workspace navigation, overview metrics, status filters, queue rows, calendar, standards checklist, content mix, and a “start a new draft” panel [4]. Preserve that information architecture for later: Overview, Content queue, Calendar, Editorial standards. Metrics should be labelled as live only when backed by approved queries; otherwise never expose sample values in production.

The future workspace should have explicit Draft, In review, Ready, Scheduled, Published, and Archived states only after their transition rules, reviewer permissions, audit logging, and revision semantics are approved. Responsive behaviour should use stacked queue rows, a scrollable calendar region, and a full-width form page or dialog that never exceeds the viewport. This section is not implementation approval.

### 7.5 Article editor — future visual reference only

The future editor can be structured as title, excerpt, markdown/rich-text body, article type, categories, featured image, author, reviewer, publication metadata, preview, and editorial feedback. It must show current state and unsaved changes clearly. Preview should be read-only and use the public article renderer. Do not implement fields, save actions, publishing, approval, or writes until security review resolves the admin boundary and state machine.

## 8. Responsive behaviour and overflow prevention

Test at 320, 360, 375, 390, 414, 430, 768, 1024, 1280, and 1440px. Root cause fixes are required for overflow: use fluid widths, `min-width: 0`, wrapping labels, bounded image dimensions, local chip scrollers, and viewport-aware dialog sizing. Do not use `overflow-x: hidden` as a substitute for fixing a wider child.

At mobile widths, navigation becomes a disclosure/dialog; controls remain at least 44px tall; article metadata wraps; hero actions stack; grid cards become a single column; category tabs wrap or scroll locally; sidebars move below content; and any modal uses `width: min(100% - 2rem, 42rem)` with a max-height and internal scroll. At tablet, use two columns selectively. At desktop, use the wide editorial frame around a bounded article body.

## 9. Motion and smooth scrolling specification

The repository already uses `scroll-behavior: auto`, compositor-friendly button press feedback, reduced-motion gates, `ScrollReveal`, and motion CSS [6]. Preserve native scrolling; do not add Lenis, Locomotive, GSAP, or another heavy dependency merely to imitate the prototype.

| Interaction | Trigger | Motion | Reduced motion |
|---|---|---|---|
| Button press | Pointer/touch activation | Existing 100–160ms scale/translate feedback | Colour/border only |
| Mobile nav | Open/close | Opacity plus 4–8px transform, 180–240ms | Instant state change |
| TOC disclosure | Toggle | 150–220ms opacity/transform; avoid height animation if it causes layout jank | Instant |
| Section reveal | First viewport entry | 6–12px translate and opacity, 320–380ms | Visible immediately |
| Image load | Image decode | Opacity 180–240ms; preserve reserved aspect ratio | Immediate |
| Anchor navigation | User activates link | Native smooth anchor only where supported; compensate sticky header | Instant jump |
| Share feedback | Copy/share success | Small text/icon state change, under 200ms | Immediate |

Never hijack scroll, block interaction during animation, rely on hover for essential information, use excessive parallax, or animate layout dimensions for ordinary content.

## 10. Accessibility requirements

Use `header`, `nav`, `main`, `article`, `aside`, `section`, and `footer` semantically. Maintain one meaningful `h1` per route and a logical heading order. All links must have descriptive accessible names. Mobile navigation and future dialogs require focus management, Escape handling, labelled controls, and `aria-expanded`/`aria-controls` where applicable. Keep visible focus rings; the existing global ring uses emerald [6].

Provide alt text from approved editorial content for meaningful images and empty alt for decorative images. Do not communicate status by colour alone. Ensure navy, emerald, amber, and muted red combinations meet WCAG AA for their text size. Article links must be distinguishable without hover. Reading progress needs a non-visual equivalent or should remain decorative. Respect `prefers-reduced-motion`. Future editor fields require visible labels, error associations, and unsaved-state announcements.

## 11. SEO and content presentation

Keep unique title and description metadata per article and category. Use canonical URLs from the article contract, never fabricate canonical values. Add `Article` JSON-LD with headline, description, author, publisher, datePublished, dateModified, and image only when real. Add `BreadcrumbList` JSON-LD that matches visible breadcrumbs. Use semantic article markup and crawlable `<a>` links, not click-only cards.

Internal links should connect related articles, categories, and the Scholars opportunity destination. Image dimensions, alt text, and stable aspect ratios are required. Publication and modification dates must come from approved fields. Resource routes must be included in sitemap generation, including active categories when category URLs are indexable; the implementation plan must inspect and correct the known omission of category routes without changing sitemap code in this planning phase. Do not expose drafts, future-scheduled rows, or unpublished authors through public metadata.

The current article route already emits canonical, Open Graph, `Article` JSON-LD, and public projection data. The current sitemap implementation reads published resource articles but, in the verified production state, omits `/resources` from static paths and does not generate category URLs. The implementation phase must address that known gap after deciding whether empty categories are indexable [8] [11] [13].

## 12. Data and architecture dependencies

Available through public projections: article ID, slug, title, excerpt, markdown content, article type, canonical URL, featured image path, read time, published date, last reviewed date, author name, bio, avatar path, active category identity, description, and display order [10]. The public routes already query these views with server-side Supabase access [8]–[10].

Representable without schema change: homepage/article/category content, author information, read time, category navigation, publication dates, canonical metadata, article body, related articles by category relation, and empty states. A featured flag, editorial “recommended” ordering, hero crop/focal point, newsletter subscription, bookmarks, per-article share analytics, and richer callout blocks are not present in the verified projection contract. Treat them as unresolved or omit them rather than inventing fields.

The base tables are explicitly protected from anonymous reads, while public roles select from fixed `security_barrier` projection views. The deployed views are owner-context views and do **not** use `security_invoker=true`; that is a material security distinction, not a naming detail. Their safety depends on explicit column lists and fixed publication predicates, so any future view change requires regression review. Do not bypass those views from the public frontend. CMS writes, reviewer workflows, and revision publishing remain blocked by the security boundary and must not be implemented as a convenience layer.

## 13. Performance requirements

Keep public pages server-rendered where possible. Query only needed projection columns and bound result sets. Avoid N+1 article/category queries; use bounded relation reads or an approved view/query shape. Reserve image dimensions to prevent layout shift, use responsive image sizes, and do not load below-fold media eagerly. Preserve `content-visibility` only where it does not break accessibility or measurement.

Targets for review: no unexpected horizontal overflow; Lighthouse Performance and Accessibility at least 90 on representative public pages where content permits; LCP under 2.5 seconds on a representative mobile profile; CLS under 0.1; INP under 200ms for primary interactions. These are acceptance targets, not permission to introduce a new analytics or optimisation dependency.

## 14. Implementation sequencing

1. Confirm the target Scholars branch and inspect current route/layout changes, token definitions, public view fields, storage URL handling, and current sitemap category behaviour.
2. Build/refine the shared Resource Center shell, navigation, footer integration, tokens, and responsive container.
3. Refine homepage composition using only published projection data and truthful empty/error states.
4. Refine category listing and slug-correct links, then add bounded pagination only if required by real volume.
5. Refine article reading experience, body rendering, progress/TOC, related content, metadata, and image treatment.
6. Complete accessibility, SEO, responsive, performance, and visual QA across every required viewport.
7. Run repository tests, type checking, production build, and route-level checks. Verify sitemap category coverage in the implementation phase.
8. Stop for review before any CMS authoring or workflow work. Security approval must precede editor/dashboard implementation.

## 15. Acceptance criteria

The public phase is acceptable only when all of the following are true: the four required public routes render with real projection data or truthful empty states; every article/category link resolves to its actual slug; the visual language matches the prototype without generic SaaS styling; article body measure is approximately 65–75 characters per line on desktop; all required viewport widths have no unintended document overflow; navigation, dialogs, focus, reduced motion, and keyboard paths work; images have reserved dimensions and correct alt behaviour; metadata and JSON-LD use real fields; public queries stay within approved projections; and no CMS write path or schema/security change is introduced.

## 16. Risks and unresolved decisions

The production source repository was inspected through its public GitHub tree and raw files, supplemented by the Updates handoff and post-deployment security clarification, rather than a local Scholars checkout. Before implementation, verify the exact branch and any unmerged changes. Confirm how `featured_image_path` becomes a browser URL and whether an approved public storage bucket exists. Decide whether category pages are indexable and add their sitemap entries only after that decision. Decide whether “featured” means newest, editorial order, or a future schema field. Confirm whether newsletters, bookmarks, search, analytics, and author avatars are in scope; omit them if their contracts are not approved. Resolve whether the owner-context projection model is explicitly accepted or replaced by the proposed invoker-context model, then resolve the CMS security review before exposing any authoring controls. Do not use prototype sample records, figures, dates, or article counts in production.

## References

[1]: https://resource-center.htmlhost.co/ "Scholars Resource Center prototype homepage"
[2]: https://resource-center.htmlhost.co/article "Scholars Resource Center prototype article page"
[3]: https://resource-center.htmlhost.co/category "Scholars Resource Center prototype category page"
[4]: https://resource-center.htmlhost.co/editorial-dashboard "Scholars Resource Center prototype editorial dashboard"
[5]: https://github.com/ImperioKDB/Scholars/blob/main/app/resources/page.tsx "Scholars Resource Center homepage route"
[6]: https://github.com/ImperioKDB/Scholars/blob/main/app/globals.css "Scholars global motion and accessibility styles"
[7]: https://github.com/ImperioKDB/Scholars/blob/main/app/layout.tsx "Scholars root layout and local fonts"
[8]: https://github.com/ImperioKDB/Scholars/blob/main/app/resources/%5Bslug%5D/page.tsx "Scholars Resource Center article route"
[9]: https://github.com/ImperioKDB/Scholars/blob/main/app/resources/category/%5Bslug%5D/page.tsx "Scholars Resource Center category route"
[10]: https://github.com/ImperioKDB/Scholars/blob/main/supabase/migrations/20261107130100_resource_center_schema.sql "Scholars Resource Center Phase 1 schema and public projections"
[11]: https://github.com/ImperioKDB/Scholars/blob/main/app/sitemap.ts "Scholars sitemap implementation"
[12]: https://github.com/ImperioKDB/Scholars/blob/main/package.json "Scholars dependencies and test scripts"
[13]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_RESOURCE_CENTER_POST_DEPLOYMENT_SECURITY_CLARIFICATION_2026-11-07.md "Resource Center post-deployment security clarification"
