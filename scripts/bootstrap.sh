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
mkdir -p "$TARGET_DIR/.claude" "$TARGET_DIR/.github/workflows"

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

copy_if_absent "$SOURCE_DIR/templates/POSTINSTALL_CHECKLIST.md.template" "$TARGET_DIR/POSTINSTALL_CHECKLIST.md"
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
# FASE 4: Validar
# ============================================================================

echo ""
echo "✔️  Fase 4: Validar instalación..."

if [[ ! -f "$HOME/.claude/settings.json" ]]; then
  echo ""
  echo "  ⚠️  ~/.claude/settings.json no encontrado."
  echo "     Ejecutá primero: bash $SOURCE_DIR/scripts/install-global.sh"
fi

validate_installation "$TARGET_DIR" || {
  echo ""
  echo "⚠️  Advertencia: se detectaron problemas post-instalación (revisar arriba)"
}

# ============================================================================
# Resumen final
# ============================================================================

cat <<'EOF'

✅ Bootstrap completo.

📋 Próximos pasos:

  1. COMPLETAR PLACEHOLDERS en CLAUDE.md y AGENT_WORKFLOW.md
     - {{ONE_PARAGRAPH_DESCRIPTION}}: qué es el proyecto en una línea
     - {{STACK_SUMMARY}}: tech stack (Node/React/Python/etc)
     - {{LINT_COMMAND}}, {{TEST_COMMAND}}, {{BUILD_COMMAND}}, {{DEV_COMMAND}}

  2. CONFIGURAR WRITE PATHS del proyecto (opcional)
     Ejecutá: scripts/post-setup.sh
     (Auto-detecta backend/, frontend/, src/ y agrega los Write paths al proyecto)

  3. Si no corriste install-global.sh todavía:
     bash scripts/install-global.sh

EOF

echo ""
echo "Para el siguiente paso interactivo, ejecutá:"
echo "  cd $TARGET_DIR"
echo "  $SOURCE_DIR/scripts/post-setup.sh"
echo ""
