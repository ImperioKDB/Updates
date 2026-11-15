# Personal Agentic Workbench — Infrastructure Preflight Report

**Project:** Personal Agentic Workbench  
**Proposed repository:** `ImperioKDB/agentic-workbench`  
**Assessed environment:** GitHub Codespaces `didactic-engine-jjxw9wg744rv2p7pj`  
**Working directory:** `/workspaces/Scholars`  
**Assessment date:** Sun Nov 15 2026  
**Report filename:** `PERSONAL_AGENTIC_WORKBENCH_INFRASTRUCTURE_PREFLIGHT_2026-11-15.md`  
**Destination:** `ImperioKDB/Updates`  
**Branch:** `report/agentic-workbench-preflight`  
**Mode:** READ-ONLY assessment (this publication is a one-time authorized push)

---

## 1. Executive Summary

The Codespaces environment is substantially ready to host a reusable OpenCode-based multi-agent system, with one major gap: the target repository `ImperioKDB/agentic-workbench` **does not yet exist** (HTTP 404) and must be created — out of scope for this read-only task.

Key positives:
- OpenCode v2.3.0 is installed and **functional** (models registry, MCP, auth, subcommands all operational).
- GitHub CLI is authenticated as `ImperioKDB` with full admin permissions on all three existing repositories.
- CodeGraph MCP server is configured and **connected**; its daemon (v1.6.2) is running with an active file watcher on `/workspaces/Scholars`.
- All required toolchains are present: Node v24.22.2, npm 11.19.1, Git 2.56.0, gh 2.103.3.
- Disk (12G free of 32G) and memory (5.1G available of 7.8G) are adequate.

Key concerns:
- The target repo `agentic-workbench` returns HTTP 404 — **needs creation** (REQUIRES USER ACTION).
- All three existing repositories are **public**; a new agentic-workbench repo should be created **private** with least-privilege access.
- OpenCode `service.json` files contain a `password` key (credential at rest, mode 600) — a credential-exposure risk to mitigate.
- No custom agent definitions exist yet (no `agents/` directory) — expected for a new project.
- The prior cross-repository HTTP 403 problem is **VERIFIED as active** — git push to `ImperioKDB/Updates` is denied with HTTP 403 even when `GH_TOKEN` is supplied directly, because the token lacks push/write scope for git over HTTPS.
- `gh auth token` was inadvertently echoed in plaintext during this session — recommend rotating `GH_TOKEN`/`GITHUB_TOKEN` before production use (security finding).

Overall verdict: **READY WITH CONDITIONS** — proceed to repo creation and credential hardening after human approval.

Classification key used throughout:
- **VERIFIED** — confirmed by direct observation during this assessment
- **NOT VERIFIED** — could not be confirmed within scope
- **BLOCKED** — actively prevented by a permissions or configuration issue
- **REQUIRES USER ACTION** — requires a human decision or action before proceeding

---

## 2. Environment Inventory

| Item | Finding | Classification |
|------|---------|----------------|
| Working directory | `/workspaces/Scholars` | VERIFIED |
| Workspaces under `/workspaces/` | `Scholars`, `Updates`, `scholars-schema-extraction`, `opencode-backup`, `opencode-config-staging` | VERIFIED |
| Operating system | Ubuntu 24.04.5 LTS (Noble Numbat), Linux 6.8.0-1070-azure x86_64 | VERIFIED |
| Development environment | GitHub Codespaces (`CODESPACES=true`) | VERIFIED |
| Codespace name | `didactic-engine-jjxw9wg744rv2p7pj` | VERIFIED |
| Disk space | 32G total, 19G used, 12G available (61%) on overlay `/` | VERIFIED |
| Memory | 7.8Gi total, 2.7Gi used, 5.1Gi available, 0B swap | VERIFIED |
| Node.js | v24.22.2 | VERIFIED |
| npm | 11.19.1 | VERIFIED |
| Git | 2.56.0 | VERIFIED |
| GitHub CLI | 2.103.3 (2026-10-26) | VERIFIED |
| OpenCode | v2.3.0 at `/home/codespace/.opencode/bin/opencode` | VERIFIED |
| OpenCode functional | Yes — `opencode models`, `opencode mcp list`, `opencode auth list` all return successfully | VERIFIED |
| `GH_TOKEN` | PRESENT (value redacted) | VERIFIED |
| `GITHUB_TOKEN` | PRESENT (value redacted) | VERIFIED |

Workspace directory listing (`/workspaces/`):
```
Scholars/              (git repo, active Codespace)
Updates/               (git repo)
scholars-schema-extraction/  (git repo)
opencode-backup/       (no .git; contains OpenCode config recovery archives)
opencode-config-staging/ (no .git; contains OpenCode config backups, manifests, snapshots)
```

Note: Token values are redacted. Presence confirmed only.

---

## 3. GitHub Authentication Assessment

`gh auth status` (summarized, token redacted):
- Host: `github.com`
- Account: **ImperioKDB** (type: User, not site admin)
- Method: `GH_TOKEN`
- Active account: true
- Git operations protocol: https

`gh api user`: login=`ImperioKDB`, name=`Abolaji Bright`, site_admin=`false` — VERIFIED

`gh api rate_limit`: core limit 5000, remaining 4981, used 19 — authenticated and healthy — VERIFIED

Token presence (values **redacted**):
- `GH_TOKEN`: PRESENT
- `GITHUB_TOKEN`: PRESENT

Authentication method actually used by GitHub CLI: **`GH_TOKEN`** (environment token), per `gh auth status`. — VERIFIED

Git credential helper (system): `/.codespaces/bin/gitcredential_github.sh` (Codespaces-managed) — VERIFIED

Global git config: only LFS filters configured; **no `user.name`/`user.email` set** at global level (local repo config sets identity for commits). Relevant if commits are later made. — VERIFIED

### Cross-repository HTTP 403 investigation — VERIFIED as active
- All three existing repos return HTTP 200 with full `admin`/`maintain`/`pull`/`push`/`triage` permissions for `ImperioKDB` via the `gh` API.
- However, `git push` to `ImperioKDB/Updates` is **denied with HTTP 403**, including when `GH_TOKEN` is supplied directly via a URL-embedded remote. This indicates `GH_TOKEN` lacks the `repo` (write/push) scope needed for git over HTTPS to this repository, despite `gh` API calls succeeding (admin read access confirmed).
- The prior cross-repository HTTP 403 problem is therefore **VERIFIED as active** — classification changed from NOT VERIFIED to BLOCKED for git push operations.

---

## 4. Repository Access Matrix

| Repository | Default branch | Visibility | Permissions (ImperioKDB) | Exists? |
|------------|---------------|------------|--------------------------|---------|
| `ImperioKDB/Scholars` | main | Public | admin, maintain, pull, push, triage | Yes |
| `ImperioKDB/Updates` | main | Public | admin, maintain, pull, push, triage | Yes |
| `ImperioKDB/scholars-schema-extraction` | main | Public | admin, maintain, pull, push, triage | Yes |
| `ImperioKDB/agentic-workbench` | — | — | — | **No (HTTP 404)** |

`ImperioKDB/agentic-workbench` does **not exist** — needs to be created. **Not created yet** (read-only restriction / out of scope for this publication task). — VERIFIED

Local git remotes in each workspace all point to `https://github.com/ImperioKDB/<repo>.git` with push URLs matching. — VERIFIED

---

## 5. OpenCode Readiness and Capabilities

OpenCode v2.3.0 is installed at `/home/codespace/.opencode/bin/opencode` and is **functional**. — VERIFIED

### Configuration (read-only, not modified)
- Config dir: `~/.config/opencode/`
  - `opencode.jsonc` — schema `https://opencode.ai/config.json`
  - `AGENTS.md` — CodeGraph usage guidance
  - `service.json` (mode 600, contains `password` key — credential at rest; value redacted)
- State dir: `~/.local/state/opencode/`
  - `model.json` — recent models (no credentials)
  - `service.json` (mode 600, contains `password`; value redacted)
- Bin: `~/.opencode/bin/opencode`, `opencode2`

### `opencode.jsonc` contents
```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "servers": {
      "codegraph": {
        "type": "local",
        "command": ["codegraph", "serve", "--mcp"],
        "disabled": false,
        "codemode": false
      }
    }
  }
}
```
One MCP server configured: `codegraph` (local, enabled, not codemode). Identical copy exists in `opencode-config-staging/global-config/`. — VERIFIED

### Available OpenCode subcommands
`upgrade`, `update`, `uninstall`, `acp`, `api`, `debug`, `auth`, `mcp`, `plugin`, `models`, `stats`, `mini`, `run`, `session`, `service`, `reload`, `pair`, `serve` — all present. — VERIFIED

Configuration conflicts: **None detected** between active `~/.config/opencode/opencode.jsonc` and the staging copy — they are identical. — VERIFIED

Custom agent definitions: **None configured** — no `~/.opencode/agents/` or `~/.config/opencode/agents/` directory exists. Expected for a new project; can be added after repo creation. — VERIFIED

---

## 6. Model Provider Assessment

`opencode models` successfully lists available models across providers. Provider IDs observed (no credentials exposed):
- `nvidia/*` (e.g., `nvidia/nemotron-3.5-super-vl-120b-a12b`, `nvidia/meta/llama-3.2-...`)
- `github-copilot/*` (e.g., `github-copilot/claude-sonnet-4.6`, `github-copilot/gpt-5.6-...`)
- `opencode/*` (e.g., `opencode/nemotron-3.5-super-vl-free`)

`opencode auth list` integrations (no secret values):
- GitHub Copilot — `GITHUB_TOKEN` — environment
- Nvidia — `Nvidia 2` — stored
- Nvidia — `Nvidia` — stored

Model provider credentials are stored/configured; values not exposed in this report. — VERIFIED

The current model in use (from `model.json` recent list): `nvidia/nemotron-3.5-super-vl-120b-a12b` with variant `thinking`. — VERIFIED

---

## 7. MCP and Subagent Readiness

| Capability | Status | Evidence | Classification |
|------------|--------|----------|----------------|
| Subagents | Supported | `explore`, `general` (OpenCode built-ins); no custom agent definitions found | VERIFIED |
| Custom agent definitions | None configured | No `agents/` directory in config paths | VERIFIED (expected for new project) |
| MCP servers | 1 configured, connected | `codegraph` via `opencode mcp list` → "codegraph connected" | VERIFIED |
| CodeGraph | Running, indexed | Daemon v1.6.2 on `daemon.sock`, file watcher active, `.codegraph/` present in Scholars | VERIFIED |
| ACP server | Available | `opencode acp` subcommand | VERIFIED |
| Plugins | Available | `opencode plugin` subcommand | VERIFIED |
| Auth management | Available | `opencode auth {list,login,logout,export,import,switch}` | VERIFIED |
| Standalone/server modes | Available | `--standalone`, `--server`, `serve` | VERIFIED |

CodeGraph daemon log confirms active file watcher and auto-sync for `/workspaces/Scholars`. — VERIFIED

---

## 8. Security Assessment

| # | Finding | Risk | Classification |
|---|---------|------|----------------|
| S1 | `GH_TOKEN` was echoed in plaintext during this session via `gh auth token` | Token may now be in session logs/history | **REQUIRES USER ACTION** — rotate `GH_TOKEN`/`GITHUB_TOKEN` before production use |
| S2 | `~/.config/opencode/service.json` and `~/.local/state/opencode/service.json` contain a `password` key (mode 600) | Credential at rest; parent dirs world-readable | **REQUIRES USER ACTION** — audit/rotate; restrict file permissions further |
| S3 | `opencode-backup/opencode-db.enc` and `.tar.gz.enc` exist (encrypted) | Encrypted at rest — lower risk, but confirms credential material backed up | NOT VERIFIED (encryption strength not assessed) |
| S4 | All three existing repos are **public** | New agentic-workbench repo should be private by default | **REQUIRES USER ACTION** — create new repo private |
| S5 | Authenticated account `ImperioKDB` has **admin** on all repos (broad scope) | Over-permissive for a multi-agent system | **REQUIRES USER ACTION** — least-privilege team/token for the new repo |
| S6 | `GH_TOKEN` lacks `repo` write scope for git push over HTTPS (HTTP 403 confirmed) | Blocks publication and future git operations | **BLOCKED** — git push to `ImperioKDB/Updates` denied |
| S7 | `GH_TOKEN` and `GITHUB_TOKEN` both present, different values | Potential token duplication/confusion | LOW — confirm which is authoritative |
| S8 | No `user.name`/`user.email` in global git config | Attribution unclear for future commits | LOW — configure before committing |

### Recommended secure credential handling for project-specific credentials
- Use **GitHub Secrets** (repository/environment secrets) or **GitHub Codespaces secrets** for CI/runtime credentials — never commit them.
- For OpenCode model provider keys, use `opencode auth login` (stored) or environment variables; avoid `service.json` plaintext passwords.
- Use a **fine-grained personal access token** or a **GitHub App** with repository-scoped permissions for the agentic-workbench repo, rather than a broad admin PAT.

### Actions that should require explicit human approval
1. Creation of `ImperioKDB/agentic-workbench` (and its visibility/initial settings).
2. Any change to repository visibility (public ↔ private).
3. Rotation or creation of `GH_TOKEN`/`GITHUB_TOKEN` or OpenCode provider credentials.
4. Granting `admin`/`write` access to any team member or service principal on the new repo.
5. Adding MCP servers or plugins that execute code or access external networks.

---

## 9. Identified Blockers

| Blocker | Severity | Classification |
|---------|----------|----------------|
| `ImperioKDB/agentic-workbench` does not exist (HTTP 404) | High | REQUIRES USER ACTION |
| Git push to `ImperioKDB/Updates` denied with HTTP 403 (`GH_TOKEN` lacks write scope for HTTPS) | High | **BLOCKED** |
| `GH_TOKEN` exposed in plaintext this session | High | REQUIRES USER ACTION |
| `service.json` password credentials at rest | Medium | REQUIRES USER ACTION |
| New repo should be private with least-privilege access | Medium | REQUIRES USER ACTION |
| Prior cross-repository HTTP 403 problem confirmed active | Medium | **BLOCKED** (for git push) |

---

## 10. Recommended Resolutions

| Blocker | Resolution | Owner |
|---------|------------|-------|
| `ImperioKDB/agentic-workbench` does not exist | Create the repository (private, default branch `main`). Out of scope for this task. | Human (after approval) |
| Git push 403 (`GH_TOKEN` lacks write scope) | Grant `GH_TOKEN` `repo` scope, or configure a token with `repo` write permission for HTTPS git operations, or use SSH. | Human |
| `GH_TOKEN` exposed in plaintext | Rotate `GH_TOKEN` and `GITHUB_TOKEN`; update anywhere they're stored. | Human |
| `service.json` password credentials at rest | Audit, rotate, restrict permissions (mode 600 or tighter). | Human |
| New repo visibility/access | Create private; scoped token/team; least-privilege. | Human |
| No custom agent definitions yet | Define agents in `~/.config/opencode/agents/` or per-project after repo creation. | Human |

---

## 11. Infrastructure Readiness Verdict

**VERDICT: READY WITH CONDITIONS**

The environment satisfies all technical prerequisites for hosting a reusable OpenCode-based multi-agent system:
- OpenCode installed and functional (v2.3.0)
- GitHub CLI authenticated as `ImperioKDB` with admin access to existing repos (via `gh` API)
- Model providers configured (NVIDIA, GitHub Copilot, OpenCode)
- MCP + CodeGraph operational and connected
- Adequate disk and memory

Conditions (must be addressed before implementation):
1. **Create** `ImperioKDB/agentic-workbench` (private) — REQUIRES USER ACTION.
2. **Resolve git push 403** — `GH_TOKEN` lacks write scope for HTTPS git; BLOCKED until token scope is corrected or an alternative auth method is configured.
3. **Rotate tokens** (`GH_TOKEN`/`GITHUB_TOKEN`) due to plaintext exposure this session — REQUIRES USER ACTION.
4. **Harden credentials** (`service.json` passwords, least-privilege token for new repo) — REQUIRES USER ACTION.

Classification summary: no implementation blockers beyond the git push auth issue; several REQUIRES USER ACTION items; one BLOCKED (git push 403).

---

## 12. Recommended Implementation Roadmap

1. **Approve** this assessment and authorize repository creation and token rotation.
2. **Rotate** `GH_TOKEN` / `GITHUB_TOKEN` (revoke the exposed token, issue a fine-grained replacement with `repo` scope).
3. **Create** `ImperioKDB/agentic-workbench` as a **private** repository with default branch `main`.
4. **Configure least-privilege access** (scoped PAT or GitHub App; no broad admin for the agent system).
5. **Resolve git push authentication** so `GH_TOKEN` (or replacement) can push over HTTPS.
6. **Harden OpenCode credential storage** (rotate `service.json` passwords, restrict file modes).
7. **Confirm 403 behavior** is resolved by testing a push to a repository.
8. **Initialize** the repo with OpenCode agent definitions and project scaffolding.
9. **Begin implementation** of the multi-agent system.

---

*This report was generated from a READ-ONLY assessment. No repositories were created or modified, no packages installed, no configuration changed, and no credentials are exposed in this document. All token/password values are redacted. This publication to `ImperioKDB/Updates` is a one-time authorized push to open a pull request for human review.*
