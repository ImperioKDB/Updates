# AI Video Factory — Independent Milestone 4A Code Review

**Repository:** [`ImperioKDB/ai-video-factory`](https://github.com/ImperioKDB/ai-video-factory)  
**Reviewed branch:** [`milestone-4a-reliability`](https://github.com/ImperioKDB/ai-video-factory/tree/milestone-4a-reliability)  
**Reported final commit:** `e0d5f1175ac26b2ab7b2e5c3348d155c7a5ead51`  
**Review mode:** Read-only; no source, test, documentation, branch, workflow, or repository changes were made.

## A. Executive verdict

# REQUIRES SIGNIFICANT FIXES

Milestone 4A contains several real improvements and the branch state is correct, but it is not safe to merge as-is because the render manifest cannot yet be trusted as an audit record in all failure and stale-output scenarios. The MP4 verifier can pass while manifest verification fails, and it can mark an existing manifest as `verified` without proving that the manifest belongs to the current brief and the file currently being verified. A failed render can also leave an older output and manifest in place. Those behaviors directly undermine the milestone’s central objective: making every output reproducible, verifiable, and auditable.

The portability and path-resolution changes are directionally sound, and the local implementation has useful real integration coverage. However, the reliability suite is not sufficiently negative or cleanup-complete, and the new audio test proves successful mixed-file production more strongly than it proves gain, ducking, fade, placement, and synchronization behavior. These are fixable, but the manifest-integrity defects should be corrected before merge.

## Repository-state verification

The repository matched the supplied handoff:

| Ref | Observed SHA | Result |
|---|---|---|
| `main` | `a3a1d827e8ec8168550be608bb89ccb959154c4f` | Confirmed unchanged |
| `milestone-3-continuation` | `fbad579515cd7712363296414385c69fc5f2332c` | Confirmed unchanged |
| `milestone-4a-reliability` | `e0d5f1175ac26b2ab7b2e5c3348d155c7a5ead51` | Confirmed and matches report |

The working tree was clean and the Milestone 4A branch was two commits ahead of `milestone-3-continuation`. The remote heads matched the local observations. No newer competing Milestone 4 branch was found in the reviewed state.

## B. Verified claims

### Branch protection and scope

The branch was created from the reported Milestone 3 continuation tip. The diff contains the twelve reported files and does not modify `main` or `milestone-3-continuation`. The branch is pushed and clean. The two commits are:

- `9be8eede9639b473056cf5d802a40d9b1c771c8d` — `Improve render reliability and auditability`
- `e0d5f1175ac26b2ab7b2e5c3348d155c7a5ead51` — `Document Milestone 4A handoff`

### Tool portability implementation

`src/render-support.ts` does perform real executable checks. `ensureExecutable()` checks that the selected path is a regular file, repairs missing POSIX execute bits, and rechecks execute access. `verifyBundledTool()` then runs the selected binary with `-version`. The code uses the npm-selected paths and does not search `PATH` for a fallback binary. Errors include the selected path and platform/architecture.

The workflow preflight in `.github/workflows/render-video.yml` performs a similar mode repair and version check for the two npm-selected binaries. This is a genuine implementation, not merely documentation.

### Media paths

The TypeScript renderer resolves brief-declared media relative to `path.dirname(BRIEF_PATH)` and explicit environment overrides relative to `process.cwd()`. It checks each input before frame generation using `requireInputFile()`. Font package resolution uses the renderer script location rather than the caller’s current directory.

`scripts/narrate.py` now resolves a relative `narration.wavPath` against the brief’s parent directory. Absolute paths remain supported. The path contract is documented in the README and ADR.

The implementation intentionally permits `..`, absolute paths, and symlinks that resolve to regular files. That is consistent with the documented contract, but it means callers remain responsible for choosing trusted briefs and assets.

### MP4 checks

`scripts/test-render.ts` genuinely checks output existence, non-zero size, MP4 container identification, H.264, 1080×1920 dimensions, 9:16 numeric aspect ratio, nominal 30 FPS, duration tolerance, optional frame count tolerance, requested audio presence, AAC codec, audio duration alignment, and a full FFmpeg decode.

The checks are stronger than the Milestone 3 verifier and produce more actionable error messages. The existing local eight-segment artifact was independently schema-checked during this review; its manifest validated against `schema/render-manifest.schema.json`.

### Workflow safeguards

The workflow adds relevant-path filters, concurrency cancellation, opt-in Piper setup, conservative artifact retention, and a more robust bundled-tool preflight. The workflow was not executed during this review, as required.

### Zero-cost compliance

No workflow was dispatched, no payment method or billing was activated, and no paid service was used during this audit. The core review commands were local. The current dependency audit reports four findings: three moderate and one high, with the existing Motion Canvas/Vite dependency line involved. No dependency upgrade was performed.

## C. Defects and risks

### Finding 1 — High: Manifest verification is not bound to the current brief or output

**Location:** `scripts/test-render.ts:46-54`; `src/render-manifest.ts:99-106`.

The verifier derives a manifest path, checks only that the path exists, and then calls `markManifestVerified()`. `markManifestVerified()` parses the manifest, sets `status = 'verified'`, sets `decodeVerified = true`, refreshes the hash of `manifest.render.outputPath`, and writes the manifest. It does not verify that:

- `manifest.render.outputPath` equals the MP4 file passed to the verifier;
- `manifest.input.briefPath` equals the current `BRIEF_PATH`;
- `manifest.input.briefSha256` equals the current brief hash;
- the manifest’s existing output hash matches the file before updating it;
- the manifest was produced by the current render invocation;
- the manifest was previously in the expected `rendered` state.

**Why it matters:** A stale manifest from an earlier brief or output can be marked `verified` while the current verifier is checking a different brief/output pairing. The resulting audit record can claim a verified relationship that was never established.

**Reproducible scenario:** Preserve an older MP4 and sibling manifest, change `BRIEF_PATH` to a different valid brief, and run `test-render` against the old MP4. The MP4 checks can pass if the durations happen to align; the old manifest is then marked verified without a brief-hash or output-path identity check.

**Recommended correction:** Make verification require a manifest identity contract. Compare the manifest’s output path and input brief path/hash against the current invocation, require `status === 'rendered'`, and reject mismatches. Pass the current brief hash and verified output hash into the update function rather than allowing the update function to infer identity from a manifest-controlled path.

### Finding 2 — High: Failed renders can leave stale successful artifacts and manifests

**Location:** `scripts/render.ts:135-172`; manifest creation at `scripts/render.ts:150-169`.

The renderer writes the MP4 with FFmpeg’s `-y` flag but does not remove an existing output or sibling manifest before beginning a new render. If FFmpeg fails after an older output exists, the old output can remain. The old manifest also remains because manifest creation occurs only after successful encoding.

The statement that failed renders do not write a new success manifest is technically true, but it does not prevent an older success manifest from being mistaken for the current run’s result.

**Why it matters:** A caller or automation system can see a prior `verified` manifest and an old MP4 after a new render failure. That creates a false impression that the latest requested render succeeded.

**Recommended correction:** At render start, use a run-specific temporary output and manifest path. Publish the final MP4 and manifest only after encoding and probing succeed, preferably with atomic rename. Alternatively, remove or mark stale sibling artifacts at the start and include a run identifier in the manifest.

### Finding 3 — Medium: Manifest writes are not atomic

**Location:** `src/render-manifest.ts:94-95` and `:104-106`.

Both manifest creation and verification use direct `writeFile()` to the final destination. An interrupted process can leave truncated or corrupt JSON. There is no temporary file, fsync, or atomic rename.

**Why it matters:** The manifest is intended to be an audit record. A partially written record can be mistaken for a valid artifact by tooling that does not validate it first.

**Recommended correction:** Write to a temporary file in the same directory, flush where practical, then atomically rename it into place. Make the verifier fail if a manifest exists but cannot be parsed or updated; do not convert that condition into a successful MP4 verification.

### Finding 4 — High: Manifest-update failures are swallowed by the MP4 verifier

**Location:** `scripts/test-render.ts:52-54`.

The `try` block includes both `stat(manifestPath)` and `markManifestVerified(manifestPath, checks)`. Any error—including malformed JSON, a missing output referenced by the manifest, a failed hash read, or a failed manifest write—is caught and reported as `No render manifest found`. The verifier then prints a successful MP4 result and exits successfully.

**Why it matters:** This can produce a passing verification command while the manifest is corrupt, stale, or still marked `rendered`. That is directly inconsistent with the auditability objective.

**Recommended correction:** Distinguish `ENOENT` from all other errors. A missing manifest may be an explicitly supported compatibility mode, but a present-and-invalid manifest must fail verification. If manifests are mandatory for new renders, a missing manifest should also fail.

### Finding 5 — Medium: Manifest fields can fall back to expected values rather than measured output

**Location:** `src/render-manifest.ts:72` and `:76`.

`durationSeconds` falls back to `expectedDurationSeconds` when ffprobe omits format duration, and `frameCount` falls back to `expectedFrameCount` when `nb_frames` is absent. The manifest therefore can contain expected values that were not measured from the output while presenting them alongside measured metadata.

**Why it matters:** The requested manifest contract specifically distinguishes expected configuration from actual output properties. A missing measurement should be `null` or explicitly labeled as estimated, not silently replaced by an expectation.

**Recommended correction:** Emit `null` for unavailable measured fields and store expected duration/frame count separately under settings or an `expected` object. Do not claim a measured frame count when ffprobe did not provide one.

### Finding 6 — Medium: The frame-rate check is nominal, not a complete CFR/VFR check

**Location:** `scripts/test-render.ts:31-32`.

The verifier checks `r_frame_rate` against 30 FPS but does not compare `avg_frame_rate`, inspect frame timestamps, or reject variable-frame-rate output. It also treats a malformed `nb_frames` value as effectively absent because `NaN` causes the comparison to evaluate false.

**Why it matters:** A file can report a nominal 30 FPS while having variable timestamps or an invalid frame-count field. The current renderer requests CFR output, so this is not evidence that the current encoder emits bad files, but the verifier’s production claim is broader than its actual check.

**Recommended correction:** Compare nominal and average frame rates, inspect duration/frame count consistency, and treat a present but non-numeric frame count as an error or an explicit unavailable measurement.

### Finding 7 — Medium: Reliability tests do not clean up temporary artifacts

**Location:** `scripts/test-reliability.ts:11-17` and throughout the file.

The suite creates a temporary directory with generated WAV files, an MP4, manifests, and copied narration audio, but never removes the directory. `mkdtempSync()` creates a unique directory each run, so repeated local runs accumulate artifacts under the system temporary directory.

**Why it matters:** This is a maintainability and reproducibility problem, especially for repeated free-environment runs. It can eventually consume disk space and leave sensitive user-like test paths behind.

**Recommended correction:** Wrap the test body in `try/finally` and remove the temporary directory with `rmSync(..., {recursive: true, force: true})`, preserving the directory only when an explicit debug flag is set.

### Finding 8 — Medium: Audio regression assertions are partial

**Location:** `scripts/test-reliability.ts:24-83`.

The new test genuinely exercises the renderer, mixed-audio FFmpeg graph, user-WAV helper, manifest generation, and verifier. However, its audio assertions primarily establish that a mixed AAC stream exists and that the file passes duration/decode checks. They do not establish numerically that:

- music fades in and out;
- ducking reduces music during narration;
- gain values are applied as intended;
- narration is placed at the expected timeline offset;
- output trimming preserves the expected samples;
- the copied user WAV has the expected format, duration, or content.

Historical Milestone 3 evidence covers more audio paths, but it is not new independent Milestone 4A evidence.

**Recommended correction:** Add deterministic audio analysis tests using generated tones. Inspect decoded PCM or `ebur128`/volume measurements in time windows for fade, ducking, gain, and placement. Keep Piper synthesis separate and optional.

### Finding 9 — Low: Renderer commit metadata depends on the caller’s working directory

**Location:** `src/render-support.ts:97-102`.

`rendererCommit()` executes `git rev-parse --verify HEAD` in the current process directory. The renderer was deliberately made runnable from another working directory, but in that scenario Git metadata is usually unavailable and the manifest records `gitCommit: null`, even when the source repository is known from the script location.

**Why it matters:** This is honest rather than fabricated, but it weakens reproducibility metadata precisely in a supported invocation mode.

**Recommended correction:** Resolve the repository root from the renderer module location and run Git with `cwd` set to that root. Continue recording `null` when the source is packaged without Git metadata.

### Finding 10 — Low: CI artifacts omit the new manifest

**Location:** `.github/workflows/render-video.yml:137-143`.

The workflow uploads `output/ai-video-factory.mp4` but not the sibling render manifest. The manifest is therefore unavailable in the downloaded CI artifact even though it is the new audit record.

**Why it matters:** A CI render can be verified, but the evidence package omits the hashes, renderer commit, measured metadata, and verification state intended for audit.

**Recommended correction:** Upload the MP4 and its manifest together, with conservative retention. Keep this change local-only until a workflow run is explicitly authorized.

## D. Test-quality assessment

### Tests that genuinely establish correctness

The branch/state checks are strong and reproducible. `npm run typecheck`, `npm run test:brief`, and Python syntax compilation are useful non-rendering checks. The source inspection confirms that `test:reliability` invokes the real renderer, narration helper, FFmpeg binary, and verifier in subprocesses rather than mocking them. The different-working-directory scenario is meaningful because the renderer script path and brief path are absolute while the process working directory is a temporary directory.

The executable-bit fixture exercises the actual `ensureExecutable()` logic, although the assertion could be stronger. The generated audio fixtures avoid copyrighted assets, Piper downloads, and paid services.

### Tests providing partial evidence

The local mixed-audio run establishes that the FFmpeg graph can execute, produce AAC, preserve expected duration, and decode successfully. It does not prove the audible behavior of ducking, gain, or fades. The user-WAV test establishes that a file can be read and copied from a brief-relative path, but it does not assert sample format, duration, or content equivalence.

The manifest test checks selected fields and rendered/verified status, but it does not validate the manifest against the JSON Schema inside `test:reliability`, test stale-manifest identity, test malformed manifests, or test interrupted/failed writes.

### Weak or missing tests

Missing important negative cases include:

- Existing stale manifest from a different brief.
- Manifest whose `outputPath` differs from the file being verified.
- Malformed manifest JSON.
- Manifest write failure or partial file.
- Failed render with pre-existing MP4 and manifest.
- Directory supplied as media input.
- Symlink and intentional `..` behavior.
- Absolute paths exercised through the full renderer, not only helper assertions.
- Corrupt/truncated MP4 and wrong codec/dimensions/audio files.
- Variable-frame-rate or malformed `nb_frames` input.
- Unexpected additional media streams.
- Actual amplitude/timing behavior of fades, gain, ducking, and placement.

The reliability test’s lack of temporary-directory cleanup is a concrete test defect.

## E. Manifest integrity assessment

**Verdict: Not trustworthy as a complete audit record until corrected.**

The manifest schema is structurally valid, and the existing local manifest validated against it during this review. The renderer writes the manifest only after FFmpeg succeeds and ffprobe returns, and it starts with `status: "rendered"` and `decodeVerified: false`. Those are good foundations.

However, schema validity is not semantic integrity. The verifier does not bind the manifest to the current brief and output, silently ignores manifest errors, and can leave or promote stale records. Direct writes are not atomic. Some measured fields silently fall back to expected values. These issues prevent the manifest from being treated as authoritative evidence.

## F. Rendering reliability assessment

### FFmpeg portability

**Verdict: Mostly sound, not ARM64-verified.** The selected-binary checks, POSIX permission repair, no-fallback behavior, and diagnostics are appropriate. The review found no destructive operation outside the selected file. There is no actual ARM64 execution evidence, so ARM64 compatibility must remain an unverified claim.

### Media paths

**Verdict: Correct in the main supported cases.** TypeScript and Python now agree on brief-relative WAV semantics. Missing-file checks occur before expensive frame generation. Absolute paths, spaces, nested paths, and different working directories are covered by implementation and the integration test. Directory, symlink, and traversal policies should be made more explicit and tested.

### MP4 verification

**Verdict: Materially improved but not production-complete.** The verifier covers the core output contract and full decode, but it lacks strong stale-manifest handling, VFR detection, strict malformed-field handling, and unexpected-stream policy. It can also report success while manifest handling fails.

### Audio correctness

**Verdict: File-level evidence is good; signal-level evidence is incomplete.** The existing renderer graph and historical Milestone 3 evidence support the existence of silent, narration, music, and mixed paths. The new Milestone 4A tests do not independently prove the requested gain, fade, ducking, placement, and synchronization semantics.

## G. Security and zero-cost assessment

No paid service, billing activation, payment method, paid API, workflow dispatch, or paid infrastructure was used. The renderer uses argument arrays for FFmpeg and ffprobe rather than interpolating media paths into a shell command, which is a positive security property. Brief paths can intentionally use absolute paths, `..`, and symlinks; this is not automatically a vulnerability for a local trusted-brief tool, but untrusted brief execution would require a sandbox or root restriction.

The workflow’s manual brief input is checked with `test -f`, and the render commands pass the selected path as an argument. The `GITHUB_OUTPUT` write uses an interpolated candidate value; a newline-containing manual input could potentially create malformed output-command data. This was not exercised and should be hardened with GitHub’s multiline output protocol or stricter path validation before exposing the workflow to untrusted users.

`npm audit` independently reported four findings: three moderate and one high, involving the existing Vite/esbuild/Motion Canvas dependency line. No broad upgrade was attempted, consistent with the milestone constraints. This is a pre-existing dependency risk rather than a newly introduced Milestone 4A package.

## H. Architectural assessment

Milestone 4A preserves the intended architecture: Motion Canvas remains the editable preview, SVG/Sharp/FFmpeg remains the deterministic final renderer, normalized JSON brief data remains shared, and Piper remains optional and local. The new support and manifest modules are appropriately small and do not replace the architecture.

The main maintainability concern is still duplicated drawing logic between Motion Canvas and SVG export. Milestone 4A shares normalized data, timing, layout preparation, and transition logic, but it does not make the drawing implementations identical. A future visual-consistency milestone should introduce a shared, renderer-neutral geometry/typography model and compare rendered frames at deterministic checkpoints. It should not replace either renderer merely for convenience.

## I. Merge recommendation

Do not merge as-is. Correct the manifest-integrity findings in priority order:

1. Bind manifest verification to the current brief path/hash and exact output path/hash.
2. Do not swallow manifest parse/update/write errors; distinguish missing from invalid.
3. Prevent stale artifacts from surviving failed renders or publish outputs atomically.
4. Stop substituting expected duration/frame count for unavailable measured metadata.
5. Add negative tests for stale, mismatched, malformed, and failed-render manifest cases.
6. Add cleanup to the reliability suite.
7. Add signal-level generated-audio assertions or explicitly narrow the milestone’s audio claims.
8. Upload the manifest alongside CI MP4 artifacts in a future authorized workflow change.

After these fixes, rerun the full safe local suite and repeat the independent review. No GitHub Actions dispatch is needed to validate these corrections.

## J. Next milestone recommendation

Milestone 4B should remain a separate **visual-consistency and preview/export parity** milestone, but it should not begin until the manifest findings above are resolved and Milestone 4A is approved for merge.

Its objectives should be to align Motion Canvas and SVG export geometry, typography, line wrapping, captions, mascot placement, intro/outro timing, and all six scene layouts while preserving the current architecture. It should add local frame-level comparison tooling and representative parity fixtures for all transitions, layouts, captions, long text, one-to-eight segment timelines, and mascot states.

Acceptance criteria should include deterministic preview/export frame comparisons within documented tolerances, consistent text wrapping and overflow behavior, preserved v1/v2 compatibility, passing existing reliability and MP4 checks, and no paid services or workflow dispatch. MCP-server work, database work, broad dependency upgrades, new audio features unrelated to parity, and full visual redesign should remain out of scope.

## Evidence limits

This review intentionally did not dispatch GitHub Actions, download Piper models, run a new production render, or execute the reliability suite again because the attached assignment prohibited generated video artifacts during the audit. The audit did execute local non-rendering checks: `npm run typecheck`, `npm run test:brief`, `python3 -m py_compile scripts/narrate.py`, `git diff --check`, JSON Schema validation against the existing local manifest, and `npm audit --json`. These results are distinguished from historical Milestone 4A render and reliability evidence rather than treated as fresh audit execution.

The repository remained clean after the read-only review, and no branch or file was modified.
