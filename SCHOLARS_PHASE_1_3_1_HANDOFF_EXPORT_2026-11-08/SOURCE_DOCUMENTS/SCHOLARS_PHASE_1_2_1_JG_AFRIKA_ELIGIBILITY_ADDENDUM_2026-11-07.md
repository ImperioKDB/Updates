# Scholars — Phase 1.2.1 JG Afrika Eligibility and First-Batch Validation

**Audit date:** 7 November 2026  
**Record:** JG Afrika Bursary 2027  
**Exact UUID:** `64790f70-f20a-4c9c-a1f4-2efabc087dcb`  
**Scope:** Independent read-only validation of the proposed Phase 1.2 first batch.  
**Result:** Batch 1 is **not approved**. No production, application, schema, configuration, deployment, or merge changes were made.

## Revised disposition

**C. EXCLUDE/RESTRICT FROM NIGERIAN CATALOGUE — legitimate opportunity but not sufficiently relevant to the target audience.**

The official provider page is live and the 2027 form is displayed, but the provider does not establish whether South African citizenship is mandatory, whether Nigerian citizens are eligible, or whether applicants must attend a South African university. Scholars initially serves Nigerian undergraduates. A general Nigerian catalogue listing would therefore risk implying eligibility that the provider has not confirmed.

The Phase 1.2 decision matrix should be amended from **SAFE TO CORRECT** to **EXCLUDE/RESTRICT FROM NIGERIAN CATALOGUE**. The proposed `how_to_apply` correction must not be written into production until either:

1. JG Afrika confirms in writing that Nigerian citizens are eligible and states the applicable university-location rule; or
2. the founder approves a separate non-Nigerian/International or South-Africa-specific catalogue policy with an explicit eligibility warning.

This is a catalogue and audience decision, not a finding that the bursary is illegitimate. The opportunity is a real JG Afrika 2027 bursary opportunity, but its relevance to Nigerian students is unresolved.

## Official sources reviewed

The following sources were opened and read on **7 November 2026**:

- [JG Afrika official 2027 bursary page and application form][1]
- [JG Afrika official LinkedIn announcement][2]

The official page contains the actual application form inline. No third-party summary was used as proof of eligibility. The page also publishes an official HR contact in its POPI terms: `hr@jgafrika.com`.

## Eligibility findings

### Citizenship and nationality

The actual form does **not** state that South African citizenship is mandatory. It asks for an ID number and includes “Foreign National” as an option under the **Race** field. That field is not a citizenship rule and cannot establish that foreign nationals are eligible or ineligible.

The form also does not state whether Nigerian citizens may apply. The official LinkedIn post includes a public comment asking whether applicants from other African countries are eligible, but the accessible provider post does not show an official answer. That comment is evidence that the question is unresolved, not evidence of eligibility.

**Finding:** citizenship eligibility is **unresolved** and must be confirmed by JG Afrika. Do not infer eligibility from the presence of “Foreign National” in a race dropdown.

### University location

The form requires the applicant to provide a **name of university**, but the official page does not state that the university must be in South Africa. The LinkedIn announcement says applicants are studying toward the named qualifications but does not resolve university location or nationality.

**Finding:** South African university attendance is **not established** by the official form. It must be confirmed before listing the opportunity for Nigerian students studying in Nigeria or elsewhere.

### Eligible qualifications

The official page explicitly lists:

- **BSc in Civil Engineering**
- **BEng in Civil Engineering**
- **MSc in Civil Engineering**
- **MEng in Civil Engineering**

The LinkedIn announcement highlights BSc and BEng Civil Engineering, but the provider’s actual application page is broader and explicitly includes MSc and MEng. A correction must include both undergraduate and postgraduate Civil Engineering qualifications if the record is ever made suitable for the relevant catalogue.

**Finding:** BSc, BEng, MSc, and MEng Civil Engineering are provider-confirmed. No other qualification should be added.

### Matric applicants and transcript requirement

The form contains high-school education fields and requires a Matric certificate. However, the provider also states:

> “A complete academic transcript from your first year to current is a mandatory requirement for all bursary applications. Applications that do not include a full academic transcript will not be considered.”

The form separately asks for the applicant’s university, degree, year of study, expected graduation, university achievements, and university education history. It does not state that a matriculant with no university transcript may apply.

**Finding:** Matric documentation is required, but the form does **not** establish that a current Matric applicant without a tertiary transcript is eligible. The full-transcript rule should be treated as a compulsory requirement unless JG Afrika confirms an exception.

### Current submission status

The official page currently displays the 2027 application form, required fields, document upload area, consent declaration, and CAPTCHA. The page states that 2027 applications opened in August 2026. The LinkedIn announcement states that applications are now open and directs applicants to the website.

This is sufficient to say that the provider is presenting the application route as open on the audit date. It is not proof that a submission would be accepted end-to-end because no form was submitted and no CAPTCHA or external submission workflow was bypassed.

**Finding:** application route is **apparently open and publicly presented as open**, but technical submission acceptance remains untested and should not be represented as guaranteed.

### 1 January 2027 date

The official form says:

> “If you have not received confirmation of your bursary application by 01 January 2027, please assume that your application has been unsuccessful.”

This is a notification/non-selection date. It is **not** an application deadline. The official page does not publish a closing deadline.

**Finding:** retain the 1 January 2027 date only as a notification/unsuccessful-application date. Do not populate `deadline` with it.

## Provider-confirmed application requirements

The actual form requires or requests the following information and documents:

- Applicant surname, first names, date of birth, ID number, gender, race, postal address, residential address, home phone, cell phone, email, home language, and other languages.
- 2027 year of study, whether the degree is four or five years, university name, degree details, and expected graduation date.
- Estimated 2027 tuition, residence, textbook, other, and total costs.
- Existing bursary or funding details.
- Education history, including high school and university information.
- Academic, sporting, and leadership achievements.
- Current sport, hobbies/interests, other information, and career plans.
- Parent/guardian identity, addresses, contact information, occupations, and monthly incomes.
- A motivation paragraph.
- A copy of the applicant’s ID.
- A copy of the Matric certificate.
- Details of existing funding or approved bursaries.
- A complete academic transcript from first year to current, stated as mandatory for all applications.
- Supporting documents uploaded in accepted file formats, without password protection.
- POPI Act and terms-and-conditions consent.
- CAPTCHA completion.

The provider says incomplete applications or applications with missing supporting documents will not be processed. The form does not state an award amount, living-cost benefit, or guaranteed funding outcome. None should be added to Scholars.

## Conditional copy-ready `how_to_apply` text

Because nationality and university-location eligibility remain unresolved, the following is **not approved for publication**. It is the exact conservative draft that could be used only after JG Afrika confirms that Nigerian citizens are eligible and the founder approves the catalogue audience decision:

> Apply through the official JG Afrika 2027 Bursary application form on the JG Afrika website. The provider lists BSc or BEng Civil Engineering and MSc or MEng Civil Engineering as eligible qualifications. The form asks for your personal details, university and degree information, 2027 study year, expected graduation date, estimated study costs, existing funding details, education history, academic/sporting/leadership achievements, career plans, and parent/guardian information. Attach a motivation paragraph, a copy of your ID, a copy of your Matric certificate, details of any existing funding or approved bursary, and a complete academic transcript from your first year to your current year. The provider states that a full transcript is mandatory and that incomplete applications or missing documents will not be processed. Do not upload password-protected documents. Complete the POPI consent declaration and CAPTCHA, then submit through the official form. The provider says that if you have not received confirmation by 1 January 2027, you should assume that your application was unsuccessful; this date is a notification date, not an application deadline. The official form does not state whether South African citizenship is required, whether Nigerian citizens are eligible, or whether the university must be in South Africa. Confirm those eligibility points with JG Afrika before applying.

## Clarification request to JG Afrika

The unresolved eligibility questions should be sent through the provider’s official HR contact, `hr@jgafrika.com`, or another official provider contact channel:

1. Is South African citizenship mandatory for the 2027 JG Afrika Bursary?
2. May Nigerian citizens apply?
3. May other African citizens apply?
4. Must the applicant attend or intend to attend a South African university, or is any accredited university accepted?
5. Is a current university transcript mandatory for every applicant, including applicants entering university from Matric?
6. Are MSc and MEng Civil Engineering applicants eligible in the same cycle as BSc and BEng applicants?
7. Is the form currently accepting submissions, and is there a closing date that is not displayed on the public page?
8. Does 1 January 2027 refer only to notification of unsuccessful applications?

Until these questions are answered, Scholars should not describe the opportunity as open to Nigerian undergraduates.

## Production snapshot

A read-only Supabase query was run against the exact UUID on **7 November 2026**. The current row is:

| Field | Current value |
|---|---|
| `id` | `64790f70-f20a-4c9c-a1f4-2efabc087dcb` |
| `title` | `JG Afrika Bursary 2027` |
| `application_url` | `https://www.jgafrika.com/careers-offered-at-jg-afrika/bursary/` |
| `how_to_apply` | `NULL` |
| `opens_at` | `NULL` |
| `deadline` | `NULL` |
| `last_cycle_closed_at` | `NULL` |
| `last_verified_at` | `NULL` |
| `verified` | `true` |

These values match the Phase 1.2 snapshot. No production correction, verification timestamp, audience flag, or catalogue change was made.

## Final recommendation

Amend the Phase 1.2 matrix entry from **SAFE TO CORRECT** to **EXCLUDE/RESTRICT FROM NIGERIAN CATALOGUE**. Do not approve Batch 1. Keep the row unchanged until JG Afrika answers the nationality and university-location questions or the founder approves a separate South Africa/international catalogue policy.

The opportunity may be a legitimate and currently presented 2027 bursary, but the provider-confirmed evidence does not establish that it belongs in Scholars’ Nigerian undergraduate catalogue. A future implementation, if approved, must be limited to provider-confirmed qualifications and documents and must not add a deadline, award amount, nationality rule, or university restriction that the provider has not published.

**No Supabase writes, production record changes, code changes, schema changes, configuration changes, deployment, merge, or application submissions occurred. Batch 1 is not approved.**

## References

[1]: https://www.jgafrika.com/careers-offered-at-jg-afrika/bursary/ "JG Afrika official 2027 bursary page and application form"
[2]: https://www.linkedin.com/posts/jg-afrika-pty-ltd_jgafrika-bursaryopportunities-activity-7496086303910985729-x31d "JG Afrika official LinkedIn 2027 bursary announcement"
