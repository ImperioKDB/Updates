# Scholars Phase 2.1.8 — Final Decision

## **BLOCKED — REPOSITORY OR BILLING RESTRICTION**

The blocker is the GitHub repository’s manual-dispatch rule, not Actions billing. Both repositories are public and have Actions enabled. Standard GitHub-hosted Ubuntu runner compute in public repositories is documented as free. Updates has no workflow on `main`; Scholars has existing manual workflows, but none is the requested diagnostic. GitHub requires the new workflow file to be present on the default branch of whichever repository hosts it before it can receive `workflow_dispatch`; therefore the requested new workflow cannot be tested from the separate branch alone. [1] [2]

No workflow, branch, or runner job was created. The default branch was not changed. No run URL or job result exists. Existing Scholars workflows were not run because they are application operations, not the dedicated runner diagnostic. Docker, PostgreSQL 17, synthetic schema-only export, row exclusion, CLI version, hash, and cleanup remain unverified. No database, credential, paid resource, or artifact was used.

**To unblock:** The repository owner must explicitly choose either (a) permit a narrowly scoped diagnostic workflow to be registered on `main` and then manually run against the diagnostic branch, or (b) use another approved runner path that can execute the branch workflow without default-branch registration. Neither choice was authorized here. Do not proceed to production extraction from a successful synthetic test.

## References

[1]: https://docs.github.com/actions/managing-workflow-runs/manually-running-a-workflow "GitHub Manually Running a Workflow"
[2]: https://docs.github.com/billing/managing-billing-for-github-actions/about-billing-for-github-actions "GitHub Actions Billing"
