# AI Video Factory — Independent Post-Correction Audit

**Repository:** `ImperioKDB/ai-video-factory`  
**Audited branch:** `milestone-4a-reliability`  
**Audited commit:** `554f3be8139c135075dc3508745c9134ecd3638a`  
**Audit mode:** Read-only; source repository was not modified, no commit/push/merge/Pull Request was performed, and no GitHub Actions workflow was dispatched.  
**Audit workspace:** `/tmp/ai-video-factory-postaudit-554f3be` plus source review of `/home/ubuntu/ai-video-factory-dev-check`.

## 1. Executive verdict

# FAIL — NOT READY TO MERGE

The corrective implementation resolves many of the original defects and the isolated local test suite passes. However, critical integrity and transaction-safety issues remain:

1. The generated `renderId` is stored and schema-validated but is not supplied to or checked by the verifier. A manifest from a different render can therefore be accepted whenever its brief/output path and hashes happen to match the current files and its status is `rendered`.
2. Verification has a time-of-check/time-of-use gap. The verifier probes and decodes the output, then separately hashes it; it hashes the brief only after parsing it and calculating expected duration. A brief or output changed between those operations can produce a manifest update that does not describe one stable snapshot.
3. The renderer deletes the previous output rollback copy before manifest creation completes. If manifest creation fails, the previous successful MP4 is no longer recoverable under the documented rollback scheme, while the new MP4 is present without a manifest.
4. Concurrent renderer processes have no lock or generation guard. Their archive, publish, rollback-deletion, and manifest-write operations can interleave and leave an inconsistent final pair or destroy another run’s rollback artifact.
5. The workflow writes untrusted manual input directly into `GITHUB_OUTPUT` using `echo`, leaving a newline/output-command injection risk.

These are not merely documentation issues. They directly affect audit identity, rollback guarantees, and the safety of automation. The branch is not ready for merge review until at least the first four are addressed or explicitly bounded by a stronger execution/locking contract.

## 2. Repository identity and branch-state evidence

### Directly observed

The authoritative checkout was clean and matched the requested state:

| Ref | Observed SHA | Result |
|---|---|---|
| `HEAD` / `origin/milestone-4a-reliability` | `554f3be8139c135075dc3508745c9134ecd3638a` | Matches expected corrective commit |
| `origin/main` | `a3a1d827e8ec8168550be608bb89ccb959154c4f` | Unchanged as required |
| `origin/milestone-3-continuation` | `fbad579515cd7712363296414385c69fc5f2332c` | Unchanged as required |

The parent history was:

```text
554f3be Correct Milestone 4A manifest integrity
e0d5f11 Document Milestone 4A handoff
9be8eed Improve render reliability and auditability
fbad579 Correct CI verification commit reference
```

`git status --short --branch` was clean and `git diff --check` passed. The corrective commit changed 10 files and contained the reported corrective implementation/documentation scope.

### Evidence classification

- Repository refs and clean state: **directly observed**.
- Commit scope: **directly observed** from `git show` and diff statistics.
- Corrective report claims: treated as claims and checked against source/tests, not accepted as evidence by themselves.

## 3. Corrective commit and diff summary

The audited commit changes:

- `.github/workflows/render-video.yml`
- `HANDOFF-MILESTONE-4A.md`
- `README.md`
- `docs/adr-002-reliability-and-render-audit.md`
- `schema/render-manifest.schema.json`
- `scripts/render.ts`
- `scripts/test-reliability.ts`
- `scripts/test-render.ts`
- `src/render-manifest.ts`
- `src/render-support.ts`

The implementation adds manifest schema version 2, AJV validation, atomic manifest writes, strict verifier checks, temporary MP4 rendering, rollback names, stronger media checks, generated-tone audio assertions, repository-root Git metadata, and manifest upload in CI.

## 4. Previous audit findings: one-by-one resolution status

| Previous finding | Status | Evidence and assessment |
|---|---|---|
| F1: Manifest verification not bound to current brief/output | **PARTIALLY FIXED** | `scripts/test-render.ts:88-96` passes current brief/output paths and hashes to `markManifestVerified()`. `src/render-manifest.ts:162-166` checks status, brief path/hash, output path, and output hash. However, `renderId` is never supplied by the verifier or compared, and validation is not snapshot/TOCTOU-safe. |
| F2: Failed renders leave stale successful artifacts | **PARTIALLY FIXED** | `scripts/render.ts:118-126` archives existing output/manifest; FFmpeg writes a temporary output and final publication occurs after probing at lines 163-165. But the old output is deleted at line 166 before manifest creation at line 167, so a manifest-creation failure loses the previous MP4 rollback copy. No concurrent-render isolation exists. |
| F3: Manifest writes not atomic | **VERIFIED FIXED, WITH DURABILITY LIMIT** | `src/render-manifest.ts:65-85` uses a unique same-directory temporary directory, exclusive creation, complete write, `handle.sync()`, round-trip JSON/schema validation, and rename. This provides atomic visibility on the target filesystem. It does not fsync the containing directory, so crash durability is not proven and should not be claimed. |
| F4: Manifest-update failures swallowed | **VERIFIED FIXED** | `scripts/test-render.ts:77-99` distinguishes missing manifests from other errors. A present malformed/inaccessible/mismatched manifest fails verification. Missing manifests fail unless `--allow-missing-manifest` is explicitly supplied. |
| F5: Measured fields fall back to expected fields | **VERIFIED FIXED** | `src/render-manifest.ts:126-134` records measured duration/frame count as nullable and stores expected duration/frame count separately. `scripts/test-render.ts:48-56` independently checks measured output metadata. |
| F6: Frame-rate check only nominal | **PARTIALLY FIXED** | `scripts/test-render.ts:43-47` checks nominal and average frame rate and rejects malformed present average metadata. It does not inspect packet timestamps or establish CFR/VFR from timestamps; a file can potentially report both rates near 30 while containing timestamp irregularities. |
| F7: Reliability tests leak temporary artifacts | **VERIFIED FIXED** | `scripts/test-reliability.ts:13` creates a unique temp root and lines 186-188 remove it in `finally`. The isolated suite passed and did not write test artifacts into the repository. |
| F8: Audio assertions partial | **PARTIALLY FIXED** | `scripts/test-reliability.ts:118-129` measures isolated music/voice bands and asserts fade-in, fade-out, ducking, and narration placement. It does not directly measure requested gain against a calibrated reference, clipping, progressive envelope shape, trimming sample boundaries, or exact audio/video synchronization beyond duration checks. |
| F9: Renderer commit depended on caller CWD | **VERIFIED FIXED** | `scripts/render.ts:18` derives `REPO_ROOT`; `src/render-support.ts:97-103` accepts a repository root as `cwd`; `scripts/render.ts:178` supplies it. The isolated render path records the repository commit rather than the unrelated caller CWD. |
| F10: CI artifact omitted manifest | **VERIFIED FIXED** | `.github/workflows/render-video.yml:137-145` uploads both `output/ai-video-factory.mp4` and `output/ai-video-factory.manifest.json` after the verification steps. |

## 5. Manifest identity and adversarial verification results

### Verified fixed behavior

`src/render-manifest.ts:152-171` rejects:

- a manifest not in `rendered` state;
- a brief path mismatch;
- a brief hash mismatch;
- an output path mismatch;
- an output hash mismatch;
- schema-invalid or malformed JSON;
- writes that fail schema validation.

`schema/render-manifest.schema.json:7-42` requires manifest version 2, render ID, identity hashes, measured/expected fields, and verification fields. The isolated reliability suite exercised brief-hash, output-path, output-hash, status, malformed JSON, schema-invalid, missing-manifest, and manifest-access-error cases.

### Residual identity weaknesses

#### Render ID is not checked

`src/render-manifest.ts:100` requires a `renderId` when creating a manifest, and the schema validates its shape. But `scripts/test-render.ts` never obtains or supplies an expected render ID. `markManifestVerified()` does not compare one. Therefore the run ID is metadata, not an invocation-binding value.

A different `rendered` manifest for the same brief path/hash and output path/hash can be accepted by a later verifier invocation. The existing test suite does not create two same-identity manifests and prove that the wrong run is rejected.

**Status:** **NOT FIXED** for the run-ID requirement.

#### TOCTOU between media checks, hashing, and update

The verifier:

1. parses the brief at `scripts/test-render.ts:25-26`;
2. probes, checks, and fully decodes the output at lines 29-69;
3. checks manifest existence at lines 77-87;
4. hashes the brief and output at lines 89-94;
5. updates the manifest at line 96.

The output is not opened through a stable file descriptor or rechecked after hashing. The brief is parsed before its hash is computed. A concurrent writer can change either file between these operations. The final manifest can consequently combine measurements from one output/brief state with hashes from another.

This is **static source analysis**, not a claimed exploit execution. The test suite changes a brief before verification, but it does not mutate a file during verification.

**Status:** **NOT FIXED** for snapshot integrity.

#### Manifest tamper resistance is logical, not cryptographic authenticity

The manifest is schema-validated and path/hash-bound, but it is not signed. A party able to rewrite the manifest can rewrite its path and hash fields to match the current brief/output and leave status as `rendered`. The implementation detects accidental stale records, not malicious manifest forgery. That may be acceptable for a local audit record, but it must not be described as cryptographic authenticity.

## 6. Transactional publication and rollback analysis

### Observed lifecycle

`render.ts:118-126`:

- generates a UUID;
- moves the existing final MP4 to `output.previous-<runId>` if present;
- moves the existing manifest to `manifest.previous-<runId>` if present.

`render.ts:140-165`:

- creates a same-filesystem temporary publication directory;
- renders FFmpeg output to `render.mp4` there;
- probes the temporary MP4;
- renames the temporary MP4 to the final output path.

`render.ts:166-167` then deletes the previous output rollback copy and starts manifest creation.

### Stage analysis

| Failure stage | Observed guarantee |
|---|---|
| Before encoding | Old MP4/manifest are moved to run-scoped names. Final paths have no current pair. Previous files are recoverable if the process remains able to inspect rollback names. |
| During FFmpeg encoding | Temporary output is used. A failed encode does not publish a partial final MP4. Old output remains in rollback storage. |
| During probing | Temporary output is still unpublished. Old output remains in rollback storage. |
| After probing, before MP4 rename | Old output and manifest remain rollback files; no new final pair. |
| After MP4 rename, before manifest creation | New MP4 is final; manifest is absent because old manifest was archived. Verifier rejects the state due required manifest. Old MP4 remains recoverable only until line 166. |
| During manifest creation | **Defect:** line 166 has already deleted the old output rollback. If atomic manifest creation fails, the old MP4 is not recoverable through the rollback mechanism; the new MP4 remains final without a manifest. |
| After manifest publication | New MP4/manifest are present, but there is no lock against another renderer interleaving its own publication. |
| During cleanup | `finally` removes frame/publication temporary directories, but rollback files are intentionally retained and can accumulate. |

### Most important adversarial case

A failure between final MP4 publication and manifest publication produces:

- new MP4 at the final path;
- no final manifest, because the previous manifest was archived;
- previous manifest in a rollback name;
- previous MP4 **already deleted** by line 166 if execution reached the manifest call.

The verifier will not accept the state because the manifest is missing. Therefore the implementation avoids one misleading-success state, but it does not provide the claimed recoverable rollback guarantee and does not restore a consistent pair automatically.

### Concurrency

No lock, lease, generation check, or compare-and-swap publication exists. Two local render processes can independently archive, rename, delete rollback files, and write the same final paths. This is a merge-blocking reliability issue for automation that can launch overlapping renders.

**Status:** **NOT FIXED** for concurrent-render safety; **PARTIALLY FIXED** for single-process stale-output prevention.

## 7. Atomicity and durability analysis

`src/render-manifest.ts:65-85` is a solid atomic-visibility implementation:

- temp directory is created beneath the destination directory;
- `mkdtemp()` gives a unique name suitable for concurrent writers;
- file is opened with `wx` and mode `0644`;
- all bytes are written and the file handle is synchronized;
- JSON is parsed and schema-validated from the temp file;
- rename publishes the complete file;
- `finally` removes the temporary directory on success or error.

A failed update leaves the existing destination untouched because the destination is only replaced after validation. Rename errors propagate after cleanup.

However, the containing directory is not fsynced after rename. The implementation should claim atomic visibility, not full crash durability across power loss/filesystem failure. This is a bounded limitation rather than the primary merge blocker.

## 8. Measured-versus-expected metadata analysis

This area is **VERIFIED FIXED** for the original fallback defect.

`src/render-manifest.ts:126-140` uses `numberOrNull()` for measured ffprobe fields and stores expected values separately:

- measured `durationSeconds` may be `null`;
- expected duration is `expectedDurationSeconds`;
- measured `frameCount` may be `null`;
- expected frame count is `expectedFrameCount`;
- measured audio duration is separate as `audioDurationSeconds`.

The verifier independently reads the current media probe and does not use manifest expected values to pass the MP4 checks.

A remaining edge is that malformed optional ffprobe values in manifest creation are converted to `null` rather than rejected. The verifier rejects malformed fields that are present in the actual output probe, so this does not silently make a bad MP4 pass, but manifest creation could record less information than the source metadata warranted.

## 9. Video verification analysis

`scripts/test-render.ts:29-69` enforces:

- non-empty regular file;
- exactly one video stream and at most one audio stream;
- MP4 container;
- H.264;
- 1080×1920;
- numeric 9:16 ratio;
- nominal 30 FPS;
- average FPS when present, including malformed-rate rejection;
- duration within 0.1 seconds;
- integer frame count when present and expected frame tolerance;
- AAC when audio is expected;
- no audio when silent output is expected;
- audio/video duration alignment within 0.2 seconds;
- full FFmpeg decode.

This is materially stronger than the pre-correction verifier and the isolated reliability suite passed.

It still does not inspect frame timestamps or compare packet duration/frame timing. A VFR file can potentially report nominal and average rates near 30 while containing timestamp irregularities. The verifier’s current production encoder requests CFR with `-r 30`, so this is a bounded verification limitation, but the claim should not be expanded to complete CFR proof without timestamp analysis.

**Status:** **PARTIALLY FIXED**.

## 10. Audio signal-level test analysis

The generated fixture in `scripts/test-reliability.ts:66-80` creates:

- a 6-second 440 Hz narration signal active only from 2–3 seconds using `aevalsrc`;
- a continuous 220 Hz music tone;
- music volume `0.8`, fade-in/out `0.2` seconds, ducking `20 dB`;
- narration gain `2`.

Measurements at lines 118-125 use FFmpeg `volumedetect` over narrow bands:

- 220 Hz band for music;
- 440 Hz band for narration;
- 0.05–0.20 seconds for fade-in;
- 1.0–1.15 seconds as music baseline and narration-silent baseline;
- 2.5–2.65 seconds during narration/ducking;
- 5.95–6.0 seconds for fade-out.

Assertions at lines 126-129 require:

- fade-in at least 3 dB below baseline;
- fade-out at least 3 dB below baseline;
- ducked music at least 2 dB below baseline;
- active narration at least 6 dB above silent narration.

The test passed, and it would fail if the relevant fades, placement, or ducking were removed strongly enough to erase those differences. The corrected filter removes the former automatic-makeup behavior by omitting the problematic explicit makeup setting.

Remaining false-positive/coverage risks:

- Gain is not calibrated against a reference output. The test uses gain `2`, but only asserts active-vs-silent narration; it does not prove the measured amplitude corresponds to exactly 2× or detect clipping.
- Fade assertions compare windows, not progressive envelope samples across the fade interval. A step change at the boundary could pass.
- Narration placement is tested at one active and one silent window, not both boundaries or a measured delay offset.
- Trimming is inferred from output duration and stream duration, not from start/end PCM boundaries.
- Audio/video synchronization is checked by duration, not timestamp/sample alignment.

**Status:** **PARTIALLY FIXED**.

## 11. Test isolation and cleanup

The isolated reliability suite passed:

```text
PASS: executable repair, directory rejection, brief-relative user WAV, transactional failed-render handling, manifest schema/identity/hash/status/error cases, cleanup scope, mixed-audio signal behavior, and different-working-directory rendering.
```

`mkdtempSync()` creates a unique root outside the repository at `scripts/test-reliability.ts:13`. The complete test body is inside `try/finally`, and line 187 recursively removes the root. The suite uses generated tones and does not download Piper. The authoritative repository remained clean.

**Status:** **VERIFIED FIXED**.

## 12. Renderer working-directory independence

`render.ts:18` derives `REPO_ROOT` from the module location. `render.ts:110-115` resolves fonts from the repository, and `render.ts:178` passes `REPO_ROOT` to `rendererCommit()`. `src/render-support.ts:97-103` runs Git with that root as `cwd`.

The isolated reliability suite renders from `tempRoot`, an unrelated current working directory, and the final manifest records a Git commit. This claim is **VERIFIED FIXED**.

## 13. GitHub Actions security and zero-cost review

### Verified

- `permissions: contents: read` is minimal for checkout/read operations.
- concurrency cancellation remains enabled at `.github/workflows/render-video.yml:40-42`.
- relevant path filters remain scoped to workflow, package, schema, source, scripts, and examples.
- Piper setup/synthesis is gated behind `install_piper == 'true'`.
- MP4 and manifest are uploaded at lines 137-145 only after prior steps succeed under `if: success()`.
- no paid service, secret, payment, or workflow dispatch was used.

### Residual workflow issue

At `.github/workflows/render-video.yml:61-66`, manual input is copied to `candidate` and written using:

```bash
echo "path=$candidate" >> "$GITHUB_OUTPUT"
```

The input is not rejected for newlines and is not emitted through a safe multiline output delimiter. `test -f` validates existence but does not make the value safe for the output protocol. A newline-containing filename/input could inject additional output lines or keys. The shell argument use is quoted, which reduces command injection risk, but the output-channel issue remains.

The same pattern is used for the fixed internal value `wav_path=output/narration.wav`, which is not user-controlled; the manual brief path is the relevant issue.

**Status:** **NOT FIXED**, low-to-medium severity depending on who can invoke manual workflows and repository policy.

## 14. Compatibility and architecture

- Existing v1/v2 brief compatibility passed `npm run test:brief`.
- Manifest schema is now strict version 2. There is no v1 manifest migration or v1 manifest verification path. This is acceptable only if manifest v1 compatibility is intentionally dropped and documented; it is not a compatibility implementation.
- Legacy manifest-free verification is explicit through `--allow-missing-manifest`; normal verification remains strict.
- Motion Canvas and SVG rendering remain separate implementations; no unrelated visual-parity work was introduced.
- No Milestone 4B visual work was introduced.

**Manifest compatibility status:** **PARTIALLY FIXED / NOT VERIFIED** as a product compatibility decision. Brief compatibility is verified; old manifest compatibility is not implemented.

## 15. Dependency and licensing status

### Dependency audit

`npm audit --json` ran in the isolated checkout and exited with status `1` because findings remain:

| Severity | Count |
|---|---:|
| Critical | 0 |
| High | 1 |
| Moderate | 3 |
| Low | 0 |
| Total | 4 |

Affected paths:

- `vite@5.4.21` — direct dependency; one high and several moderate advisories, including Windows `launch-editor` command/path issues and Vite filesystem/middleware issues. Audit metadata reported no automatic fix available.
- `esbuild@0.21.5` — transitive under `vite`; one moderate advisory. `tsx` also brings a non-vulnerable `esbuild@0.25.12` path in the installed tree. No automatic fix was reported for the vulnerable Vite path.
- `@motion-canvas/vite-plugin@3.17.2` — direct dependency, reported moderate through its Vite relationship; no automatic fix available.
- `@motion-canvas/ffmpeg@3.17.2` — direct dependency, reported moderate through `@motion-canvas/vite-plugin`; no automatic fix available.

These packages are primarily build/development/editor tooling in this project. The Vite findings matter when exposing the development server or using affected Windows/editor paths; they are not evidence that the headless FFmpeg renderer itself is remotely exploitable. No dependency upgrade was performed under the read-only restriction.

### Licensing

No new dependency or model was added by the corrective commit. Piper and voice models were not downloaded or executed for this audit. Existing repository licensing and the prior Piper/model licensing caveats remain unchanged.

## 16. Commands executed and exact results

All commands below were run safely and read-only with respect to the authoritative repository. Tests that generate files ran in `/tmp/ai-video-factory-postaudit-554f3be`, an isolated checkout with a symlink to existing `node_modules`; generated build output was confined to that temporary checkout.

| Command | Result | Repository modification | Network/paid resource |
|---|---|---|---|
| `git remote -v`, branch/ref/status/log checks | PASS; expected refs and clean tree | None | None |
| `git show HEAD` and corrective diff inspection | PASS; expected 10-file corrective scope | None | None |
| `npm run typecheck` in isolated checkout | PASS | None in authoritative repo | None |
| `npm run test:brief` in isolated checkout | PASS: v1/v2, layout, timeline, eight segments | None in authoritative repo | None |
| `python3 -m py_compile scripts/narrate.py` in isolated checkout | PASS | None in authoritative repo | None |
| `npm run build` in isolated checkout | PASS; existing Vite CJS API deprecation warning | Build output only in `/tmp` | None |
| `npm run test:reliability` in isolated checkout | PASS; full corrective reliability message above | Temp root cleaned by suite | Local generated tones only |
| `npm audit --json` in isolated checkout | Exit 1; 0 critical, 1 high, 3 moderate | None | Registry metadata access; no install |
| Static workflow inspection | Completed; no execution | None | None |
| `git diff --check` | PASS | None | None |

No production render was run as part of this audit. The reliability suite’s isolated integration render used generated local tones, temporary output paths, and no external assets or Piper models.

## 17. Tests not executed and why

- GitHub Actions workflow: **NOT EXECUTED**, explicitly prohibited by the audit instructions and unnecessary for static workflow review.
- Piper synthesis/model download: **NOT EXECUTED**, explicitly prohibited and unnecessary because generated tones cover the audio regression path.
- Production render in the authoritative checkout: **NOT EXECUTED**, to avoid overwriting repository outputs; the isolated reliability render was sufficient for local integration evidence.
- ARM64 end-to-end execution: **NOT EXECUTED**, hardware was unavailable. Bundled-tool permission/error paths were inspected and exercised with local fixtures where safe.
- Crash/power-loss fault injection: **NOT EXECUTED**. Source-level reasoning was used because process-kill/fault injection around publication could leave test artifacts and cannot prove filesystem crash durability without a controlled filesystem harness.
- Concurrent render stress test: **NOT EXECUTED**. The source-level absence of a lock/generation guard is already directly observable; running overlapping renders would add output races and is not necessary to establish the defect.
- Adversarial mid-verification file mutation: **NOT EXECUTED**. The TOCTOU window is directly observable from call order; a race test would be nondeterministic and is not needed to establish the source-level gap.

## 18. Remaining risks and recommended fixes

1. **Bind verification to a render invocation.** Pass an expected render ID or signed/unguessable render token from the render orchestration into verification, and reject manifests whose token does not match the current invocation. If verification is intentionally artifact-only, remove claims that the run ID authenticates the invocation.
2. **Close the TOCTOU window.** Verify from stable file descriptors or hash/probe/decode one immutable temporary output before publication. For the brief, read once into a buffer, parse and hash the same bytes, and pass the snapshot hash through verification. For the output, hash and probe the same immutable file or recheck identity/hash immediately before atomic manifest update.
3. **Retain rollback files until manifest publication succeeds.** Delete the previous output only after the new manifest has been atomically published and validated. Consider a recovery marker or explicit rollback transaction state for interruption between output and manifest publication.
4. **Add a per-output lock or generation compare-and-swap.** Prevent overlapping renders from archiving/publishing the same final output and manifest paths.
5. **Harden workflow output handling.** Reject newline/control characters and enforce a repository-relative path, or use a safe multiline `GITHUB_OUTPUT` delimiter with validated content. Prefer `printf` for fixed-format output.
6. **Decide and document manifest v1 compatibility.** Either provide a deliberate migration/legacy verifier path or explicitly state that manifest v1 is unsupported and require regeneration.
7. **Improve audio regression precision.** Add calibrated gain assertions, clipping checks, multiple samples across fade envelopes, explicit start/end placement windows, and sample/timestamp synchronization checks.
8. **Consider packet timestamp checks** if the verifier is intended to make a complete CFR claim rather than only validate the current encoder’s nominal/average metadata.

Do not begin Milestone 4B visual-parity work until these Milestone 4A integrity blockers are resolved and re-audited.

## 19. Final verdict and merge recommendation

# FAIL — NOT READY TO MERGE

The corrective branch is materially improved and many prior findings are verified fixed. The isolated local test suite is credible for its covered cases and all safe requested checks passed. Nevertheless, the unverified run-ID binding, TOCTOU gap, incomplete rollback retention, and missing concurrent-render protection leave critical/high reliability concerns unresolved. The workflow output-channel issue is an additional bounded security defect.

**Recommendation:** Do not merge or submit for merge review yet. Apply targeted corrections, rerun the isolated adversarial audit, and repeat the branch/ref safety checks. No Milestone 4B work should be started until the final verdict changes to PASS or, at minimum, a justified conditional verdict with no critical integrity issue.
