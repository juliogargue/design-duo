#!/usr/bin/env bash
# Install Agent Design Duo canonical content to runtime locations.
# Source of truth: this directory (final/design-duo/).
# Edit files here, then re-run this script. Never hand-edit runtime copies.
#
# Usage:
#   ./install.sh              # install for the current platform (Hermes today)
#   ./install.sh --help       # show help
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
HERMES_DST="${HOME}/.hermes/skills/design-duo"

usage() {
  cat <<EOF
Agent Design Duo installer

Usage:
  ./install.sh              Install to Hermes runtime (~/.hermes/skills/design-duo/)
  ./install.sh --help       Show this help

This script deploys this directory's content as the runtime source of truth.
Edits to personas/, templates/, or assets/ in final/design-duo/ take effect
on the next run of install.sh. Do not edit runtime copies directly.

Future platforms (Cursor, Claude Code, Codex) can be added by extending this
script — see TODOs below.
EOF
}

# --- parse args -------------------------------------------------------------
case "${1:-}" in
  --help|-h) usage; exit 0 ;;
  "")         : ;;
  *)          echo "Unknown arg: $1"; usage; exit 2 ;;
esac

# --- preflight -------------------------------------------------------------
if [ ! -f "$ROOT/SKILL.md" ]; then
  echo "error: $ROOT/SKILL.md not found — are you running from the right directory?" >&2
  exit 1
fi
if [ ! -d "$ROOT/personas" ]; then
  echo "error: $ROOT/personas/ not found" >&2
  exit 1
fi

# --- install: Hermes ---------------------------------------------------------
echo "installing to Hermes ($HERMES_DST)..."
mkdir -p "$HERMES_DST"

# Top-level files
cp "$ROOT/SKILL.md" "$HERMES_DST/SKILL.md"

# Persona files (deploy as canonical names — no de- prefix, since design-duo
# is original work, not adapted from any ce- upstream skill)
mkdir -p "$HERMES_DST/personas"
for p in "$ROOT"/personas/*.md; do
  [ -f "$p" ] || continue
  name="$(basename "$p")"
  cp "$p" "$HERMES_DST/personas/$name"
  echo "  personas/$name"
done

# Auxiliary files
[ -d "$ROOT/templates" ] && {
  mkdir -p "$HERMES_DST/templates"
  cp -R "$ROOT/templates/." "$HERMES_DST/templates/"
  echo "  templates/"
}
[ -d "$ROOT/assets" ] && {
  mkdir -p "$HERMES_DST/assets"
  cp -R "$ROOT/assets/." "$HERMES_DST/assets/"
  echo "  assets/"
}

echo ""
echo "✓ installed to: $HERMES_DST"
echo ""
echo "Reload Hermes to pick up changes (or invoke /design-duo again)."

# --- TODOs (uncomment when adding platforms) -------------------------------
#
# Cursor:
#   CURSOR_DST="${HOME}/.cursor/agents"
#   mkdir -p "$CURSOR_DST"
#   cp "$ROOT/personas/design-researcher.md" "$CURSOR_DST/de-design-researcher.md"
#   cp "$ROOT/personas/design-principal.md"  "$CURSOR_DST/de-design-principal.md"
#
# Claude Code:
#   CLAUDE_DST="${HOME}/.claude/agents"
#   mkdir -p "$CLAUDE_DST"
#   cp "$ROOT/personas/design-researcher.md" "$CLAUDE_DST/design-researcher.md"
#   cp "$ROOT/personas/design-principal.md"  "$CLAUDE_DST/design-principal.md"
#
# Codex: similar pattern, target ${HOME}/.codex/<wherever>
