#!/usr/bin/env bash
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
  if grep -q "{{PROJECT_NAME}}\|{{ONE_PARAGRAPH}}\|{{STACK_SUMMARY}}" "$file"; then
    return 0
  fi

  return 1  # es moderno/ya mergeado
}

# Propone merge o reemplazo
propose_claude_md_merge() {
  local target_dir="$1"
  local project_name="$2"
  local template_file="$SOURCE_DIR/templates/CLAUDE.md.template"
  local existing_file="$target_dir/CLAUDE.md"

  if [[ ! -f "$existing_file" ]]; then
    # No existe, simplemente copiar template
    sed "s/{{PROJECT_NAME}}/$project_name/g" "$template_file" > "$existing_file"
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

    case "$REPLY" in
      1)
        cp "$existing_file" "$existing_file.bak"
        sed "s/{{PROJECT_NAME}}/$project_name/g" "$template_file" > "$existing_file"
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
