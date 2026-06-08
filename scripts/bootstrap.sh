#!/usr/bin/env bash
set -euo pipefail

# Instala/actualiza la configuración canónica de Claude Code de la Software
# Factory en un repo de trabajo, sin pisar nada de lo que ya exista ahí.
#
# Uso: scripts/bootstrap.sh <ruta-al-repo-destino> [nombre-del-proyecto]

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:?Uso: bootstrap.sh <ruta-al-repo-destino> [nombre-del-proyecto]}"
PROJECT_NAME="${2:-$(basename "$TARGET_DIR")}"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "El directorio destino no existe: $TARGET_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR/.claude/agents" "$TARGET_DIR/.claude/skills" "$TARGET_DIR/.github/workflows"

copy_if_absent() {
  local src="$1" dest="$2"
  if [[ -e "$dest" ]]; then
    echo "ya existe, se omite: $dest"
  else
    cp -r "$src" "$dest"
    echo "creado:              $dest"
  fi
}

copy_if_absent "$SOURCE_DIR/templates/settings.json.template" "$TARGET_DIR/.claude/settings.json"
copy_if_absent "$SOURCE_DIR/templates/github/workflows/ci.yml" "$TARGET_DIR/.github/workflows/ci.yml"
copy_if_absent "$SOURCE_DIR/templates/github/pull_request_template.md" "$TARGET_DIR/.github/pull_request_template.md"

for f in CLAUDE.md AGENT_WORKFLOW.md; do
  dest="$TARGET_DIR/$f"
  if [[ -e "$dest" ]]; then
    echo "ya existe, se omite: $dest"
  else
    sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$SOURCE_DIR/templates/$f.template" > "$dest"
    echo "creado:              $dest (todavía faltan completar los placeholders {{...}} además de PROJECT_NAME)"
  fi
done

for agent in db-query-agent qa-visual-agent research-agent; do
  copy_if_absent "$SOURCE_DIR/.claude/agents/$agent.md" "$TARGET_DIR/.claude/agents/$agent.md"
done

for skill in qa stop-slop; do
  copy_if_absent "$SOURCE_DIR/.claude/skills/$skill" "$TARGET_DIR/.claude/skills/$skill"
done

cat <<EOF

Listo. Pasos manuales pendientes para $TARGET_DIR:
  1. Completar los placeholders {{...}} que quedaron en CLAUDE.md y AGENT_WORKFLOW.md.
  2. Agregar reglas allow/ask específicas de rutas en .claude/settings.json según
     la estructura real de directorios frontend/backend de este repo (la plantilla
     trae sólo lo genérico).
  3. Instalar las skills que no se pueden vendorizar por motivos de licencia
     (frontend-design, remotion) y configurar los conectores MCP —
     ver docs/external-setup-checklist.md en softwareFactory.
EOF
