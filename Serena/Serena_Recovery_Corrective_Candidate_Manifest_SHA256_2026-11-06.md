# Corrective Candidate Manifest and SHA-256

**Branch:** `serena/recovery-corrective-2026-11-06` (local only; no commit/push).
**Base:** `6bb268b216b6250e4ae64b73b9f6c2a85f31e686`.
**Original recovered patch SHA-256:** `563c58a0e21c139734ee5c2935c26899d99f89552713474bb3e52b96748346f5`.
**Verification:** backend 131/131 tests, backend typecheck/build/lint, frontend typecheck/build, focused Prettier, and `git diff --check` pass. No Postgres transaction-integration test, Supabase CLI migration-list, Vercel effective-duration check, production migration, or deployment.
**Release status:** local corrective candidate only; still gated on runtime DB role and exact server-role privileges, Postgres transaction integration test, Vercel duration verification, and approval for any remote or production action.

| Change | Original path (if renamed) | Candidate path | SHA-256 |
|---|---|---|---|
| `M` | `docs/deployment.md` | `docs/deployment.md` | `34b51585ac52c8bbc9b9fbca9d70f248d19e1d99f6f8f4ff5ffffe3161f5cf4f` |
| `M` | `frontend/src/app/App.tsx` | `frontend/src/app/App.tsx` | `1bc9be5fb1c03bb6a9403694bf9092ef3124b8e534f0097dfa72d9e13539626b` |
| `M` | `frontend/src/app/api.ts` | `frontend/src/app/api.ts` | `bce30d0496cfaaf5c152631514f66ed8d0b375b22fb94f187d016df9b8f58fe3` |
| `M` | `frontend/src/app/types.ts` | `frontend/src/app/types.ts` | `195069caa1d7bdd0161ddefd8106a073681b3fda6bc207dfcf44c548f8445691` |
| `M` | `frontend/src/components/ResearchHistory.tsx` | `frontend/src/components/ResearchHistory.tsx` | `de492e196cfdec30c90907d86808030ae773b776b47c78118709a90c3ca8230d` |
| `M` | `frontend/src/components/ResearchResult.tsx` | `frontend/src/components/ResearchResult.tsx` | `8ad9096b2623413444c555819679fd77492bea30946abc243fef75a1ecad970b` |
| `M` | `frontend/src/components/ResearchResultsScreen.tsx` | `frontend/src/components/ResearchResultsScreen.tsx` | `a5a2c938c92b3d6652b4e917d7669b3f1469aa610ebdc2dbe58bf3a9956c6c55` |
| `M` | `src/api/app.ts` | `src/api/app.ts` | `8c7431b52505e325b93e9de6fc56083f1909daae4987a3249e64bfa76cd56aa1` |
| `M` | `src/persistence/in-memory-task-repository.ts` | `src/persistence/in-memory-task-repository.ts` | `39d646a606c27140feb6cb6f6bd178374b4d548a1a6dae3d69ad7d39c362a8f0` |
| `M` | `src/persistence/postgres-task-repository.ts` | `src/persistence/postgres-task-repository.ts` | `b58afd9573331313ffeaff4b2073be04600d7bfe24f77ccfc635818a3f2565be` |
| `M` | `src/persistence/task-repository.ts` | `src/persistence/task-repository.ts` | `1e086ddb18aef226b97bbfd18198f3ed64272af91239fb23f5f954f3aa581906` |
| `M` | `src/research/research-service.ts` | `src/research/research-service.ts` | `385075097ca5a5fcf88d2bebab7980fbb673775411313a99fa7f667bbb5a2c3a` |
| `R` | `supabase/migrations/20261011195000_initial_research_tasks.sql` | `supabase/migrations/20261011185158_initial_research_tasks.sql` | `0493bb8dfba3fe006459a8c58dfaee3820fec6c04c607cbdcba60efd665408ef` |
| `R` | `supabase/migrations/20261012122500_research_sources_evidence.sql` | `supabase/migrations/20261012112654_research_sources_evidence.sql` | `9b5f2d169a614cb8dfc7feb682277532cdc3d4ef33e0909f27f68e44e0fc7746` |
| `R` | `supabase/migrations/20261012123000_enable_rls_on_research_tables.sql` | `supabase/migrations/20261012113049_enable_rls_on_research_tables.sql` | `dfd2c8864c8e45c25ad3004359dfbb0d74a89bab675357d54540f25e1091890f` |
| `R` | `supabase/migrations/20261012204800_request_admission_limits.sql` | `supabase/migrations/20261012195728_request_admission_limits.sql` | `589256f1abf110e23f703372881a986ea8ee4b38cd20dd25e86ff52649580da2` |
| `R` | `supabase/migrations/20261012222000_research_task_owner.sql` | `supabase/migrations/20261012212648_research_task_owner.sql` | `7d44904d2004dc94b85f24ffa7fb4c829cd23ac873222b4e0f5f82151a6c299d` |
| `??` | `—` | `docs/SERENA_RECOVERY_HANDOFF_2026-11-04.md` | `e2ea6632d48493cdf389fe3b4e09a13626c43901ae5460920d74e8e8c8b00ecc` |
| `??` | `—` | `src/research/research-analysis-service.ts` | `8060b200aa30f97e59a5b3ef6e850287a64136b6c07f5c5a3eef27406bb27f61` |
| `??` | `—` | `supabase/migrations/20261103090000_research_analysis_attempts.sql` | `8aa23169f73c70fc5b077c2c4a5f3206e05aaf7b7e8ba82acb1be0d65bb64990` |
| `??` | `—` | `tests/research-analysis-service.test.ts` | `3fc50942dacd6963fbbbe35510e0330726f55f587f7dd44abb7b527d52d4455e` |

## Candidate archive

- File: `Serena_Recovery_Candidate_CORRECTED_LOCAL_2026-11-06.tar.gz`
- Size: 193376 bytes.
- Entries: 133.
- SHA-256: `8db41418bfb4a0aa32c3bbc2a318079dcfd30d134b8aa4b66220c017799457e8`.
- `.git`, dependencies, build outputs, `.vercel`, and `.env*` files are excluded.
