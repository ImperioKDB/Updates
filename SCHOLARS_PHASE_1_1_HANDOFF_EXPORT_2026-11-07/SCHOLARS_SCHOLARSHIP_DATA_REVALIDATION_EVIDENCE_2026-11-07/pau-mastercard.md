# Pan-Atlantic University Mastercard Foundation Scholars Program — evidence note

**Audit date:** 2026-11-07
**Record slug:** `mastercard-foundation-scholars-program-at-pan-atlantic-university-aaaaaaaa`

## Findings

The Mastercard Foundation Scholars Program at Pan-Atlantic University exists. PAU’s current official program page describes the scholarship, eligibility criteria, selection process, contacts, and states that applications for the 2026/2027 admission cycle are closed. It says to check back for the 2027 application form. The Foundation’s official PAU partner page independently confirms the partnership, but labels Admissions “Open” without cycle dates or application steps. That generic status conflicts with PAU’s cycle-specific closed notice, so current status/date should be manually reconciled rather than treating the program as open.

The stored URL, `https://pau.edu.ng/mastercard-foundation/`, is the correct official PAU program page, it fetched successfully on the audit date, and the Foundation’s official partner page links to it. Successful HTTP/page retrieval establishes reachability, not that applications are open. No replacement URL is proposed.

## Record values and editorial proposals (not production changes)

- Stored instructions: NULL. **Classification: PARTIAL.** PAU publishes eligibility and a prior/current-cycle process, including an interest form for candidates without UTME results, sitting UTME and a 220 minimum score, followed by an online application, screening/interview, and award decision. The online application is now closed for 2026/2027, and the next-cycle form and dates are not published. No complete current-cycle application instructions can responsibly be proposed; proposed instructions remain empty.
- Stored deadline: 2027-05-22. **Not verified.** The PAU page says 2026/2027 applications are closed, but it gives no deadline or opening date and does not substantiate 2027-05-22. Do not carry this date forward as confirmed.
- Stored `opens_at`: NULL. No opening date for a future cycle is published in the sources reviewed.
- Stored `last_cycle_closed_at`: 2026-05-22. PAU confirms the 2026/2027 cycle is closed but does not state its precise closing date; the stored date is not independently verified here.
- Stored `last_verified_at`: NULL. Recommend **REQUIRES_MANUAL_REVIEW** because PAU’s current-cycle-specific closed statement conflicts with the Foundation directory’s undated “Admissions Open” label. Today's review is substantive, but that conflict prevents an unqualified verification-date update.
- Priorities: P1 for missing/materially incomplete actionable instructions; P2 for provenance/date reconciliation; P3 for unsupported deadline/lifecycle dates. No P0 destination defect is indicated.

## Sources

1. **Mastercard Foundation Scholars Program at Pan-Atlantic University** — Pan-Atlantic University, official provider page. URL: https://pau.edu.ng/mastercard-foundation/ . Publication date: not shown. Accessed: 2026-11-07. Supports the program’s existence, scholarship benefits, eligibility (academic excellence, leadership/impact, financial need, required O-Level credits and UTME score/subjects), priority groups, application stages, email/phone contacts, no-fee statement, and closure of applications for 2026/2027. It does not state a precise deadline/opening date or publish a next-cycle form. **Tier 1; high confidence for what the page states, medium for present status given conflicting directory metadata.**
2. **Pan-Atlantic University** — Mastercard Foundation, official partner/directory page. URL: https://mastercardfdn.org/en/what-we-do/our-programs/mastercard-foundation-scholars-program/where-to-apply/pan-atlantic-university/ . Publication date: not shown. Accessed: 2026-11-07. Supports the Foundation’s recognition of PAU as a partner, description of the program, study levels/country, and a Foundation-directory “Admissions Open” label; it links readers to the PAU program page. It gives no dated cycle or application procedure. **Tier 1; high confidence for partner listing and displayed label, low confidence that the undated generic label establishes an open current cycle.**

## Supported and unresolved claims

**Supported:** the program exists; PAU is an official Mastercard Foundation partner; the stored URL is authoritative and linked from the Foundation directory; PAU’s page is currently reachable; PAU states the 2026/2027 cycle is closed; eligibility/process details are published on PAU’s page.

**Unresolved:** whether the Foundation’s “Admissions Open” label is stale or applies to a different cycle; opening/deadline dates for any future cycle; the precise closure date underlying the stored 2026-05-22 value; whether the stored 2027-05-22 deadline is accurate. No URL, deadline, or future-cycle instructions are invented here.
