#!/usr/bin/env bash
set -euo pipefail

# Instala/actualiza la configuración canónica de Claude Code de la Software
# Factory en un repo de trabajo, sin pisar lo que ya exista ahí.
#
# Uso: scripts/bootstrap.sh <ruta-al-repo-destino> [nombre-del-proyecto]

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:?Uso: bootstrap.sh <ruta-al-repo-destino> [nombre-del-proyecto]}"
PROJECT_NAME="${2:-$(basename "$TARGET_DIR")}"

# Cargar helpers
source "$SOURCE_DIR/scripts/lib/install-helpers.sh"
source "$SOURCE_DIR/scripts/lib/merge-claude.sh"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "El directorio destino no existe: $TARGET_DIR" >&2
  exit 1
fi

echo ""
echo "🚀 Bootstrap de Software Factory"
echo "   Destino: $TARGET_DIR"
echo "   Proyecto: $PROJECT_NAME"
echo ""

# ============================================================================
# FASE 1: Crear directorios base
# ============================================================================

echo "📁 Fase 1: Crear estructura de directorios..."
mkdir -p "$TARGET_DIR/.claude/agents" "$TARGET_DIR/.claude/skills" "$TARGET_DIR/.github/workflows"

# ============================================================================
# FASE 2: Copiar plantillas (skip-if-exists)
# ============================================================================

echo ""
echo "📋 Fase 2: Copiar plantillas..."

copy_if_absent() {
  local src="$1" dest="$2"
  if [[ -e "$dest" ]]; then
    echo "  ⏭️  ya existe, se omite: $dest"
  else
    cp -r "$src" "$dest"
    echo "  ✅ creado: $dest"
  fi
}

copy_if_absent "$SOURCE_DIR/templates/settings.json.template" "$TARGET_DIR/.claude/settings.json"
copy_if_absent "$SOURCE_DIR/templates/github/workflows/ci.yml" "$TARGET_DIR/.github/workflows/ci.yml"
copy_if_absent "$SOURCE_DIR/templates/github/pull_request_template.md" "$TARGET_DIR/.github/pull_request_template.md"

# ============================================================================
# FASE 3: Mergear CLAUDE.md inteligentemente
# ============================================================================

echo ""
echo "📝 Fase 3: Procesar CLAUDE.md..."
propose_claude_md_merge "$TARGET_DIR" "$PROJECT_NAME"

# Crear AGENT_WORKFLOW.md si no existe
if [[ ! -f "$TARGET_DIR/AGENT_WORKFLOW.md" ]]; then
  sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$SOURCE_DIR/templates/AGENT_WORKFLOW.md.template" > "$TARGET_DIR/AGENT_WORKFLOW.md"
  echo "  ✅ creado: $TARGET_DIR/AGENT_WORKFLOW.md"
else
  echo "  ⏭️  ya existe, se omite: $TARGET_DIR/AGENT_WORKFLOW.md"
fi

# ============================================================================
# FASE 4: Vendorizar skills locales (qa, stop-slop)
# ============================================================================

echo ""
echo "🛠️  Fase 4: Vendorizar skills locales..."

for skill in qa stop-slop; do
  copy_if_absent "$SOURCE_DIR/.claude/skills/$skill" "$TARGET_DIR/.claude/skills/$skill"
done

# ============================================================================
# FASE 5: Vendorizar agentes
# ============================================================================

echo ""
echo "👤 Fase 5: Vendorizar agentes..."

for agent in db-query-agent qa-visual-agent research-agent; do
  copy_if_absent "$SOURCE_DIR/.claude/agents/$agent.md" "$TARGET_DIR/.claude/agents/$agent.md"
done

# ============================================================================
# FASE 6: Detectar/instalar dependencias globales (NUEVO)
# ============================================================================

echo ""
echo "🌐 Fase 6: Verificar dependencias globales..."
echo "   (Se instalan una sola vez a nivel de máquina, no por proyecto)"
echo ""

install_superpowers_if_needed
echo ""

read -p "¿Instalar skills adicionales? (frontend-design, remotion) (s/n) " -n 1 -r
echo ""
if [[ -z "$REPLY" ]]; then
  echo "⚠️  Entrada cancelada o vacía" >&2
  exit 1
fi

if [[ $REPLY =~ ^[Ss]$ ]]; then
  install_frontend_design_if_wanted
  install_remotion_if_wanted
fi

# ============================================================================
# FASE 7: Validar
# ============================================================================

echo ""
echo "✔️  Fase 7: Validar instalación..."
validate_installation "$TARGET_DIR" || {
  echo ""
  echo "⚠️  Advertencia: se detectaron problemas post-instalación (revisar arriba)"
}

# ============================================================================
# Resumen final
# ============================================================================

cat <<'EOF'

✅ Bootstrap completo.

📋 Próximos pasos manuales:

  1. COMPLETAR PLACEHOLDERS en CLAUDE.md y AGENT_WORKFLOW.md
     - {{ONE_PARAGRAPH_DESCRIPTION}}: qué es el proyecto en una línea
     - {{STACK_SUMMARY}}: tech stack (Node/React/Python/etc)
     - {{LINT_COMMAND}}, {{TEST_COMMAND}}, {{BUILD_COMMAND}}, {{DEV_COMMAND}}

     Ejecutá: scripts/post-setup.sh
     (O editá a mano — el checklist es interactivo)

  2. CONFIGURAR REGLAS DE PERMISOS en .claude/settings.json
     - Las reglas genéricas ya están. Personalizá con rutas reales del proyecto
       (p. ej. si tenés backend/ y frontend/, ajustá las reglas de Edit())

     Ver: https://claude.ai/claude-code/docs/reference/settings#permissions

  3. INSTALAR MCP SERVERS (por máquina, no por proyecto)
     - GitHub MCP: `/mcp install github`
     - Context7: `/mcp install context7` (para docs de librerías)
     - Otros: ver docs/external-setup-checklist.md

     Ejecutá nuevamente: scripts/post-setup.sh
     (Te guiará paso a paso)

Más info: docs/external-setup-checklist.md

EOF

echo ""
echo "Para el siguiente paso interactivo, ejecutá:"
echo "  cd $TARGET_DIR"
echo "  $SOURCE_DIR/scripts/post-setup.sh"
echo ""
