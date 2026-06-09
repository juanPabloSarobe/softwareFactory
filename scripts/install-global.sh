#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SOURCE_DIR/scripts/lib/install-helpers.sh"

echo ""
echo "🌐 Instalación global de Software Factory"
echo "   Destino: ~/.claude/"
echo ""

mkdir -p "$HOME/.claude/agents" "$HOME/.claude/skills"

# ── Permisos ──────────────────────────────────────────────────────────────────
echo "📋 Permisos"
merge_settings "$SOURCE_DIR/templates/settings.json.template" "$HOME/.claude/settings.json"
echo ""

# ── Agentes ───────────────────────────────────────────────────────────────────
echo "👤 Agentes"
for agent in db-query-agent qa-visual-agent research-agent; do
  if [[ -f "$HOME/.claude/agents/$agent.md" ]]; then
    cp "$SOURCE_DIR/.claude/agents/$agent.md" "$HOME/.claude/agents/$agent.md"
    echo "  🔄 actualizado: $agent.md"
  else
    cp "$SOURCE_DIR/.claude/agents/$agent.md" "$HOME/.claude/agents/$agent.md"
    echo "  ✅ instalado: $agent.md"
  fi
done
echo ""

# ── Skills vendorizadas ───────────────────────────────────────────────────────
echo "🛠️  Skills vendorizadas"
for skill in qa stop-slop; do
  if [[ -d "$HOME/.claude/skills/$skill" ]]; then
    rm -rf "$HOME/.claude/skills/$skill"
    cp -r "$SOURCE_DIR/.claude/skills/$skill" "$HOME/.claude/skills/$skill"
    echo "  🔄 actualizado: $skill/"
  else
    cp -r "$SOURCE_DIR/.claude/skills/$skill" "$HOME/.claude/skills/$skill"
    echo "  ✅ instalado: $skill/"
  fi
done
echo ""

# ── Plugins (no se pueden instalar desde bash) ────────────────────────────────
echo "🔌 Plugins (requieren Claude Code para instalar)"
if [[ -d "$HOME/.claude/plugins/cache/claude-plugins-official/superpowers" ]]; then
  echo "  ✅ Superpowers instalado"
else
  echo "  ⚠️  Superpowers no instalado (requerido)"
  echo "     → Dentro de Claude Code: /plugin install superpowers@claude-plugins-official"
fi

if [[ -d "$HOME/.claude/plugins/cache/claude-plugins-official/frontend-design" ]]; then
  echo "  ✅ frontend-design instalado"
else
  echo "  ℹ️  frontend-design no instalado (opcional)"
  echo "     → Dentro de Claude Code: /plugin install frontend-design@claude-plugins-official"
fi

if [[ -d "$HOME/.claude/plugins/cache/claude-plugins-official/remotion" ]]; then
  echo "  ✅ remotion instalado"
else
  echo "  ℹ️  remotion no instalado (opcional)"
  echo "     → Dentro de Claude Code: /plugin install remotion@claude-plugins-official"
fi
echo ""

# ── MCP servers ───────────────────────────────────────────────────────────────
echo "🌐 MCP servers"
if command -v claude &>/dev/null && claude mcp list 2>/dev/null | grep -q "context7"; then
  echo "  ✅ context7 configurado"
else
  echo "  ⚠️  context7 no configurado"
  echo "     → claude mcp add context7 -- npx -y @upstash/context7-mcp"
fi

if command -v claude &>/dev/null && claude mcp list 2>/dev/null | grep -q "playwright"; then
  echo "  ✅ playwright configurado"
else
  echo "  ⚠️  playwright no configurado"
  echo "     → claude mcp add playwright -- npx @playwright/mcp@latest"
fi

echo "  ℹ️  Gmail / Google Calendar: configurar desde claude.ai/settings"
echo ""

echo "✅ Instalación global completa."
echo ""
echo "Para proyectos nuevos:"
echo "  bash scripts/bootstrap.sh <ruta-al-proyecto>"
echo ""
echo "Para actualizar en otra máquina:"
echo "  git pull && bash scripts/install-global.sh"
echo ""
