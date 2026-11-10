# Scholars Phase 2.1.8 — Runner Security Assessment

**Assessment:** Suitable for a harmless synthetic diagnostic only if the dispatch workflow is registered safely; not approved for production schema capture.
**Author:** Manus AI

Both repositories are public. Workflow source, run status, and logs are visible publicly. The requested diagnostic was designed to print only benign runner/tool pass/fail output, avoid secrets and checkout, and upload no artifacts. Public standard GitHub-hosted runners are documented as free; larger runners are not covered by that rule. No billing settings were changed. [1]

The proposed least-privilege configuration is `workflow_dispatch` only, `runs-on: ubuntu-24.04`, short timeout, `permissions: {}`, no third-party actions, no secrets, no artifact upload/cache, and explicit cleanup of the disposable PostgreSQL container and temporary files. An empty permission set avoids granting the workflow `GITHUB_TOKEN` repository access. Workflow code and every command would still be public, so output must never include environment variables, filesystem listings, hashes, or connection details. [2]

A public repo is not appropriate for a later production capture containing private schema definitions, even when table data is excluded. Database credentials must never be placed in a public workflow or logs. A schema dump and its hash can reveal proprietary structure and must stay in private encrypted storage. For production capture, use an approved private repository or other private execution environment, short-lived least-privilege database access, private logs, and restricted retention. This phase did not obtain credentials or connect to Supabase.

GitHub-hosted runner egress to Supabase was not tested. No private network path or database access should be assumed. A successful synthetic runner test would demonstrate only temporary Linux/container mechanics; it would not authorize production access. [3]

## References

[1]: https://docs.github.com/billing/managing-billing-for-github-actions/about-billing-for-github-actions "GitHub Actions Billing"
[2]: https://docs.github.com/actions/security-for-github-actions/security-guides/automatic-token-authentication "GitHub GITHUB_TOKEN Permissions"
[3]: https://docs.github.com/actions/managing-workflow-runs/manually-running-a-workflow "GitHub Manually Running a Workflow"
