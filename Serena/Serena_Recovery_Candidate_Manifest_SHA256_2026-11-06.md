# Verified Serena Recovery Source Manifest and SHA-256

**Purpose:** Local provenance record for the recovered source patch; this is not a release approval.

**Baseline:** `6bb268b216b6250e4ae64b73b9f6c2a85f31e686` (parent `76a470a3fd8b1c2de2adadea5939db41311deb72`)
**Claimed recovery commit:** `97ed7b913659d05b920da89477020e822484c671` — not found in remote refs or local Git object database.
**Patch:** `Serena_Recovery_Engine_COMPLETE.patch` — 92,964 bytes, SHA-256 `563c58a0e21c139734ee5c2935c26899d99f89552713474bb3e52b96748346f5`.
**Patch application:** `git apply --check` PASS; apply PASS. Exact path set equals manifest: 16/16. Per-file hashes match supplied checksum list: 16/16.
**Candidate status:** Review-only reconstruction; blocked from release pending atomic-finalization fix, migration-version reconciliation, safe backend-role confirmation, client-role revokes, Vercel duration verification, and formatting corrections.

| SHA-256 | Status | Path |
|---|---|---|
| `e2ea6632d48493cdf389fe3b4e09a13626c43901ae5460920d74e8e8c8b00ecc` | MATCH | `docs/SERENA_RECOVERY_HANDOFF_2026-11-04.md` |
| `34b51585ac52c8bbc9b9fbca9d70f248d19e1d99f6f8f4ff5ffffe3161f5cf4f` | MATCH | `docs/deployment.md` |
| `1bc9be5fb1c03bb6a9403694bf9092ef3124b8e534f0097dfa72d9e13539626b` | MATCH | `frontend/src/app/App.tsx` |
| `bce30d0496cfaaf5c152631514f66ed8d0b375b22fb94f187d016df9b8f58fe3` | MATCH | `frontend/src/app/api.ts` |
| `195069caa1d7bdd0161ddefd8106a073681b3fda6bc207dfcf44c548f8445691` | MATCH | `frontend/src/app/types.ts` |
| `c47e5b347297c7fd86cc9bc6b202ea51f2542b7a9c0b08c59bd1644c79222a4f` | MATCH | `frontend/src/components/ResearchHistory.tsx` |
| `8ad9096b2623413444c555819679fd77492bea30946abc243fef75a1ecad970b` | MATCH | `frontend/src/components/ResearchResult.tsx` |
| `a5a2c938c92b3d6652b4e917d7669b3f1469aa610ebdc2dbe58bf3a9956c6c55` | MATCH | `frontend/src/components/ResearchResultsScreen.tsx` |
| `c50f1b761e3453677c5ef71592312af6e9032733c3cb67028243e79d545b0e0a` | MATCH | `src/api/app.ts` |
| `6b77c97b294e01a7ee79da5afaf3fecfdd8dde5932b613f94869a3910568f427` | MATCH | `src/persistence/in-memory-task-repository.ts` |
| `0a0c0bd608916432d978ef1befd45a464342201a419cec1729d590fcad0b9c8b` | MATCH | `src/persistence/postgres-task-repository.ts` |
| `40dd0a77c202c23aceebf65df6c575c003a8adbcf3cc2d05eff289889396b65c` | MATCH | `src/persistence/task-repository.ts` |
| `41db4264ab1dac2b65b6c5fb931aceeb00ae1c8374c9fbe5d1833b14ef16efd3` | MATCH | `src/research/research-analysis-service.ts` |
| `385075097ca5a5fcf88d2bebab7980fbb673775411313a99fa7f667bbb5a2c3a` | MATCH | `src/research/research-service.ts` |
| `3a39b15c898afdac156de31c39ec4bab4ee8f20e79922701c79408a09e4e16fe` | MATCH | `supabase/migrations/20261103090000_research_analysis_attempts.sql` |
| `f56967caeb89b002d249ce9b456e6de2d37f7d045b7d9fa4224f2faa974d6340` | MATCH | `tests/research-analysis-service.test.ts` |

## Changed-path set

```text
M  docs/deployment.md
M  frontend/src/app/App.tsx
M  frontend/src/app/api.ts
M  frontend/src/app/types.ts
M  frontend/src/components/ResearchHistory.tsx
M  frontend/src/components/ResearchResult.tsx
M  frontend/src/components/ResearchResultsScreen.tsx
M  src/api/app.ts
M  src/persistence/in-memory-task-repository.ts
M  src/persistence/postgres-task-repository.ts
M  src/persistence/task-repository.ts
M  src/research/research-service.ts
A  docs/SERENA_RECOVERY_HANDOFF_2026-11-04.md
A  src/research/research-analysis-service.ts
A  supabase/migrations/20261103090000_research_analysis_attempts.sql
A  tests/research-analysis-service.test.ts
```

No Git commit, branch, PR, push, merge, deployment, production schema change, or environment-variable modification was made.

## Review-only source bundle

- Archive: `Serena_Recovery_Candidate_REVIEW_ONLY_2026-11-06.tar.gz`
- Size: 192,036 bytes; 133 archive entries.
- SHA-256: `d4459aace10764ea9a87711cef2ea6560963472a45014860a2e158927632627c`.
- Contents: clean baseline plus the checksum-verified recovery patch. `.git`, dependency directories, build output, Vercel metadata, and `.env*` files were excluded. This bundle is for review/reproduction only; it is **not release-ready** and its contents were not modified to address audit findings.
