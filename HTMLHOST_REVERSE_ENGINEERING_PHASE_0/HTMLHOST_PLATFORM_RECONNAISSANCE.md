# HTMLhost Platform Reconnaissance

**Project:** HTMLhost Reverse Engineering Lab
**Phase:** 0 — Platform identification and preliminary public inspection
**Date:** 2026-11-08
**Status:** Complete for review

## Platform identification

The platform identified for this project is **htmlhost.co**, branded in its public pages as **htmlhost.co** or **HTMLhost**. The official public website is:

<https://htmlhost.co/>

The homepage describes HTMLhost as HTML hosting for individual files, folders, and multi-page websites. Its public workflow is: import or paste HTML, preview it, optionally edit it visually with AI, and publish a shareable HTTPS link. The platform also advertises custom domains, a CLI, an MCP server, REST API access, media uploads, forms, optional expiry, and one-click public sharing. [1]

## Product functionality

### VERIFIED — hosting and publishing model

HTMLhost states that it hosts HTML pages together with CSS, browser JavaScript, images, fonts, and other assets. Plain HTML/CSS/browser JavaScript do not require a build step. Server-side PHP, Node.js services, and databases are not presented as part of the static hosting runtime and require a separate backend. [1]

It supports a single HTML file, a folder or ZIP, and multi-page directories. The public documentation maps `index.html` to `/` and other HTML files to clean paths such as `/about` or `/contact`. Published sites receive a shareable HTTPS address on an HTMLhost subdomain; Pro users can connect custom domains, with HTMLhost handling SSL and routing according to the product documentation. [1] [2]

### VERIFIED — AI editing model

The editor page says users can click an element in a live preview, describe a change, and review the result. It also describes a non-AI Element Edit mode for text, links, images, videos/embeds, and forms. The product states that AI edits are checked at desktop and phone sizes before application, including checks for visible changes, overflow/disappearance, failed image or stylesheet loads, and unintended header/footer restyling. It also says the change can be undone as one project-wide step. [3]

These are product claims and workflow documentation. They are not yet independent proof of the internal implementation of the checking system.

### VERIFIED — generation and import entry points

The homepage exposes three public start tabs: **Import Project**, **Generate Site**, and **WordPress to HTML**. It also documents pasting HTML, dropping a ZIP/folder, importing from a URL under paid features, moving an owned WordPress site to HTML, starting from templates, using the CLI, or connecting an AI assistant through MCP. [1] [2]

The homepage’s generation panel instructs a user to describe a site and select ChatGPT, then bring the resulting HTML back for hosting. This establishes a prompt-to-HTML workflow, but it does not prove which model, prompt template, or generation pipeline runs behind the public form.

### VERIFIED — AI-tool integration

The official MCP documentation describes hosted Claude connectivity and local stdio MCP setup for coding tools. The documented hosted connector exposes project listing, project retrieval, file reading/search, draft saving, preview retrieval, and separate draft publishing. The documentation explicitly distinguishes saving a draft from publishing it. [2]

The public homepage lists integrations or setup examples for Claude Code, Claude Desktop, Cursor, VS Code, Codex, Antigravity, Windsurf, and Cline. [1]

## Public examples and generated-site availability

### VERIFIED — official template corpus

The homepage exposes a template collection and currently advertises 28 templates. Two public template pages were inspected:

- [Creative Playground Landing](https://htmlhost.co/templates/creative-playground-landing), a free, one-page, phone-ready creative-tool landing page;
- [Kinetica Motion Typography](https://htmlhost.co/templates/kinetica-motion-typography), a Pro, one-page, phone-ready type-animation landing page.

Both pages provide public descriptions, section inventories, font listings, palette descriptions, form notes, customization instructions, and desktop/phone preview affordances. They are legitimate public examples of the design/content system HTMLhost presents to users. [4] [5]

### INFERRED — template metadata is a useful initial comparison corpus

The template pages expose enough structured information to form an initial comparison corpus: page count, section count, named fonts, stated libraries, palette values, responsive claims, image usage, form presence, and interaction concepts such as accordions, carousels, selectors, or pointer-following effects. This is strong evidence for what HTMLhost’s template system intends to provide, but it does not establish that every template uses the same runtime code or component implementation.

### UNKNOWN — public customer-generated-site directory

No public directory of all customer-generated sites was established in Phase 0. The public sitemap exposes pages, templates, guides, docs, tools, use cases, and comparison pages, but the robots policy disallows crawling paths such as `/dashboard/`, `/new/`, `/preview/`, and `/site/`. [6]

The homepage provides an example URL pattern such as `https://bold-fern-x3k.htmlhost.co`, and the docs state that published sites live on HTMLhost subdomains. However, the example was treated as documentation/example text rather than as proof of a currently accessible customer site. Authenticated or owner-only project discovery was not attempted.

## Preliminary browser and DOM observations

### VERIFIED — public homepage structure

The Manus sandbox browser loaded the homepage successfully and saved a screenshot plus raw HTML. The visible homepage includes:

- sticky top navigation;
- product navigation and sign-in/start-hosting controls;
- a hero with import/generate/WordPress tabs;
- a textarea for pasted HTML or dropped project content;
- template links;
- an MCP/CLI section;
- feature cards;
- an FAQ accordion; and
- footer navigation.

The DOM includes a viewport meta tag with `width=device-width, initial-scale=1`, publicly loaded CSS chunks, and Next.js-style static chunk paths under `/_next/static/`. The body’s direct structure includes a sticky navigation region and a mobile-navigation region with classes indicating hidden/open state, transition duration, reduced-motion handling, and a breakpoint around `max-[1199px]`. These are direct observations of the public homepage DOM, not claims about private source organization.

### VERIFIED — public homepage visual baseline

At the inspected desktop viewport, the homepage used a near-black background (`rgb(10, 10, 11)`), light foreground text (`rgb(242, 242, 243)`), and a Figtree-based sans-serif stack. The first hero heading computed to 88px, 600 weight, approximately 0.95 line height, and approximately `-0.04em` tracking at that viewport. The page loaded Figtree, Gochi Hand, and JetBrains Mono font resources from HTMLhost’s static media paths.

The hero screenshot showed an editorial, high-contrast composition with very large type, a compact explanatory paragraph, a dark rounded import panel, lime/green interaction accents, and dense but ordered navigation. These observations are descriptive and should be re-measured at controlled viewport sizes during Phase 1.

### VERIFIED — public serving and framework signals

A direct public header request returned `server: Vercel`, `x-powered-by: Next.js`, `x-nextjs-prerender: 1`, `x-vercel-cache: HIT`, strict transport security, `x-frame-options: DENY`, `x-content-type-options: nosniff`, a restrictive permissions policy, and `cache-control: public, max-age=0, must-revalidate`. This supports the statement that the public marketing page is served through Vercel/Next.js infrastructure. It does **not** prove that generated customer websites use the same application framework or hosting path.

### INFERRED — utility-class-driven styling on the public marketing surface

The captured HTML contains classes that resemble Tailwind utility composition, including responsive prefixes, arbitrary values, `backdrop-blur`, `motion-reduce`, and CSS color-mix expressions. This strongly suggests utility-class-driven styling on the public marketing/editorial surface. It does not establish whether the platform uses Tailwind itself, a compatible compiler, or a private design-token layer that emits similar classes.

### UNKNOWN — generated-site runtime architecture

The platform’s public marketing site exposes framework and asset evidence, but no public evidence yet connects that architecture to published customer websites. Generated sites may be plain HTML/CSS/JavaScript as the docs claim, template-specific static bundles, or a mixture. This question must remain open until public preview pages or intentionally created test sites can be inspected without crossing account or publication boundaries.

## What can be investigated through browser inspection

Without signing in, the available public surface supports:

- visual screenshots and scroll-state comparisons of official pages and templates;
- DOM structure, computed styles, loaded fonts, script/style URLs, link structure, and accessibility-visible text;
- public navigation interactions such as FAQ disclosure, template preview controls, tabs, and mobile-menu affordances when safe and reversible;
- browser performance/resource timing for public pages;
- responsive behavior at desktop, tablet, and phone viewport sizes; and
- public HTTP headers, cache indicators, robots policy, sitemap coverage, and static asset paths.

The following remain inaccessible or intentionally untested in Phase 0:

- account-scoped projects, drafts, unpublished previews, and project files;
- editor actions that require sign-in, file upload, AI generation, or publication;
- private API requests or bearer-token endpoints;
- customer-site enumeration beyond publicly linked pages; and
- proprietary source code or server implementation details.

## Initial research opportunities

The highest-value next targets are:

1. compare three to five official template pages with different visual genres;
2. open public live-preview controls where available and record the preview origin and asset graph;
3. measure responsive transformations at desktop, tablet, and phone widths;
4. inspect public accordion, carousel, hover, pointer-following, and menu behaviors with bounded interactions;
5. extract public CSS custom-property and font-loading evidence from several pages;
6. measure resource timing, cache behavior, layout shifts, and lazy-loading signals on representative pages; and
7. only after review, determine whether a user-authorized test project can be created for editor/runtime inspection.

## Phase 0 conclusion

HTMLhost is a public static-site hosting and AI-assisted editing platform at `htmlhost.co`. Its documented product model is broader than a simple file host: it combines import, visual editing, AI-assisted changes, templates, forms, media, multi-page routing, CLI/MCP/API deployment, and public HTTPS publishing. The public marketing/editorial surface is inspectable and provides strong initial evidence of a Next.js/Vercel delivery stack, Figtree/Gochi Hand/JetBrains Mono font loading, utility-style responsive classes, and a visually deliberate dark editorial system.

The key boundary is important: these observations are about HTMLhost’s public application and official template metadata. They are not yet proof of the runtime architecture of arbitrary customer-generated sites. Phase 1 should therefore prioritize comparative public template/preview inspection and keep every finding labeled VERIFIED, INFERRED, or UNKNOWN.

## References

[1]: https://htmlhost.co/ "HTMLhost official homepage"
[2]: https://htmlhost.co/docs/mcp "HTMLhost MCP server documentation"
[3]: https://htmlhost.co/editor "HTMLhost AI HTML Editor"
[4]: https://htmlhost.co/templates/creative-playground-landing "Creative Playground Landing template"
[5]: https://htmlhost.co/templates/kinetica-motion-typography "Kinetica Motion Typography template"
[6]: https://htmlhost.co/robots.txt "HTMLhost robots policy"


## Phase 1A addendum — platform versus template runtime

### VERIFIED — public preview states are inspectable rendered documents

Five public templates were opened through their `Live preview` controls at desktop, tablet, and mobile viewport sizes. Each preview exposed actual rendered content in inline sandboxed iframe documents. The preview URL remained on the template page with `#preview`; no standalone published-site URL was exposed.

### VERIFIED — the platform shell is separate from preview content

The public platform pages use the HTMLhost shell: Next.js-style static chunks, host navigation, host-level Figtree typography, near-black body colors, and preview-wrapper controls. The embedded preview documents have template-specific HTML/CSS/JavaScript, fonts, assets, forms, responsive rules, and animation mechanisms. Host shell assets must not be attributed to the template runtime.

### UNKNOWN — published generated websites

No customer-published HTMLhost subdomain site was verified. The generated website runtime, deployment headers, CSP, asset transformation, framework usage, and production performance remain UNKNOWN. Preview `srcdoc` is not evidence that published sites use the same delivery mechanism.

### Evidence artifacts

The Phase 1A capture produced 21 viewport records and 81 PNG screenshots. See `/home/ubuntu/rea-phase1a/capture-index.json`, `/home/ubuntu/rea-phase1a/screenshots/`, and `PHASE_1A_PUBLIC_CORPUS_BASELINE.md`.
