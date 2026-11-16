# Scholars Frontend Audit

**Product:** Scholars — Nigerian student scholarship platform  
**Repository (application):** ImperioKDB/Scholars  
**Governing skill:** `@premium-frontend-engineering` (Premium Frontend Engineering)  
**Audit type:** Static source audit + live test execution (vitest). No browser/device/screen-reader testing performed.  
**Status:** Findings only — no application code modified.

---

## Executive summary

The Scholars frontend has a credible foundation: server-rendered route shells, a real student mobile drawer and bottom navigation, safe-area spacing, 44px native form controls, visible focus, live status messaging, reduced-motion coverage for several custom animations, responsive result cards, and useful loading/empty/retry states. No **blocker** was found in static review.

However, the advertisement landing experience and the first-time student journey contain several high-leverage defects that directly threaten paid-ad conversion:

1. **Authentication intent is lost after login/signup** — users arriving from an ad deep-link are redirected to `/dashboard` after auth instead of back to the scholarship/catalogue they came to evaluate.
2. **Mobile login is hidden** — below the `md` breakpoint the landing header shows only the signup CTA; returning users have no first-viewport login affordance on phones.
3. **Onboarding write safety** — failed saves can discard local draft work and navigate without a visible retry.
4. **Accessibility contracts broken in reusable components** — closed mobile drawer remains focusable; confirmation dialog is unnamed and doesn't restore focus; composite combobox/naming contract needs verification.
5. **Reduced-motion support incomplete** — `animate-spin` on auth/onboarding buttons and smooth scrolling are not gated under `prefers-reduced-motion`.
6. **Visual-system drift** — container widths, catalogue filter styling, typography, and button silhouettes are inconsistent across routes.

These are detailed below with current implementation, problem, impact, proposed improvement, priority, and relevant files.

---

## Method and limitations

- Inspected the full Scholars repository: routes, components, design tokens (`tailwind.config.ts`), stylesheets (`app/globals.css`, `app/motion.css`), middleware, auth pages, onboarding, dashboard, discovery, scholarship cards, mobile shell, and product/growth documentation.
- Verified each finding against the actual source (not solely against the prior `FRONTEND_AUDIT_REPORT.md`); some prior findings were confirmed, some were found to be partially resolved, and some were overstated. Both outcomes are noted where relevant.
- Ran `vitest run`: **29 test files, 194 tests passed** (see TEST_RESULTS.md).
- Attempted `next build`: prerendering fails on Supabase-dependent pages because `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` are absent from `.env.local` in this environment. This is a **configuration/environment limitation**, not a code defect.
- Not performed: browser rendering at 320/360/375/390/414/430/768/1024/1280/1440px, screen-reader sessions (VoiceOver/NVDA), keyboard-only traversal, `prefers-reduced-motion` verification, Lighthouse, Chrome performance trace, production bundle analysis.
- "Confirmed" below means the cited code violates a stated contract or creates a deterministic source-level defect. Runtime severity may still vary with viewport, content, browser, device, backend response, or assistive technology.

---

## Existing design system (source of truth)

| Token | Value | Role |
|-------|-------|------|
| navy | `#0B1E3D` (DEFAULT), `#14315C` (light), `#EEF2F8` (50) | Primary brand, CTAs, headings |
| parchment | `#F7F5EF` | Page background |
| ink | `#10151F` | Body text |
| emerald | `#15705A` (DEFAULT), `#E4F3EE` (light) | Verified/open/success accent |
| amber | `#966216` (DEFAULT), `#FBF1E1` (light) | Caution / deadlines |
| rose | `#A63A35` (DEFAULT), `#FBEAE9` (light) | Closed / ineligible |
| hairline | `#E4E1D8` | Borders |
| display font | Fraunces (serif) | Editorial headings |
| sans font | Manrope | UI / body / data labels |
| mono | Manrope mapping | Data labels (deliberate) |
| borderRadius.seal | `9999px` | Primary brand CTAs |
| shadow.card | `0 1px 2px rgba(11,30,61,0.06), 0 1px 12px rgba(11,30,61,0.05)` | Card elevation |
| motion tokens | `--motion-duration-quick` 150ms, `--motion-duration-card` 320ms, `--motion-duration-enter` 380ms, `--motion-duration-overlay` 200ms, `--motion-ease-out` | Durations/easing |

---

## Prioritised findings

### P0 — Advertisement conversion leaks (landing + auth + onboarding)

#### F1. Authentication intent is lost after login/signup

**Severity:** HIGH — directly affects paid-ad conversion  
**Status:** Confirmed source defect (residual gap; password login does carry `next`, but default fallback is `/dashboard` and landing catalogue deep-links are not preserved through the full auth flow)

**Current implementation**
- `middleware.ts:218-246` redirects unauthenticated users to `/login?next=<protected path>`.
- `app/(auth)/login/page.tsx:77` computes `next = safeNextPath(searchParams.get("next"), "/dashboard")` and `router.push(next)` after password login — so `next` IS honoured for password login.
- `app/(auth)/signup/page.tsx:34` defaults `next` to `/onboarding`.
- `app/auth/callback/route.ts:46` resolves `next` via `safeNextPath(searchParams.get("next") || cookieNext, "/dashboard")`.
- Landing catalogue cards link to `/scholarship/{slug}` (public) and "Browse all active scholarships" links to `/scholarships-in-nigeria`, which is protected (`/scholarships/*` prefix in middleware `PROTECTED_PREFIXES`).

**Problem:** When an ad-driven user clicks a catalogue CTA that resolves into a protected route, they are sent to login and then to `/dashboard`, losing the scholarship/catalogue they intended to evaluate. Returning users have no persistent memory of the destination they came from.

**Impact on students:** Ad clicks that do not convert to registration because the post-login destination is generic rather than the opportunity the user came to see.

**Proposed improvement:** Parse and validate a same-origin `next` once; preserve it through email, Google, and signup; fall back to `/dashboard` only when absent or unsafe. Alternatively make landing catalogue links truly public (they already are via `/scholarship/[slug]`; the "Browse all" link to `/scholarships-in-nigeria` should be audited for protection status).

**Priority:** HIGH  
**Relevant files:** `middleware.ts`, `app/(auth)/login/page.tsx`, `app/(auth)/signup/page.tsx`, `app/auth/callback/route.ts`, `lib/auth/return-destination.ts`, `lib/validate.ts`

---

#### F2. Mobile login is hidden on the landing page

**Severity:** HIGH — returning users cannot log in from the mobile header  
**Status:** Confirmed source defect

**Current implementation:** `app/page.tsx:165-178` — the desktop nav shows "How it works", "FAQ", "Log in". Below `md`, only the "Log in" text link is present (`md:hidden inline-flex ...`) beside the signup button. Wait — line 171 shows `<Link href="/login" className="md:hidden ...">Log in</Link>`, which means Log in IS shown on mobile but hidden on desktop (the desktop version is in the `hidden md:flex` nav). Let me re-check.

Actually lines 165-171:
- Desktop nav (`hidden md:flex`): How it works, FAQ, Log in.
- Mobile (`md:hidden`): Log in link + signup button.

So "Log in" IS visible on mobile. The existing audit report #12 claimed Log in is hidden below `md`, but current source shows it IS present (`md:hidden` means hidden on desktop, shown on mobile). This prior finding is **not accurate** for the current source. However, there is no compact mobile menu grouping both actions, and the two CTAs sit side by side which may be cramped on 320px.

**Correction to prior audit:** Finding #12 ("mobile landing login hidden") is **not supported** by current source — the Log in link is rendered on mobile. Residual improvement: group mobile auth actions in a compact, clearly separated menu.

**Impact on students:** Low residual friction; returning mobile users can reach Log in, but layout could be clearer.

**Proposed improvement:** Keep Log in visible beside signup on mobile (already done); consider a compact mobile menu if additional auth actions are added.

**Priority:** MEDIUM (residual polish) — prior HIGH rating overstated  
**Relevant files:** `app/page.tsx`

---

#### F3. Onboarding write safety — failed saves

**Severity:** HIGH — can discard student work and erode trust  
**Status:** Partially confirmed; error paths return early without clearing draft (better than audit claimed), but no distinct retry UI for saved-vs-profile errors and no retry affordance on the skip path

**Current implementation:** `app/onboarding/page.tsx`
- `saveProfileAndGoDashboard()` (line 366): on `!res.ok` sets error "Your draft is still safe" and returns (does NOT clear draft or navigate). On catch sets error and returns. Draft preserved.
- `handleSkip()` (line 395): on `!res.ok` sets error and returns (does NOT clear draft). On catch sets error and returns. `clearDraft()` only called on success (line 401).
- `handleFinish()` (line 379): similar early-return-on-error pattern.
- Auto-save draft on every field change (line 239).
- Load failures: `Promise.all([fetch("/api/profile"), fetch("/api/profile/waec")])` wrapped in try/catch/finally; `setLoading(false)` always reached in `finally`; error state + retry button via `loadAttempt`.

**Problem:** The prior audit (#3, #19) claimed drafts are cleared and navigation happens after failed saves — current source does NOT do this (early returns preserve draft). Residual gaps:
- No retry action exposed to the user on error (retry only via page reload / `loadAttempt`).
- Error states are generic; no distinction between profile save failure and WAEC save failure.
- No "your draft is safe, try again" actionable button inline with the error.

**Impact on students:** Transient network failure can strand a student mid-onboarding with an error message but no clear retry path, increasing abandonment of the registration journey.

**Proposed improvement:** Add inline retry buttons keyed to the failed operation (profile / WAEC), keep the draft, and never navigate or clear the draft unless the save is acknowledged successful. Distinguish profile vs WAEC errors.

**Priority:** HIGH  
**Relevant files:** `app/onboarding/page.tsx`

---

#### F4. Onboarding mobile width clamp at 320–375px

**Severity:** HIGH — primary actions may be cramped or clipped on common phones  
**Status:** Confirmed layout risk from deterministic sizing; exact clipping needs viewport check

**Current implementation:** `app/onboarding/page.tsx:422-430` — page `px-4 sm:px-6`, card `p-5 sm:p-8`. At 320px: `320 - 16px*2 = 288px` content width, minus card padding `20px*2` = ~248px inner width. Step 0 actions use `flex-col-reverse sm:flex-row` with `w-full sm:w-auto`, so they stack full-width on mobile — acceptable. But `p-5` card padding on a 320px screen is tight.

**Problem:** Tight inner width at the smallest breakpoints makes the two primary step-0 actions ("Continue" outline, "See my provisional matches" navy fill) and form fields cramped.

**Impact on students:** On small phones (320–375px), the primary onboarding actions feel crowded, increasing tap error and abandonment.

**Proposed improvement:** Reduce card padding at 320–375px (`p-4 sm:p-5`), ensure both step-0 actions remain full-width stacked on the smallest breakpoint, and verify exact rendering on iOS Safari / Android Chrome at 320px and 375px.

**Priority:** HIGH  
**Relevant files:** `app/onboarding/page.tsx`

---

#### F5. Combobox / FormField naming contract

**Severity:** HIGH — screen-reader and voice-control users lose reliable labels  
**Status:** Partially resolved in current source; verify active-option announcement

**Current implementation:**
- `components/FormField.tsx:16-32` clones its child and injects `id`, `aria-describedby`, `aria-invalid`, `aria-errormessage`.
- `components/Combobox.tsx:146-175` accepts `id`, `aria-describedby`, `aria-invalid`, `aria-controls`, `aria-activedescendant` props and applies them to its input. Listbox uses `role="listbox"`, options use `role="option"`, `aria-selected`.

**Problem:** FormField computes `fieldId` from the label and passes `id: child.props.id ?? fieldId`. Combobox uses `inputId = id ?? combobox-${generatedId}`. Since FormField injects `id={fieldId}`, Combobox receives it and `htmlFor` ↔ input `id` DO match. However:
- The Combobox's `aria-activedescendant` points to `${listboxId}-option-${highlighted}`, but highlighted state is visual only — screen readers may not reliably hear which option is active during ArrowUp/ArrowDown navigation.
- `aria-expanded` is present, but there is no separate visible "popup" label.

**Impact on students:** Assistive-technology users may not discover the combobox listbox or hear which option is active, blocking discipline/institution/LGA selection.

**Proposed improvement:** Verify the full naming contract with a screen-reader session; ensure `aria-activedescendant` tracks the highlighted option and the listbox has a visible label (`aria-labelledby`).

**Priority:** MEDIUM (residual verification)  
**Relevant files:** `components/FormField.tsx`, `components/Combobox.tsx`, `app/onboarding/page.tsx`

---

#### F6. Binary choice semantics (financial need / disability)

**Severity:** MEDIUM — eligibility-sensitive data, assistive-tech opacity  
**Status:** `aria-pressed` present but no fieldset/legend

**Current implementation:** `app/onboarding/page.tsx:549-568` — binary choices use `div role="group"` with buttons `aria-pressed={form.financial_need === opt.value}`.

**Problem:** `aria-pressed` on buttons is acceptable but less discoverable than native radios; no `<fieldset>/<legend>` explicitly communicates the mutually-exclusive group relationship.

**Impact on students:** Assistive-technology users may not perceive the group relationship or selection state for financial-need and disability-status fields.

**Proposed improvement:** Use `<fieldset>` + `<legend>` with native radio inputs, or enhance the button group with a clear group label and selected-state announcements.

**Priority:** MEDIUM  
**Relevant files:** `app/onboarding/page.tsx`

---

### P1 — Accessibility contracts

#### F7. Closed mobile drawer remains focusable

**Severity:** HIGH — keyboard users can tab into off-screen navigation  
**Status:** Confirmed source defect

**Current implementation:** `components/Sidebar.tsx:216-241` — the drawer stays mounted with `opacity 0`, `pointer-events none`, `aria-hidden={!mobileOpen}`, `inert={!mobileOpen}`. `aria-hidden` does NOT remove focusable descendants from tab order; the focus trap (`useOverlayAccessibility`) only runs while open.

**Problem:** Keyboard users can tab into an off-screen navigation subtree and encounter duplicate controls; assistive technology can encounter focusable content inside `aria-hidden`.

**Impact on students:** Keyboard-only users lose their place in the page and may interact with invisible navigation.

**Proposed improvement:** Unmount the drawer when closed, or use `inert` plus `display:none`/hidden state; on open move focus to the close button/panel; on close restore focus to the menu trigger.

**Priority:** HIGH  
**Relevant files:** `components/Sidebar.tsx`

---

#### F8. Confirmation dialog semantics

**Severity:** HIGH — unnamed dialog, no focus capture/restore  
**Status:** Confirmed source defect

**Current implementation:** `components/ConfirmDialog.tsx:35-99` — overlay has `role="dialog"`/`aria-modal` but no accessible name or description; focuses Cancel but does not capture/restore the opener; no shared scroll-lock behavior.

**Problem:** Screen-reader users hear an unnamed generic dialog; after closing, keyboard focus falls back to the document rather than the destructive-action trigger.

**Impact on students:** Destructive actions (delete account, remove saved item) are announced poorly and focus is lost after dismissal.

**Proposed improvement:** Add a labelled heading/message id (`aria-labelledby`/`aria-describedby`), capture the invoking element, restore focus on close, and use the shared overlay accessibility pattern for Escape and scroll lock.

**Priority:** HIGH  
**Relevant files:** `components/ConfirmDialog.tsx`

---

#### F9. Reduced-motion gaps

**Severity:** HIGH — users who request reduced motion still see animation  
**Status:** Confirmed source defect

**Current implementation:**
- `app/globals.css:5-9` — `html { scroll-behavior: auto }` (good), but `app/page.tsx:59` and auth/onboarding use imperative smooth scrolling / `animate-spin`.
- `app/(auth)/login/page.tsx:243,262` — `animate-spin` on submit and Google buttons, not gated under reduced motion.
- `app/onboarding/page.tsx:649,667` — `animate-spin` on save buttons.
- `components/Confetti.tsx` — confetti burst not reduced-motion gated in all paths.
- `components/Sidebar.tsx` — drawer transforms lack `motion-reduce` overrides in some paths.

**Problem:** Users requesting reduced motion still receive animated spinners, smooth scroll travel, confetti, and sliding navigation.

**Impact on students:** Vestibular discomfort and slower perceived interactions for users who opted out of motion.

**Proposed improvement:** Under `prefers-reduced-motion: reduce`, set `html` scroll behavior to auto, use `behavior: "auto"` for imperative scrolling, gate `animate-spin`/confetti/drawer transforms with `animation: none` / static progress cues.

**Priority:** HIGH  
**Relevant files:** `app/globals.css`, `app/page.tsx`, `app/(auth)/login/page.tsx`, `app/onboarding/page.tsx`, `components/Confetti.tsx`, `components/Sidebar.tsx`

---

### P2 — Accessibility & interaction (medium)

#### F10. Step indicator lacks `aria-current`

**Severity:** MEDIUM — screen-reader users cannot orient in the 5-step flow  
**Status:** Confirmed source defect

**Current implementation:** `components/StepIndicator.tsx:9-45` — active/completed steps communicated through CSS, numbers, and a checkmark only; no `aria-current="step"`, no "Step n of 5" text.

**Proposed improvement:** Mark active step with `aria-current="step"`; expose "Step n of 5" and completion/current text.

**Priority:** MEDIUM  
**Relevant files:** `components/StepIndicator.tsx`

---

#### F11. Personal statement naming (DraftPanel)

**Severity:** MEDIUM — unnamed multiline input  
**Status:** Needs verification against current `components/DraftPanel.tsx`

**Current implementation:** Audit #17 states "Personal statement" is a `p`, not a label; textarea has no id/name association; character counter live but not described by the field.

**Proposed improvement:** Use a real label or `aria-labelledby`; assign an id; connect counter/limit with `aria-describedby`.

**Priority:** MEDIUM  
**Relevant files:** `components/DraftPanel.tsx`

---

#### F12. Notification bell panel lacks dialog semantics

**Severity:** MEDIUM — `aria-expanded` without `aria-controls`, no Escape/focus management  
**Status:** Confirmed source defect

**Current implementation:** `components/NotificationBell.tsx:79-117` — trigger exposes `aria-expanded` but not `aria-controls`; panel is a plain div without landmark/dialog role, Escape handling, focus movement, or restoration.

**Proposed improvement:** Give the panel an id and labelled region; add Escape and focus management; make trigger/panel relationship explicit via `aria-controls`.

**Priority:** MEDIUM  
**Relevant files:** `components/NotificationBell.tsx`

---

#### F13. Report form labels

**Severity:** MEDIUM — select has no `htmlFor`/id; textarea relies on placeholder  
**Status:** Confirmed source defect

**Current implementation:** `components/ReportScholarshipButton.tsx:39-46` — visible label but no `htmlFor`/id on the select; textarea has no label, relies on placeholder "Optional details."

**Proposed improvement:** Add unique ids and explicit labels; connect limit/help text with `aria-describedby`.

**Priority:** MEDIUM  
**Relevant files:** `components/ReportScholarshipButton.tsx`

---

### P3 — Visual-system consistency (medium)

#### F14. Container width rhythm drifts across routes

**Severity:** MEDIUM — content width jumps during navigation  
**Status:** Confirmed source defect

**Current implementation:** `app/dashboard/layout.tsx:15-18` (`max-w-7xl px-6 lg:px-10`), `app/discover/layout.tsx` (`max-w-5xl px-6`), `app/opportunities/layout.tsx` (`max-w-3xl px-6`).

**Problem:** No named content-width system; content width and left/right balance jump during normal navigation.

**Proposed improvement:** Define named wide/catalogue/reading width tiers and apply through shared shell/container components.

**Priority:** MEDIUM  
**Relevant files:** `app/dashboard/layout.tsx`, `app/discover/layout.tsx`, `app/opportunities/layout.tsx`, `app/scholarships/layout.tsx`

---

#### F15. Catalogue filter styling drift

**Severity:** MEDIUM — adjacent browse experiences feel like separate products  
**Status:** Confirmed source defect

**Current implementation:** `app/discover/DiscoverClient.tsx:144-173` uses `rounded-2xl` panel, `rounded-xl` controls, explicit `min-h-[48px]`/`min-h-[44px]`; `app/opportunities/OpportunitiesClient.tsx:155-187` uses different padding/radius.

**Proposed improvement:** Extract a shared catalogue filter recipe (radius, height, padding, focus, elevation); permit only content-specific differences.

**Priority:** MEDIUM  
**Relevant files:** `app/discover/DiscoverClient.tsx`, `app/opportunities/OpportunitiesClient.tsx`

---

#### F16. CTA silhouette overuse

**Severity:** MEDIUM — `rounded-seal` pill used for primary actions and routine pagination alike  
**Status:** Confirmed source deviation from guidance

**Current implementation:** `app/page.tsx:93-101`, `app/dashboard/DashboardClient.tsx:288-296`, `app/applications/ApplicationsClient.tsx:328-331`, `app/discover/DiscoverClient.tsx:212-218`, `app/opportunities/OpportunitiesClient.tsx:221-227` all use `rounded-seal` for primary and routine actions.

**Proposed improvement:** Reserve full pills (`rounded-seal`) for primary/brand actions; use medium-radius buttons for routine actions; underlined/inline treatments for low-priority navigation.

**Priority:** MEDIUM  
**Relevant files:** Multiple CTA call sites

---

#### F17. Typography: Fraunces as global display on product surfaces

**Severity:** MEDIUM — serif display face on dashboard/catalogue/admin headings reads editorial, not operational  
**Status:** Confirmed visual-system deviation (not a functional defect)

**Current implementation:** `app/layout.tsx:2,10-20,54-55` maps Fraunces to `font-display` globally; `tailwind.config.ts:38-47`.

**Proposed improvement:** Use a sans display family for product surfaces, or scope Fraunces to clearly editorial/marketing sections (landing hero, testimonials) and document the intentional split.

**Priority:** MEDIUM  
**Relevant files:** `app/layout.tsx`, `tailwind.config.ts`

---

#### F18. Mobile navigation section state

**Severity:** MEDIUM — users lose orientation on secondary/detail routes  
**Status:** Confirmed source defect

**Current implementation:** `components/Sidebar.tsx:40-44,249-262` — bottom bar has only Dashboard, Opportunities, Applications, Profile and uses exact `pathname === href`; Discover has no dedicated mobile tab; opportunity detail/notifications/settings have no active section state.

**Proposed improvement:** Use prefix/section matching; add a deliberate destination for omitted routes; keep detail/list active treatment consistent.

**Priority:** MEDIUM  
**Relevant files:** `components/Sidebar.tsx`

---

#### F19. Admin mobile header and touch targets

**Severity:** MEDIUM — tall multi-row header on phones; ~40px admin toggle  
**Status:** Confirmed source defect

**Current implementation:** `app/admin/layout.tsx:19-64` (eleven links in one flex row, no mobile breakpoint); `components/Sidebar.tsx:307-364` (admin toggle ~40px).

**Proposed improvement:** Compact drawer/menu below `md`; set `min-h-[44px] min-w-[44px]` for toggles and mobile actions.

**Priority:** MEDIUM  
**Relevant files:** `app/admin/layout.tsx`, `components/Sidebar.tsx`

---

### Hypotheses requiring live validation (not confirmed)

| # | Area | Why unconfirmed |
|---|------|-----------------|
| H1 | Shimmer paint cost | Continuous `background-position` animation on dashboard loading; no device trace run |
| H2 | Repeated blur compositing | Multiple `backdrop-blur-sm` surfaces during scroll; not measured |
| H3 | Hydration breadth | Large route bodies handed to client components; bundle/hydration cost not measured |
| H4 | Exact 320px onboarding clipping | Deterministic sizing suggests risk; needs 320px/375px rendering check |

---

## Quick wins (high leverage, low coordination)

1. Preserve & validate `next` return path through password login, Google, signup.
2. Stack onboarding step-0 actions full-width at 320–375px; reduce card padding.
3. Add inline retry on failed onboarding saves; never clear draft unless save acknowledged.
4. Unmount or `inert` the closed mobile drawer; restore focus on close.
5. Add labelled confirmation dialog + focus restoration.
6. Gate `animate-spin`, smooth scroll, confetti, drawer transforms under reduced motion.
7. Add `aria-current="step"` to StepIndicator; explicit labels to report/draft controls.
8. Keep mobile Log in visible (done); add section-aware mobile-tab active state.
9. Read `discipline` from rejection URL; surface saved-query errors separately.

---

## Deeper fixes (recommendations, not yet implemented)

- Create shared interaction primitives: accessible combobox, dialog, disclosure/popover, form-field contract, mobile navigation primitive.
- Make data writes transactional from the user's perspective: preserve local drafts, distinguish request failure from empty data, require acknowledgement before destructive navigation.
- Define a product surface system: named container widths, catalogue filters, result cards, empty states, radii, shadows, button hierarchy, icon family, type roles as shared tokens/components.
- Narrow client boundaries: keep static cards/route sections in Server Components; isolate interactive save/share/feedback leaves; measure route JS/hydration in production build.
- Run an accessibility and device matrix: keyboard-only traversal, VoiceOver/NVDA, 320/375/768px widths, iOS Safari/Android Chrome, `prefers-reduced-motion`, `prefers-reduced-transparency`, slow-network failure paths.

---

## Files referenced (application, not modified)

`middleware.ts`, `app/page.tsx`, `app/layout.tsx`, `app/globals.css`, `app/motion.css`, `app/(auth)/login/page.tsx`, `app/(auth)/signup/page.tsx`, `app/auth/callback/route.ts`, `app/onboarding/page.tsx`, `app/dashboard/layout.tsx`, `app/dashboard/page.tsx`, `app/dashboard/DashboardClient.tsx`, `app/discover/layout.tsx`, `app/discover/DiscoverClient.tsx`, `app/opportunities/layout.tsx`, `app/opportunities/OpportunitiesClient.tsx`, `app/scholarships/layout.tsx`, `components/Sidebar.tsx`, `components/ScholarshipCard.tsx`, `components/FormField.tsx`, `components/Combobox.tsx`, `components/StepIndicator.tsx`, `components/DraftPanel.tsx`, `components/ConfirmDialog.tsx`, `components/NotificationBell.tsx`, `components/ReportScholarshipButton.tsx`, `tailwind.config.ts`, `lib/auth/return-destination.ts`, `lib/validate.ts`.
