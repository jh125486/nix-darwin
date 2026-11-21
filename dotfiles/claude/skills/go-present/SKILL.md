---
name: go-present
description: >
  Rules and gotchas for writing and verifying Go `present` slide decks (golang.org/x/tools/cmd/present)
  for this user. Covers which syntax to use (the new Markdown format, not legacy), what markup does and
  does not render, image sizing, mermaid diagrams, speaker notes, and a Playwright verification loop.
  Use whenever creating, editing, converting, or reviewing a `.slide` file, or running `present`.
---

Writing, editing, or checking a `.slide` deck. Read this before touching one.

## 1. Match the repo's syntax first
- Before writing, open a recent deck in the same repo (e.g. `modern_databases.slide`, `oapi.slide`, `tdd.slide`). Newer decks use the **Markdown** format. Older ones use legacy syntax. A deck is Markdown iff its first line starts with `# `.
- New decks: Markdown format. Do not write legacy by default (a past session did, and the whole deck had to be converted).

## 2. Markdown format
- Header block: `# Title`, subtitle, date, blank line, then author lines (name, role, email, links).
- Slides are `## Title`. Speaker notes are lines starting `: ` (plain text, no markup), placed after the slide body.
- Emphasis: `**bold**`, `*italic*`, `` `code` ``. Multi-word emphasis works.
- Nested bullets: indent two spaces (`  - sub`). Legacy format has no nesting at all.
- Code blocks: use a fenced block (```), with a blank line before it. A 4-space indented block placed right after a bullet list is swallowed into the last list item and renders as a jumbled paragraph. An indented block is only safe after a heading or paragraph.
- A plain line that is not a bullet is a paragraph; use it for a standalone sentence (e.g. a lead-in like "Spot the problem in this test:").
- Put blank lines around `.image` and `.caption` lines so they are not read as part of a list.
- Do NOT use `###` / `**` subsections: the slide template renders them badly (heading drawn at the bottom of the slide in a huge font, sub-sub headings numbered "1.1.1."). Split into separate slides instead.

## 3. Things that differ from what you would guess
- `.caption` text still uses the OLD inline rules even in a Markdown deck: `*bold*` and `_italic_` (multi-word italic via `_a_b_`). Markdown markers (`**x**`) show as literal asterisks in captions. Backtick code works.
- Legacy decks (if you must edit one): bold/italic/code apply to a single word only; multi-word italic joins words with underscores (`_blast_radius_`); `**` double-asterisk renders as literal.
- `.image path H W`: use `H _` to constrain by height (preferred for tall or wide diagrams) or `_ W` for width. Content area is about 940px wide and about 560px tall under the title.
- `present` appends an auto "Thank you" slide built from the header authors. The deck's real count is slides + 1.
- Installed `present` can lag: check `go version -m ~/go/bin/present` against `go list -m golang.org/x/tools@latest`, upgrade with `go install golang.org/x/tools/cmd/present@latest`.

## 4. Running it
- `present` defaults to port 3999 and serves the directory it is run in (the repo root if run there, so the URL becomes `/UNT/deck.slide`). A stale server on 3999 gives `bind: address already in use`; check `lsof -nP -iTCP:3999 -sTCP:LISTEN`. Do not kill the user's long-running server; use your own port.
- For checks: `present -http 127.0.0.1:4187 -notes=false -play=false` from the directory holding the deck; kill it afterwards.

## 5. Diagrams (mermaid)
- Keep `.mmd` source beside the PNG. Render: `mmdc -i x.mmd -o x.png -s 3 -b white` (add `-C x.css` for CSS).
- Wide left-to-right flowcharts shrink text when scaled to the slide width. Flowcharts that are tall rather than wide (TB) read better sized by height; keep very flat ones LR and add bullets under them to use the empty space.
- Convention used so far: nodes that are models or agents are dark blue (`fill:#1f3a8a`, `stroke:#12255c`, white text); tools, CI, and humans stay light. In flowcharts use `classDef m fill:#1f3a8a,stroke:#12255c,color:#ffffff`.
- Sequence diagrams: per-actor colour needs a CSS file. Fill by `rect.actor[name="ID"]`. White text must target the `tspan`, because mermaid forces actor label tspans to black: `[id="root-N"] text > tspan { fill:#fff !important }` (N = actor index in declaration order).
- Always view the rendered PNG; verify text colour and legibility rather than assuming the CSS worked.

## 6. Verify every deck change
1. Playwright needs a local install: `npm i playwright && npx playwright install chromium` in a scratch dir; pass that dir's `node_modules` as `NODE_PATH`.
2. Run `scripts/verify.js` (in this skill's directory): `NODE_PATH=<dir>/node_modules node verify.js http://127.0.0.1:PORT/deck.slide <outdir>`. It screenshots every slide at 1280x720 and prints per-slide content bottom (out of 700), `TIGHT/OVERFLOW` flags, and any literal `*` or `_` left in rendered text. Real code blocks legitimately contain `_`/`*`; anything else is a markup bug.
3. Do not trust a content-bottom measurement that includes `.pagenumber` (it is fixed at the bottom and makes every slide look like it ends at 671). The script excludes it.
4. Actually look at screenshots of changed slides. Metrics miss ugly-but-fitting layouts, wrong colours, and merged bullets.

## 7. Working with the user's layout choices
- The user sets sizes and spacing deliberately: images sized to fill the slide with the caption on the bottom edge, tight bottoms, standalone sentences that are not bullets, a green `.image images/UNT_green.png 3 850` divider line used as a spacer. Do not "fix" these; if something looks like a defect, ask first.
- Slides must stand alone: each bullet should read as a complete thought without the speaker notes. Fragments like "Ask: ambiguous, and what breaks if wrong?" or "Plausible code; review misses subtle shifts" were rejected. When bolding, never drop words that make the sentence work.
- Do not add content the user did not ask for (outside companies, public case studies, citations, statistics). Keep to what was requested and flag suggestions instead.
- The user edits the deck between turns. Re-read the current text before editing and change exact strings; never overwrite the file wholesale.
