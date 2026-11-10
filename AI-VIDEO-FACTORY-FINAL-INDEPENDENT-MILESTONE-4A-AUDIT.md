# AI Video Factory — Final Independent Milestone 4A Audit

**Audit date:** 2026-11-05  
**Repository:** `ImperioKDB/ai-video-factory`  
**Audited ref:** `milestone-4a-reliability` at `cc9ca628b09cec36b4e82e6f9d35e69fb1e8d3ad`  
**Implementation commit:** `079d8819a6a2cd9886d3a6a6d5855e6a8dc8402e`  
**Handoff metadata commit:** `cc9ca628b09cec36b4e82e6f9d35e69fb1e8d3ad`  
**Working method:** Read-only inspection and tests in a fresh temporary clone at `/tmp/ai-video-factory-audit.51dSMv/repo`. No source edits, commits, pushes, merges, PRs, GitHub Actions dispatches, Piper downloads, dependency upgrades, paid services, or destructive fault injection were performed.

## 1. Executive verdict

# FAIL — NOT READY TO MERGE

The implementation materially improves normal render verification and passes the documented local gates. However, the review found high-severity transaction and concurrency issues that prevent establishing the stated reliability guarantees:

1. **Process termination bypasses rollback and lock release.** The old output/manifest are moved away before rendering; the new MP4 and manifest are published in separate operations. SIGKILL, process/host crash, or power loss can leave missing or mixed-generation files, and there is no startup recovery for archived `.previous-*` files. This is distinct from the documented lack of full power-loss durability: even ordinary process termination can bypass JavaScript `catch`/`finally`.
2. **Stale-lock reclamation is not atomic.** Two contenders can both classify one stale lock as reclaimable. After one contender replaces it with a fresh lock, the other can unlink the replacement and create another lock. Both may then publish to the same output concurrently. The existing stale-lock test is single-contender only.
3. **Workflow render failures can be masked by `tee`.** Both render steps pipe `npm run render` to `tee` without `set -o pipefail` or checking the renderer's `PIPESTATUS`. A renderer failure can be hidden if later steps happen to accept the resulting artifacts.

These are not resolved by the passing tests. Additional medium-severity concerns include best-effort rollback that silently ignores restore failures, lexical rather than canonical lock paths, path-based output/manifest TOCTOU, and test assertions that are narrower than the claims they support.

## 2. Repository identity and branch evidence

The public remote was fetched in a fresh clone. The detached audit checkout was pinned to the requested commit and had a clean tracked worktree before tests. The remote refs observed were:

| Ref | Observed SHA | Expected | Result |
|---|---|---|---|
| `origin/milestone-4a-reliability` | `cc9ca628b09cec36b4e82e6f9d35e69fb1e8d3ad` | same | Match |
| `origin/main` | `a3a1d827e8ec8168550be608bb89ccb959154c4f` | same | Match |
| `origin/milestone-3-continuation` | `fbad579515cd7712363296414385c69fc5f2332c` | same | Match |

The audit clone was detached at the expected SHA rather than checked out as a local named branch; GitHub’s remote milestone branch points to that exact commit. The implementation and handoff commit objects resolve to the reported SHAs. No protected branch was modified.

The corrective range changes `package.json` to add the `test:workflow-safety` script; it does not change `package-lock.json` or upgrade dependencies. `npm ci` created only ignored local install/build/test artifacts in the temporary audit clone.

## 3. Corrective commit review

The corrective changes add or strengthen invocation IDs, manifest checks, output identity checks, transactional rollback, output locks, workflow path validation, audio regression checks, timestamp checks, and explicit v1 manifest incompatibility. The changes are focused and the claimed normal-path behavior is substantially represented in code and tests.

The principal residual issue is that normal exception handling is not equivalent to crash consistency or pair-level atomicity. `scripts/render.ts:132-138` archives prior files separately; `:177-205` publishes the MP4 and manifest separately and marks committed only after identity verification; `:214-224` contains process-local cleanup/rollback. A process termination bypasses those JavaScript handlers. At `:216-219`, rollback removal/renames are also best-effort in ways that can leave an inconsistent pair or suppress the actual restoration failure. The existing rollback regression covers an ordinary early failure, not process termination or failures during rollback operations.

**Classification:** PARTIALLY FIXED. Normal caught error restoration is tested; crash recovery and failure-atomic pair publication are not established.

## 4. Manifest identity

**Classification:** VERIFIED FIXED for ordinary ID/status correlation; PARTIALLY FIXED as an independent trust guarantee.

`scripts/render.ts:118-120,179-204` creates a render UUID, places it in the manifest, and checks the published manifest against that ID. `scripts/test-render.ts:37-38,109-116` requires `RENDER_ID` and passes it to manifest verification; `src/render-manifest.ts:162-179` checks identity and status. The reliability test at `scripts/test-reliability.ts:173-175` checks a wrong ID, and further cases check invalid status/schema and missing/malformed manifests.

The expected ID is supplied through caller-controlled environment state. This is useful for detecting an accidentally stale manifest when the workflow correctly captures the just-completed renderer's ID, but it is not a cryptographic or independently trusted invocation token: a caller that can choose the environment can select an ID from a different manifest. The appropriate claim is correlation under a trusted orchestrator, not proof against a malicious caller.

Default verification requires a valid manifest; explicit `--allow-missing-manifest` is a separate opt-in that warns and returns without marking a manifest verified. Manifest v1 is explicitly unsupported, while brief v1 remains supported; see section 11.

## 5. Snapshot integrity and TOCTOU

**Brief: VERIFIED FIXED. Output: PARTIALLY FIXED.**

The renderer and verifier each read the brief bytes once, hash that byte buffer, and parse the same buffer (`scripts/render.ts:139-141`; `scripts/test-render.ts:39-42`). This closes the ordinary brief reread mismatch between parsing and hashing.

The verifier captures `dev`, `ino`, `size`, and `mtimeMs`, runs probe/decode/hash through path-based tools, and compares those metadata fields afterward (`scripts/test-render.ts:44-46,48-89`). This detects many persistent ordinary replacements or mutations. It does not pin all operations to one open file descriptor or immutable snapshot. A replacement/mutation that preserves size/time metadata, a file changed and restored between checks, timestamp-granularity differences, or symlink retargeting can make probe/decode/hash observe different path contents without necessarily changing the final metadata tuple. The final SHA-256 is a strong content digest for the bytes read by hashing, but it does not prove those are the same bytes that FFprobe and FFmpeg decoded.

Manifest verification also reads, checks, and atomically rewrites by pathname (`src/render-manifest.ts:162-170`); atomic replacement avoids partial JSON writes but is not compare-and-swap against a concurrent writer or symlink/path replacement.

**Limitation correctly documented:** output checks detect ordinary replacement/mutation and do not claim a universal immutable read lock. The remaining race is bounded by that documented limitation but does not support adversarially race-free verification.

## 6. Transaction and rollback

**Classification: NOT FIXED for crash/termination consistency; PARTIALLY FIXED for caught errors.**

`scripts/render.ts:132-138` moves existing MP4 and manifest to separate run-suffixed archives before input validation and rendering. It then encodes to a temporary output, renames the MP4 into its final path, writes the manifest, validates identity, and sets `committed` (`:152-205`). On caught failures, `:214-220` attempts to remove new artifacts and restore archived files.

Consequences:

- A kill/crash after archiving but before publication leaves final output/manifest missing and archives stranded.
- A kill/crash after MP4 publication but before manifest publication can expose a new MP4 with no manifest (or a restored old manifest only if the process catch runs).
- During separate path operations, readers that do not take the renderer lock can observe missing or mixed generations.
- No startup recovery scans run-scoped archives after process termination.
- Rollback renames use `.catch(() => undefined)` (`:217-219`), hiding failed restoration. If removal of a new output at `:216` throws, control exits that catch path before the restore attempts. The resulting state and error may be ambiguous.
- `committed = true` occurs before archive deletion (`:205-207`); a cleanup error may report failure after the new pair is committed and leave one archive behind.
- There is a smaller temporary-directory leak possibility if `publicationDir` creation succeeds but `framesDir` creation fails before the inner cleanup `try/finally` begins (`:152-155`).

The tested failure at `scripts/test-reliability.ts:207-220` is an ordinary pre-publication missing-input error and demonstrates restoration for that case. It does not exercise interruption or rollback I/O failures.

## 7. Locking and concurrency

**Classification: NOT FIXED — high-severity race in stale reclamation; PARTIALLY FIXED for ordinary lock contention.**

`src/render-support.ts:117-154` uses exclusive lock-file creation and token-checked release, which is useful for ordinary same-path contention. It does not safely serialize every physical output alias or concurrent stale recovery:

- **Stale reclaim race:** `:127-138` reads/stats a lock, decides it is stale, unlinks by pathname, then recursively creates a new lock. Two contenders can both inspect the old stale lock; after A replaces it, B may unlink A’s fresh lock and create its own. Both processes may then believe they own the output lock. The test at `scripts/test-reliability.ts:116-121` exercises one dead-PID recovery, not simultaneous reclaimers.
- **Owner liveness:** same-host `process.kill(pid, 0)` is used (`:130-134`). A PID reused by another process may keep a stale lock alive. Errors other than a confirmed `ESRCH`, including `EPERM` (process exists but cannot be signaled), are treated as dead and may make a live owner's old lock reclaimable after 60 seconds. Hostname labels can differ or collide across container/VM namespaces. A normally detectable same-host live PID is not stolen solely because it has run longer than 60 seconds; the problem is reliability of the owner test and the reclaim race.
- **Aliases and collisions:** lock names are based on the lexical output path (`:119-120`) and renderer paths use `path.resolve`, not physical canonicalization (`scripts/render.ts:21,25-26`). Symlinked parent aliases can point at the same physical output while using different locks. Only exact resolved-string equality between manifest and output is rejected (`scripts/render.ts:119`). Distinct outputs sharing a manifest path or overlapping with another output/lock/archive namespace are not serialized by the output-only lock.
- **Release ownership:** token checking before unlinking is a positive safeguard (`:143-151`), but pathname replacement between token read and unlink is another path-level race.
- **Malformed/partial lock:** a failed write after exclusive file creation, or abrupt termination during lock creation, can leave malformed metadata that conservative parsing retains indefinitely, blocking that destination (`:121-140`).

The active-lock-over-60-seconds case is not a simple fixed timeout lease: a lock whose same-host owner is reliably found remains protected. However, the stale recovery algorithm and identity model do not provide the stated “active lock must never be stolen” guarantee under all documented challenge conditions.

## 8. Workflow security

**Classification: PARTIALLY FIXED.**

Positive findings in `.github/workflows/render-video.yml:62-76`: control characters are rejected, the requested path is resolved and confined under the repository root, the candidate is quoted, the file is required, and `$GITHUB_OUTPUT` uses fixed-format `printf`. The static safety test passed. Workflow permissions are limited to `contents: read`; cancellation is scoped by workflow/ref; Piper installation and narration are opt-in; artifact upload follows verification and uses `if: success()` (workflow lines 37-42, 100-127, 161-170). The matching render ID is passed to the verifier in both silent and narrated paths.

**Finding — render failure masking:** the render commands at workflow lines 133-136 and 143-146 pipe `npm run render` to `tee render.log`, then extract a nonempty ID. With no `set -o pipefail` or explicit check of the renderer’s `PIPESTATUS`, the pipeline status is generally `tee`’s status. This can mask a nonzero renderer exit. Subsequent verification may catch many failed renders, but that is not a substitute for preserving the render command’s exit code.

The path safety check resolves a path and then subsequently uses the original pathname, leaving a theoretical check/use race if another actor can mutate the ephemeral job workspace concurrently. No such actor was demonstrated. `scripts/test-workflow-safety.ts` is a static regex test, not runtime testing with hostile filenames or symlink races.

No workflow was dispatched.

## 9. Audio signal tests

**Classification: PARTIALLY FIXED; useful coarse smoke checks, not proof of the broader audio claims.**

`scripts/test-reliability.ts:147-165` checks selected windows from deterministic tones. It demonstrates approximate audio presence, fade direction at a few points, measurable ducking, narration contrast, and peak headroom in a short narration-active window. The test passed.

Boundaries of the evidence:

- Gain compares a 150 ms filtered window with a ±4 dB tolerance; this is coarse and does not robustly verify gain under broader content or limiter action.
- Fade assertions use several samples, but can miss local reversals, plateaus between samples, or inaccurate precise endpoints.
- Narration is checked at selected times (pre, active, post); the start boundary and exact trim are not located, and substantial leakage outside sampled windows can escape detection.
- Ducking only requires a measurable >2 dB reduction, not the requested attenuation depth. The test does not isolate possible leakage throughout the signal or verify all sidechain settings.
- Clipping is checked only in one 150 ms active window, not across the entire output.
- Duration tolerances do not prove sample-level synchronization or exact audio/video start/end alignment.

The project documentation appropriately disclaims exact sample-level audio/video sync. Broader claims about calibrated gain, specified duck depth, precise narration boundaries, or whole-file clipping resistance should remain qualified.

## 10. Frame timestamp verification

**Classification: PARTIALLY FIXED.**

`scripts/test-render.ts:21-29` extracts `best_effort_timestamp_time` and checks each parsed adjacent interval against 1/30 second ±2 ms. This catches ordinary cadence deviations, duplicates, and non-monotonic intervals among parsed values. The normal rendered fixture passed.

The parser filters blank values (`:22-24`), does not require parsed timestamp count to equal expected/reported frame count, does not constrain first/final timestamps against the expected timeline, and does not directly verify audio/video stream start-time alignment. The report’s claim that every frame interval is checked is therefore conditional on FFprobe emitting a complete parseable row for every frame. No negative fixtures cover missing rows, VFR, duplicate timestamps, or end-frame/timeline mismatch. These gaps limit coverage; they do not negate the positive normal-file cadence test.

## 11. Manifest compatibility

**Classification: VERIFIED FIXED / documented intentional incompatibility.**

Manifest v2 is the enforced schema and manifest v1 is explicitly unsupported in the README, ADR, and handoff; existing v1 records require regeneration. Brief v1 compatibility remains supported. Normal verification fails for a missing manifest; the explicit missing-manifest legacy option is opt-in and does not silently mark the output’s manifest verified. No undocumented compatibility break was identified in this decision.

## 12. Test quality and execution results

The requested commands were run in the isolated clone after `npm ci`. `npm ci` exited 0. Exact gate results:

| Command | Exit | Result |
|---|---:|---|
| `npm run typecheck` | 0 | PASS |
| `npm run test:brief` | 0 | PASS |
| `python3 -m py_compile scripts/narrate.py` | 0 | PASS |
| `npm run build` | 0 | PASS; existing Vite CJS API deprecation warning |
| `npm run test:workflow-safety` | 0 | PASS |
| `npm run test:reliability` | 0 | PASS |
| `git diff --check` | 0 | PASS |

The reliability test is meaningful for ordinary manifest mismatch/status/schema failures, required missing-manifest behavior, one stale-dead-PID lock recovery, basic lock contention, and one early caught render failure with restoration. It does not cover the high-risk simultaneous stale-reclaim race, renderer process termination at each publication boundary, forced rollback failures, symlink/path aliases, or host/PID/permission edge cases. The workflow test checks expected source text patterns and does not execute adversarial workflow input cases. Passing local gates is evidence for the implemented test scope, not evidence against the static high-severity issues above.

No destructive fault injection was performed. Process-termination/crash guarantees are classified from static lifecycle analysis, not an executed kill test.

## 13. Dependency audit

`npm ci` reported **4 vulnerabilities: 1 high and 3 moderate**. A read-only `npm audit --json` was also performed by an independent reviewer and reported the same count. The cited dependency path includes pinned Vite 5.4.21 and transitive esbuild 0.21.5; no fix was applied or dependency changed. Practical exposure is usage-dependent: the app’s development server binds to `0.0.0.0`, so development-server advisories deserve attention when reachable on an untrusted network. The audit result is not evidence that the production renderer is automatically exploitable. No package upgrade was attempted, per instruction.

## 14. Remaining limitations and findings classification

| Area | Classification | Severity / summary |
|---|---|---|
| Manifest ID/status in normal trusted workflow | VERIFIED FIXED | Low residual; checks are present and wrong-ID test exists. |
| Caller-independent render invocation proof | PARTIALLY FIXED | Medium; `RENDER_ID` is caller-supplied correlation, not a trust boundary. |
| Brief byte snapshot | VERIFIED FIXED | Same bytes are parsed and hashed. |
| Output immutable snapshot / TOCTOU | PARTIALLY FIXED | Medium; path-based checks detect ordinary persistent changes, not all races. |
| Caught-error rollback | PARTIALLY FIXED | Ordinary early-failure restore passes. |
| Process termination / crash consistency | NOT FIXED | High; bypasses handlers and can strand archives/missing or mixed pair. |
| Stale lock reclamation race | NOT FIXED | High; check/unlink/replace sequence can grant two owners. |
| Lock alias/PID/host edge cases | PARTIALLY FIXED | Medium; canonical identity and robust owner liveness are not established. |
| Workflow input/path protections | VERIFIED FIXED for stated common cases | Static checks and code support basic protections. |
| Workflow render exit propagation | NOT FIXED | Medium; pipeline can mask renderer failure. |
| Audio regression coverage | PARTIALLY FIXED | Coarse selected-window checks pass; precision claims exceed scope. |
| Frame cadence verification | PARTIALLY FIXED | Adjacent cadence checked; full coverage and endpoint alignment are not proven. |
| Manifest v1 policy | VERIFIED FIXED | Explicit, consistent, intentionally breaking decision. |
| Local gate execution | VERIFIED FIXED | All prescribed commands passed in isolated checkout. |
| Dependency findings | NOT APPLICABLE to corrective patch; unresolved | Existing high/moderate advisories remain; no upgrade attempted. |

## 15. Merge recommendation

**Do not merge this branch yet.** At minimum, address and independently re-audit:

1. Crash/termination consistency across archive, MP4 publication, and manifest publication; add a recovery protocol or narrow the guarantee so process-crash safety is not claimed. Pair-level visibility must be considered for readers that do not honor the renderer lock.
2. Atomic stale-lock reclamation that cannot unlink a replacement lock after another contender has acquired it; add a deterministic concurrent stale-recovery test. Strengthen owner-liveness handling so `EPERM`, PID reuse, and host identity ambiguity cannot steal a live lock.
3. Preserve renderer pipeline failure status in Actions (`set -o pipefail` or explicit `PIPESTATUS` handling).
4. Make rollback errors observable and test restoration failures; validate path aliases and manifest/output namespace collisions.
5. Bound claims for audio and frame timestamp checks to what the tests actually measure, and add negative tests for missing frame rows and key audio regressions if stronger claims are required.

The current branch is a meaningful improvement over the prior rejected revision, but the evidence does not support `PASS — READY FOR MERGE` or `CONDITIONAL PASS` under the provided decision criteria because high-severity integrity/concurrency issues remain.
