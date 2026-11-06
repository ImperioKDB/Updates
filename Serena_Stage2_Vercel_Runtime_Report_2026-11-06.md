# Serena Recovery Engine — Stage 2 Vercel Runtime Report

**Investigation time:** 2026-11-06, approximately 14:08–14:10 CET  
**Stage:** 2 — Verify effective Vercel runtime configuration  
**Verdict:** **FAIL — recovery-analysis endpoint is not present in the current production deployment; effective configured duration for that endpoint cannot be established.**

## Verified facts

- Vercel lists backend project **`serena`**, project ID **`prj_isitPHfi6fA9dHXAM10InktZsa9H`**, under team **`team_xPAueGwV3MitbRK6JLWqWNcQ`**. The separate frontend project is `serena-frontend` (`prj_AM00cIdRlDE4RbWrwTvmrQ2WtyOl`). The backend project's framework is reported as **Fastify**. The Vercel team context reports plan **Hobby**.
- The current production deployment is **`dpl_2RgcRJC4bBFvLwjeZV34CBJH2C7H`**, status **READY**, deployment URL [serena-f8otofaj5-imperiokdbs-projects.vercel.app](https://serena-f8otofaj5-imperiokdbs-projects.vercel.app), with production aliases `serena-theta-bice.vercel.app`, `serena-imperiokdbs-projects.vercel.app`, and `serena-git-main-imperiokdbs-projects.vercel.app`. It is built from `main` at commit **`6bb268b216b6250e4ae64b73b9f6c2a85f31e686`**. Deployment metadata reports region `iad1` and function type `LAMBDAS`.
- At that exact SHA, the public GitHub source tree contains `src/server.ts` and `src/api/app.ts`. The route file has existing research-task GET, DELETE, and POST creation routes, but no `POST /v1/research-tasks/:taskId/analyze` route. The separate recovery implementation commit noted in the supplied handoff is therefore **not** the code currently served in production. Vercel’s Fastify documentation says a Fastify application deploys as a single Vercel Function and recognizes `src/server.{js,mjs,cjs,ts,cts,mts}` as an entrypoint. The source and framework metadata are consistent with `src/server.ts` being the entrypoint; Vercel's deployment-file endpoint returned 404, so the generated deployed bundle itself could not be inspected.
- No `vercel.json` or `vercel.ts` exists at the deployed commit's repository root. Thus there is no repository-level `functions`/`maxDuration` override in those standard config files at that SHA. This does not prove the absence of build-generated settings or a dashboard-level project default.
- Current Vercel documentation states Hobby Functions have a maximum duration of **300 seconds** (with the documented Fluid Compute configuration), and that the project dashboard sets a default while code/config can set per-function duration. This establishes the plan ceiling, **not** the value saved on this Serena project or the effective duration for an analysis handler that is not deployed. [Vercel Function duration documentation](https://vercel.com/docs/functions/configuring-functions/duration) [Vercel Fastify documentation](https://vercel.com/docs/frameworks/backend/fastify)

## Configuration and adequacy assessment

The supplied roadmap says an owner screenshot showed a 300-second project-level setting, but that screenshot was not attached in this task. The Vercel project API response available here did not include the Function Max Duration field. The deployment source-file listing also failed with `404 File tree not found`, and the deployment metadata does not expose generated per-function duration. Consequently, the dashboard default, any generated/function-specific override, and the effective duration are **unverified**. I cannot treat the screenshot described in the roadmap as current live evidence.

Because the analysis route is absent from the current production commit, there is no exact production analysis function to evaluate against its model timeout, retries, persistence work, or HTTP response overhead. Vercel's documented Hobby maximum of 300 seconds would be a ceiling for a future deployment, not proof that a future recovery handler receives that duration. No setting change is indicated by this investigation, and none was made.

## Assumptions and unresolved questions

- The Vercel team plan and project/deployment responses returned by the connected Vercel integration represent the current account state at the investigation time.
- The project-level screenshot referenced by the roadmap was not present among the files available in this task, so its identity and recency cannot be checked.
- The precise project default and generated per-function maximum require an authenticated Vercel dashboard/CLI/API view that exposes the Function Max Duration or `vercel inspect` output for the relevant deployment. The connected read-only Vercel tools did not provide it.
- The recovery implementation needs a later approved deployment before its actual runtime can be evaluated. No deployment was triggered.

## Changes, checks, risks, and remaining work

**Changed:** None. No repository files, Git branches, Vercel settings, environment variables, Supabase objects, or deployments were changed.

**Read-only checks:** Vercel project list/details, team deployment context, production deployment list and detail, deployment file-tree lookup (404), public GitHub source/config inspection at the exact production SHA, and Vercel's official duration and Fastify documentation.

**Risks:** Treating the stated 300-second dashboard setting as the effective analysis-function duration would be unsupported. More importantly, the current production API does not include the recovery-analysis route; clients cannot exercise that feature against this deployment.

**Next action:** The owner already explicitly instructed continuation through the roadmap, so Stage 3's read-only migration review may proceed. To resolve the Stage 2 configuration uncertainty, provide current dashboard evidence or authorize authenticated dashboard inspection. Stages 4, 6, and 7 remain separately approval-gated for their exact production-changing actions, regardless of the general request to complete the roadmap.
