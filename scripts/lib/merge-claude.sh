#!/usr/bin/env bash
set -euo pipefail
# scripts/lib/merge-claude.sh

# Detecta si el CLAUDE.md destino es "viejo" (del proyecto original, no mergeado con factory)
is_claude_md_old_format() {
  local file="$1"

  # Heurística: si contiene "This file provides guidance" y NO contiene
  # "Idioma — regla crítica" es probablemente el CLAUDE.md viejo (en inglés/formato anterior)
  if grep -q "This file provides guidance" "$file" && \
     ! grep -q "Idioma — regla crítica" "$file"; then
    return 0  # es viejo
  fi

  # Si contiene "{{PROJECT_NAME}}" o placeholders sin completar, también es candidato a rehacer
  if grep -qF "{{PROJECT_NAME}}" "$file" || \
     grep -qF "{{ONE_PARAGRAPH}}" "$file" || \
     grep -qF "{{STACK_SUMMARY}}" "$file"; then
    return 0
  fi

  return 1  # es moderno/ya mergeado
}

# Propone merge o reemplazo
propose_claude_md_merge() {
  local target_dir="$1"
  local project_name="$2"

  # Validar que SOURCE_DIR esté definida
  if [[ -z "$SOURCE_DIR" ]]; then
    echo "❌ Error: SOURCE_DIR no está definida" >&2
    return 1
  fi

  local template_file="$SOURCE_DIR/templates/CLAUDE.md.template"

  # Validar que el template exista
  if [[ ! -f "$template_file" ]]; then
    echo "❌ Template no encontrado: $template_file" >&2
    return 1
  fi

  local existing_file="$target_dir/CLAUDE.md"

  if [[ ! -f "$existing_file" ]]; then
    # No existe, simplemente copiar template
    # Escapar caracteres especiales en $project_name para sed
    local escaped_name
    escaped_name=$(printf '%s\n' "$project_name" | sed -e 's/[\/&]/\\&/g')
    sed "s/{{PROJECT_NAME}}/$escaped_name/g" "$template_file" > "$existing_file"
    echo "creado (desde template): $existing_file"
    return 0
  fi

  echo ""
  echo "📝 CLAUDE.md ya existe en $target_dir"

  if is_claude_md_old_format "$existing_file"; then
    echo "   Formato detectado: VIEJO (no mergeado con factory)"
    echo ""
    echo "   Opción 1: Reemplazar completamente (perderás comentarios viejos)"
    echo "   Opción 2: Revisar manualmente y mergear a mano"
    echo "   Opción 3: Dejar como está (NO recomendado)"
    echo ""
    read -p "¿Qué hacemos? (1/2/3) " -n 1 -r
    if [[ $? -ne 0 ]]; then
      echo ""
      echo "⚠️  Entrada cancelada" >&2
      return 1
    fi
    echo ""

    # Validar que sea 1, 2 o 3
    if [[ ! "$REPLY" =~ ^[1-3]$ ]]; then
      echo "❌ Opción inválida: '$REPLY' (esperado 1, 2 o 3)" >&2
      return 1
    fi

    case "$REPLY" in
      1)
        cp "$existing_file" "$existing_file.bak"
        # Escapar caracteres especiales en $project_name para sed
        local escaped_name
        escaped_name=$(printf '%s\n' "$project_name" | sed -e 's/[\/&]/\\&/g')
        sed "s/{{PROJECT_NAME}}/$escaped_name/g" "$template_file" > "$existing_file"
        echo "✅ Reemplazado. Backup guardado en: $existing_file.bak"
        return 0
        ;;
      2)
        echo "⏭️  Pendiente manual merge. Ver:"
        echo "    - Template: $template_file"
        echo "    - Existente: $existing_file"
        return 1
        ;;
      3)
        echo "⚠️  Advertencia: CLAUDE.md no está actualizado con factory"
        return 1
        ;;
    esac
  else
    echo "   Formato detectado: MODERNO (ya tiene integración factory)"
    echo "✅ Se mantiene como está"
    return 0
  fi
}
