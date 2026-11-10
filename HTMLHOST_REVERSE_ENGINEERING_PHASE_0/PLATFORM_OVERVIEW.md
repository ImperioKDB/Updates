# Platform Overview — Phase 1A

HTMLhost is a public HTML hosting and AI-assisted editing platform at `https://htmlhost.co/`. Its documented product supports file/folder/ZIP import, multi-page static sites, visual element editing, AI editing, templates, media, forms, CLI/MCP/API deployment, public HTTPS subdomains, and custom domains.

## Three-system model

### A. Platform frontend — VERIFIED

The homepage, editor, and template detail pages form the HTMLhost application shell. Public evidence includes Next.js-style static chunks, Vercel/Next.js response headers, sticky navigation, responsive mobile navigation, host-level Figtree typography, host body colors, import/generation tabs, preview controls, and device presentation frames.

### B. Template/preview frontend — VERIFIED

The selected public templates expose `Live preview` states. Their rendered content is delivered through inline sandboxed `srcdoc` iframes with template-specific HTML/CSS/JavaScript, fonts, images/canvas, forms, responsive rules, and animation mechanisms. The five inspected templates are heterogeneous and should not be modeled as one proven shared runtime.

### C. Published generated websites — UNKNOWN

No publicly verified customer-generated HTMLhost subdomain site was accessed in Phase 1A. Published-site delivery, headers, asset URLs, CSP, runtime libraries, framework choice, and performance remain unknown.

## Current investigation boundary

Phase 1A used only public pages and reversible preview opening. No account, upload, publish, form submission, private project, bearer token, undocumented authenticated endpoint, or proprietary source archive was accessed.
