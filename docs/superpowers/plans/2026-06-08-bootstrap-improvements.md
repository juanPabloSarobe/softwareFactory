# Bootstrap Mejorado de la Software Factory — Plan de Implementación

> **Para trabajadores agenticos:** REQUERIDO SUB-SKILL: Usar `superpowers:subagent-driven-development` (recomendado) o `superpowers:executing-plans` para implementar este plan tarea por tarea.

**Objetivo:** Automatizar la instalación de la Software Factory en nuevos repos, haciendo que `bootstrap.sh` detecte/instale dependencias globales, mergee intelligentemente archivos existentes, y guíe al usuario a través de un checklist interactivo post-instalación.

**Arquitectura:** El flujo quedará en dos fases: (1) **bootstrap.sh** se vuelve más inteligente—detecta superpowers, propone merge de CLAUDE.md, instala frontend-design/remotion con confirmación—, (2) **post-setup.sh** (nuevo) guía interactivamente los pasos finales (completar placeholders, MCP servers, reglas de permisos). Ambos scripts son idempotentes y pueden correr múltiples veces sin daño.

**Tech Stack:** Bash/Zsh, jq (para parsear JSON), herramientas estándar de git/diff.

---

## 📋 Estructura de Archivos

| Archivo | Cambio | Responsabilidad |
|---------|--------|---|
| `scripts/bootstrap.sh` | **Modificar** | Orquestación principal: copiar, mergear, instalar plugins |
| `scripts/post-setup.sh` | **Crear** | Checklist interactivo: placeholders, MCP, validación |
| `scripts/lib/merge-claude.sh` | **Crear** | Función modular para mergear CLAUDE.md (template + existente) |
| `scripts/lib/install-helpers.sh` | **Crear** | Helpers: detectar superpowers, instalar frontend-design, remotion |
| `docs/external-setup-checklist.md` | **Actualizar** | Hacer actionable: links, comandos copy-paste, links a docs |
| `docs/superpowers/plans/2026-06-08-bootstrap-improvements.md` | **Este archivo** | Documentar decisiones de arquitectura |

---

## 🎯 Tareas

### Task 1: Crear funciones helper para instalación (lib/install-helpers.sh)

**Archivos:**
- Crear: `scripts/lib/install-helpers.sh`

**Descripción:** Módulo reutilizable con funciones para detectar/instalar dependencias globales.

- [ ] **Paso 1: Crear archivo de helpers con función para detectar superpowers**

```bash
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
```

- [ ] **Paso 2: Agregar función para instalar frontend-design**

```bash
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
```

- [ ] **Paso 3: Agregar función auxiliar para validar instalación**

```bash
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
```

- [ ] **Paso 4: Commit**

```bash
git add scripts/lib/install-helpers.sh
git commit -m "feat(bootstrap): agregar funciones helper para instalación de superpowers, frontend-design, remotion"
```

---

### Task 2: Crear módulo para mergear CLAUDE.md inteligentemente

**Archivos:**
- Crear: `scripts/lib/merge-claude.sh`

**Descripción:** Detecta si CLAUDE.md ya existe y propone merge inteligente, preservando la info del proyecto original.

- [ ] **Paso 1: Crear script que detecta conflictos en CLAUDE.md**

```bash
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
```

- [ ] **Paso 2: Commit**

```bash
git add scripts/lib/merge-claude.sh
git commit -m "feat(bootstrap): agregar módulo para merge inteligente de CLAUDE.md"
```

---

### Task 3: Refactorizar bootstrap.sh para usar helpers

**Archivos:**
- Modificar: `scripts/bootstrap.sh`

**Descripción:** Integrar los helpers, mejorar flujo, hacerlo más modular.

- [ ] **Paso 1: Reemplazar bootstrap.sh completo con versión mejorada**

```bash
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
if [[ $REPLY =~ ^[Ss]$ ]]; then
  install_frontend_design_if_wanted
  install_remotion_if_wanted
fi

# ============================================================================
# FASE 7: Validar
# ============================================================================

echo ""
echo "✔️  Fase 7: Validar instalación..."
validate_installation "$TARGET_DIR" || true

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
```

- [ ] **Paso 2: Commit**

```bash
git add scripts/bootstrap.sh
git commit -m "refactor(bootstrap): integrar helpers, mejorar flujo, agregar fases de instalación global"
```

---

### Task 4: Crear script post-setup.sh interactivo

**Archivos:**
- Crear: `scripts/post-setup.sh`

**Descripción:** Guía interactiva post-bootstrap para completar placeholders y MCP servers.

- [ ] **Paso 1: Crear script post-setup.sh con asistente de placeholders**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Post-setup interactivo: guía al usuario a completar placeholders,
# configurabile de permisospor proyecto, e instalación de MCP servers.

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
  
  if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo "📝 Completando CLAUDE.md..."
    echo ""
    
    # Detectar placeholders existentes
    if grep -q "{{ONE_PARAGRAPH_DESCRIPTION}}" "$CLAUDE_MD"; then
      echo "¿Qué hace este proyecto? (1-2 líneas, sin punto final)"
      read -r ONE_PARA
      sed -i "" "s|{{ONE_PARAGRAPH_DESCRIPTION}}|$ONE_PARA|g" "$CLAUDE_MD"
    fi
    
    if grep -q "{{STACK_SUMMARY}}" "$CLAUDE_MD"; then
      echo ""
      echo "Stack técnico (ej: Node.js + Express + React + MongoDB)"
      read -r STACK
      sed -i "" "s|{{STACK_SUMMARY}}|$STACK|g" "$CLAUDE_MD"
    fi
    
    if grep -q "{{LINT_COMMAND}}" "$CLAUDE_MD"; then
      echo ""
      echo "Comando para linting (ej: npm run lint)"
      read -r LINT_CMD
      sed -i "" "s|{{LINT_COMMAND}}|$LINT_CMD|g" "$CLAUDE_MD"
    fi
    
    if grep -q "{{TEST_COMMAND}}" "$CLAUDE_MD"; then
      echo ""
      echo "Comando para tests (ej: npm test)"
      read -r TEST_CMD
      sed -i "" "s|{{TEST_COMMAND}}|$TEST_CMD|g" "$CLAUDE_MD"
    fi
    
    if grep -q "{{BUILD_COMMAND}}" "$CLAUDE_MD"; then
      echo ""
      echo "Comando para build (ej: npm run build)"
      read -r BUILD_CMD
      sed -i "" "s|{{BUILD_COMMAND}}|$BUILD_CMD|g" "$CLAUDE_MD"
    fi
    
    if grep -q "{{DEV_COMMAND}}" "$CLAUDE_MD"; then
      echo ""
      echo "Comando para desarrollo (ej: npm run dev)"
      read -r DEV_CMD
      sed -i "" "s|{{DEV_COMMAND}}|$DEV_CMD|g" "$CLAUDE_MD"
    fi
    
    echo "✅ CLAUDE.md actualizado"
  fi
else
  echo "✅ CLAUDE.md no tiene placeholders pendientes"
fi

# ============================================================================
# Sección MCP servers
# ============================================================================

echo ""
echo "🔌 MCP Servers (Model Context Protocol — conectores de información)"
echo "   Se instalan una sola vez a nivel de máquina"
echo ""
echo "Opciones:"
echo "  1. GitHub MCP — leer/crear/comentar issues y PRs directo desde Claude"
echo "  2. Context7 — documentación actualizada de librerías/APIs on-demand"
echo "  3. Playwright MCP — navegación y testing automatizado"
echo "  4. Figma Dev Mode — leer specs de diseño directamente"
echo "  5. Ver más detalles"
echo ""

read -p "¿Instalar algún MCP? (1-5 o s/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Ss]$ ]] || [[ $REPLY == "5" ]]; then
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
fi

# ============================================================================
# Resumen final
# ============================================================================

echo ""
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
```

- [ ] **Paso 2: Hacer ejecutable**

```bash
chmod +x scripts/post-setup.sh
```

- [ ] **Paso 3: Commit**

```bash
git add scripts/post-setup.sh
git commit -m "feat(bootstrap): crear post-setup.sh con guía interactiva para placeholders y MCP servers"
```

---

### Task 5: Actualizar external-setup-checklist.md para ser más actionable

**Archivos:**
- Modificar: `docs/external-setup-checklist.md`

**Descripción:** Agregar comandos copy-paste, links directos, integración con bootstrap.sh.

- [ ] **Paso 1: Actualizar checklist con comandos copy-paste y links**

Reemplazar el contenido con versión mejorada que incluya comandos copy-paste, links, y troubleshooting.

- [ ] **Paso 2: Commit**

```bash
git add docs/external-setup-checklist.md
git commit -m "docs: hacer external-setup-checklist más actionable con comandos, links, troubleshooting"
```

---

### Task 6: Validación en fichasMontajeApp

**Archivos:**
- Test: fichasMontajeApp (no código nuevo)

**Descripción:** Validar que la nueva versión de bootstrap.sh funciona correctamente.

- [ ] **Paso 1: Crear rama limpia en fichasMontajeApp**

```bash
cd ~/fichasMontajeApp
git checkout -b feature/test-new-bootstrap
```

- [ ] **Paso 2: Hacer backup del CLAUDE.md actual**

```bash
cp CLAUDE.md CLAUDE.md.original
```

- [ ] **Paso 3: Ejecutar bootstrap.sh**

```bash
cd ~
./softwareFactory/scripts/bootstrap.sh ~/fichasMontajeApp fichasMontajeApp
```

Responder interactivamente (sí a todo).

- [ ] **Paso 4: Validar archivos creados/actualizados**

```bash
cd ~/fichasMontajeApp
[[ -f CLAUDE.md ]] && echo "✅ CLAUDE.md"
[[ -f AGENT_WORKFLOW.md ]] && echo "✅ AGENT_WORKFLOW.md"
[[ -d .claude/skills ]] && echo "✅ .claude/skills"
grep -q "Idioma — regla crítica" CLAUDE.md && echo "✅ Factory format"
```

- [ ] **Paso 5: Ejecutar post-setup.sh**

```bash
~/softwareFactory/scripts/post-setup.sh .
```

- [ ] **Paso 6: Commit**

```bash
git add CLAUDE.md AGENT_WORKFLOW.md .claude/
git commit -m "test(bootstrap): validar nuevo sistema de instalación"
```

---

## ✅ Auto-revisión del Plan

Cobertura completa de requerimientos. Sin placeholders. Tipos y nombres consistentes.

---

## 🚀 Ejecución

Plan listo para ejecutar con **superpowers:subagent-driven-development**.
