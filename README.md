---
name: design-duo
description: "Two-agent design pipeline. design-researcher gathers competitive UI/UX patterns; design-principal synthesizes research into engineering-ready specs and self-contained HTML mockups. Both agents discover the host project's design system at runtime — no per-project editing required."
source: original
platforms: [hermes]
install: ./install.sh
---

# Agent Design Duo

A two-agent design flow that grounds design direction in competitor research, then hands engineering-ready specs and a self-contained HTML mockup. Each agent discovers the host project's design system at runtime — no per-project editing required.

> **Source-of-truth lives here.** To make changes, edit files in this directory and re-run `./install.sh`. The runtime copy at `~/.hermes/skills/design-duo/` is generated; do not hand-edit it.

## What it does

**Pipeline:**

```
Your question → design-researcher → research + gallery
             → design-principal  → design spec + mockup
             → engineering handoff
```

1. **`design-researcher`** — Gathers competitive UI/UX patterns, traces them to real product UI (Refero / Mobbin / web), saves a visual reference gallery.
2. **`design-principal`** — Reads the research, synthesizes design direction against the discovered design system, hands off an engineering-ready spec + interactive mockup.

Both agents discover `DESIGN.md`, the component library, and product context from your workspace automatically. They adapt to whatever host project you point them at.

[▶ Watch the 71-second demo](./assets/preview.mp4)

## When to use

- Before designing a new feature, flow, or page
- When you want competitor patterns grounded in real product UI, not generic training-data averages
- When design handoff must reference **your** components and tokens, not an invented design system
- When you want visual artifacts (research gallery + mockup) alongside written specs

**Don't use for:** copy-edits, one-off styling tweaks, or "what color should this be" questions. Those are craft questions, not pipeline questions.

## Install

```bash
./install.sh
```

Deploys to `~/.hermes/skills/design-duo/`. The runtime Hermes loads this from.

To add Cursor / Claude Code / Codex support later, edit `install.sh` and uncomment the relevant platform block at the bottom.

## Use

In Hermes:

```
/design-duo <your feature or pattern question>
```

Examples:
- `/design-duo account type selection patterns`
- `/design-duo how competitors handle portfolio overview on mobile`
- `/design-duo stepper vs accordion for multi-step forms`

The orchestrator captures your topic (or asks for one), discovers your workspace, dispatches the researcher, and surfaces a one-liner before auto-continuing to the principal. Both artifacts go to `.design-output/` in your repo.

## Layout

```
design-duo/
├── SKILL.md                       # orchestrator
├── personas/
│   ├── design-researcher.md       # canonical (no de- prefix — design-duo is original)
│   └── design-principal.md
├── templates/
│   └── DESIGN-CONTEXT.md          # optional product context file
├── assets/
│   └── gallery-template.html      # visual reference gallery base
├── install.sh                     # deploys to runtime
└── README.md                      # this file
```

## Optional: provide upfront context

Drop a `DESIGN-CONTEXT.md` at your repo root (modeled on `templates/DESIGN-CONTEXT.md` here). The orchestrator reads it on every run; both agents use it. Industry, audience, competitors, differentiators — one file, low friction.

The agents also pick up:
- `DESIGN.md` (or `docs/DESIGN.md`, `design/DESIGN.md`, `.cursor/DESIGN.md`) for design tokens
- `STRATEGY.md` or `README.md` as fallbacks
- The component library in `components/ui/` (or wherever your project keeps it)

If `DESIGN-CONTEXT.md` is missing, the orchestrator asks **one** clarifying question — industry and 2–3 competitors.

## Outputs

| Output | Where |
|--------|-------|
| Research findings | `.design-output/research/{topic-slug}/` (in your repo) |
| Visual gallery | `.design-output/research/{topic-slug}/index.html` |
| Design spec | Principal's chat response |
| Interactive mockup | `.design-output/concepts/{feature-slug}/mockup.html` |

Add `.design-output/` to `.gitignore` for exploration that shouldn't ship.

## Notes

- **design-principal** also works standalone (no research → confidence capped at Medium). Invoke `/design-researcher` or `/design-principal` directly when you only want one stage.
- **External research can fail.** If MCP and web search both fail, the orchestrator continues with design-system-only grounding and caps the principal's confidence at Medium.
- **The mockup is a concept sketch**, not production code. After the spec is approved, run `de-plan` or your planning tool to break it into engineering tickets.

## Attribution

Original work by JulioGarcia. No external attributions.
