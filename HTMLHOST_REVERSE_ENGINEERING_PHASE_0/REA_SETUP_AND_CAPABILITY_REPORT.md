# REA Setup and Capability Report

**Project:** HTMLhost Reverse Engineering Lab
**Phase:** 0 — Research environment setup and platform reconnaissance
**Date:** 2026-11-08
**Status:** Complete for review

## Scope

This report answers whether the official Reverse Engineer Anything (REA) project can be executed in the current Manus sandbox, what is operational, what remains unconfigured, and what evidence supports those conclusions.

The official project is [morluto/rea](https://github.com/morluto/rea). The project describes REA as a local MCP and CLI toolkit for investigating released software, JavaScript/Electron applications, websites, browser activity, and native binaries. Its official website is [rea.tools](https://rea.tools/). The repository README and installation guide are the primary setup sources used here. [1] [2]

## Official REA capabilities relevant to this project

REA is designed to connect a coding agent to inspection tools. Its documented website workflow can observe a selected browser page, associate an interaction with network activity, retain accessibility text and JSON response shapes, and optionally retain loaded script sources. The official browser guide demonstrates this with a public Notes example and explicitly describes bounded observation windows rather than unrestricted traffic collection. [3]

For HTMLhost research, the most relevant documented capability families are:

- passive web-page inspection and script/resource evidence;
- bounded browser scenarios using Playwright;
- browser screenshots and web captures;
- static JavaScript analysis for local artifacts or exported bundles;
- comparison of web captures and evidence bundles; and
- evidence records that retain limitations and provenance instead of presenting guesses as source truth.

REA also supports native, Android, managed-code, firmware, packet-capture, and other analysis domains. Those are outside the current Phase 0 scope and should not be enabled or installed unless a later research question requires them.

## Prerequisites and limitations found in the documentation

The current REA release reports version **6.8.0** from npm and requires Node.js `^22.23.4 || ^24.22.1 || >=26.12.1`. The sandbox has Node.js **22.23.4** and npm **10.9.9**, so the runtime version is compatible. [1] [2]

The documented setup command is:

```sh
npx rea-agents@latest setup
```

Setup is an approval-based configuration transaction. It detects supported coding-agent clients, previews proposed configuration changes, backs up existing configuration where applicable, and only writes after approval. The setup guide distinguishes npm package-download approval from REA configuration approval. [2]

The project also documents optional external providers. Ghidra, IDA, JADX, Hopper, JEB, Kuna, and similar tools are not bundled as universally available analysis engines. Several require caller-supplied installations, licensed commercial software, or explicit environment configuration. REA states that it does not grant licenses or authorize bypassing commercial-tool restrictions. [1] [2]

For browser observation, REA expects a caller-controlled browser or a supported browser-capture path. The official guide uses Chrome remote debugging and a bounded observation command. This is compatible in principle with the sandbox’s Chromium and browser-inspection tooling, but a persistent REA agent registration is a separate concern. [3]

## Environment verification

### Runtime checks

The sandbox exposes:

- Node.js: `/home/ubuntu/.nvm/versions/node/v22.13.0/bin/node`, reporting `v22.23.4`;
- npm: reporting `10.9.9`;
- Python 3;
- Chromium at `/usr/bin/chromium`; and
- Playwright CLI at `/usr/local/bin/playwright`.

### Package and CLI checks

`npx -y rea-agents@latest --help` completed successfully and resolved REA 6.8.0. The CLI exposed the documented analysis commands, including `analyze-javascript-application`, `capture-browser-scenario`, `capture-web-screenshot`, `inspect-web-page`, `analyze-web-bundle`, and evidence comparison/export commands.

`rea setup --dry-run --format json` completed without applying changes. Its plan contained no planned or applied actions because no supported external coding-agent client was detected in the sandbox.

`rea doctor --format json` completed and returned a truthful non-ready result for a full agent environment:

- `healthy: false`;
- `environment_healthy: false`;
- no REA skill registration present;
- no agent registrations present; and
- Ghidra, IDA, JADX, and Kuna unavailable because they are not configured.

This does **not** mean the CLI is unusable. It means the full guided agent integration and optional native-provider environment are not configured.

## Legitimate smoke test

A small local JavaScript fixture was created solely to verify the supported static-analysis path. It contained a `package.json` and one `index.js` module exporting a simple `greet(name)` function. The command:

```sh
npx -y rea-agents@latest analyze-javascript-application \
  /home/ubuntu/rea-phase0/fixture --json
```

completed successfully. The result reported `operation: analyze_javascript_application`, produced an evidence identifier, normalized and raw result sections, relationship coverage, authority/limitation metadata, and a sealed application graph. Progress output showed inventory, parsing, semantic projection, graph construction, validation, and evidence hashing.

The retained smoke-test artifact is:

`/home/ubuntu/rea-phase0/rea-javascript-smoke-test.json`

This is a valid verification of REA’s local static JavaScript analysis path. It is not evidence about HTMLhost and is not being used as such.

## Configuration decision

REA is **executable but not natively registered as a Manus agent skill in this sandbox**. No supported coding-agent client was detected, so there was no legitimate client configuration target to modify. I did not create a fabricated registration or modify unrelated agent configuration.

The practical Phase 1 integration is therefore:

1. use the official `npx rea-agents@latest` CLI for bounded commands where a concrete input contract is known;
2. use the Manus browser inspection tools for stateful public-page navigation, DOM/runtime inspection, screenshots, and responsive checks;
3. retain command outputs and browser artifacts under the project research directory; and
4. if a later task requires a persistent MCP registration, configure REA against an explicitly available supported client or run it in a separate cloud/container environment with a real MCP client.

A separate cloud execution environment is not currently necessary for public HTMLhost research because the sandbox already has a compatible Node runtime, browser, and Playwright tooling. It would become useful if the investigation requires a dedicated Chrome remote-debugging session, long-running capture, or a caller-supplied native analysis engine.

## Limitations and unresolved setup questions

- The sandbox does not expose a detected Claude Code, Codex, Cursor, Gemini CLI, VS Code, or other supported REA client configuration.
- Optional native-analysis providers are not configured and are not needed for public HTMLhost work.
- The browser smoke test used Manus’s stateful browser inspection path; a dedicated REA CDP capture against that exact browser session was not asserted, because the browser session’s debugging endpoint is not exposed as a user-controlled local port here.
- No authenticated HTMLhost project was accessed. Consequently, editor internals, draft APIs, account-scoped project files, and unpublished generated sites remain out of scope.

## Phase 0 conclusion

**Successfully configured:** compatible Node/npm runtime confirmed; official REA package resolved; REA CLI commands operational; local JavaScript static-analysis smoke test passed; Chromium, Playwright, and Manus browser inspection available.

**Not configured:** persistent REA skill registration with an external coding agent; native analysis engines; authenticated HTMLhost access.

**Recommended operating mode:** evidence-first public reconnaissance using Manus browser tools plus REA CLI operations that have a clear, bounded input contract. Do not claim REA is installed as an agent integration until a real supported client is intentionally configured and doctor reports that registration.

## References

[1]: https://github.com/morluto/rea "Official Reverse Engineer Anything repository"
[2]: https://github.com/morluto/rea/blob/main/docs/getting-started/installation.md "REA installation and setup guide"
[3]: https://rea.tools/guides/browser/ "REA browser observation guide"
