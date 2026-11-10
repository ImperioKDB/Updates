# Scholars Phase 2.1.8 — GitHub Actions Eligibility

**Status:** Public standard-runner billing is eligible; the requested branch-only dispatch test is not triggerable without a default-branch workflow.
**Checked:** 2026-11-10
**Author:** Manus AI

## Repository and Actions state

GitHub API metadata confirms both `ImperioKDB/Updates` and `ImperioKDB/Scholars` are public, unarchived repositories on `main`. GitHub Actions is enabled for both, with allowed actions set to `all`; the repository workflow token default is read-only. The authenticated account has write/admin access to both repositories.

`Updates` has no workflow files or registered workflows on its default branch. `Scholars` has eight workflow files: `ci.yml` is push/pull-request driven; the other seven include `workflow_dispatch`, several alongside schedules. Those existing workflows are application jobs and were not run or repurposed. The requested `scholars-runner-preflight.yml` does not exist on either default branch.

GitHub’s manual-run documentation says the workflow file must be on the default branch for `workflow_dispatch` to receive events. Once registered there, a user with write access can select a different branch/ref to run it. Therefore, adding the requested new file only on `infra/phase-2-1-8-github-runner-preflight` in either repository would not make that new workflow dispatchable. Running an existing Scholars workflow would not test the requested diagnostic and could invoke unrelated application behavior. [1]

## Billing eligibility

GitHub’s current billing documentation states that standard GitHub-hosted runner usage in public repositories is free independently of included compute usage. This assessment applies to a standard `ubuntu-24.04` runner only—not a larger runner, private runner, artifact/cache storage, or other billed services. A no-artifact, no-cache diagnostic on a public repository is therefore expected to incur no Actions compute charge. No billing or repository setting was changed. [2]

The legacy user billing endpoint checked from this session returned HTTP 404, so personal usage or plan allowance was not read. That does not change the public-standard-runner pricing rule; the workflow must remain on a standard runner and avoid paid storage/features. [3]

## Decision on workflow creation

No branch or workflow was created. The requested dedicated file in a separate branch cannot be manually dispatched until that workflow exists on the default branch of the chosen repository. Adding it to `main` would violate the desired no-default-branch test. No harmless technical run can be truthfully claimed from the available repository state.

## References

[1]: https://docs.github.com/actions/managing-workflow-runs/manually-running-a-workflow "GitHub Manually Running a Workflow"
[2]: https://docs.github.com/billing/managing-billing-for-github-actions/about-billing-for-github-actions "GitHub Actions Billing"
[3]: https://docs.github.com/en/rest/billing/usage "GitHub REST Billing Usage API"
