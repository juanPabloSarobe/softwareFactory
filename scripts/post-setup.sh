#!/usr/bin/env bash
set -euo pipefail

# Post-setup interactivo: guía al usuario a completar placeholders,
# configuración de permisos por proyecto, e instalación de MCP servers.

PROJECT_DIR="${1:-.}"  # por defecto, directorio actual
CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"
AGENT_WF="$PROJECT_DIR/AGENT_WORKFLOW.md"
SETTINGS_JSON="$PROJECT_DIR/.claude/settings.json"

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ ! -f "$SOURCE_DIR/scripts/lib/project-permissions.sh" ]]; then
  echo "❌ No encontré scripts/lib/project-permissions.sh — ejecutá este script desde el repo softwareFactory"
  exit 1
fi
source "$SOURCE_DIR/scripts/lib/project-permissions.sh"

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

  if [[ $REPLY =~ ^[Ss]$ ]]; then
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

    # Procesar AGENT_WORKFLOW.md si existe
    if [[ -f "$AGENT_WF" ]] && grep -qF "{{" "$AGENT_WF"; then
      echo ""
      echo "📝 Completando AGENT_WORKFLOW.md..."
      echo ""

      if grep -qF "{{PROJECT_NAME}}" "$AGENT_WF"; then
        # Reutilizar PROJECT_NAME del comando
        PROJECT_NAME_FOR_AGENT=$(basename "$PROJECT_DIR")
        sed -i "" "s|{{PROJECT_NAME}}|$PROJECT_NAME_FOR_AGENT|g" "$AGENT_WF"
        echo "✅ AGENT_WORKFLOW.md actualizado con PROJECT_NAME"
      fi
    fi
  fi
else
  echo "✅ CLAUDE.md no tiene placeholders pendientes"
fi

# ============================================================================
# Fase: Write paths proyecto-específicos
# ============================================================================

echo ""
echo "✏️  Write paths: configurar permisos de escritura del proyecto..."
echo ""

# Directorios no estándar conocidos (se ignoran en la detección automática)
KNOWN_DIRS=("backend" "frontend" "src" "app" ".git" ".claude" ".github" "docs" "scripts" "templates" "node_modules" "dist" "build" ".next" ".nuxt" "coverage")

DETECTED_PATHS=()
while IFS= read -r line; do
  [[ -n "$line" ]] && DETECTED_PATHS+=("$line")
done < <(detect_write_paths "$PROJECT_DIR")

# Detectar directorios no estándar con código (tienen src/ o package.json)
NONSTANDARD_EXTRAS=()
for dir_path in "$PROJECT_DIR"/*/; do
  dir_name=$(basename "$dir_path")
  skip=false
  for known in "${KNOWN_DIRS[@]}"; do
    [[ "$dir_name" == "$known" ]] && skip=true && break
  done
  if [[ "$skip" == "false" ]] && \
     ([[ -d "$dir_path/src" ]] || [[ -f "$dir_path/package.json" ]] || [[ -f "$dir_path/pyproject.toml" ]]); then
    NONSTANDARD_EXTRAS+=("$dir_name")
  fi
done

# Preguntar por directorios no estándar
for dir_name in "${NONSTANDARD_EXTRAS[@]+"${NONSTANDARD_EXTRAS[@]}"}"; do
  read -p "  Detecté '$dir_name/' con código — ¿pre-aprobar escrituras ahí? (s/n) " -n 1 -r
  echo ""
  [[ $REPLY =~ ^[Ss]$ ]] && DETECTED_PATHS+=("Write($dir_name/**)")
done

if [[ ${#DETECTED_PATHS[@]} -eq 0 ]]; then
  echo "  ℹ️  No detecté directorios de código. Configurá Write paths manualmente en .claude/settings.json"
else
  if [[ ! -f "$SETTINGS_JSON" ]]; then
    echo "  ❌ No encontré $SETTINGS_JSON — ejecutá bootstrap.sh primero"
  else
    echo "  Voy a agregar a .claude/settings.json:"
    for p in "${DETECTED_PATHS[@]+"${DETECTED_PATHS[@]}"}"; do
      echo "    $p"
    done
    echo ""
    read -p "  ¿Confirmás? (s/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Ss]$ ]]; then
      # Construir array JSON y mergear con jq (deduplicando, escritura atómica)
      JSON_ARRAY=$(printf '%s\n' "${DETECTED_PATHS[@]+"${DETECTED_PATHS[@]}"}" | jq -R . | jq -s .)
      TMP_SETTINGS=$(mktemp)
      jq --argjson paths "$JSON_ARRAY" '.permissions.allow = (.permissions.allow + $paths | unique)' "$SETTINGS_JSON" > "$TMP_SETTINGS" && mv "$TMP_SETTINGS" "$SETTINGS_JSON"
      echo "  ✅ Write paths agregados"
    fi
  fi
fi

# ============================================================================
# Sección: hooks de notificación en ~/.claude/settings.json
# ============================================================================

echo ""
echo "🔔 Hooks de notificación (por máquina, no por proyecto)"
echo "   Avisan cuando Claude termina de trabajar o necesita atención."
echo ""

USER_SETTINGS="$HOME/.claude/settings.json"
HOOKS_TEMPLATE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/templates/user-settings.json.template"

if [[ -f "$USER_SETTINGS" ]] && jq -e '.hooks.Stop' "$USER_SETTINGS" >/dev/null 2>&1; then
  echo "✅ Hooks de notificación ya configurados en $USER_SETTINGS"
else
  echo "  Requiere: macOS (usa osascript nativo, sin dependencias extras)"
  echo ""
  read -p "¿Configurar notificaciones nativas de macOS? (s/n) " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Ss]$ ]]; then
    if [[ ! -f "$USER_SETTINGS" ]]; then
      echo "{}" > "$USER_SETTINGS"
    fi

    NEW_SETTINGS=$(jq --slurpfile hooks "$HOOKS_TEMPLATE" '. + {hooks: $hooks[0].hooks}' "$USER_SETTINGS")
    echo "$NEW_SETTINGS" > "$USER_SETTINGS"
    echo "  ✅ Hooks de notificación aplicados en $USER_SETTINGS"
    echo "  ℹ️  Reiniciá Claude Code para que tomen efecto"
  fi
fi

# ============================================================================
# Sección MCP servers interactiva
# ============================================================================

echo ""
echo "🔌 MCP Servers (Model Context Protocol — conectores de información)"
echo "   Se instalan una sola vez a nivel de máquina"
echo ""
echo "Opciones disponibles:"
echo "  1. GitHub MCP — leer/crear/comentar issues y PRs directo"
echo "  2. Context7 — documentación de librerías/APIs on-demand"
echo "  3. Playwright MCP — navegación y testing automatizado"
echo "  4. Figma Dev Mode — leer specs de diseño directamente"
echo "  5. Ver más detalles"
echo ""
read -p "¿Instalar algún MCP? (1-5 o s/n) " -n 1 -r
if [[ -z "$REPLY" ]]; then
  echo ""
  echo "⚠️  Entrada cancelada" >&2
elif [[ $REPLY =~ ^[Ss5]$ ]]; then
  echo ""
  cat <<'MCPHELP'

GitHub MCP:
  /mcp install github
  Requiere: GitHub personal access token (Settings > Developer settings > Personal access tokens)

Context7 (recomendado para desarrollo):
  /mcp install context7
  Requiere: API key (https://context7.ai/)

Playwright MCP:
  /mcp install playwright
  Requiere: Bun instalado (https://bun.sh/)

Para más: docs/external-setup-checklist.md

MCPHELP
else
  echo ""
fi

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
