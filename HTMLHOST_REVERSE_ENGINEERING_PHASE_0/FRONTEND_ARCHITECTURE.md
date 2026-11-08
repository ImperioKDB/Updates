# Frontend Architecture — Phase 1A

## A. HTMLhost platform frontend

### VERIFIED

The public homepage, editor, and template detail pages expose Next.js-style `/_next/static/` CSS/JavaScript chunks. Earlier public headers returned `server: Vercel`, `x-powered-by: Next.js`, `x-nextjs-prerender: 1`, cache indicators, strict transport security, `x-frame-options: DENY`, and `x-content-type-options: nosniff`. The host body computes to a near-black background and Figtree-based typography.

The host DOM includes sticky navigation, a mobile navigation region, start/import tabs, editor/template controls, FAQ disclosure, and a preview wrapper. These are platform-shell observations.

### UNKNOWN

The private component tree, framework version, data-fetching model, editor state architecture, preview orchestration, and publication pipeline are not exposed by public evidence.

## B. HTMLhost template/preview frontend

### VERIFIED

All five selected templates expose public `Live preview` states. The capture found three iframe documents per preview, including a full preview and desktop/phone presentation frames. The iframe documents use inline `srcdoc` with sandboxed scripts. Their HTML/CSS/JavaScript and asset graphs are template-specific.

The previews show plain HTML/CSS/JavaScript evidence rather than a proven shared application framework. Examples include semantic sections/forms, CSS custom properties, media queries, inline SVG, canvas/WebGL, images, inline scripts, external CDN libraries, Google Fonts, and template-specific form actions.

### INFERRED

The preview iframes are likely HTMLhost-generated presentation artifacts because content is inline `srcdoc` under the template page and no standalone preview URL was exposed. This does not establish the exact production output of a published site.

## C. Published generated websites

### UNKNOWN

No verified customer-published HTMLhost subdomain site was accessed in Phase 1A. The generated-site runtime cannot be equated with either the Next.js shell or the preview `srcdoc` runtime.

## Architectural boundary rule

Host-page chunks/fonts/styles and preview iframe source must be logged separately in future work. A library named in template metadata must not be attributed to the platform shell, and a host Next.js signal must not be attributed to the generated website.
