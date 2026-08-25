# CLAUDE.md

Guidance for Claude Code (and other AI assistants) working in this repository.

## What this is

A minimal static website — three files, no build step, no dependencies, no
framework:

- `index.html` — single page (French UI text), links `style.css` and `script.js`
- `style.css` — page styling (dark theme, centered card layout)
- `script.js` — one click counter behavior for the button in `index.html`

There is no `package.json`, no bundler, no test suite, and no CI configured.
The entire app is plain HTML/CSS/vanilla JS.

## Running it

Open `index.html` directly in a browser, or serve the directory with any
static file server, e.g.:

```
python3 -m http.server 8000
```

There is no install step and nothing to compile.

## Conventions

- Keep it dependency-free — do not introduce a bundler, framework, or
  package manager unless the user explicitly asks for one.
- UI text in `index.html`/`script.js` is in French (e.g. "Cliqué N fois");
  match that language when editing user-facing strings unless told otherwise.
- Element IDs are used directly by `script.js` (e.g. `#counter-btn`) —
  if you rename an element in `index.html`, update the matching selector
  in `script.js`.
- No test suite exists. Verify changes by opening `index.html` in a browser.

## Working in this repo

- Changes are small by nature — prefer direct edits to the three files over
  adding new files or abstractions.
- If a task grows beyond what plain HTML/CSS/JS can reasonably do, flag it
  to the user before adding tooling (bundlers, frameworks, package.json).
