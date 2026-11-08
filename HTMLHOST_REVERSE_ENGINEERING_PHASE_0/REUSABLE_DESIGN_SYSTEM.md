# Reusable Design System — Phase 1A Evidence

## Boundary

This document describes reproducible design principles and observable patterns, not HTMLhost proprietary code or branding. Platform shell, template preview, and published generated-site evidence are separated.

## Platform shell primitives — VERIFIED

The public shell exposes sticky navigation, responsive mobile navigation, tabs, rounded dark panels, FAQ disclosures, template cards, preview controls, device-mode controls, and host-level typography/color tokens. These primitives belong to the public HTMLhost application shell.

## Template primitives — VERIFIED

Across the five previews, repeated conceptual primitives include:

- semantic hero and section compositions;
- responsive navigation and mobile menu states;
- CTA buttons and badges;
- cards and elevated panels;
- image-backed content blocks or procedural visual fields;
- accordions and FAQ controls;
- sliders/carousels;
- forms targeting the platform’s form mechanism;
- scroll reveals and reduced-motion paths; and
- explicit typography/color variables or declarations.

The implementation differs materially. Creative uses draggable SVG/CSS shapes and GSAP/Swiper. Kinetica uses type/sound/motion controls and multiple CDN libraries. Futuristic uses custom WebGL. Portfolio uses image-heavy inline source and CSS motion. Business uses semantic agency sections, Lucide, lazy images, counters, theme state, and a mobile overlay.

## Inferred abstract tokens

The corpus supports an abstract role-based model:

- `surface-page`;
- `surface-elevated`;
- `text-primary`;
- `text-muted`;
- `accent-primary`;
- `line-subtle`;
- `display-font`;
- `body-font`;
- `label-font`;
- `radius-card`;
- `container-gutter`; and
- `motion-reduced`.

These are research abstractions. They are not claims that HTMLhost uses these exact token names.

## UNKNOWN

A single shared template design system, shared component library, published-site token inheritance, and post-generation normalization are not proven. Template metadata and inline source show recurring concepts, but not a common implementation repository.


## Phase 1B runtime-tested interaction primitives

The following are reusable **patterns**, not evidence of a shared HTMLhost component library:

- **Accessible motion toggle — VERIFIED in Kinetica preview:** visible state, accessible name, and `aria-pressed` changed together; the sampled animation inventory paused and resumed. Abstract state tokens such as `motion-running` and `motion-paused` may help a reconstruction, but are not HTMLhost token names.
- **Semantic FAQ disclosure — VERIFIED in Business preview:** button, `aria-controls`, and `aria-expanded` tracked panel open/close. The open panel was about 109.6 px; a sampled 500 ms grid-row transition was observed. One close measurement differed by capture timing and remains under review.
- **Bounded direct manipulation — VERIFIED once in Creative preview:** an orange shape moved under pointer drag. Keyboard/bounds/feedback details were source declarations and were not exhaustively validated.
- **Reduced-motion variant — VERIFIED as template-specific:** sampled states differed across all five previews. Treat it as a per-component variant and test the page-level and interactive states separately, not as a universal shared implementation.

Three original implementations of scroll reveal, pointer drag, and disclosure state are linked in `INTERACTION_EXPERIMENTS.md`; they demonstrate generic techniques, not source recreation.
