#!/usr/bin/env bash
set -euo pipefail

# Post-setup interactivo: guía al usuario a completar placeholders,
# configuración de permisos por proyecto, e instalación de MCP servers.

PROJECT_DIR="${1:-.}"  # por defecto, directorio actual
CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"
AGENT_WF="$PROJECT_DIR/AGENT_WORKFLOW.md"
SETTINGS_JSON="$PROJECT_DIR/.claude/settings.json"

if [[ ! -f "$CLAUDE_MD" ]]; then
  echo "❌ No encontré CLAUDE.md en $PROJECT_DIR"
  echo "   ¿Ejecutaste bootstrap.sh primero?"
  exit 1
fi

echo ""
echo "🔧 Post-Setup: completar configuración del proyecto"
echo "   Directorio: $PROJECT_DIR"
echo ""

# ============================================================================
# Detectar placeholders pendientes
# ============================================================================

PENDING_CLAUDE=$(grep -c "{{.*}}" "$CLAUDE_MD" || true)
PENDING_AGENT=$(grep -c "{{.*}}" "$AGENT_WF" || true)

if [[ $PENDING_CLAUDE -gt 0 ]] || [[ $PENDING_AGENT -gt 0 ]]; then
  echo "⚠️  Hay placeholders sin completar:"
  [[ $PENDING_CLAUDE -gt 0 ]] && echo "   - CLAUDE.md: $PENDING_CLAUDE placeholders"
  [[ $PENDING_AGENT -gt 0 ]] && echo "   - AGENT_WORKFLOW.md: $PENDING_AGENT placeholders"
  echo ""
  read -p "¿Completar ahora de forma interactiva? (s/n) " -n 1 -r
  echo ""

  if [[ -z "$REPLY" ]]; then
    echo "⚠️  Entrada cancelada" >&2
  elif [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo "📝 Completando CLAUDE.md..."
    echo ""

    # Detectar placeholders existentes y pedirlos interactivamente
    if grep -qF "{{ONE_PARAGRAPH_DESCRIPTION}}" "$CLAUDE_MD"; then
      echo "¿Qué hace este proyecto? (1-2 líneas, sin punto final)"
      read -r ONE_PARA
      if [[ -n "$ONE_PARA" ]]; then
        # Escapar caracteres especiales para sed
        ONE_PARA_ESCAPED=$(printf '%s\n' "$ONE_PARA" | sed -e 's/[\/&]/\\&/g')
        sed -i "" "s|{{ONE_PARAGRAPH_DESCRIPTION}}|$ONE_PARA_ESCAPED|g" "$CLAUDE_MD"
      fi
    fi

    if grep -qF "{{STACK_SUMMARY}}" "$CLAUDE_MD"; then
      echo ""
      echo "Stack técnico (ej: Node.js + Express + React + MongoDB)"
      read -r STACK
      if [[ -n "$STACK" ]]; then
        STACK_ESCAPED=$(printf '%s\n' "$STACK" | sed -e 's/[\/&]/\\&/g')
        sed -i "" "s|{{STACK_SUMMARY}}|$STACK_ESCAPED|g" "$CLAUDE_MD"
      fi
    fi

    if grep -qF "{{LINT_COMMAND}}" "$CLAUDE_MD"; then
      echo ""
      echo "Comando para linting (ej: npm run lint)"
      read -r LINT_CMD
      if [[ -n "$LINT_CMD" ]]; then
        LINT_CMD_ESCAPED=$(printf '%s\n' "$LINT_CMD" | sed -e 's/[\/&]/\\&/g')
        sed -i "" "s|{{LINT_COMMAND}}|$LINT_CMD_ESCAPED|g" "$CLAUDE_MD"
      fi
    fi

    if grep -qF "{{TEST_COMMAND}}" "$CLAUDE_MD"; then
      echo ""
      echo "Comando para tests (ej: npm test)"
      read -r TEST_CMD
      if [[ -n "$TEST_CMD" ]]; then
        TEST_CMD_ESCAPED=$(printf '%s\n' "$TEST_CMD" | sed -e 's/[\/&]/\\&/g')
        sed -i "" "s|{{TEST_COMMAND}}|$TEST_CMD_ESCAPED|g" "$CLAUDE_MD"
      fi
    fi

    if grep -qF "{{BUILD_COMMAND}}" "$CLAUDE_MD"; then
      echo ""
      echo "Comando para build (ej: npm run build)"
      read -r BUILD_CMD
      if [[ -n "$BUILD_CMD" ]]; then
        BUILD_CMD_ESCAPED=$(printf '%s\n' "$BUILD_CMD" | sed -e 's/[\/&]/\\&/g')
        sed -i "" "s|{{BUILD_COMMAND}}|$BUILD_CMD_ESCAPED|g" "$CLAUDE_MD"
      fi
    fi

    if grep -qF "{{DEV_COMMAND}}" "$CLAUDE_MD"; then
      echo ""
      echo "Comando para desarrollo (ej: npm run dev)"
      read -r DEV_CMD
      if [[ -n "$DEV_CMD" ]]; then
        DEV_CMD_ESCAPED=$(printf '%s\n' "$DEV_CMD" | sed -e 's/[\/&]/\\&/g')
        sed -i "" "s|{{DEV_COMMAND}}|$DEV_CMD_ESCAPED|g" "$CLAUDE_MD"
      fi
    fi

    echo "✅ CLAUDE.md actualizado"
  fi
else
  echo "✅ CLAUDE.md no tiene placeholders pendientes"
fi

# ============================================================================
# Sección MCP servers (solo para información)
# ============================================================================

echo ""
echo "🔌 MCP Servers (Model Context Protocol — conectores de información)"
echo "   Se instalan una sola vez a nivel de máquina"
echo ""
echo "Opciones disponibles:"
echo "  - GitHub MCP: leer/crear/comentar issues y PRs directo"
echo "  - Context7: documentación de librerías/APIs on-demand"
echo "  - Playwright MCP: navegación y testing automatizado"
echo "  - Figma Dev Mode: leer specs de diseño directamente"
echo ""
echo "Para instalarlos, ejecutá desde Claude Code:"
echo "  /mcp install github"
echo "  /mcp install context7"
echo "  /mcp install playwright"
echo ""
echo "Ver más en: docs/external-setup-checklist.md"
echo ""

# ============================================================================
# Resumen final
# ============================================================================

echo "✨ Setup post-bootstrap completo!"
echo ""
echo "Próximos pasos:"
echo "  1. Commiteá los cambios: git add -A && git commit -m 'config: completar placeholders post-bootstrap'"
echo "  2. Abrí tu primer issue/feature en el proyecto"
echo "  3. Usá /brainstorming para planificar la solución"
echo "  4. Seguí el flujo de Superpowers: planificar → implementar → review"
echo ""
echo "Para más info: CLAUDE.md, docs/superpowers/specs/"
echo ""
