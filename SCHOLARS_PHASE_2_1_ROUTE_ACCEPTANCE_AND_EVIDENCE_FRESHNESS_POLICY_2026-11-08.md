# Scholars Phase 2.1 — Application-Route Acceptance Matrix and Freshness Standard

**Status:** Proposed editorial standard; A-03 and A-04 are pending approval.
**Controlling source:** Phase 1.3.1 route-state definitions and publication rules.
**Core rule:** Route identity, accessibility/reachability, and submission acceptance are separate facts. None may be inferred from another.

## 1. The three route questions

**Generic freshness states:** `fresh_provider_recheck`, `carried_forward`, `mixed_freshness`, `stale`, `not_checked`. Keep check timestamps, source publication dates, Phase 1.3.1 recheck provenance, and claims reviewed as separate fields; do not overload the state enum.

Every exact-cycle route must be evaluated across three distinct axes:

1. **Identity/provenance:** Is this the provider’s programme-specific route, or a third-party channel linked by the provider for this exact cycle?
2. **Observed access:** What did the reviewer or safe fetch actually observe—reachable content, a sign-in wall, 403, CAPTCHA, closed form, redirect, or error? This describes the observed access path for the checker, not every student’s access.
3. **Acceptance evidence:** Does an authoritative, current source present the exact cycle as open and direct applicants to this route, or does the form itself explicitly state it is accepting responses? A successful submission is not required and must not be attempted by Scholars.

Recommended separate values:

- `route_provenance`: `provider_owned`, `provider_linked_third_party`, `institutional_authoritative`, `unlinked_third_party`, `unknown`.
- `route_kind`: `programme_page`, `cycle_form`, `third_party_form`, `generic_portal`, `login_portal`, `email`, `postal_or_physical`, `closed_form`, `paid_programme`, `other`.
- `observed_access`: `reachable`, `login_required`, `forbidden_403`, `captcha_or_challenge`, `closed_page`, `redirected`, `timeout_or_error`, `not_checked`.
- `acceptance_evidence`: `provider_presents_exact_cycle_open`, `form_explicitly_accepting`, `provider_instructions_current`, `explicitly_closed`, `conflicting`, `unconfirmed`, `not_applicable`.
- `end_to_end_submission_tested`: always `false` under the Scholars review workflow. Do not create a user account, submit data, click a final submission action, bypass CAPTCHA, or claim acceptance success.

## 2. Route-type decision matrix

| Route type / observed case | Minimum evidence to establish provenance | What it proves / does not prove | Default treatment |
|---|---|---|---|
| **Official programme information page, no form** | Provider-controlled URL or authoritative institution link; exact opportunity/programme relationship. | Can establish authenticity and published requirements. Does **not** prove a current cycle is open or provide an application path. | Use as evidence/source link only. No apply-now CTA unless the page supplies current-cycle instructions to a valid route. |
| **Provider-hosted, programme-specific form** | Official programme/cycle page identifies the form, or form is on verified provider domain and clearly names the exact programme/cycle. | Establishes route identity. A working page or active-looking submit button does not prove responses are accepted. | May support actionability only when current exact-cycle open evidence also passes and no closure/conflict is observed. Record if no explicit form-acceptance label is visible. |
| **Third-party hosted form linked by provider** | Current official provider page/notice names or links the exact form for the exact cycle; form title/programme/cycle align; redirect chain is safe. | A valid route can be hosted by a third party. A third-party form link without current provider linkage or cycle alignment is insufficient. | Manual review of provenance and form identity required. If the provider’s current open notice links it, do not submit; label “provider-listed application route; submission not tested.” |
| **Third-party directory or social post** | Source URL/date and source class. Provider corroboration needed for eligibility, date, or route claims. | May be a discovery lead or corroborating context; never by itself proves provider acceptance, official deadline, or current eligibility. | Candidate intake only unless independently supported by official evidence. No CTA based solely on the directory/post. |
| **Redirected or changed application URL** | Preserve requested/final URL and safe redirect chain; verify the provider’s current exact-cycle page identifies the new destination and the host/programme matches. | A redirect by itself establishes neither route provenance nor acceptance; an unrelated or changed host may indicate a different programme. | Manual review is required after a material host/path change. CTA only after exact-cycle provenance and open evidence are re-confirmed; otherwise no CTA. |
| **Generic portal home/root** | Provider relationship plus exact current programme instructions that identify the portal path. | A homepage, provider portal root, or general login is not a programme-specific application route. | `generic_or_non_programme_route`; manual review or no current route. No apply-now CTA. |
| **Login-required application portal** | Official current-cycle instruction explicitly identifies this portal and says the exact cycle is open; route identity is programme-specific; the expected sign-in step is documented by the provider. | A login screen proves only that a login page is reachable. It does not prove applications are open or that the user can submit. Scholars must not sign in using a student’s credentials. | `login_required`; may show an accurately labeled “Continue to the provider portal” only after editorial approval and all other gates. Otherwise `manual_review`; never describe the login screen as acceptance evidence. |
| **403 / 401 / WAF / CAPTCHA / access challenge** | Preserve exact URL, timestamp, redirect/outcome, and safe-fetch limitation; corroborate with a public official call or alternative provider route. | Proves only that this check encountered an access challenge. It does not prove open, closed, nonexistent, or malicious. | `source_unavailable_or_integrity_unresolved`. No bypass, credential guessing, CAPTCHA solving, or repeated aggressive fetch. No CTA to the challenged endpoint unless a separately verified public instruction/route resolves it. |
| **Form explicitly says “closed,” “not accepting responses,” or cycle ended** | Capture the exact provider/form message and identify the cycle; verify the route is provider-owned/provider-linked. | Supports closure of that exact form/cycle, not of every future cycle under the provider. | `closed_provider_route`; exact cycle becomes historical. Preserve source and suppress active CTA/reminder. |
| **Official email submission** | Current exact-cycle official instructions name the address and required materials; no conflicting official channel; recipient domain/address is transcribed and rechecked. | Supports an official submission channel and provider-presented current instructions. Scholars cannot test inbox receipt. | Student-facing instructions may link to the official page or provide a guarded `mailto:` affordance. Do not auto-send or imply receipt. If email and postal instructions conflict, manual review. |
| **Official postal/physical submission** | Current exact-cycle provider/institution notice names the receiving office/address, deadline, and acceptable package/process; no conflict. | Supports published instructions, not delivery/receipt by the provider. | Present precise instructions and date semantics, with travel/postal caveat. No automated submission. Conflict or missing exact address blocks actionability. |
| **Conflicting official channels** | Capture both current official instructions and compare cycle, dates, recipients, and route. | Establishes a conflict; do not select the newest-looking URL or one convenient channel without a source-backed resolution. | `conflicting_provider_instructions` → `manual_review`; no CTA, match, save-as-actionable, or reminder. Bode Amao is the fixture. |
| **Paid route adjacent to an award** | Provider/source evidence establishes a distinct paid programme, fees, and any award relationship. | A paid programme is not an application route for a scholarship unless an explicit, current, evidenced connection is approved. | Separate opportunity identity, fee fields, and route. Do not substitute the paid route for scholarship applicants. Decagon Institute is the fixture. |
| **No current route found** | Record sources checked, route search scope, and date. | “Not found” is not proof the provider has no future route. | `no_current_route_verified`; non-actionable or historical depending on the exact-cycle evidence. |

### 2.1 CTA, human-review, and student-language matrix for the ten required route classes

| Route class | Can it support an actionable CTA? | Manual confirmation required? | Student-facing wording when allowed/held |
|---|---|---|---|
| Official programme information page | Not by itself; yes only when it identifies an exact open cycle and a specific application next step. | Yes if cycle, scope, or next step is ambiguous. | “Official programme information; this page alone does not establish that applications are open.” |
| Official application form | Yes when exact-cycle open evidence, form identity, freshness, and no-closure/no-conflict gates pass. A test submission is never required. | Yes before first publication and after material form/cycle change. | “The provider presents this cycle as open; the form was reviewed on [date]. Scholars did not submit an application.” |
| Provider-linked third-party form | Yes only when the current official provider page links the exact form for the exact open cycle and the form aligns. | Yes, to verify provenance, cycle and host. | “The provider links this application form for [cycle]; submission was not tested.” |
| Generic provider portal | No, until a programme-specific route is identified. | Yes. | “We could not verify a programme-specific application route.” |
| Login-required portal | Only if the official current-cycle instructions identify this exact portal and present the cycle as open; no account access by Scholars. | Yes. | “Continue to the provider portal; sign-in may be required. Scholars did not access an applicant account.” |
| Official email or postal application | Yes when current exact-cycle instructions specify destination, steps and timing, with no conflict. | Yes for material destination/instruction changes or any competing channel. | “Follow the provider’s published [email/postal] instructions for [cycle]; Scholars did not send or verify receipt.” |
| Closed application form | No. | Reviewer confirms the closure applies to this exact cycle before archiving; future cycles are separate. | “This [cycle] form is shown as closed; no current application CTA.” |
| Inaccessible page / HTTP 403 | No CTA to the challenged route while its student usability is unresolved. An alternative official route may qualify after review. | Yes. | “The source could not be assessed from our review path. This does not by itself mean the programme is closed.” |
| Redirected or changed application URL | Only after the final host/path is provider-confirmed and exact-cycle/open evidence is rechecked. | Yes after any material change. | “The provider’s link now points to [approved host] as checked [date]; submission was not tested.” |
| Paid-programme application route | No for a scholarship application. A separately approved paid-programme listing is evaluated under its own scope and fees. | Yes to establish any award/fee relationship. | “This is a fee-paying programme, not the scholarship route; stated fees and any separate award are shown independently.” |

## 3. Evidence threshold for an “actionable” route without a test submission

A true end-to-end submission cannot be safely tested without becoming an applicant or transmitting personal data. The recommended acceptable substitute is **provider-backed open presentation**, not a claim of successful submission:

### Required evidence

1. **Exact cycle:** a current provider or authoritative institution source identifies the exact intake/year/programme; no inferred recurrence.
2. **Explicit open statement or equivalent:** the provider says applications are open/accepting now for that exact cycle, or the form itself displays a current-cycle “accepting responses” signal. An old stored deadline, a “rolling” label without cycle identity, or a generic “apply” page is insufficient.
3. **Route link/provenance:** the provider source links to the specific route or names the exact email/postal channel. Third-party form hosts require an exact provider link or written authoritative identification for this cycle.
4. **Route-cycle consistency:** form title, provider, cycle label, eligibility, and instructions align. A form that lists multiple years without a provider statement tying the present cycle to the intended year does not create multiple cycles by itself.
5. **No contrary signal:** no provider/form closure banner, contradictory official date/state, discontinued notice, or unresolved material channel conflict.
6. **Current assessment:** source and route checks meet the applicable freshness interval, and the reviewer records precisely what was observed.
7. **Human approval:** a qualified reviewer approves the route and current-cycle interpretation; higher-risk conflicts use the A-05 independent approval rule once approved.

### Permitted student-facing wording

- If the provider explicitly says open and links the route: **“The provider currently presents the [exact cycle] application as open. Scholars reviewed the linked route on [date]; we did not submit an application.”**
- If an official form visibly says it is accepting responses: **“The provider-linked form displayed an accepting-responses status when checked on [date]. Scholars did not submit the form.”**
- If only route identity/reachability is known: **“Official programme/application information”** or **“route was reachable when checked,”** not “accepting applications.”
- If the route is login-protected or access-challenged: state the limitation; do not imply acceptance from the login screen or 403 response.

Never say “Scholars confirmed your application will be accepted,” “we tested the application,” or “guaranteed open.” Provider-presented openness is time-bound evidence, not an endorsement or successful submission guarantee.

## 4. Required behavior for known route anomalies

- **403/401:** no lifecycle transition by itself. Record an access outcome, retain the last supported state with its age only if still within policy, and block the CTA unless another official source gives a current, usable route. Do not fetch around access restrictions.
- **Login-only portal:** do not treat login availability as an application window. Require an exact current official cycle notice and route instructions. If the notice does not resolve the cycle, use `manual_review`.
- **CAPTCHA:** do not solve, bypass, automate, or submit. A CAPTCHA challenge is an access limitation; it does not establish open or closed state.
- **Generic or redirecting route:** store requested and final URLs, validate redirect host/scheme, detect unrelated programme/paid programme, and require a programme-specific landing step before public CTA.
- **Third-party form:** a provider link can establish provenance, not acceptance. Check current provider cycle status, exact form/cycle identity, closure notice, and conflict. If any is unknown, no actionable CTA.
- **Conflicting email/post instructions:** retain both claims with separate source captures; do not “resolve” by choosing the newer page without an explicit superseding statement.
- **Expired deadline without a current closure check:** stop current CTAs/reminders and send to review. Record “published deadline passed; current provider status not confirmed” rather than assert a provider closed the programme.

### 4.1 Inaccessible source while the last successful check is still fresh

A new 401/403/CAPTCHA/timeout does not retroactively make the last successful provider claim stale and does not prove the cycle closed. Keep the prior claim and its original `checked_at`/`freshness_state`, append a separate new access-observation capture, and mark current route accessibility as challenged/unknown. Under the recommended safe default, the cycle becomes `manual_review` and loses active CTA, match, and reminder capabilities until a reviewer verifies a student-usable alternative route or provider instructions that resolve the access issue. The older “provider presented open” claim remains visible to editors and may remain historically visible; it is not promoted to a new current check. If A-04 later approves a less restrictive within-window exception, that exception must be explicit, limited to the exact route/scope, and tested; it must not convert the 403 itself into acceptance evidence.

## 5. Proposed freshness and revalidation intervals

These are maximum ages for current actionability, not automatic statements about truth. They are configurable by claim type and require A-04 approval.

| Claim/check type | Proposed maximum age while relevant | Recheck trigger / fail-closed behavior |
|---|---|---|
| Provider identity/domain and programme relationship | 365 days | Recheck immediately on domain/ownership/name change, suspicious redirect, provider merge, or authenticity challenge. Expiry blocks a new actionable approval until revalidated. |
| Audience, academic level, material eligibility, and funding/fee coverage | 90 days within the same active cycle | Always recheck for a new cycle or contradictory provider update. Expiry makes affected material claims stale and blocks actionability; do not copy claims across cycles. |
| Exact-cycle open/accepting presentation | 7 days during an active window; 24 hours when within 72 hours of published deadline | If route/status check fails or sources conflict, set current status unresolved/conflicting and route to manual review; do not auto-close. |
| Route provenance and redirect chain | 30 days, and immediately after URL/host/form-ID change | If final host or programme differs, block CTA pending review. |
| Route availability/access state | 7 days during active window; 24 hours within 72 hours of deadline | 403/login/CAPTCHA/error becomes an access limitation; no acceptance inference. |
| Opening date transition | Recheck within 24 hours of stated opening and again when the provider publishes “open” | Future date alone permits `upcoming`, not `actionable`. Reaching the date does not auto-open the cycle. |
| Deadline/closure transition | 7 days when more than 30 days away; 72 hours within 30 days; 24 hours within 7 days | Once the source deadline passes, remove active capabilities immediately; seek closure/extension evidence. No status = manual review, not provider-closed. |
| Historical source/claim | No active freshness clock for what the source said at the time; maintain its capture date and immutable historical state | Historical evidence cannot be reused as proof of a future cycle. Corrections append a new claim/event. |
| Reviewer approval | Valid only for the exact cycle, catalogue scope, policy version, and evidence revision approved | Any material evidence change, superseding claim, new cycle, policy change, or expiry invalidates the approval and forces re-evaluation. |

**Interval meaning:** `checked_at` tells when a reviewer looked. `published_at` tells when a source says it was published. Neither date is substituted for the other. A date claim may remain historically accurate while the provider’s current acceptance state becomes stale.

### 5.1 Expiry outcomes by evidence category

| Category | Proposed interval/checkpoint | On expiry or failed recheck | Human review and actionability | Historical visibility |
|---|---|---|---|---|
| Provider identity | 365 days; immediate recheck on domain/ownership/redirect anomaly. | Mark current authenticity support stale; do not erase the historic provider-source claim. | Human revalidation required before a new/current actionable approval. | Prior identity evidence remains in private history; public display follows separate scope/archive policy. |
| Eligibility requirements | 90 days within an active cycle; always recheck for a new cycle or material provider update. | Mark affected requirements stale; unknown hard criteria cannot be treated as satisfied. | Human review; non-actionable if a material requirement is stale. | Prior requirement wording remains tied to its prior capture/cycle and cannot be reused as current. |
| Academic-level requirements | 90 days within the same cycle; invalidate on a new cycle or changed programme route. | Mark level/applicant-stage claim stale. | Human review; no actionable match until current scope is supported. | Historical level claim remains labeled with its check date. |
| Application opening dates | The source-published date itself remains an immutable historical claim; recheck within 24 hours around the expected opening. | Date arrival does not auto-open the cycle. Without a fresh open signal, mark current status unresolved. | Human confirmation before actionable transition. | Original date and source remain historically visible. |
| Deadlines and closure | Recheck at 7 days when >30 days away, 72 hours within 30 days, 24 hours within 7 days; trigger immediate review after the date passes. | Remove active capabilities immediately. If no provider closure/extension is found, say “published deadline passed; current status not confirmed,” not “provider closed.” | Human review required; no CTA/match/reminder while elapsed status is unresolved. | Deadline and previous status stay available in historical audit/archive. |
| Application-route provenance and access | Provenance 30 days; access state 7 days, tightened to 24 hours within 72 hours of deadline; immediate on URL/host change. | Record latest access observation separately; a 403 does not close the programme. No current CTA to a challenged route. | Human review for URL/host changes, access challenge, or unresolved alternate route; current actionability fails closed if route usability is material. | Previous route capture remains labeled as last known; only an approved archive may show it. |
| Funding and award coverage | 90 days within a cycle and always recheck for a new cycle or provider benefit/fee change. | Mark coverage claims stale; remove “fully funded” and other coverage copy. | Human review; if coverage uncertainty changes the material offer, keep the cycle non-actionable. | Prior component-level claims remain linked to their cycle and source. |
| Historical information | No claim of currentness; retain exact source/capture date and cycle identity. | Retention expiry follows the separate retention schedule; never roll historic information into a new cycle. | Human review only for public archive eligibility or correction. | Historical fact remains private/auditable, and may be public only under approved archive/SEO policy. |

## 6. Review procedure and event handling

1. Check the provider’s current programme/cycle announcement and the exact linked route.
2. Capture source role, URL, checked timestamp (UTC), stated publication date (or `unavailable`), route provenance, access result, and only a minimal evidentiary excerpt/hash.
3. Record separate claims for lifecycle, route provenance, route reachability, acceptance signal, deadline/opening semantics, and instructions.
4. Record the exact check limitations: “not submitted,” “login required,” “403 from reviewer network,” “form title names multiple entries,” etc.
5. Reviewer resolves or explicitly preserves conflict. A claim is never made “current” by editing the report date.
6. Re-evaluate the central publication decision; if actionable, set `next_review_at` and reminder/revalidation obligations.
7. On extension/cancellation/reopening, append a new event and claim; retain old deadlines, captures, and decisions; invalidate caches; recalculate cycle-bound reminders idempotently.

## 7. Worked route examples

| Case | Correct route/status representation | Allowed result |
|---|---|---|
| ASUU/FUK 2026 | Branch route only; FUK deadline and call are not a national route. The evidenced call is historical. | No national listing or CTA; ask students to verify their own branch’s current call. |
| Bode Amao | Provider form is reachable, but official homepage says post and the form page says email; current cycle is not official-confirmed. | `manual_review` or approved warning-only restricted lead; no selection of either route, no CTA. |
| Decagon Foundation vs Institute | Keep Foundation scholarship form and Institute direct-pay form separate. | Foundation can be a restricted lead; never route scholarship applicants to the paid Institute form or call the combined offering fully funded. |
| JG Afrika | Official inline form and open presentation; no submission or CAPTCHA testing; Nigerian citizenship/university location unresolved. | Excluded from the Nigerian-undergraduate catalogue; not classified as closed. Notification date is not a deadline. |
| PAU/Mastercard | PAU says 2026/27 closed; Foundation directory says “Admissions Open.” This is a lifecycle conflict, not automatically a route-channel conflict. | `manual_review`; no open CTA until cycle/status evidence is reconciled. |
| NDDC portal | Postgraduate cycle, deadline in official call; login/403 anomalies and submission acceptance unresolved. | Excluded from undergraduate scope; no status inference from portal access. |
| Separate synthetic negative route fixture | Carry-forward evidence only; no exact-cycle route or current open signal. This is not the positive worked example. | `manual_review`; no CTA/match/reminder. |

## 8. Related documents

- [Governance decision refinement](SCHOLARS_PHASE_2_1_GOVERNANCE_DECISION_REFINEMENT_2026-11-08.md)
- [Authoritative publication policy and gates](SCHOLARS_PHASE_2_1_AUTHORITATIVE_PUBLICATION_POLICY_2026-11-08.md)
- [Evidence retention and security policy](SCHOLARS_PHASE_2_1_EVIDENCE_RETENTION_AND_SECURITY_POLICY_2026-11-08.md)
- [Technical specification](SCHOLARS_PHASE_2_1_TECHNICAL_SPECIFICATION_AND_FINAL_ERD_2026-11-08.md)
- [Readiness assessment](SCHOLARS_PHASE_2_1_IMPLEMENTATION_READINESS_ASSESSMENT_2026-11-08.md)
