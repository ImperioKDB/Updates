# Interaction Experiments — Phase 1B

These are three **original**, self-contained HTML files made to demonstrate reusable motion techniques suggested by the public-preview research. They do not copy HTMLhost branding or source code and have no external dependencies. Each can be opened directly in a browser or served as a static file.

## Experiment 1 — Scroll reveal

[Open the scroll-reveal experiment](phase1b-experiments/01-scroll-reveal.html)

**Technique:** IntersectionObserver turns a small `data-visible` state on once when a card enters the viewport. CSS then transitions opacity and a restrained vertical transform; observer entries are unobserved after reveal.

**Why this is useful:** The visibility trigger is not a continuously running animation loop. CSS handles the lightweight visual change, and a stagger is kept to 70 ms across neighboring cards. Essential content remains available without JavaScript, and `prefers-reduced-motion: reduce` immediately reveals the final state and disables smooth scrolling/transitions.

**Smoke test:** In headless system Chromium, scrolling the first card into view set `data-visible="true"`, computed opacity was `1`, and no page error was recorded. In a 390×844 reduced-motion context, all four cards were immediately visible at opacity `1`.

**Trade-offs:** Opacity-hidden content remains in the accessibility tree before visual reveal; this demo uses non-interactive text cards so keyboard focus cannot be hidden. For production, avoid applying an initially transparent state to focusable content, and ensure the observer fallback exposes everything.

## Experiment 2 — Bounded pointer drag

[Open the pointer-drag experiment](phase1b-experiments/02-pointer-drag.html)

**Technique:** Pointer Events capture the active pointer on drag start; coordinates are calculated relative to the stage and clamped to its boundaries. Arrow keys move the same object in 16 px steps, Home and buttons reposition it, and a short easing transition is used only for explicit repositioning—not while following the pointer.

**Why this is useful:** Direct manipulation benefits from immediate pointer tracking. Bounds keep the object discoverable, pointer capture prevents a drag from being lost when the cursor leaves the tile, and keyboard movement provides a practical non-pointer alternative. The tile uses `touch-action:none` locally rather than globally disabling page gestures.

**Smoke test:** System Chromium moved the tile from `(20,24)` to `(132,106)` CSS px after a pointer drag. ArrowRight then moved the x position to `148px`; the post-movement rectangle remained within the stage bounds.

**Trade-offs:** A draggable control needs clear instructions, visible focus, a keyboard path, and careful touch behavior. In real interfaces, make sure a drag action does not prevent activating a meaningful button or interfere with page scrolling outside the handle.

## Experiment 3 — Accessible disclosure

[Open the accessible-disclosure experiment](phase1b-experiments/03-accessible-disclosure.html)

**Technique:** Each native button references a panel with `aria-controls`; `aria-expanded`, `aria-hidden`, and `inert` track the open state. A single-open-at-a-time interaction uses a CSS grid-row transition (`0fr`→`1fr`) and a short icon change. A reduced-motion media query removes the transitions. If JavaScript is unavailable, the answers remain visible rather than leaving essential content hidden.

**Why this is useful:** The control relationship is explicit, the panel participates in normal document flow, and height does not need to be measured in JavaScript. The state change is separate from its presentation; reduced motion keeps the same content and behavior while removing animation.

**Smoke test:** Clicking question 2 set `aria-expanded="true"`, exposed the panel with `aria-hidden="false"` and `inert=false`, and produced about 98 px panel height after the transition. Opening question 3 closed question 2 and opened question 3. Under reduced motion, the computed transition duration was `0s`.

**Trade-offs:** One-open-at-a-time is a product choice, not a universal accessibility requirement. Test sequential keyboard navigation, focus retention, content with links/forms, and state changes while a transition is in progress.

## Reproduction and validation notes

The smoke tests were local to these three files and used `/usr/bin/chromium` with Playwright. They verify these demonstrations only; they are not additional evidence about HTMLhost. Source files are standalone, no package install is required, and no external network asset is fetched.

## Research linkage

- `PHASE_1B_MOTION_DEEP_AUDIT.md` — actual preview evidence and unresolved questions.
- `ANIMATION_TECHNIQUE_COMPARISON.md` — comparative technique map.
- `FRONTEND_MOTION_ENGINEERING_GUIDE.md` — broader implementation guidance.
