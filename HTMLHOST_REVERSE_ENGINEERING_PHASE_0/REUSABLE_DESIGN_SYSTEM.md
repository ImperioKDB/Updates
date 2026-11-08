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
