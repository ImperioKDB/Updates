# Scholars OpenCode Skills — Runtime Verification

**Date:** 2026-11-12
**Repository:** ImperioKDB/Scholars
**Working directory:** /workspaces/Scholars
**OpenCode version:** v2.2.7

## Objective

Establish that Scholars' installed OpenCode skills are operational (discoverable, loadable, and invocable) at runtime, not merely present in the repository. No application source code, Supabase schema/migration/RLS, dependencies, or OpenCode configuration was modified, and no commit was made in the Scholars repo.

## Phase 1 — Environment verification

| # | Check | Result |
|---|-------|--------|
| 1 | OpenCode version | `opencode v2.2.7` |
| 2 | Active repository / working directory | `ImperioKDB/Scholars` at `/workspaces/Scholars` (origin `https://github.com/ImperioKDB/Scholars`) |
| 3 | `.agents/skills/` contents | Two directories: `emil-design-eng`, `mobile-native` |
| 4 | Eight expected skill directories + SKILL.md | **Only two exist**, each with a valid SKILL.md (YAML frontmatter `name` + `description`):<br>• `.agents/skills/emil-design-eng/SKILL.md`<br>• `.agents/skills/mobile-native/SKILL.md` |
| 5 | OpenCode config & skill discovery | `/home/codespace/.config/opencode/opencode.jsonc` configures only the `codegraph` MCP server; no `skills` key. Per OpenCode v2, project-level skills are discovered from `.agents/skills/` and loaded **on demand** via the skill tool — not pre-injected into every prompt. |
| 6 | `SCHOLARS_OPENCODE_POLICY.md` | **Does not exist** anywhere in the repo or filesystem (searched recursively). No development policy is present to apply. |

`skills-lock.json` locks exactly the two installed skills (source `emilkowalski/skills`, type `github`): `emil-design-eng` and `mobile-native`.

## Phase 2 — Runtime discovery

OpenCode v2 skill mechanics (confirmed via docs + runtime): a skill is a folder containing `SKILL.md` with YAML frontmatter (`name`, `description`). The runtime advertises a skill when relevant, and the agent loads its instructions **on demand** via the `skill` tool.

| Skill | Installed | Discoverable | Loaded | Format supported |
|---|---|---|---|---|
| emil-design-eng | Yes | Yes | Yes (via `skill` tool) | Yes — standard SKILL.md |
| mobile-native | Yes | Yes | Yes (via `skill` tool) | Yes — standard SKILL.md |
| frontend-design | No | No | No | N/A — not installed |
| webapp-testing | No | No | No | N/A — not installed |
| vercel-react-best-practices | No | No | No | N/A — not installed |
| web-design-guidelines | No | No | No | N/A — not installed |
| supabase | No | No | No | N/A — not installed |
| seo | No | No | No | N/A — not installed |

**Direct evidence of loading:** invoking the `skill` tool for `emil-design-eng` and `mobile-native` returned each skill's full instructions into the session (base directory confirmed as `.agents/skills/<name>/`).

- No unsupported/incompatible skill format: both installed skills use the standard OpenCode `SKILL.md` + YAML frontmatter format.
- The other six named skills are not installed, not discoverable, and not loadable — no directory, no SKILL.md, not offered by the `skill` tool. Per the verification rules, no success is claimed where the runtime provides no evidence.

## Phase 3 — Harmless invocation tests

Read-only applications of each loaded skill's own guidance and required output format. No source modified, no scripts executed.

**emil-design-eng** — hypothetical button interaction review (applied the skill's required Before/After/Why table plus animation/button rules):

| Before | After | Why |
|---|---|---|
| `transition: all 300ms` | `transition: transform 160ms ease-out` | Specify exact properties; avoid `all`; keep UI under 300ms |
| `transform: scale(0)` entry animation | `transform: scale(0.95); opacity: 0` | Nothing appears from nothing; start from a visible scale |
| `ease-in` on hover | `ease-out` custom `cubic-bezier(0.23, 1, 0.32, 1)` | `ease-in` feels sluggish; `ease-out` gives instant feedback |
| No `:active` state on button | `transform: scale(0.97)` on `:active` | Buttons must respond instantly to press |
| 400ms dropdown duration | 150–250ms | UI animations should stay under 300ms |

**mobile-native** — mobile viewport & touch-target scenario (applied the skill's Output format — what was wrong / what changed / what needs a phone):

- **What was wrong:** symptoms matched from its table — input zoom (<16px font), stuck hover state (ungated `:hover`), wrong app-shell height (`100vh`).
- **What changed:** `input, textarea, select { font-size: 16px; }`; hover gated behind `@media (hover: hover) and (pointer: fine)`; `.app { height: 100dvh; }` / `.hero { min-height: 100svh; }` (each flagged as verify-from-code).
- **What needs a phone:** confirm input-zip recurrence, sticky-hover absence, tap-highlight removal, click-delay elimination, safe-area handling on real hardware (skill Hard Rule 5 — emulation cannot reproduce these).

**Result:** both loaded skills invoked successfully. The six missing skills could not be invoked — no evidence exists.

## Phase 4 — Final report

### Skill matrix

| Skill | Installed | Discoverable | Loaded | Invoked | Result |
|---|---|---|---|---|---|
| emil-design-eng | Yes | Yes | Yes | Yes | Operational — instructions loaded via skill tool and applied to button review |
| mobile-native | Yes | Yes | Yes | Yes | Operational — instructions loaded via skill tool and applied to mobile viewport review |
| frontend-design | No | No | No | No | Not installed — cannot invoke |
| webapp-testing | No | No | No | No | Not installed — cannot invoke |
| vercel-react-best-practices | No | No | No | No | Not installed — cannot invoke |
| web-design-guidelines | No | No | No | No | Not installed — cannot invoke |
| supabase | No | No | No | No | Not installed — cannot invoke |
| seo | No | No | No | No | Not installed — cannot invoke |

### Key findings

- **OpenCode version:** v2.2.7. Runtime discovers project skills from `.agents/skills/` and loads them on demand via the skill tool — confirmed working for the two installed skills.
- **Eight-skill claim is incorrect:** only **2 of 8** skills are actually installed (`emil-design-eng`, `mobile-native`), both recorded in `skills-lock.json`. Six are absent.
- **Compatibility issues:** none with the installed skills (standard `SKILL.md` + YAML frontmatter). The primary gap is the mismatch between the claimed inventory (8) and actual inventory (2).
- **Context/token overhead:** skills are loaded on demand, so zero overhead when unused. Loading both skills added their full `SKILL.md` content (~43 KB combined) to context at load time; no persistent per-turn overhead.
- **Development policy:** `SCHOLARS_OPENCODE_POLICY.md` does not exist, so no development policy is being applied. The only AGENTS.md-equivalent is the user-level CodeGraph note at `~/.config/opencode/AGENTS.md`.
- **Configuration files inspected:** `/home/codespace/.config/opencode/opencode.jsonc`, `/home/codespace/.config/opencode/AGENTS.md`, `/home/codespace/.config/opencode/service.json`, `/workspaces/Scholars/skills-lock.json`.
- **Manual action still required:** yes. To satisfy the claimed eight-skill inventory, the six missing skills (`frontend-design`, `webapp-testing`, `vercel-react-best-practices`, `web-design-guidelines`, `supabase`, `seo`) would need to be installed under `.agents/skills/` with valid `SKILL.md` files, and `SCHOLARS_OPENCODE_POLICY.md` would need to be created if a policy is intended. No code changes, commits, dependency changes, or config overwrites were made during this verification.

### Conclusion

The two installed skills are **operational, not merely present**: they are discoverable, loadable on demand via the OpenCode runtime, and their instructions were successfully applied to harmless read-only tasks. However, the repository does **not** contain eight skills — it contains two. Six of the eight named skills are absent and cannot be invoked.
