#!/usr/bin/env bash
# scripts/lib/install-helpers.sh

# Detecta si Superpowers está instalado globalmente
check_superpowers_installed() {
  if [[ -d "$HOME/.claude/plugins/cache/claude-plugins-official/superpowers" ]]; then
    return 0
  else
    return 1
  fi
}

# Guía la instalación interactiva de Superpowers si no existe
install_superpowers_if_needed() {
  if check_superpowers_installed; then
    echo "✅ Superpowers ya instalado globalmente"
    return 0
  fi

  echo ""
  echo "⚠️  Superpowers NO está instalado globalmente"
  echo ""
  echo "Superpowers es la base del flujo de trabajo de la factory."
  echo "Se instala una sola vez a nivel de máquina, no por proyecto."
  echo ""
  read -p "¿Deseas instalar Superpowers ahora? (s/n) " -n 1 -r
  if [[ $? -ne 0 ]]; then
    echo ""
    echo "⚠️  Entrada cancelada" >&2
    return 1
  fi
  echo ""

  if [[ $REPLY =~ ^[Ss]$ ]]; then
    if ! command -v /plugin &> /dev/null; then
      echo "❌ Error: Claude Code plugin manager no está disponible" >&2
      echo "   ¿Estás dentro de Claude Code? Visitá: https://claude.com/claude-code" >&2
      return 1
    fi
    echo "Ejecutando: /plugin install superpowers@claude-plugins-official"
    /plugin install superpowers@claude-plugins-official
    if check_superpowers_installed; then
      echo "✅ Superpowers instalado exitosamente"
      return 0
    else
      echo "❌ Falló la instalación. Visitá: https://github.com/obra/superpowers"
      return 1
    fi
  else
    echo "⚠️  Superpowers es necesario para el flujo completo."
    return 1
  fi
}

# Guía instalación de frontend-design (no se puede vendorizar por licencia)
install_frontend_design_if_wanted() {
  echo ""
  echo "📦 Frontend Design (skill oficial de Anthropic)"
  echo "   Uso: revisión visual de diseños, auditoría de accesibilidad"
  echo "   Licencia: no se puede vendorizar, se instala desde marketplace"
  echo ""
  read -p "¿Deseas instalar frontend-design? (s/n) " -n 1 -r
  if [[ $? -ne 0 ]]; then
    echo ""
    echo "⚠️  Entrada cancelada" >&2
    return 1
  fi
  echo ""

  if [[ $REPLY =~ ^[Ss]$ ]]; then
    if ! command -v /plugin &> /dev/null; then
      echo "❌ Error: Claude Code plugin manager no está disponible" >&2
      echo "   ¿Estás dentro de Claude Code? Visitá: https://claude.com/claude-code" >&2
      return 1
    fi
    echo "Ejecutando: /plugin install frontend-design@claude-plugins-official"
    /plugin install frontend-design@claude-plugins-official
    echo "✅ Frontend Design instalado"
  else
    echo "⏭️  Saltear por ahora (lo instalás después si lo necesitás)"
  fi
}

# Guía instalación de remotion (licencia restrictiva)
install_remotion_if_wanted() {
  # Detectar si Node.js está disponible
  if ! command -v npx &> /dev/null; then
    echo ""
    echo "⏭️  Remotion requiere Node.js + npx"
    echo "   No encontrado. Visitá: https://nodejs.org/"
    return 0
  fi

  echo ""
  echo "📹 Remotion (generación de videos)"
  echo "   Uso: crear videos/animaciones programáticamente"
  echo "   Licencia: se instala con su propio instalador"
  echo ""
  read -p "¿Deseas instalar Remotion? (s/n) " -n 1 -r
  if [[ $? -ne 0 ]]; then
    echo ""
    echo "⚠️  Entrada cancelada" >&2
    return 1
  fi
  echo ""

  if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo "Ejecutando: npx skills add remotion"
    npx skills add remotion
    echo "✅ Remotion instalado"
  else
    echo "⏭️  Saltear por ahora"
  fi
}

# Valida que la instalación básica esté completa
validate_installation() {
  local target_dir="$1"

  # Validar que target_dir sea proporcionado y sea un directorio válido
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

  if [[ -d "$target_dir/.claude/skills" ]]; then
    if [[ -r "$target_dir/.claude/skills" ]]; then
      echo "  ✅ .claude/skills exists and readable"
    else
      echo "  ❌ .claude/skills exists but not readable"
      has_error=1
    fi
  else
    echo "  ❌ .claude/skills missing"
    has_error=1
  fi

  if [[ -f "$target_dir/CLAUDE.md" ]]; then
    if [[ -r "$target_dir/CLAUDE.md" ]]; then
      echo "  ✅ CLAUDE.md exists and readable"
    else
      echo "  ❌ CLAUDE.md exists but not readable"
      has_error=1
    fi
  else
    echo "  ❌ CLAUDE.md missing"
    has_error=1
  fi

  if [[ -f "$target_dir/.claude/settings.json" ]]; then
    if [[ -r "$target_dir/.claude/settings.json" ]]; then
      echo "  ✅ .claude/settings.json exists and readable"
    else
      echo "  ❌ .claude/settings.json exists but not readable"
      has_error=1
    fi
  else
    echo "  ❌ .claude/settings.json missing"
    has_error=1
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
