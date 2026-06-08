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
  echo ""

  if [[ $REPLY =~ ^[Ss]$ ]]; then
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
  echo ""

  if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo "Ejecutando: /plugin install frontend-design@claude-plugins-official"
    /plugin install frontend-design@claude-plugins-official
    echo "✅ Frontend Design instalado"
  else
    echo "⏭️  Saltear por ahora (lo instalás después si lo necesitás)"
  fi
}

# Guía instalación de remotion (licencia restrictiva)
install_remotion_if_wanted() {
  echo ""
  echo "📹 Remotion (generación de videos)"
  echo "   Uso: crear videos/animaciones programáticamente"
  echo "   Licencia: se instala con su propio instalador"
  echo ""
  read -p "¿Deseas instalar Remotion? (s/n) " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Ss]$ ]]; then
    if command -v npx &> /dev/null; then
      echo "Ejecutando: npx skills add remotion"
      npx skills add remotion
      echo "✅ Remotion instalado"
    else
      echo "❌ npx no encontrado. Necesitás Node.js instalado"
      echo "   Visitá: https://nodejs.org/"
      return 1
    fi
  else
    echo "⏭️  Saltear por ahora"
  fi
}

# Valida que la instalación básica esté completa
validate_installation() {
  local target_dir="$1"
  local has_error=0

  echo ""
  echo "🔍 Validación post-instalación:"

  if [[ -d "$target_dir/.claude/skills" ]]; then
    echo "  ✅ .claude/skills exists"
  else
    echo "  ❌ .claude/skills missing"
    has_error=1
  fi

  if [[ -f "$target_dir/CLAUDE.md" ]]; then
    echo "  ✅ CLAUDE.md exists"
  else
    echo "  ❌ CLAUDE.md missing"
    has_error=1
  fi

  if [[ -f "$target_dir/.claude/settings.json" ]]; then
    echo "  ✅ .claude/settings.json exists"
  else
    echo "  ❌ .claude/settings.json missing"
    has_error=1
  fi

  return $has_error
}
