SCHOLARS — PHASE 1.1 IMPLEMENTATION-READINESS AND DATA RECONCILIATION AUDIT

Project details

- Application repository: "ImperioKDB/Scholars"
- Reporting repository: "ImperioKDB/Updates"
- Production domain: "https://www.scholars.com.ng"
- Revalidation report: "SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_2026-11-07.md"
- Evidence directory: "SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/"
- Revalidation commit: "187621218ae89cfdb6b952d3edcf821715100776"

Objective

Prepare a technically verified, record-by-record implementation specification for the scholarship data corrections proposed in the Phase 1 revalidation report.

This is a READ-ONLY audit. Do not apply any corrections.

The purpose is to establish whether the proposed corrections are accurate, compatible with the current database schema, and safe for the existing Scholars application.

1. Strict restrictions

You may inspect:

- The current "main" branch of Scholars.
- Existing database migrations and schema definitions.
- Relevant TypeScript types, queries, components and lifecycle logic.
- Production scholarship records through read-only queries.
- Official public scholarship sources.

You must NOT:

- Insert, update or delete production records.
- Run migrations.
- Change database schemas, RLS, policies or functions.
- Modify application code or configuration.
- Deploy or merge anything.
- Create test scholarship records.
- Create accounts or submit external applications.
- Bypass access controls.
- Access student profiles, private matching data or authentication records.

Only a Markdown report may be created in "ImperioKDB/Updates".

2. Reconcile the actual production inventory

Run a fresh, reproducible, read-only query against production Supabase.

Report:

- Query execution date and time.
- Total scholarship rows.
- Verified scholarship rows.
- Verified records with usable slugs.
- Records with missing or blank "how_to_apply".
- Records with missing "last_verified_at".
- Records with missing deadlines.
- Records with past deadlines.
- Records with future deadlines and historical close markers.

Provide the SQL or exact query logic used.

For all 17 target records, retrieve the minimum required public fields:

- Database UUID.
- Scholarship title.
- Slug.
- Verification status.
- Application URL.
- Application instructions.
- Opening date.
- Deadline.
- Last-cycle closure date.
- Last verification timestamp.

Do not use slugs as substitutes for database UUIDs.

Reconcile the actual values against the Phase 1 report and identify every discrepancy.

3. Inspect the actual data model and application logic

Read the current code and schema to establish:

1. What fields exist for scholarship application instructions and URLs?
2. Is there a source URL or provenance field?
3. Does the schema support verification notes or uncertainty classifications?
4. Does the application support states such as "SOURCE_UNAVAILABLE" or "REQUIRES_MANUAL_REVIEW"?
5. What exactly does "last_verified_at" represent?
6. How do "deadline", "opens_at", and "last_cycle_closed_at" interact?
7. How does the frontend decide whether a scholarship is open, closed or upcoming?
8. Can a record be safely represented as a historical opportunity?
9. Are scholarship records distinguishable from paid educational programmes?

Do not invent new columns, enum values or status fields.

If the proposed editorial classifications cannot be represented by the existing schema, explain the limitation and propose a separate schema-design decision. Do not implement it.

4. Critical investigation: Decagon

This issue must receive special attention.

The official Decagon application page says applications are open:

"https://decagon.institute/apply"

However, its official fees page states that participants pay:

- ₦275,000 per year for the Honours Programme.
- University tuition and other school-related fees in addition to that programme fee.

Official fees page:

"https://decagon.institute/fees"

Determine whether the programme is genuinely a scholarship opportunity, a paid educational programme, or a programme with a separately documented scholarship/fee-waiver component.

Inspect official provider evidence for:

- Scholarships or fee waivers.
- Who receives financial assistance, if anyone.
- Whether the programme pays students or charges students.
- The actual financial benefit to an applicant.
- Whether the programme meets Scholars' existing definition of a scholarship.

Do not assume that an application form or an open application status makes something a scholarship.

If no official evidence establishes a scholarship award or fee waiver, recommend holding the record for editorial review rather than simply replacing its application URL.

Do not change the record.

5. Critical investigation: NDDC

Official scholarship portal:

"https://scholarship.nddc.gov.ng/login"

Official announcement:

"https://www.facebook.com/OfficialNDDC/posts/nddc-20262027-local-post-graduate-scholarship-call-for-applicationsthe-niger-del/1509046547707715/"

The published deadline is 8 November 2026.

Verify, without creating an account or submitting an application:

- Whether the official portal loads.
- Whether the portal displays account creation or login.
- Whether a current application form or programme-specific application route is publicly visible.
- Whether the official announcement still supports the stated deadline.
- Whether the application can actually be confirmed as accepting submissions.

Distinguish portal reachability from application availability.

If the form cannot be verified, preserve that uncertainty. Do not claim that applications are open solely because the deadline has not passed.

6. Validate all proposed corrections

For each of the 17 records, prepare a proposed old-versus-new comparison.

Include:

Field| Current production value| Proposed value| Evidence| Confidence| Schema-compatible?

Classify each proposed change as:

- CONFIRMED — supported by authoritative evidence.
- CONDITIONAL — supported only if an unresolved condition is satisfied.
- UNSUPPORTED — insufficient evidence; do not implement.
- MANUAL REVIEW — requires a human editorial decision.

Pay particular attention to:

- Decagon's classification as a scholarship.
- ASUU's lack of a verified central application route.
- Bode Amao's conflicting official submission channels.
- PAU's conflicting status information.
- NDDC's inaccessible or unconfirmed application workflow.
- Unsupported future dates.
- Historical application requirements that must not be presented as current-cycle requirements.

Do not remove a deadline or lifecycle field without explaining the effect on the existing application logic.

7. Verification timestamps and source provenance

Establish whether "last_verified_at" can safely represent the date a source was reviewed even when the current application status remains unresolved.

Do not treat a verification timestamp as proof that applications are open.

If the existing schema cannot distinguish:

- Source reviewed.
- Application status confirmed.
- Application portal inaccessible.
- Conflicting provider information.

Explain how this limitation should be handled without inventing unsupported database values.

8. Implementation safety assessment

Group proposed changes into:

- Batch A: confirmed application destination corrections.
- Batch B: confirmed application instruction corrections.
- Batch C: verification timestamps and provenance.
- Batch D: deadline and lifecycle corrections.
- Manual editorial decisions: records that cannot safely be changed yet.

For every batch, provide:

- Exact affected database UUIDs.
- Exact fields to change.
- Old and proposed values.
- Source evidence.
- Risk assessment.
- Expected frontend impact.
- Rollback considerations.

Do not execute any batch.

9. Required report

Create:

"SCHOLARS_PHASE_1_1_IMPLEMENTATION_READINESS_AUDIT_2026-11-07.md"

Commit it to "ImperioKDB/Updates".

Include:

1. Executive summary.
2. Fresh production inventory and reproducible query evidence.
3. Exact 17-record reconciliation.
4. Schema and application-logic findings.
5. Decagon classification investigation.
6. NDDC application-availability investigation.
7. Proposed correction matrix.
8. Verification timestamp and provenance assessment.
9. Batch-by-batch implementation plan.
10. Manual decisions and unresolved questions.
11. Audit-integrity declaration.

Explicitly confirm that no production data, code, schema, configuration or deployment was modified.

10. Final decision

End the report with one of:

- READY FOR LIMITED IMPLEMENTATION.
- READY WITH CONDITIONS.
- NOT READY FOR IMPLEMENTATION.

A recommendation of READY FOR LIMITED IMPLEMENTATION must mean that exact database UUIDs, field values, supporting sources and schema compatibility have all been established for the proposed batch.

Do not interpret this audit as authorisation to make changes. Wait for explicit approval.