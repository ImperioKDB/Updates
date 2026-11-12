# CodeGraph Fresh-Session Verification — 2026-11-12

**Repository:** ImperioKDB/Scholars  
**Workspace:** /workspaces/Scholars  
**Verification date:** 2026-11-12  
**Reported installation:** CodeGraph 1.6.2, 381 indexed files, 4,785 nodes, 10,232 edges (per CODEGRAPH_INSTALLATION_REPORT.md, dated 2026-11-11)  
**MCP config:** ~/.config/opencode/opencode.jsonc (codegraph server entry: `codegraph serve --mcp`, not disabled)  
**Index location:** /workspaces/Scholars/.codegraph/ (codegraph.db present)

---

## 1. Restart verification (Phase 2.1)

### 1.1 This session cannot restart itself

This OpenCode session cannot safely restart itself and persist verification across the restart. Per the task, I am **not pretending** that restart persistence has been verified. Instead:

- I verified CodeGraph is discoverable and callable **in this session** (section 2 below).
- I provide the **exact restart instruction** below for a fresh session to complete the post-restart verification.
- A fresh session must re-run the checks in section 2 and confirm the graph remains usable after restart.

### 1.2 Exact restart instruction

> Start a brand-new OpenCode session whose working directory is `/workspaces/Scholars`, then verify CodeGraph there.

The CodeGraph MCP configuration is persistent (written to `~/.config/opencode/opencode.jsonc`, not session-only), so a new OpenCode session should load it automatically. No re-installation is required unless the MCP server entry is missing.

### 1.3 What a fresh session must verify (post-restart)

| # | Check | How to verify |
|---|---|---|
| 1 | OpenCode discovers the CodeGraph MCP server | Confirm `codegraph` server entry present in `~/.config/opencode/opencode.jsonc` and that `codegraph_explore` appears as an available MCP tool |
| 2 | CodeGraph tools are callable, not merely listed | Call `codegraph_explore` with a real Scholars symbol (e.g. `getResourceImageUrl`) and confirm it returns verbatim source, not an error |
| 3 | The Scholars graph can be queried | Pass `projectPath: "/workspaces/Scholars"` and confirm the index (codegraph.db) is opened |
| 4 | Real symbol query returns source locations and relationships | Query `getResourceHome`, `getResourceArticle`, `ResourceCard`, `ResourceAdSlot`, `getResourceImageUrl`; confirm file:line source and callers/dependants |
| 5 | Dependency/impact query returns meaningful callers or dependants | Query a symbol and inspect its blast radius / callers (e.g. `ResourceAdSlot` → 6 callers across the three resource page routes) |
| 6 | Graph remains usable after another restart | Restart OpenCode once more and re-run checks 1–5 |

---

## 2. CodeGraph verification in this session (Phase 2.2)

CodeGraph was queried via `codegraph_explore` with `projectPath: "/workspaces/Scholars"`.

### 2.1 Server discovery and callability

**Confirmed.** The `codegraph` MCP server is configured in `~/.config/opencode/opencode.jsonc`:

```jsonc
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
```

`codegraph_explore` was successfully invoked against the Scholars index and returned verbatim, line-numbered source plus call paths and blast radius. The tool is callable, not merely listed.

### 2.2 Real symbol queries return source locations and relationships

**Confirmed.** Querying `getResourceHome getResourceArticle getResourceImageUrl ResourceCard ResourceAdSlot ResourceCenter` returned:

- `getResourceHome` — `lib/resource-center.ts:56` (queries `resource_public_articles` / `resource_public_categories`)
- `getResourceArticle` — `lib/resource-center.ts:105`
- `getResourceImageUrl` — `lib/resource-center.ts:130-134` (approves paths under `resource-center/featured/`, rejects traversal)
- `isApprovedResourceImagePath` — `lib/resource-center.ts:136-138`
- `getResourceCanonicalUrl` — `lib/resource-center.ts:140-154`
- `ResourceAdSlot` — `components/resource-center.tsx:29-36` (ads disabled-by-default logic)
- `ResourceCard` — `components/resource-center.tsx:44-64`
- `ResourcePageFrame`, `ResourceImage`, `ResourceEmptyState`, `ResourceErrorState`, `OpportunityBridge`, `ResourceMasthead` — `components/resource-center.tsx`

Each symbol returned its exact file and line numbers with verbatim source (treated as already Read).

### 2.3 Dependency / impact query returns meaningful callers and dependants

**Confirmed.** The exploration returned a flow graph and blast radius, e.g.:

- Flow: `ResourceCard` → next/link → `/resources/:slug` → `ResourceArticlePage` → renders `<ResourceAdSlot>`
- Blast radius for `ResourceAdSlot`: 6 callers across `app/resources/[slug]/page.tsx`, `app/resources/page.tsx`, `app/resources/category/[slug]/page.tsx`
- Blast radius for `ResourceCard`: 6 callers across the three resource page routes
- Dynamic-dispatch links: `ResourcesPage → ResourceCard`, `ResourceCategoryPage → ResourceCard`, `ResourcesPage → ResourceAdSlot`, `ResourceCategoryPage → ResourceAdSlot`

This demonstrates the graph tracks real cross-file relationships including dynamic (JSX/Next Link) hops that grep cannot follow.

### 2.4 CodeGraph quality

| Quality check | Result | Evidence |
|---|---|---|
| Excludes `.env*`, credentials, tokens, private keys | PASS | `.codegraph/` added to root `.gitignore`; `node_modules`, `.next`, `.env*`, `.vercel`, `*.log` excluded via existing `.gitignore`; CodeGraph is local SQLite only, no API keys, no data leaves the machine (per installation report §4) |
| Excludes generated directories and dependencies | PASS | `node_modules`, `.next`, `.vercel` excluded |
| Tracks relevant source files | PASS | 381 files indexed; `lib/resource-center.ts`, `components/resource-center.tsx`, `app/resources/**`, `lib/resource-content.ts`, `lib/sitemap-data.ts` all present and queried successfully |
| Refreshed after source changes | Reported | Auto-sync enabled by default per installation report §7; not re-verified after a change in this session |

### 2.5 Symbols discovered (actual, from the graph)

All preferred symbols exist and were resolved:
- `getResourceHome` — `lib/resource-center.ts:56`
- `getResourceArticle` — `lib/resource-center.ts:105`
- `ResourceCard` — `components/resource-center.tsx:44`
- `ResourceAdSlot` — `components/resource-center.tsx:29`
- `getResourceImageUrl` — `lib/resource-center.ts:130`

No symbol was assumed to exist; each was confirmed by querying the graph.

---

## 3. Overall CodeGraph status

**CodeGraph works in this OpenCode session:**
1. OpenCode discovers the CodeGraph MCP server — ✅ (persistent config)
2. CodeGraph tools are callable — ✅ (`codegraph_explore` returned source + relationships)
3. The Scholars graph can be queried — ✅ (`projectPath: /workspaces/Scholars`, codegraph.db opened)
4. Real symbol query returns source locations and relationships — ✅ (all 5 preferred symbols resolved to file:line)
5. Dependency/impact query returns meaningful callers/dependants — ✅ (6 callers for ResourceAdSlot/ResourceCard; dynamic JSX/Link hops traced)
6. Graph remains usable after another restart — ⚠️ **NOT yet verified** (this session cannot restart itself; see exact restart instruction in section 1.2)

**Bottom line:** CodeGraph is installed, integrated, and functional now. Fresh-session persistence after restart remains to be demonstrated by a new OpenCode session following the instruction above. No secrets were exposed in this verification.
