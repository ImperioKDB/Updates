# AI Video Factory — Milestone 4A Final Corrective Implementation Report

**Repository:** `ImperioKDB/ai-video-factory`  
**Branch:** `milestone-4a-reliability`  
**Starting HEAD:** `554f3be8139c135075dc3508745c9134ecd3638a`  
**Final branch HEAD:** `cc9ca628b09cec36b4e82e6f9d35e69fb1e8d3ad`  
**Implementation commit:** `079d8819a6a2cd9886d3a6a6d5855e6a8dc8402e`  
**Handoff metadata commit:** `cc9ca628b09cec36b4e82e6f9d35e69fb1e8d3ad`  
**Status:** Pushed to the milestone branch only; not merged and no Pull Request created.

## Executive summary

This implementation resolves the remaining merge-blocking findings from the independent post-correction audit. The changes remain targeted to the existing deterministic SVG/Sharp/FFmpeg renderer and preserve the Motion Canvas preview, existing brief formats, layout system, and zero-cash operating model.

The implementation now binds verification to the exact render invocation, uses one brief byte snapshot, detects ordinary output replacement during verification, serializes publication with an atomic per-output lock, restores the prior MP4/manifest pair on failure, hardens the Actions brief-path output protocol, measures generated-tone audio behavior more precisely, validates frame timestamps, and explicitly documents that manifest version 1 is unsupported.

## 1. Previous findings and exact corrective actions

| Previous finding | Corrective action | Result |
|---|---|---|
| Manifest `renderId` was descriptive only | `scripts/render.ts` generates one UUID and prints it; CI captures it from renderer output; `scripts/test-render.ts` requires `RENDER_ID`; `src/render-manifest.ts:153-179` requires an exact ID match before status transition. | Fixed and covered by wrong-ID regression. |
| Brief/output TOCTOU gap | Renderer reads and hashes one brief byte buffer before parsing. Verifier reads/hashes one brief buffer and compares output device, inode, size, and mtime after probe/decode/hash. | Ordinary replacement/mutation is detected; limits are documented honestly. |
| Rollback MP4 deleted before manifest publication | Renderer retains run-scoped rollback copies until the new pair is published and identity-checked. Outer failure handling restores the prior pair before lock release. | Fixed and covered by failed-render restoration regression. |
| Concurrent renders could interleave | `src/render-support.ts:117-154` implements atomic exclusive per-output locks with random ownership tokens, PID/host metadata, conservative stale-lock recovery, and ownership-checked release. | Fixed for overlapping local renders targeting the same output. Different destinations use independent locks. |
| Workflow output injection | `.github/workflows/render-video.yml` rejects control characters, canonicalizes the requested path, confines it below the repository root, validates the file, and writes the output with fixed-format `printf`. | Fixed and covered by `npm run test:workflow-safety`. |
| Audio tests were partial | Generated deterministic tones now test progressive fade windows, calibrated normalized-mix gain, narration before/during/after boundaries, ducking, and peak clipping. | Improved; exact sample-level synchronization remains a limitation. |
| Frame-rate verification lacked timestamps | `scripts/test-render.ts:21-29` reads FFprobe frame timestamps, rejects missing/malformed data, and requires intervals within 2 ms of 1/30 second. | Fixed for the stated CFR claim. |
| Manifest v1 compatibility was implicit | README, ADR, and handoff explicitly declare manifest v1 unsupported. Existing v1 outputs must be regenerated into v2; normal verification does not accept v1 silently. | Explicit Option B decision. |

## 2. Files changed

- `.github/workflows/render-video.yml`
- `README.md`
- `HANDOFF-MILESTONE-4A.md`
- `docs/adr-002-reliability-and-render-audit.md`
- `package.json`
- `scripts/render.ts`
- `scripts/test-render.ts`
- `scripts/test-reliability.ts`
- `scripts/test-workflow-safety.ts`
- `src/render-manifest.ts`
- `src/render-support.ts`

No `package-lock.json` or dependency version was changed. No generated MP4, manifest, WAV, model, virtual environment, or build artifact was committed.

## 3. Important functions and guarantees

### Invocation identity

`render.ts:118-120` creates exactly one UUID per invocation. The ID is stored in the version-2 manifest and emitted as `Render ID: ...`. The Actions workflow captures that fixed-format renderer output and sets `RENDER_ID` for the verifier. `markManifestVerified()` invokes `assertManifestIdentity()` and rejects any manifest with a different ID before changing `rendered` to `verified`.

The reliability suite creates a valid manifest, verifies it with the correct ID, and explicitly verifies that a different ID fails. An arbitrary manifest cannot provide the trusted expected ID to the verifier; the expected ID comes from the orchestration environment.

### Brief and output integrity

The renderer hashes the exact brief bytes used for parsing. The verifier hashes the exact brief bytes used for parsing. The output is probed and fully decoded before hashing; the verifier then compares device, inode, size, and modification time against the initial snapshot. The implementation claims detection of ordinary replacement or mutation, not a kernel-level immutable read lock against every adversarial filesystem race.

### Transaction and rollback

`render.ts:121-224` acquires the per-output lock before archiving. The transaction is:

1. Create the render ID and output lock.
2. Archive prior MP4 and manifest to unique run-scoped names.
3. Validate tools, read the brief snapshot, validate inputs, and render frames.
4. Encode to a same-filesystem temporary MP4.
5. Probe the temporary output.
6. Publish the MP4 and create the schema-validated manifest.
7. Validate published manifest identity and output hash.
8. Mark the transaction committed.
9. Delete rollback copies only after the pair is complete.
10. Restore the previous pair on any pre-commit failure and release the lock.

Crash durability beyond atomic rename and handle flush is not claimed; the containing directory is not explicitly fsynced.

### Locking

`acquireOutputLock()` uses exclusive file creation (`wx`) and writes a random token, PID, host, and start timestamp. A second active owner cannot be stolen. A stale lock is recovered only when same-host ownership cannot be established and the lock is older than 60 seconds. `releaseOutputLock()` verifies the ownership token before unlinking. Lock files are per output path, so independent outputs do not block one another.

## 4. Tests added and exact results

The final local gate command was:

```bash
npm run typecheck
npm run test:brief
python3 -m py_compile scripts/narrate.py
npm run build
npm run test:workflow-safety
npm run test:reliability
git diff --check
```

It completed with exit code 0 and printed `FINAL_REQUIRED_GATES_PASS`.

Observed results:

- `npm run typecheck`: PASS.
- `npm run test:brief`: PASS — v1/v2 validation, layout checks, timeline boundaries, eight segments, and overflow rejection.
- `python3 -m py_compile scripts/narrate.py`: PASS.
- `npm run build`: PASS. The existing Vite CJS API deprecation warning remains; no build error occurred.
- `npm run test:workflow-safety`: PASS — control-character injection, canonicalization, repository containment, and safe output formatting.
- `npm run test:reliability`: PASS — executable repair, directory rejection, brief-relative WAV, lock contention/release, independent destination locks, stale-lock recovery, transactional failed-render restoration, wrong render ID, manifest schema/path/hash/status cases, output identity, cleanup, calibrated mixed-audio behavior, and different-working-directory rendering.
- `git diff --check`: PASS.

A final isolated eight-segment render was also executed in `/tmp/ai-video-factory-finalfix-render`, not in the authoritative checkout. It passed strict verification:

- Render ID: `70541adf-ce5d-4643-84f4-40a86b228c9b`.
- Duration: 22.000 seconds.
- Frames: 660 expected / 660 measured.
- Video: H.264, 1080×1920, 9:16, 30 FPS.
- Audio: absent as requested.
- Full FFmpeg decode: PASS.
- Manifest: status `verified`, `decodeVerified: true`.

## 5. Audio measurements and tolerances

The reliability fixture uses a 6-second 440 Hz narration tone active only from 2–3 seconds at amplitude 0.2 and a continuous 220 Hz music tone. The output is measured through narrow 5 Hz band-pass filters.

The test measures multiple fade-in windows, multiple fade-out windows, a steady music baseline, music during narration, narration before/during/after its intended interval, and peak output volume. It requires a progressive move from the early fade window toward the steady baseline, at least 2 dB music attenuation during narration, at least 6 dB narration placement contrast, at least 6 dB narration drop after the active window, and peak volume below digital clipping.

The gain assertion is calibrated for FFmpeg’s normalized two-input mix: requested narration gain is 2× (+6.02 dB), while the normalized two-input mix contributes approximately −6.02 dB. The expected net output is therefore 0 dB relative to the source reference, with a ±4 dB tolerance. This detects omitted gain while accommodating AAC/filter measurement variance. Exact sample-level audio/video synchronization is not claimed; stream duration and deterministic time-window placement are checked.

## 6. Frame timestamp verification

The verifier uses the bundled ffprobe to extract `best_effort_timestamp_time` for every video frame. It rejects missing or malformed timestamps and rejects any adjacent interval differing from 1/30 second by more than 2 ms. The final 660-frame sample passed. This is a stronger CFR check than nominal/average metadata alone, though it remains a verifier-level timestamp check rather than a cryptographic media signature.

## 7. Compatibility decision

Brief schema version 1 remains supported and passed `npm run test:brief`. Render manifest version 1 is intentionally unsupported. The project does not silently reinterpret a v1 manifest as v2. Existing v1 output records must be regenerated with the current renderer and verifier to produce a v2 manifest. Missing-manifest compatibility remains explicit only through `--allow-missing-manifest`.

## 8. Dependency audit status

`npm audit --json` was rerun locally and exited with status 1 because the existing dependency tree still reports:

- 0 critical;
- 1 high;
- 3 moderate;
- 0 low findings.

The affected line remains Vite/Motion Canvas tooling and transitive esbuild. No dependency upgrade was attempted because the task required targeted corrective changes and no automatic fix was reported. No new dependency was introduced by this implementation.

## 9. Branch, protected refs, and zero-cost confirmation

After pushing only the milestone branch:

```text
origin/milestone-4a-reliability = cc9ca628b09cec36b4e82e6f9d35e69fb1e8d3ad
origin/main                    = a3a1d827e8ec8168550be608bb89ccb959154c4f
origin/milestone-3-continuation = fbad579515cd7712363296414385c69fc5f2332c
```

The working tree is clean and the local branch tracks the pushed milestone branch. `main` and `milestone-3-continuation` were not modified. No force-push, merge, or Pull Request was performed.

No GitHub Actions workflow was dispatched. No paid API, paid compute, paid storage, billing activation, payment method, Piper download, voice-model download, or external rendering service was used for this implementation or its tests.

## 10. Known limitations

The separate Motion Canvas preview and deterministic SVG renderer remain separate implementations; visual parity remains outside Milestone 4A. Lock recovery is conservative and cannot establish full power-loss durability without filesystem journaling/directory fsync. Output identity checks detect ordinary replacement and mutation but do not provide a universal immutable read lock. Audio tests are deterministic and signal-level but do not claim exact sample-level synchronization. ARM64 end-to-end execution, Piper synthesis, and Actions execution were intentionally not repeated.

## Final recommendation

The final corrective implementation is complete and pushed to `milestone-4a-reliability`. It is ready for a fresh independent audit. It has not been merged, and Milestone 4B visual-parity work should remain gated on that independent audit’s verdict.
