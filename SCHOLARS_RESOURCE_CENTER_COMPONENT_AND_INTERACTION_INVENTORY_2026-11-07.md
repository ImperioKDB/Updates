# SCHOLARS RESOURCE CENTER — COMPONENT AND INTERACTION INVENTORY

**Prepared:** 2026-11-07  
**Scope:** Public Resource Center design and future visual references only. No CMS writes are approved.

The inventory below distinguishes verified reusable code from components that need to be refined or created. “Existing” means verified in the Scholars source tree; it does not mean the component already matches the target visual system.

| Component | Purpose | Existing or new | Reusability | Desktop behaviour | Mobile behaviour | Interaction states | Accessibility | Data dependencies |
|---|---|---|---|---|---|---|---|---|
| `ResourceMasthead` | Publication identity and primary navigation | New/refine | All public routes | Inline logo, nav, Scholars CTA | Collapsed menu/disclosure; no clipped links | Default, focus, open, active route | Semantic nav, labelled menu, `aria-expanded`, focus management | Static labels and route links |
| `ResourceMobileNav` | Accessible mobile navigation | New | Resource Center | Not rendered | Viewport-safe panel or disclosure | Closed, open, Escape, outside close | Keyboard trap only when modal; Escape; focus return | Static labels |
| `Breadcrumbs` | Orientation and SEO-visible hierarchy | Existing via `SeoJsonLd` | Article/category/home | Inline breadcrumb | Wraps or compact stack | Links, current page | `nav` label, current page, visible focus | Route and article/category names |
| `EditorialEyebrow` | Small editorial context label | New/refine | All pages | Uppercase label with tracking | Same, wraps naturally | Static | Not colour-only; readable contrast | Static or article type/category |
| `FieldGuideLabel` | Numbered publication framing | New | Home/article/category | Compact label such as field guide / issue | Wraps; never fixed width | Static | Text remains meaningful without styling | Static or approved content metadata |
| `FeaturedStory` | Prominent article entry | New/refine | Home/category | Image + copy in editorial split | Stacked image and copy | Hover/focus/pressed/link loading | Whole card link or clear link; alt text | Published article projection |
| `EditorialDesk` | Curated set of latest/selected stories | New | Home | One lead plus secondary list | Stacked list | Hover/focus; no hover-only content | Heading and list semantics | Published article rows; selection policy unresolved |
| `SubjectNav` | Category discovery | Existing category-chip pattern; refine | Home/category | Inline/wrapped subjects | Wrapped or local horizontal scroller | Active, focus, selected route | Labelled nav; scrollable region announced | Public category projection |
| `ResourceCard` | Standard article listing | Existing route pattern; refine | Home/category/related | Bounded grid/list card | Single-column stack | Hover, focus, pressed | Actual slug link; visible focus; image alt | Published article projection |
| `GuideCard` | Practical guide with read-time framing | New/refine | Home/category | Editorial list item | Stacked list item | Hover/focus | Heading/link relationship | Article title, excerpt, category, read time |
| `OpportunityBridge` | Connect reading to Scholars matching | New | Home/article/category | High-contrast editorial CTA | Stacked copy and button | Default, hover, focus, pressed | Descriptive destination; no misleading promise | Verified public Scholars route |
| `Footer` | Cross-site navigation and brand close | Existing; reuse/refine | All public routes | Multi-column footer | Stacked groups | Link focus | Landmark, heading hierarchy | Existing links; verify route validity |
| `ResourceArticleHeader` | Article title, metadata, summary | New/refine | Article | Wide header around bounded reading column | Stacked metadata | Static and link states | One `h1`; `time`; author name | Article projection |
| `FeaturedImage` | Stable editorial image treatment | New/refine | Article/cards | Reserved aspect ratio and crop | Fluid width, same ratio | Loading, loaded, missing | Real alt text or empty decorative alt | `featured_image_path`; URL strategy unresolved |
| `ReadingProgress` | Non-intrusive article progress | New | Article | Thin fixed/inline indicator | Same, never obscures content | Scroll update, complete | Decorative or text alternative; no colour-only meaning | Article scroll container |
| `ArticleTableOfContents` | Jump navigation for long articles | New | Article | Sticky side rail when useful | Labelled disclosure before body | Closed/open, active heading | Button semantics, anchor focus, sticky offset | Parsed article headings |
| `ResourceArticleBody` | Render markdown article content | Existing; verify/refine | Article | 65–75 character measure | 17px comfortable measure | Link, quote, list, callout | Semantic HTML, link distinction, heading order | `content_markdown` |
| `ArticleCallout` | Practical warning or note | New/refine | Article body | Bounded inset panel | Full width within body | Static | Icon not sole signal; text label | Requires supported content representation; otherwise omit |
| `ArticleShareRail` | Share article | Existing `ShareButton`; compose | Article | Inline/side rail, low priority | Inline below header/end | Idle, sharing, success, error | Accessible label and status | Canonical URL/title; Share API capability |
| `AuthorBio` | Author identity and trust | Existing data; new presentation | Article | Sidebar or end-of-article block | Below article | Static, avatar fallback | Real name/bio; alt handling | Author projection fields |
| `RelatedArticles` | Continue reading | New | Article | Three-item editorial row | Stacked list | Hover/focus | Real slugs and headings | Article-category relation or bounded fallback |
| `ResourceEmptyState` | Honest no-content state | New/refine | Home/category | Quiet bounded panel | Full-width stack | CTA focus | Clear status text and next action | Row count/category |
| `ResourceErrorState` | Safe fetch failure state | New | All public routes | Editorially styled message | Same | Retry/link focus | No sensitive error detail | Server error boundary |
| `EditorialWorkspaceShell` | Future dashboard visual frame | New, future only | Future admin | Navigation, queue, metrics, calendar | Stacked/scroll-safe | Tabs, filters, empty states | Future focus and table/list semantics | Admin contracts unresolved |
| `EditorialQueueRow` | Future workflow record | New, future only | Future admin | Status, title, owner, updated date | Stacked row | Filter, selection | Status text + icon; not colour-only | Workflow/security unresolved |
| `EditorialCalendar` | Future planning view | New, future only | Future admin | Calendar with milestones | Scrollable local calendar or agenda | Date selection | Keyboard date navigation | Scheduling data unresolved |
| `EditorialStandardsPanel` | Future checklist | New, future only | Future admin/editor | Checklist beside queue | Stacked panel | Incomplete/complete | Native checkbox semantics | Review policy unresolved |
| `ArticleEditorShell` | Future visual editor reference | New, blocked | Future admin | Form + preview | Full page preferred over fixed modal | Dirty, preview, validation | Labels, errors, focus, unsaved warning | Write/security/schema decisions unresolved |

## Interaction rules

Use the existing 100–160ms button press treatment and visible emerald focus ring. Navigation drawers and disclosures should remain below 250ms; ordinary reveals 320–380ms; no animation should block a click or keyboard action. Anchor navigation must not hide the heading under a sticky header. Hover is enhancement only; every essential action works by keyboard and touch.

All lists must support loading, empty, and error states. Loading should reserve image and card geometry. Empty states must not display prototype sample records or fabricated counts. Errors should be useful to readers without exposing Supabase details. Any future admin state must use text and icon in addition to colour.

## Data contract boundary

Public components may consume only the verified projection fields: article identity, title, excerpt, markdown content, article type, canonical URL, image path, read time, publication and review dates, author identity fields, category identity, description, and display order. “Featured”, “recommended”, newsletter, bookmark, analytics, and editor-specific fields are not part of the verified public contract and must be omitted or explicitly approved later.

## References

[1]: https://resource-center.htmlhost.co/ "Scholars Resource Center prototype"
[2]: https://github.com/ImperioKDB/Scholars/blob/main/components/ResourceArticleBody.tsx "Existing article body component"
[3]: https://github.com/ImperioKDB/Scholars/blob/main/components/ScrollReveal.tsx "Existing reveal component"
[4]: https://github.com/ImperioKDB/Scholars/blob/main/components/ShareButton.tsx "Existing share component"
[5]: https://github.com/ImperioKDB/Scholars/blob/main/components/Footer.tsx "Existing footer component"
[6]: https://github.com/ImperioKDB/Scholars/blob/main/supabase/migrations/20261107130100_resource_center_schema.sql "Public Resource Center data projections"
