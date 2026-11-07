# Lagos State Scholarship Board Bursary & Scholarship Awards — evidence note

**Audit date:** 2026-11-07
**Record slug:** `lagos-state-scholarship-board-bursary-scholarship-awards-d9c8ed08`

## Findings

The program exists. The Lagos State Scholarship Board's own site describes its bursary and scholarship award categories, and the Board's official social post states that its 2025/2026 academic-session Bursary and Scholarship Awards application cycle had successfully concluded, culminating in a CBT on 12 September 2026. The site is reachable but displays a maintenance notice and mainly old announcements; the Board-branded portal is also reachable but renders a login screen. Neither reachability nor a login screen proves that a new application cycle is open.

Current instructions are **MISSING** in the database (`NULL`). The official portal's terms page lists headings for eligibility, process, and award criteria but supplies no substantive steps or requirements under those headings. The official site gives categories and general institutional purpose, not a sufficiently supported, cycle-specific procedure. Do not draft instructions from inference.

No official 2026/2027 application opening or deadline was confirmed in the official sources reviewed. The database's `opens_at=2027-01-19` and `deadline=2027-03-06` are future dates and remain unsupported. The official Board instead confirms closure of the 2025/2026 cycle. No next-cycle dates should be presented as published without an authoritative notice.

## Record values supplied for audit (not production changes)

- **URL:** `https://www.lagosscholarship.org/`
- **Instructions:** `NULL`
- **Deadline:** `2027-03-06`
- **Opens at:** `2027-01-19`
- **Last cycle closed at:** `NULL`
- **Last verified at:** `NULL`

## Sources read

1. **Lagos State Scholarship Board homepage** — Lagos State Scholarship Board. URL: https://www.lagosscholarship.org/ . Publication date: not shown; its page contains historical announcement dates, including 2023. Accessed 2026-11-07. **Tier 1, official provider.** Supports that the Board presents bursary/scholarship categories and an official site; the fetched page also displayed a website-maintenance notice and old announcements. Confidence: high for page contents and observed state; this page does not establish a current application cycle.
2. **Terms and Conditions** — Lagos State Scholarship Board application portal. URL: https://portal.lagosscholarship.org/terms-and-condition . Effective/last updated: April 2025. Accessed 2026-11-07. **Tier 1, official provider portal.** Identifies itself as the Lagos State Scholarship and Bursary Application Portal and contains only empty section headings for eligibility, application process, and award criteria. Confidence: high for what the page displays; it does not support eligibility requirements or actionable steps.
3. **LSSB - Lagos State Scholarship Board** — Lagos State Scholarship Board application portal. URL: https://portal.lagosscholarship.org/ . Publication date: not shown. Accessed 2026-11-07. **Tier 1, official provider portal.** The page identifies the Lagos State Scholarship Board and renders a login screen. Confidence: high for observed content; no claim that applications are open.
4. **Lagos State Scholarship Board's Post** — Lagos State Scholarship Board (official Facebook page). URL: https://www.facebook.com/lssboard/posts/the-executive-secretary-of-the-lagos-state-scholarship-board-mrs-rasheedat-a-dar/1094699376442382/ . Published 2026-09-12. Accessed 2026-11-07. **Tier 1, official Board announcement.** Says the Board successfully concluded its 2025/2026 academic-session Bursary and Scholarship Awards application cycle; says the cycle culminated in a CBT on Saturday, 12 September 2026, at PSSDC and that the examination was hybrid. Confidence: high.

## Supported claims

- The Board and its bursary/scholarship awards are real and publicly represented by the official Board site and portal.
- The Board states that the 2025/2026 academic-session application cycle concluded and held a CBT on 2026-09-12.
- The official homepage and portal pages were retrievable during this review. The homepage displays a maintenance notice; the portal displays login. These observations do not establish application availability.
- The portal terms page does not publish usable eligibility criteria or application steps in the inspected text.

## Unresolved claims

- Whether the Board has announced a 2026/2027 cycle, and any opening date, closing date, eligibility, requirements, or application procedure; no such dates or instructions were confirmed in the official pages/posts read.
- Whether the stored 2027-01-19 and 2027-03-06 dates were intended for a new cycle or copied forward from a prior timetable; they are not substantiated by reviewed primary sources.
- The official homepage's maintenance notice gives no end date, and the retrieved homepage did not establish that the visible Apply control points to the current portal.

## Proposals (editorial only; no production changes made)

- **Proposed application instructions:** empty. Do not publish a procedure or requirements until an official current-cycle notice or complete portal guidance is available.
- **Proposed application URL:** empty/no change proposed. Retain the provider homepage as a valid official information destination; it is reachable but maintenance-flagged and stale. The official branded portal is separately reachable, but the login screen alone does not establish it as an active application destination.
- **Deadline/lifecycle:** treat the 2025/2026 cycle as concluded. Do not treat 2027-01-19 or 2027-03-06 as verified next-cycle dates without primary evidence.
- **Verification date:** recommend setting `last_verified_at` to `2026-11-07`, since today's source review checked program existence and official status of the most recently confirmed cycle. This is not verification of the unsupported 2027 dates.
- **Priorities:** P1—obtain authoritative next-cycle instructions before publishing (especially given the future stored opening date); P2—record source/date provenance; P3—correct lifecycle and remove/confirm unsupported deadline/opening fields. No P0 destination correction is supported.
