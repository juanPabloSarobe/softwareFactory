#!/usr/bin/env bash
# scripts/lib/install-helpers.sh

# Valida que la instalación básica esté completa
validate_installation() {
  local target_dir="$1"

  if [[ -z "$target_dir" ]]; then
    echo "❌ Error: target_dir no puede estar vacío" >&2
    return 1
  fi

  if [[ ! -d "$target_dir" ]]; then
    echo "❌ Error: $target_dir no es un directorio válido" >&2
    return 1
  fi

  local has_error=0

  echo ""
  echo "🔍 Validación post-instalación:"

  if [[ -f "$target_dir/CLAUDE.md" ]]; then
    if [[ -r "$target_dir/CLAUDE.md" ]]; then
      echo "  ✅ CLAUDE.md existe y es legible"
    else
      echo "  ❌ CLAUDE.md existe pero no es legible"
      has_error=1
    fi
  else
    echo "  ❌ CLAUDE.md no encontrado"
    has_error=1
  fi

  if [[ -f "$target_dir/AGENT_WORKFLOW.md" ]]; then
    echo "  ✅ AGENT_WORKFLOW.md existe"
  else
    echo "  ⚠️  AGENT_WORKFLOW.md no encontrado (opcional pero recomendado)"
  fi

  if [[ -f "$HOME/.claude/settings.json" ]]; then
    echo "  ✅ ~/.claude/settings.json (global) existe"
  else
    echo "  ⚠️  ~/.claude/settings.json no encontrado — ejecutá install-global.sh"
  fi

  return $has_error
}

merge_settings() {
  local template="$1" target="$2"
  [[ -z "${1:-}" ]] && { echo "Error: se requiere template" >&2; return 1; }
  [[ -z "${2:-}" ]] && { echo "Error: se requiere target" >&2; return 1; }

  if [[ ! -f "$target" ]]; then
    cp "$template" "$target"
    echo "  ✅ creado: $target"
    return 0
  fi

  local before_allow before_deny
  before_allow=$(jq '.permissions.allow | length' "$target")
  before_deny=$(jq '.permissions.deny | length' "$target")

  local TMP_FILE
  TMP_FILE=$(mktemp)
  jq -s '
    .[0] as $tmpl | .[1] as $proj |
    ($proj | del(.permissions)) + {
      permissions: {
        allow: ((($tmpl.permissions.allow // []) + ($proj.permissions.allow // [])) | unique),
        ask:   ((($tmpl.permissions.ask   // []) + ($proj.permissions.ask   // [])) | unique),
        deny:  ((($tmpl.permissions.deny  // []) + ($proj.permissions.deny  // [])) | unique)
      }
    }
  ' "$template" "$target" > "$TMP_FILE" && mv "$TMP_FILE" "$target"

  local new_allow new_deny
  new_allow=$(( $(jq '.permissions.allow | length' "$target") - before_allow ))
  new_deny=$(( $(jq '.permissions.deny | length' "$target") - before_deny ))

  if [[ $new_allow -eq 0 && $new_deny -eq 0 ]]; then
    echo "  ✅ ya sincronizado: $target"
  else
    echo "  🔄 sincronizado: $target (+${new_allow} allow, +${new_deny} deny)"
  fi
}
