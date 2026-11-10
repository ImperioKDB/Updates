# Decagon Undergraduate Honors Program — revalidation evidence

**Audit/access date:** 2026-11-07
**Record slug:** `decagon-undergraduate-honors-program`
**Scope:** Public scholarship/program information only; no production data was changed.

## Findings

The Decagon Honours Program exists and has a live official application route. Decagon’s official programme page says the programme is for Nigerian citizens who scored at least 250 in UTME/JAMB and have not yet started university. It describes a four-year programme running alongside the student’s degree, including university access, leadership training, career preparation, mentorship, community membership, and opportunity access.

The official `/apply` page currently says “Applications Open.” It instructs applicants to have their JAMB score, preferred university, choice of course, and parent/guardian contact details ready. It names Christopher University and Wellspring University as selected partner universities and says applications are reviewed within five working days, after which successful candidates may be contacted for a screening call and formal offer. The page’s “Click Here to Apply” button links to the provider-controlled secure form at `https://zfrmz.com/pDDZpINUoiQo2eSg4ifu`.

The stored URL `https://www.decagonfoundation.org/apply` returned 404 in the prior audit and is not the current official route found in this review. The current official domain is `https://decagon.institute/apply`. No deadline was published on the reviewed official pages. The stored 2026-10-15 deadline is unsupported and should not be retained as an active or verified deadline without a source.

**Instructions classification:** ACTIONABLE for the current programme route, with no published deadline. The official page provides eligibility, preparation requirements, application route, and next steps. It does not establish a current closing date.

## Record values supplied for comparison

- **URL:** `https://www.decagonfoundation.org/apply`
- **Instructions:** stored text described an application route and materials but used the stale destination
- **Deadline:** `2026-10-15`
- **Opens at:** `NULL`
- **Last cycle closed at:** `NULL`
- **Last verified at:** `2026-10-06 11:52:53.120101+00`

## Proposals — editorial only; no production changes made

- **Instructions:** “Applications are open on Decagon’s official Honours Program page. Applicants must be Nigerian citizens, have scored at least 250 in JAMB/UTME, and not yet have started university. Prepare your JAMB score, preferred university, choice of course, and parent/guardian contact details. The official page identifies Christopher University and Wellspring University as partner-university options. Apply through the ‘Click Here to Apply’ link on `https://decagon.institute/apply`, which opens the provider-linked secure form. Decagon says applications are reviewed within five working days and successful candidates may be contacted for a screening call and formal offer. No application deadline is published on the reviewed official pages; confirm the live page before applying.”
- **URL:** Replace the stale 404 destination with `https://decagon.institute/apply` as the stable official landing page. Keep the secure form URL as a linked route in instructions, not as an unverified standalone replacement.
- **Deadline/lifecycle:** Remove or mark `2026-10-15` as unsupported. Do not infer a closing date from the prior 404 or from the absence of a displayed deadline.
- **Verification date:** Set `last_verified_at` to `2026-11-07`.
- **Priority:** P0 for the stale/broken stored destination because a working official route is available; P1 for replacing the outdated instructions and deadline; P2 for provenance and verification timestamp.

## Sources

1. **Decagon Honours Program**, official provider page, https://decagon.institute/. Publication date not shown; accessed 2026-11-07. Supports the programme’s eligibility concept, Nigerian-citizen requirement, JAMB threshold, not-yet-started-university requirement, and four-year programme structure.
2. **Apply | Decagon Honours Program**, official provider application page, https://decagon.institute/apply. Publication date not shown; accessed 2026-11-07. Displays “Applications Open,” preparation requirements, partner universities, five-working-day review statement, and the provider-linked secure application form.
3. **Decagon secure application form**, provider-linked route surfaced by the official `/apply` page, https://zfrmz.com/pDDZpINUoiQo2eSg4ifu. Accessed 2026-11-07 through the official page’s application button. The exact form’s availability should be rechecked when implementing a correction.

## Unresolved

- No official application closing date was published on the reviewed pages.
- The form’s current response state was not independently submitted or tested; the official landing page says applications are open.
- The programme page states that it costs ₦275,000 per year, but the reviewed materials do not clearly establish whether that is a scholarship benefit, a family contribution, or a programme fee. Do not convert that statement into scholarship-financial terms without clarification.
