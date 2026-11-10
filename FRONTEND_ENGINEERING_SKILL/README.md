# premium-frontend-engineering

`premium-frontend-engineering` is a portable workflow for planning, building, refining, and reviewing frontend work in an existing repository. It is intentionally framework-agnostic and does not force a particular visual style. Instead, it requires the engineer to discover the product’s architecture and identity, establish a deliberate design direction, define semantic tokens and component boundaries, implement deterministic interactions, and verify accessibility, responsive behavior, performance, SEO, and regressions.

## Reuse it

Load `SKILL.md` before starting a substantial frontend task. It is appropriate for a new route, public page, design-system extension, responsive redesign, interaction/motion pass, accessibility review, or production-readiness review. It is not necessary for backend-only work or a mechanical one-line style fix.

The skill expects the engineer to inspect the target repository before editing. Pass it the product brief, relevant route or design specifications, existing brand tokens, browser/device constraints, and any explicit “do not change” boundaries. If a required API, asset, permission, or data contract is missing, the expected behavior is to report the gap rather than invent it.

## What it standardizes

The workflow standardizes the order of thinking, not the aesthetic outcome. Each project still chooses its own typography, color, layout, imagery, interaction vocabulary, and component composition. The common requirements are that those choices are intentional, encoded as usable tokens, responsive at narrow widths, accessible without hover or motion, and supported by evidence.

The final review must cover visual quality, layout, typography, spacing, interactions, motion, reduced motion, keyboard and touch behavior, accessibility, browser errors, performance, SEO, and regression safety. A page that merely renders is not considered complete.

## Suggested project handoff

A useful handoff to an AI frontend engineer includes:

- the repository path and target branch;
- the product goal and primary users;
- the routes or components in scope;
- relevant existing design tokens and shared components;
- the current data/API contract;
- required viewport/browser constraints;
- acceptance targets and prohibited changes.

The skill’s expected completion report should list exact modified files, verification commands and conditions, measured results versus targets, untouched systems, and unresolved decisions.

## Portability

The skill contains no Scholars-specific routes, colors, schemas, assets, or proprietary implementation details. It can guide React, Next.js, Vue, Svelte, static HTML/CSS, or another frontend stack, provided the implementing agent adapts its workflow to the repository’s actual architecture.
