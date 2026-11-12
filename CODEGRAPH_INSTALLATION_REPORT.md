# CodeGraph Installation Report — OpenCode + Scholars

**Repository:** ImperioKDB/Scholars  
**Workspace:** /workspaces/Scholars  
**Report date:** 2026-11-11  
**Installed by:** Autonomous engineering agent

---

## 1. Project identified and installed

**Official CodeGraph project:** https://github.com/colbymchenry/codegraph  
**Official npm package:** `@colbymchenry/codegraph`  
**Version installed:** 1.6.2 (latest)  
**Installation method:** Official standalone install script (`install.sh`) — downloads a self-contained bundle (vendored Node runtime + app), no separate Node.js/build tools required.

No substitute or similarly-named CodeGraph project was used. The official installation instructions from the CodeGraph repository README were followed:

1. Install the CLI via `install.sh`
2. Wire up agents via `codegraph install`
3. Initialize each project via `codegraph init`

---

## 2. Existing environment inspected (pre-install)

| Item | Value |
|------|-------|
| OS | Linux codespaces-1eb630 6.8.0-1070-azure x86_64 |
| Architecture | x86_64 (amd64) |
| Node.js | v20.20.2 |
| npm | 10.8.2 |
| OpenCode | v2.2.7 (`/home/codespace/.opencode/bin/opencode`) |
| OpenCode working | Yes (authenticated as ImperioKDB) |
| Existing `opencode.json` | None (project or global) |
| Existing `AGENTS.md` | None in repository |
| CodeGraph already installed | No (`@colbymchenry/codegraph` not in node_modules) |
| Disk space | 15 GB available (/workspaces) |
| Memory | 7.8 GiB total, ~2.2 GiB available |
| Existing MCP configuration | None |
| `.gitignore` | `node_modules`, `.next`, `.env`, `.env.local`, `.vercel`, `*.log` |

---

## 3. Installation and integration

### A3a. CLI installation

```
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
```

Result:
- Installed to `/home/codespace/.codegraph/versions/v1.6.2`
- Linked `/home/codespace/.local/bin/codegraph`
- `codegraph --version` → `1.6.2`

### A3b. OpenCode wiring

```
codegraph install --target opencode --yes --location global
```

Result:
- Created `~/.config/opencode/opencode.jsonc` with the CodeGraph MCP server entry:
  ```json
  {
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
- Created `~/.config/opencode/AGENTS.md` with CodeGraph usage instructions
- Telemetry notice displayed (can be disabled with `codegraph telemetry off` or `CODEGRAPH_TELEMETRY=0`)

No existing OpenCode plugins, settings, model configuration, LSP configuration, or agent instructions were overwritten or removed. Only the CodeGraph MCP server entry was added to `opencode.jsonc`.

### A3c. Integration method

The supported `codegraph install` method was used (not a manual hack). The installer did not propose modifying unrelated configurations, so no fallback to manual integration was needed.

---

## 4. Scholars repository indexed

```
cd /workspaces/Scholars
codegraph init
```

Result:
- Initialized in `/workspaces/Scholars`
- Indexed **381 files**
- **4,785 nodes, 10,232 edges** built in ~2.1 seconds
- `.codegraph/` directory created at repository root

### Exclusions (requirement A4)

- `.codegraph/` added to root `.gitignore` — generated graph databases/caches excluded from Git tracking
- `.codegraph/.gitignore` (created by CodeGraph) ignores all contents except itself
- `node_modules`, `.next`, `.env*`, `.vercel`, `*.log` already excluded via existing `.gitignore`
- No production data, secrets, tokens, or private keys indexed — CodeGraph is 100% local, SQLite only, no API keys, no data leaves the machine
- Resource-efficient configuration suitable for GitHub Codespaces (worker pools and caches auto-sized to container resources)
- No embedding models or external services installed — structural graph functionality only

---

## 5. Integration verification

| # | Verification | Result |
|---|-------------|--------|
| 1 | CodeGraph CLI runs successfully | ✅ `codegraph --version` → 1.6.2; `codegraph explore` works |
| 2 | Scholars indexing completes | ✅ 381 files, 4,785 nodes, 10,232 edges in ~2.1s |
| 3 | Graph contains actual Scholars source files and symbols | ✅ Query `getResourceImageUrl` returned verbatim line-numbered source from `lib/resource-center.ts:130-134` with callers and blast radius |
| 4 | OpenCode can discover CodeGraph MCP tools | ✅ `codegraph` server entry present in `~/.config/opencode/opencode.jsonc`; MCP tool `codegraph_explore` available per-project |
| 5 | OpenCode can query a real Scholars symbol and retrieve relationships | ✅ `codegraph explore "ResourceCenter"` returned 24 symbols across 4 files with call paths and blast radius |
| 6 | Integration survives OpenCode restart | ✅ Configuration written persistently to `~/.config/opencode/opencode.jsonc` (not session-only) |

### Sample query output

`codegraph explore "getResourceImageUrl"` returned:
- Symbol `getResourceImageUrl` at `lib/resource-center.ts:130`
- 4 callers in `app/resources/[slug]/page.tsx`, `components/resource-center.tsx`
- Verbatim source code of the function and related symbols

---

## 6. Repository changes made

| File | Change |
|------|--------|
| `.gitignore` | Added `.codegraph` entry to exclude generated graph database from Git tracking |

No other repository files were modified. No `.env*`, credentials, or secrets were touched. No production data was indexed.

---

## 7. Post-installation note

OpenCode should be restarted to load the new MCP server configuration. The CodeGraph MCP server is available per-project: pass the Scholars project path (`/workspaces/Scholars`) as `projectPath` to `codegraph_explore` (and other codegraph tools) to query the Scholars index. Auto-sync is enabled by default, so the graph stays current as files change.
