# AI Video Factory — Progress Report

**Report date:** 2026-11-02  
**Repository:** `ImperioKDB/ai-video-factory`  
**Project:** Video Factory  
**Budget rule:** Zero cash; no paid plans, APIs, hosting, compute, storage, or billing activation.

## Current position

Milestone 3 is complete on the development branch. The repository now has a structured multi-segment video brief system, a deterministic vertical-video renderer, local Piper narration support, optional music and user-supplied WAV support, automated MP4 verification, and a GitHub Actions workflow capable of producing a narrated artifact.

The most important remaining product limitation is architectural rather than operational: Motion Canvas remains the editable preview, while the final CI export is produced by the shared-brief SVG/Sharp/FFmpeg renderer. The two paths share normalized brief data, timing, design tokens, layout preparation, and transition logic, but their drawing code is not identical.

## Repository and branch state

The repository is accessible and remains private.

- `main` remains unchanged at `a3a1d827` — `Document milestone-three audit and handoff checkpoint`.
- `milestone-3-continuation` was the development branch used for the work.
- The implementation branch began at `a233050` — `Update milestone 3 handoff after review push`.
- The latest development-branch commit is `fbad579` — `Correct CI verification commit reference`.
- The preceding documentation commit is `47d3a8d` — `Record successful narrated CI verification`.
- The handoff update was pushed to GitHub on the development branch only.
- No merge into `main` was performed.
- No pull request was opened.
- No existing files, generated media, Piper model weights, or local environments were added to Git.

## Work completed

### Repository forensic audit

The existing repository was independently inspected rather than accepted at face value. The audit covered branches, commit history, repository structure, README and milestone documentation, package configuration, schema, TypeScript source, Motion Canvas scenes, headless renderer, narration scripts, examples, tests, ignored files, and GitHub Actions configuration.

The audit distinguished claimed functionality from verified functionality and identified the private-repository Actions allowance as a cost-verification blocker before the owner explicitly authorized a run.

### Brief and rendering system

The development branch now contains:

- Backward-compatible v1 and v2 JSON brief schemas.
- Ajv validation and normalized timeline construction.
- Support for one to eight segments.
- Six scene layouts: information, statistic, comparison, steps, timeline, and quote.
- Intro and outro durations.
- Scene-specific transitions: cut, fade, slide-up, and wipe.
- Caption and metadata options.
- Shared design tokens for the cream, black, navy, teal, gold, and typography system.
- Text wrapping and overflow rejection before rendering.
- A reusable vector mascot named Dot.
- A deterministic SVG frame renderer using Sharp and bundled FFmpeg.
- 1080×1920 vertical output at 30 FPS using H.264 MP4.
- Silent, narration-only, music-only, and mixed music-plus-narration paths.
- Music fades, gain, narration gain, ducking, limiting, and output trimming.

### Narration and audio

`scripts/narrate.py` now synthesizes each segment separately with local Piper, checks speech duration against each segment allocation, places clips on the complete timeline, and supports a validated user-provided PCM WAV route.

The selected `en_US-lessac-medium` Piper voice model is downloaded locally and remains ignored by Git. Narration does not require a hosted API or repository secret.

### Verification and tests

The development branch passed the following local checks:

- TypeScript type-checking.
- Brief-model tests.
- Vite production build.
- Python syntax compilation for the narration script.
- v1 and v2 brief validation.
- Eight-segment silent rendering.
- MP4 metadata verification.
- Full FFmpeg decode verification.

The local eight-segment render was verified as a 22-second, 1080×1920, 30 FPS H.264 MP4 containing all eight scenes.

A local ARM64 sandbox issue was encountered: the installed bundled ffprobe file lacked its executable bit after `npm ci`, causing an `EACCES` error. After correcting only the ignored local file permission, the project’s own verifier passed. This is an environment portability issue worth addressing later, although it does not prove a GitHub x64 runner failure.

## GitHub Actions result

After explicit owner confirmation that the run was within the included/free allowance, one manual workflow run was dispatched:

- **Run:** [41433489649](https://github.com/ImperioKDB/ai-video-factory/actions/runs/41433489649)
- **Branch:** `milestone-3-continuation`
- **Commit tested:** `a23305060b5c4c40503f7d4f367dd1faecda4ad2`
- **Brief:** `examples/multi-segment-narrated.json`
- **Piper:** enabled
- **Result:** success
- **Runtime:** approximately 4 minutes 36 seconds

The workflow completed all relevant steps:

- Checked out the development branch.
- Installed Node dependencies.
- Validated the selected brief.
- Verified bundled FFmpeg tools.
- Type-checked the project.
- Ran brief-model tests.
- Built the Motion Canvas application.
- Installed Python and Piper.
- Downloaded or restored the Piper voice model.
- Synthesized narration for all three segments.
- Rendered the narrated MP4.
- Verified the narrated audio/video output.
- Uploaded the MP4 artifact.

The downloaded artifact was independently inspected after the workflow:

- **Duration:** 29.700 seconds.
- **Video:** H.264, 1080×1920, 30/1 FPS, 891 frames, 9:16.
- **Audio:** AAC-LC, 22,050 Hz, mono, 29.700 seconds.
- **Decode:** Complete FFmpeg decode passed.
- **Artifact SHA-256:** `ca9a12485d99ed0120d7c9002ba1f527393f8732ce5efde7b73ff0129f8a33a9`.

The downloaded artifact is available as [the verified narrated MP4](/home/ubuntu/ci-artifact-41433489649/ai-video-factory.mp4).

The development-branch handoff was updated to record the successful CI run and mark Milestone 3 complete. It is available in GitHub through the latest development-branch commit.

## Cost and licensing position

The renderer is designed to operate without paid rendering services, paid APIs, databases, or cloud storage. The current pipeline uses repository source, npm dependencies, local Piper, and GitHub Actions only when explicitly authorized.

The main ongoing cost risk is private GitHub Actions usage. The repository’s Actions billing endpoint was not accessible to the session and returned HTTP 403. Therefore the actual remaining allowance could not be independently read. The narrated run proceeded only after the owner explicitly confirmed that it was within the included/free allowance.

The workflow is reasonably cost-controlled because Piper is opt-in, the job has a 20-minute timeout, the artifact retention is limited to 14 days, and no paid service or payment method was added. Automatic pushes to `main` can still consume private Actions allowance, so future workflow design should consider concurrency cancellation and minimizing unnecessary runs.

Important license notes remain:

- Motion Canvas packages: MIT.
- Sharp: Apache-2.0.
- Ajv and Vite: MIT.
- Bundled FFmpeg/ffprobe installer packages: LGPL-2.1 declarations.
- Inter and Playfair Display font packages: OFL-1.1.
- Piper: GPL-3.0 according to the current Piper project.
- The Lessac voice package declares MIT but points to the separate Lessac Blizzard dataset license. Engine, model, dataset, music, and user audio terms should be reviewed before commercial redistribution.

## What is not complete yet

The following items are not blockers for the completed Milestone 3, but remain future work:

1. Preview and final export do not use identical drawing code. They share data and design logic, not pixel-identical rendering.
2. The Motion Canvas preview currently loads a committed example brief rather than acting as a general runtime brief editor.
3. There is no broad visual regression suite comparing preview frames with final-export frames.
4. The ARM64 bundled ffprobe executable-permission issue should be made robust across environments.
5. Relative media-path resolution should be anchored explicitly to the brief or project root.
6. The four existing npm audit findings remain in the Motion Canvas/Vite dependency chain; no non-breaking fix was available in the audit performed.
7. Music assets and broader asset licensing documentation remain the responsibility of the project owner.
8. The project has not yet been turned into an MCP server or a hosted application, intentionally.

## Recommended next milestone

The next milestone should focus on cost-safe production reliability rather than infrastructure expansion:

1. Normalize bundled executable permissions and media-path resolution.
2. Add a machine-readable render manifest containing brief hash, renderer commit, duration, dimensions, frame rate, codecs, audio presence, and decode status.
3. Add workflow concurrency cancellation and retain manual approval for Piper runs.
4. Refactor Motion Canvas layout components to consume the same prepared layout data used by the headless renderer.
5. Add a small set of deterministic visual reference frames.
6. Add more example briefs for user WAV, music, captions, and mixed audio.
7. Do not begin MCP-server or database work until the core production workflow needs it.

## Bottom line

The project has moved from an unverified Milestone 3 claim to a verified end-to-end narrated pipeline. The development branch produces multi-segment vertical videos, synthesizes narration locally, mixes it into the final MP4, verifies the output, and has now passed one real GitHub Actions narrated run with a downloadable artifact. `main` remains protected and unchanged. The next decision is product-focused: improve renderer/preview consistency and repeatability, or define the next content-production capability before adding infrastructure.
