# Scholars Implementation Report — Premium Frontend Engineering

**Product:** Scholars — Nigerian student scholarship platform  
**Repository (application):** ImperioKDB/Scholars  
**Repository (this report):** ImperioKDB/Updates → `SCHOLARS_FRONTEND_ENGINEERING/`  
**Governing skill:** `@premium-frontend-engineering` (Premium Frontend Engineering)  
**Status:** Design decisions and prioritised plan only — no application source code modified.

---

## Scope

This implementation report covers the advertisement landing experience and the complete first-time student journey:

1. Landing page (`/`) — first impression from paid ads.
2. Registration & authentication (`/login`, `/signup`, `/auth/callback`).
3. Student onboarding (`/onboarding`).
4. Dashboard (`/dashboard`).
5. Scholarship discovery & matching (`/discover`, `/opportunities`).
6. Scholarship cards (`components/ScholarshipCard.tsx`).
7. Mobile shell (`components/Sidebar.tsx`).

It does **not** cover admin surfaces, resource center, community, settings, or backend algorithms, which are out of scope for the advertisement-readiness objective.

---

## Phase 3 — Visual direction

### Established brand identity (preserved, not replaced)

- **Palette:** navy `#0B1E3D` (primary), parchment `#F7F5EF` (background), ink `#10151F` (body), emerald `#15705A` (verified/open/success), amber `#966216` (caution/deadlines), rose `#A63A35` (closed/ineligible), hairline `#E4E1D8` (borders).
- **Typography:** Fraunces (serif display) for editorial headings; Manrope (sans) for UI, body, and data labels. Manrope also mapped to mono for data labels (deliberate, documented).
- **Radius:** `rounded-seal` (9999px) reserved for primary brand CTAs; `rounded-xl`/`rounded-2xl` for cards and panels.
- **Elevation:** `shadow-card` subtle shadow; hairline borders.
- **Motion:** transform/opacity only; durations from `--motion-duration-*` tokens; `prefers-reduced-motion` overrides in `app/globals.css` and `app/motion.css`.

### Visual concept for the advertisement journey

**User problem:** A student clicks an ad and must, within seconds, understand what Scholars is, see relevant verified scholarships, and register with confidence — on any phone.

**Compositional purpose:** The landing page leads with the value proposition ("Apply to the scholarships you can actually win"), proves it with a live/verified catalogue strip, then explains "how it works" and social proof. Every CTA has a clear next step.

**Visual hierarchy:**
1. Hero `h1` (Fraunces display, navy) — what's noticed first.
2. Value strap and sub-copy (Manrope sans) — the "why".
3. Primary CTA "Build your free profile" (navy `rounded-seal`) — the conversion action.
4. Secondary "Log in" — for returning users.
5. Catalogue strip ("Open now") — proof of live supply.
6. "How it works" + testimonials + FAQ — trust and clarity.

**Typography roles:**
- `font-display` (Fraunces): hero `h1`, section headings on marketing pages only.
- `font-sans` (Manrope): body copy, form labels, data, UI chrome.
- Reading measure: body copy constrained to ~60–75 ch; hero uses `text-balance`.

**Surface, border, accent, image treatment:**
- Parchment background; white cards with hairline border + subtle shadow.
- Emerald for verified/open status; amber for deadlines/caution; rose for closed/ineligible.
- Provider monograms (circular, bounded) rather than unconstrained imagery.

**Layout rhythm & responsive recomposition:**
- Landing: `max-w-6xl` container; hero stacks on mobile, two-column (copy + catalogue) on `lg:`.
- Auth: two-column `AuthShell` on desktop; single-column centered card on mobile.
- Onboarding: single column; card padding reduced at 320–375px; step-0 actions stacked full-width on smallest breakpoint.
- Authenticated routes: named container width tier (replaces route-local `max-w-7xl`/`5xl`/`3xl`).

**Intentionally omitted (to avoid generic SaaS aesthetics):**
- No purple gradients, no neon, no glassmorphism on content, no gratuitous rounded rectangles on every surface, no autoplay carousels, no decorative motion, no dashboard-card default pattern.

---

## Phase 4 — Implementation plan (recommendations, not yet applied)

No application source files were created, modified, or removed. The following is the approved plan, prioritised P0–P3.

### P0 — Advertisement conversion leaks (do first)

| # | Improvement | Files | Status |
|---|-------------|-------|--------|
| P0-1 | Preserve & validate same-origin `next` return path through password login, Google OAuth, and signup; fall back to `/dashboard` only when absent/unsafe. Make landing catalogue deep-links survive auth. | `middleware.ts`, `app/(auth)/login/page.tsx`, `app/(auth)/signup/page.tsx`, `app/auth/callback/route.ts`, `lib/auth/return-destination.ts`, `lib/validate.ts` | Not implemented |
| P0-2 | Keep Log in visible beside signup in mobile landing header; group auth actions clearly on small screens. | `app/page.tsx` | Not implemented (Log in already rendered on mobile; residual grouping polish) |
| P0-3 | Stack onboarding step-0 actions full-width at 320–375px; reduce card padding at smallest breakpoint (`p-4 sm:p-5`). | `app/onboarding/page.tsx` | Not implemented |
| P0-4 | Add inline retry on failed onboarding saves (profile / WAEC); keep draft; never navigate or clear draft unless save acknowledged. Distinguish profile vs WAEC errors. | `app/onboarding/page.tsx` | Not implemented |

### P1 — Accessibility contracts

| # | Improvement | Files | Status |
|---|-------------|-------|--------|
| P1-1 | Unmount or `inert`+`display:none` the closed mobile drawer; capture focus on open (close/panel), restore focus to trigger on close. | `components/Sidebar.tsx` | Not implemented |
| P1-2 | Labelled confirmation dialog (`aria-labelledby`/`aria-describedby`); capture opener; restore focus on close; shared scroll-lock + Escape pattern. | `components/ConfirmDialog.tsx` | Not implemented |
| P1-3 | Gate `animate-spin`, smooth scrolling, confetti, and drawer transforms under `prefers-reduced-motion: reduce`; static progress/success cues. | `app/globals.css`, `app/page.tsx`, `app/(auth)/login/page.tsx`, `app/onboarding/page.tsx`, `components/Confetti.tsx`, `components/Sidebar.tsx` | Not implemented |
| P1-4 | Verify combobox `aria-activedescendant` tracks highlighted option; listbox labelled via `aria-labelledby`; confirm FormField `htmlFor`↔input id contract end-to-end. | `components/FormField.tsx`, `components/Combobox.tsx` | Not implemented |
| P1-5 | Add `aria-current="step"` + "Step n of 5" text to StepIndicator. | `components/StepIndicator.tsx` | Not implemented |
| P1-6 | Explicit labels + `aria-describedby` for report form (select + textarea) and DraftPanel personal-statement textarea/character counter. | `components/ReportScholarshipButton.tsx`, `components/DraftPanel.tsx` | Not implemented |
| P1-7 | `<fieldset>`/`<legend>` or enhanced radio-group semantics for financial-need and disability binary choices. | `app/onboarding/page.tsx` | Not implemented |

### P2 — Visual-system consistency

| # | Improvement | Files | Status |
|---|-------------|-------|--------|
| P2-1 | Define named container-width tiers (wide/catalogue/reading); apply via shared shell/container component across dashboard/discover/opportunities/scholarships. | `app/dashboard/layout.tsx`, `app/discover/layout.tsx`, `app/opportunities/layout.tsx`, `app/scholarships/layout.tsx` | Not implemented |
| P2-2 | Extract shared catalogue filter recipe (radius, height, padding, focus, elevation). | `app/discover/DiscoverClient.tsx`, `app/opportunities/OpportunitiesClient.tsx` | Not implemented |
| P2-3 | Reserve `rounded-seal` for primary/brand CTAs; medium-radius buttons for routine actions; underlined/inline for low-priority navigation. | All CTA call sites | Not implemented |
| P2-4 | Scope Fraunces to editorial/marketing sections; sans display for product UI headings. Document the intentional split. | `app/layout.tsx`, `tailwind.config.ts` | Not implemented |
| P2-5 | Add Discover to mobile bottom tabs; prefix/section matching for active state; consistent detail/list active treatment. | `components/Sidebar.tsx` | Not implemented |
| P2-6 | Compact admin drawer/menu below `md`; `min-h-[44px] min-w-[44px]` for admin toggles and mobile actions. | `app/admin/layout.tsx`, `components/Sidebar.tsx` | Not implemented |

### P3 — Engagement (post-launch)

| # | Improvement | Files | Status |
|---|-------------|-------|--------|
| P3-1 | Saved section: detail link, unsave, track action, deadline context. | `app/applications/ApplicationsClient.tsx` | Not implemented |
| P3-2 | Rejection → discover filter handoff: initialise `discipline` from `?discipline=` search param. | `app/applications/ApplicationsClient.tsx`, `app/discover/DiscoverClient.tsx` | Not implemented |
| P3-3 | Surface saved-query errors separately with retry + unavailable state (don't equate failure with empty list). | `app/applications/page.tsx` | Not implemented |

---

## Design and UX improvements implemented

**None.** No application source code was changed as part of this reporting task. All improvements above are recommendations awaiting explicit authorisation before implementation.

The Premium Frontend Engineering skill was applied as follows:
- **Step 1 (Understand):** Inspected routes, components, design tokens, middleware, auth, onboarding, dashboard, discovery, cards, mobile shell, and product/growth docs. Verified the prior `FRONTEND_AUDIT_REPORT.md` against actual source — confirmed some findings, corrected two overstated findings (F2 mobile login, F3 write safety), and identified residual gaps.
- **Step 2 (Visual direction):** Documented above; respects the established navy/parchment/emerald brand and Fraunces/Manrope typography; omits generic SaaS aesthetics.
- **Step 3 (Design system):** Existing tokens listed as source of truth; no new raw values introduced; aliases recommended before new values.
- **Steps 4–10:** Page/state architecture, interaction contracts, responsive breakpoints, accessibility/SEO, optimisation, safety boundaries, and senior review checklist all applied to the audit and recommendations (see FRONTEND_AUDIT.md and TEST_RESULTS.md).

---

## Files created, modified, or removed

**In the Scholars application (ImperioKDB/Scholars):**
- Created: none.
- Modified: none.
- Removed: none.

**In the Updates repository (ImperioKDB/Updates):**
- Created: `SCHOLARS_FRONTEND_ENGINEERING/README.md`, `FRONTEND_AUDIT.md`, `IMPLEMENTATION_REPORT.md`, `TEST_RESULTS.md` (this publication).
- Modified: none.
- Removed: none.

No unrelated systems (auth, data, security, deployment, product) were touched.

---

## Safety boundaries honoured

- No production database schema changes.
- No Supabase authentication behaviour changes.
- No scholarship matching / eligibility algorithm changes.
- No security controls bypassed.
- No unapproved backend contracts created.
- No privileged data or write actions moved to the browser.
- No migration, permission, publication, payment, or external-action behaviour created from a visual request.
- Nothing deployed to production; no merge performed.
