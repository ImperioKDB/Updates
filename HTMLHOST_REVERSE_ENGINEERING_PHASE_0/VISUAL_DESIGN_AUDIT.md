# Visual Design Audit — Phase 1A

## Scope

This audit covers the HTMLhost platform shell and five public template/preview frontends. It does not claim that published generated sites use the same design system.

## Platform frontend — VERIFIED

The homepage, editor, and template detail pages use a dark editorial shell: near-black `rgb(10, 10, 11)` background, light `rgb(242, 242, 243)` text, Figtree-based body typography, large display headings, lime/green accents, rounded dark panels, thin borders, and generous vertical spacing. The public shell includes sticky navigation and a responsive mobile navigation region.

At the captured 1440px homepage viewport, the hero heading was previously measured at 88px, 600 weight, approximately 0.95 line height, and approximately `-0.04em` tracking. These values describe the platform page at that viewport, not templates.

## Template/preview frontend — VERIFIED

The five templates do not share one palette or type system:

- **Creative Playground:** warm off-white, near-black, orange, pink, blue, and lime; Bricolage Grotesque and Inter; rounded controls and colorful inline SVG/CSS artwork.
- **Kinetica:** near-black, cream, lime, warm grey, and dark panels; Instrument Sans, Instrument Serif, and Inter Tight; thin card edges and type-led composition.
- **Futuristic Dark:** near-black, white, deep brown, and pale lavender; Manrope; frosted-pane treatment and procedural flame field.
- **Full-Stack Portfolio:** near-black, white, electric magenta, violet, and muted grey; Atyp; image-heavy portfolio presentation.
- **Business Web Studio:** warm cream, near-black, lime, warm grey, and dark green/black; Bricolage Grotesque, Instrument Serif, and JetBrains Mono; rounded image treatments and agency-style content hierarchy.

Template colors and typography are evidenced by public metadata and, where available, inline preview CSS variables/font declarations. Exact computed metrics remain UNKNOWN for most template frames.

## INFERRED reusable visual principles

Across the corpus, premium presentation appears to rely on role-based contrast, oversized display typography, strong section rhythm, deliberate accent colors, constrained content widths, high-contrast calls to action, and template-specific type pairing rather than one universal brand system. This is an inference from repeated visual and source evidence, not a claim about private HTMLhost design tokens.

## UNKNOWN

Published generated-site visual output, post-publication transformations, exact production font loading/fallback behavior, and cross-browser image rendering remain unknown.

## Evidence artifacts

Screenshots: `/home/ubuntu/rea-phase1a/screenshots/`
Capture index: `/home/ubuntu/rea-phase1a/capture-index.json`
Comparative baseline: `PHASE_1A_PUBLIC_CORPUS_BASELINE.md`
