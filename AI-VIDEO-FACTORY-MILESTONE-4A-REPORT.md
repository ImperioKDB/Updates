# AI Video Factory — Milestone 4A Progress Report

**Report date:** 2026-11-03  
**Repository:** [`ImperioKDB/ai-video-factory`](https://github.com/ImperioKDB/ai-video-factory)  
**Milestone:** 4A — Cost-Safe Reproducibility, Rendering Reliability and Quality Assurance  
**Status:** Complete and pushed for review; not merged  
**Branch:** [`milestone-4a-reliability`](https://github.com/ImperioKDB/ai-video-factory/tree/milestone-4a-reliability)  
**Final branch commit:** `e0d5f1175ac26b2ab7b2e5c3348d155c7a5ead51`

## Executive summary

Milestone 4A moved the project from a functionally verified but operationally fragile renderer to a more reproducible and auditable local production pipeline. The renderer now validates and repairs bundled FFmpeg tooling, resolves media consistently, rejects missing inputs before frame generation, emits a machine-readable render manifest, and has a substantially stronger MP4 verifier. The local reliability suite exercises these behaviors with generated audio fixtures and does not require Piper downloads or GitHub Actions.

The work was completed on a new branch created from the verified Milestone 3 tip. It was committed and pushed only to `milestone-4a-reliability`. No merge or pull request was created.

## Starting repository state

The required pre-change audit matched the historical handoff exactly:

| Reference | Verified value |
|---|---|
| `main` | `a3a1d827e8ec8168550be608bb89ccb959154c4f` |
| `milestone-3-continuation` | `fbad579515cd7712363296414385c69fc5f2332c` |
| Historical narrated-CI documentation | `47d3a8d` exists in the Milestone 3 history |
| Newer Milestone 4 branch before work | None |
| Starting working tree | Clean |

The new branch was created from `milestone-3-continuation` without modifying either protected branch.

## Problems addressed

The audit identified several real reliability gaps. The bundled ARM64 ffprobe executable could lose its POSIX executable bit after dependency installation, producing an `EACCES` failure. The renderer also relied on the process working directory for fonts and media, which made invocation from another directory unreliable. Rendered MP4s had no machine-readable audit record, and the existing verifier did not check several important production invariants such as aspect ratio, plausible frame count, silent/audio consistency, or output non-emptiness. Finally, user-supplied WAV handling in the narration helper did not follow the same brief-relative path contract as the renderer.

## Implemented changes

### Bundled FFmpeg and ffprobe portability

`src/render-support.ts` now validates the npm-selected FFmpeg and ffprobe binaries before use. On POSIX systems, a missing executable bit is repaired programmatically. The code then runs the binary’s version command. Missing files, failed permission repair, and unsupported architectures produce explicit errors containing the tool path and platform/architecture. The implementation never silently falls back to an unrelated system binary.

The GitHub Actions preflight was updated to apply the same permission repair and architecture-aware execution check.

### Media-path resolution

Paths declared in a JSON brief are resolved relative to the directory containing that brief. Absolute paths remain supported. Explicit `MUSIC_PATH` and `NARRATION_PATH` environment overrides are resolved relative to the caller’s current working directory. Every asset is checked as a regular file before frame generation, and failures identify both the requested path and the resolved path.

Font loading was also made independent of the caller’s working directory by resolving the repository’s font packages from the renderer script location.

The Python narration helper now resolves `narration.wavPath` relative to the brief directory unless the path is absolute, keeping user-WAV behavior aligned with the renderer.

### Render manifests

Every successful render now writes a sibling JSON manifest, or a path supplied through `MANIFEST_OUTPUT`. The manifest begins with status `rendered` and changes to `verified` only after the MP4 verifier completes successfully.

The manifest records the input brief path and SHA-256, renderer package version, available Git commit, render timestamp, output path and SHA-256, duration, dimensions, frame rate, frame count, codecs, audio metadata, segment count, renderer settings, warnings, and verification checks. A failed render does not create a new success manifest.

The manifest contract is documented in [`schema/render-manifest.schema.json`](https://github.com/ImperioKDB/ai-video-factory/blob/milestone-4a-reliability/schema/render-manifest.schema.json).

### Stronger MP4 quality assurance

`scripts/test-render.ts` now verifies:

- Output existence and non-zero size.
- MP4 container validity.
- H.264 video.
- 1080×1920 resolution.
- 9:16 aspect ratio.
- 30 FPS.
- Duration within tolerance of the normalized brief timeline.
- Plausible frame count.
- Expected silent or audio-present state.
- AAC audio where audio was requested.
- Audio/video duration alignment.
- Full FFmpeg decode.

Errors are reported as actionable verification failures. Harmless encoder metadata differences are not treated as defects.

### Regression testing

A new `npm run test:reliability` suite uses generated sine-wave fixtures rather than copyrighted audio or Piper model downloads. It covers executable-bit repair, absolute and relative media paths, spaces, nested directories, missing-media diagnostics, user-supplied WAV handling, mixed audio, manifest creation and verification, and rendering from a different working directory.

### Workflow cost controls

The workflow remains inspection-only for this milestone. It was not dispatched. Safe YAML improvements were made: push and pull-request rendering is limited to relevant source/configuration/schema/example changes, concurrency cancellation prevents stale duplicate runs, Piper remains opt-in, and the bundled-tool preflight is more robust.

## Verification evidence

All of the following completed successfully in the local sandbox:

| Command | Result |
|---|---|
| `npm run typecheck` | PASS |
| `npm run test:brief` | PASS |
| `npm run test:reliability` | PASS |
| `npm run build` | PASS; existing Vite CJS API deprecation warning remains |
| `python3 -m py_compile scripts/narrate.py` | PASS |
| `npm run brief:validate -- examples/first-brief.json` | PASS |
| `npm run brief:validate -- examples/eight-segment.json` | PASS |
| `git diff --check` | PASS |

A real local eight-segment render was also completed with the new renderer and verifier:

- Duration: 22.000 seconds.
- Frames: 660.
- Video: H.264, 1080×1920, 30 FPS.
- Aspect ratio: 9:16.
- Audio: absent, as requested by the brief.
- Full FFmpeg decode: passed.
- Manifest state: changed from `rendered` to `verified`.
- Input brief SHA-256: `733d4bd8ee8110c6b22170b0a39b3aade1e430b24d776d16454cda4b00a52db2`.
- Output SHA-256: `61cb8ef28b2a49d9273677c273d9602d1fc5084e0b0605e17231e459d46cac3c`.

The historical narrated CI run from Milestone 3 remains valid evidence for Milestone 3 only. It was not repeated or represented as verification of new Milestone 4A code.

## Commits and repository state

Milestone 4A was recorded in two commits:

1. `9be8eede9639b473056cf5d802a40d9b1c771c8d` — `Improve render reliability and auditability`
2. `e0d5f1175ac26b2ab7b2e5c3348d155c7a5ead51` — `Document Milestone 4A handoff`

The final branch is pushed and clean. The remote heads were verified as:

| Branch | SHA | State |
|---|---|---|
| `main` | `a3a1d827e8ec8168550be608bb89ccb959154c4f` | Unchanged |
| `milestone-3-continuation` | `fbad579515cd7712363296414385c69fc5f2332c` | Unchanged |
| `milestone-4a-reliability` | `e0d5f1175ac26b2ab7b2e5c3348d155c7a5ead51` | Pushed and clean |

The detailed handoff is available as [`HANDOFF-MILESTONE-4A.md`](https://github.com/ImperioKDB/ai-video-factory/blob/milestone-4a-reliability/HANDOFF-MILESTONE-4A.md).

## Not executed and why

No GitHub Actions workflow was dispatched. The repository is private, the remaining allowance was not assumed to be unlimited, and Milestone 4A explicitly required local/free verification without additional workflow spend.

End-to-end ARM64 hardware execution was not available in the current environment. The executable-permission repair and architecture error paths were tested with local fixtures and the installed bundled tools, but this is not a claim that the complete pipeline was executed on ARM64 hardware.

Piper synthesis and model download were not repeated. The existing Milestone 3 local and narrated-CI evidence remains historical and was not used to claim verification of new Milestone 4A code.

The workflow YAML was inspected and updated but not executed.

## Remaining limitations

The Motion Canvas preview and SVG/Sharp/FFmpeg renderer still have separate drawing implementations. Their shared normalized brief, timing, design tokens, layout preparation, and transition logic remain intact, but complete visual consistency is a later milestone.

Manifest timestamps are intentionally time-dependent. Other manifest metadata is deterministic where the encoder and environment permit. Existing dependency audit findings in the Motion Canvas/Vite dependency line remain; no broad dependency upgrade was attempted.

## Current position and recommended next step

The project is ready for review of Milestone 4A on the dedicated branch. The core production path remains usable without paid services or GitHub Actions. The next decision should be whether to merge this branch after review or begin a separately scoped visual-consistency milestone. No Milestone 4B or subsequent milestone has been started.

## Zero-cost confirmation

No paid service, billing activation, payment method, paid API, paid rendering service, or paid infrastructure was used for Milestone 4A. No GitHub Actions workflow was dispatched. No generated video, manifest, Piper model, temporary WAV, virtual environment, or build artifact was committed.
