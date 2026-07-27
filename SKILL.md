---
name: design-duo
description: "Two-agent design pipeline. Runs design-researcher (competitive UI/UX research with structured output and gallery) then design-principal (synthesizes research into engineering-ready design specs and self-contained HTML mockups). Use when designing new features, flows, or pages and you want competitor-grounded design direction that fits the host project's design system."
version: 1.0.0
author: JulioGarcia (design-duo orchestrator for the migrated design-researcher + design-principal personas)
license: MIT
platforms: [linux, macos, windows]
metadata:
    hermes:
      tags: [design, ux, ui, research, mockups, design-system, competitive-analysis]
      related_skills: [de-craft, de-ideate, de-plan, de-brainstorm]
---

# Design Duo — research-then-synthesize pipeline

A two-agent design flow that grounds design direction in competitor research, then hands engineering-ready specs and a self-contained HTML mockup. Both agents discover the host project's design system at runtime — no per-project agent editing required.

> **This skill's value is the tightness of the handoff, not the breadth of what it covers.** All intelligence lives in the agent definitions; this orchestrator is glue.

## When to Use

- Before designing a new feature, flow, or page
- When you want competitor patterns grounded in real product UI, not generic training-data averages
- When design handoff must reference **your** components and tokens, not an invented design system
- When you want visual artifacts (research gallery + mockup) alongside written specs

**Don't use for:** copy-edit, one-off styling tweaks, or "what color should this be" questions. Those are `de-craft` territory.

## The Pipeline

```
User question
     │
     ▼
[1. Capture topic]              ← orchestrator only
     │
     ▼
[2. Workspace discovery]        ← orchestrator does this once; both agents reuse
     │
     ▼
[3. design-researcher]          ← delegate_task with minimal payload
     │
     ▼
Research gallery (.html) + structured findings (md)
     │
     ▼
[4. design-principal]           ← delegate_task with research as context
     │
     ▼
Design spec (md) + interactive mockup (.html)
     │
     ▼
Engineering handoff (spec + mockup)
```

The orchestrator (you, when this skill is invoked) runs steps 1–4 **sequentially**, in this session. The user stays in the loop — they can interrupt at any UI boundary, but you **never pause for approval** between researcher and principal.

## Step 1 — Capture the topic

If the user gave a topic (e.g. `/design-duo account type selection patterns`), use it directly.

If not, ask — and offer concrete seeds so the user doesn't over-think the question:

> What design question or feature should I research and design for?
>
> Examples:
> - "Account opening flow patterns"
> - "How do competitors handle portfolio overview on mobile?"
> - "Stepper vs. accordion for multi-step forms"

Note any constraints the user provides (specific competitors to focus on, specific states to explore, mobile vs. desktop emphasis) — pass them to the researcher.

## Step 2 — Workspace discovery

Run these reads **before** dispatching the researcher. Both agents reuse the result.

1. `find . -maxdepth 3 -iname "DESIGN*.md" -not -path "./node_modules/*"` — locate `DESIGN.md`
2. `find . -maxdepth 3 -iname "DESIGN-CONTEXT.md" -not -path "./node_modules/*"` — locate product context
3. `find . -maxdepth 3 -iname "STRATEGY.md" -not -path "./node_modules/*"` — fallback strategy doc
4. `cat package.json 2>/dev/null | head -50` — detect component libraries
5. `find ./components -maxdepth 2 -type d 2>/dev/null | head -20` — discover component layout

Build a **workspace summary**:

```
# Workspace discovery
- Design system: <path to DESIGN.md, or "not found">
- Product context: <path to DESIGN-CONTEXT.md or STRATEGY.md, or "ask one question">
- Component library: <list of discovered libs and project wrappers>
- Conventions: <AGENTS.md path or "none">
- Viewport priority: <from DESIGN.md or DESIGN-CONTEXT.md>
```

If `DESIGN-CONTEXT.md` is missing, ask **one** clarifying question about industry/competitors/differentiators — the highest-leverage question. Don't gate the pipeline on perfect context. (The full template lives at `references/templates/DESIGN-CONTEXT.md`.)

## Step 3 — Dispatch `design-researcher`

Read the persona first: `read_file(path="~/.hermes/skills/creative/design-duo/references/personas/design-researcher.md")`.

Then dispatch with a **minimal payload** — let the persona carry the methodology:

```python
delegate_task(
    goal=f"""Research {topic} for our product.

Workspace summary:
{workspace_summary}

Focus hint: {focus_hint}""",
    context=f"""<full body of references/personas/design-researcher.md, after the YAML frontmatter and adaptation note>

WORKSPACE:
{workspace_summary}

FOCUS: {focus_hint}

The host codebase already has its own design system at {design_system_path}. Read it before researching — your findings should reference the host's tokens and components, not invent a parallel system.""",
    toolsets=["web", "terminal", "file"]
)
```

> **Minimum payload rule:** the prompt has only topic + focus. The persona body has everything else. Resist the temptation to restate methodology in the prompt — duplication makes both agents drift apart over time.

**Failure handling:** if the researcher errors (no web, MCP unavailable, network failure), warn the user (`"External research unavailable: {reason}. Proceeding with internal grounding only."`) and continue with whatever context you have. Don't block — the principal can still work from `DESIGN.md` + workspace context alone, with confidence capped at Medium.

**Expected output:** structured markdown findings (8 required sections per the persona) + an HTML gallery at `.design-output/research/{topic-slug}/index.html` from the bundled template.

## Step 4 — Surface research, auto-continue

After the researcher returns, show a one-liner and **auto-continue to Step 5**:

```
Research complete.
Confidence: [High/Medium/Low] — [reason]
Gallery: {path}

Handing off to design-principal for synthesis...
```

> **Never pause for approval between researcher and principal.** The user can interrupt via the UI if the research missed the mark. Auto-continue.

## Step 5 — Dispatch `design-principal`

Read the research output, then read the persona: `read_file(path="~/.hermes/skills/creative/design-duo/references/personas/design-principal.md")`.

Dispatch with research as context (still minimal — don't restate the persona):

```python
delegate_task(
    goal=f"""Synthesize the research into design direction and an engineering-ready spec for {topic}.

Produce the 9 output sections defined in your persona (design direction, visual specs, component behavior, all states, micro-interactions, what we're NOT doing, research gaps, feasibility checkpoints, interactive mockup).""",
    context=f"""<full body of references/personas/design-principal.md, after the YAML frontmatter and adaptation note>

RESEARCH FINDINGS:
{researcher_output}

GALLERY: {gallery_path}

WORKSPACE:
{workspace_summary}

The mockup MUST use tokens and component conventions from {design_system_path}. Hand off components as:
Component: {{ExistingWrapper}} (existing)
Base: {{path from discovery}}
Customization: {{specific props/slots only}}

Do NOT invent a parallel design system. Use what exists; wrap before inventing.""",
    toolsets=["terminal", "file", "web"]
)
```

**Standalone mode:** the principal works without research input but caps Design Confidence at Medium (per persona). If the user only wants spec work, skip Step 3 and dispatch principal directly with the workspace summary as context.

## Step 6 — Handoff

After both agents return, present both artifact paths with one short paragraph:

```
## Design Duo Handoff

**Question:** {original user request}
**Confidence:** {from principal's output}

**Research**
- Summary: {2-3 sentences from researcher's summary}
- Gallery: {path to gallery.html}

**Design direction**
{1-2 paragraphs from principal's "Design direction" section}

**Spec**
- File: {path to spec.md or full output}
- Mockup: {path to mockup.html}

**Components used (must match discovered library)**
{list from principal's output}

**Open questions**
{any research gaps or feasibility concerns the principal flagged}
```

Then offer the next step via `clarify`:

| Option | When to offer |
|---|---|
| Open the mockup (`mockup.html`) | Always |
| Iterate on the spec (re-dispatch principal with adjustments) | When spec exists but isn't quite right |
| Run a deeper iteration (more options, refined states) | When principal's confidence is Medium/Low |
| Hand off to engineering (write a plan with `de-plan`) | When spec is final |

## Inputs the skill reads from the workspace

| Resource | Cascade |
|---|---|
| Design system | `DESIGN.md` → `docs/DESIGN.md` → `design/DESIGN.md` → `.cursor/DESIGN.md` |
| Product context | `DESIGN-CONTEXT.md` → `STRATEGY.md` → `README.md` → codebase scan |
| Component library | `components/ui/` → shadcn/Radix/MUI (from `package.json`) → Tailwind config → global styles |
| Conventions | `AGENTS.md` → `.cursor/rules/` → contribution docs |

## Common Pitfalls

1. **Skipping workspace discovery** — both agents will guess about the design system if you don't pass context. The guesses will look plausible but won't match your tokens. Always run Step 2.
2. **Bloating the prompt** — if you restate persona methodology in the goal/context, the two copies will drift over time. Trust the agent's persona; pass only topic + workspace context.
3. **Dispatching both agents in parallel** — they're sequential. The principal needs the researcher's output. Don't `delegate_task(tasks=[researcher, principal])` — that's wrong.
4. **Blocking on research failure** — if the researcher can't fetch web/MCP, proceed with what you have. The principal is still useful from DESIGN.md + workspace context alone.
5. **Asking more than one context question** — if `DESIGN-CONTEXT.md` is missing, ask **one** question (industry/competitors/differentiators). Don't gate the pipeline on perfect context.
6. **Treating the mockup as production code** — the HTML is a concept sketch, not implementation. Engineering should plan with `de-plan` after the spec is approved; the mockup informs the plan, it doesn't replace it.

## Verification Checklist

- [ ] Topic captured (with examples offered if absent)
- [ ] Workspace discovery ran before dispatching
- [ ] Researcher received minimal prompt (topic + focus) + workspace summary as context
- [ ] Researcher output includes a gallery at `.design-output/research/{slug}/index.html`
- [ ] Auto-continued to principal after research (no approval pause)
- [ ] Principal received the researcher's full output as context
- [ ] Principal output references discovered component names, not invented ones
- [ ] Mockup uses design tokens from DESIGN.md (no hardcoded hex colors)
- [ ] All states enumerated (empty, loading, error, success, edge cases)
- [ ] Design Confidence declared with reason
- [ ] User was offered the mockup + spec + next-step menu

## Output Locations

| Output | Path (preferred) | Fallback |
|---|---|---|
| Research gallery | `.design-output/research/{topic-slug}/index.html` | `~/Desktop/design-research/{topic-slug}/index.html` |
| Mockup | `.design-output/concepts/{feature-slug}/mockup.html` | `~/Desktop/design-concepts/{feature-slug}/mockup.html` |
| Spec | Embedded in principal's output (no separate file) | — |

Recommend the user add `.design-output/` to `.gitignore` for design exploration that shouldn't ship.

## Bundled Assets

| File | Purpose |
|---|---|
| `references/personas/design-researcher.md` | Canonical persona prompt (de-workspace original, lightly tightened) |
| `references/personas/design-principal.md` | Canonical persona prompt (lightly tightened) |
| `references/personas/de-design-researcher.md` | Cursor `~/.cursor/agents/` variant |
| `references/personas/de-design-principal.md` | Cursor `~/.cursor/agents/` variant |
| `references/assets/gallery-template.html` | Base HTML for the researcher's gallery output |
| `references/templates/DESIGN-CONTEXT.md` | Optional product context file (copy to repo root, fill in) |

## What This Skill Does NOT Do (anti-bloat rules)

- **Redefine agent behavior** — all methodology lives in the persona files. If a rule belongs in the agent, put it there, not here.
- **Add conditional logic** — no "if Low confidence, stop" branching. The principal's persona handles degradation gracefully.
- **Replace standalone invocation** — `@design-researcher` and `@design-principal` still work independently. This skill is for when you want both in sequence.
- **Re-explain persona instructions in the prompt** — see Pitfall #2.

## Related Skills

- **`de-craft`** — UI craft standards and motion patterns; useful as a reference for the principal when refining micro-interactions
- **`de-ideate`** — generates ranked ideas before deep brainstorming; use when you don't have a feature question yet
- **`de-brainstorm`** — pins down requirements once an idea is chosen; precedes `design-duo` if scope is unclear
- **`de-plan`** — converts the design spec into an implementation plan for engineering
