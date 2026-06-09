# Global Config por Máquina — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mover la configuración universal de Claude Code (permisos, agentes, skills) de per-proyecto a `~/.claude/` mediante un nuevo script `install-global.sh`, y simplificar `bootstrap.sh` para que solo instale contexto específico del proyecto.

**Architecture:** Se agrega `merge_settings()` a `install-helpers.sh` para hacer union-merge de permisos sin pisar configuración existente. `install-global.sh` usa esa función junto con copias de agentes y skills, y detección de plugins/MCPs. `bootstrap.sh` pierde las fases de settings/skills/agentes y queda enfocado en CLAUDE.md + AGENT_WORKFLOW.md + .github/.

**Tech Stack:** bash, jq (ya requerido), Claude Code CLI (`claude mcp list`)

---

## Mapa de archivos

| Archivo | Acción |
|---------|--------|
| `scripts/lib/install-helpers.sh` | Agregar `merge_settings()` |
| `scripts/lib/test-merge-settings.sh` | Crear — 8 tests TDD |
| `scripts/install-global.sh` | Crear — script principal |
| `scripts/bootstrap.sh` | Modificar — eliminar fases 2(settings)/4/5/6, actualizar fase 1 y validación |

---

### Task 1: `merge_settings()` con TDD

**Files:**
- Create: `scripts/lib/test-merge-settings.sh`
- Modify: `scripts/lib/install-helpers.sh` (agregar al final)

- [ ] **Step 1: Escribir el test file que falla**

Crear `scripts/lib/test-merge-settings.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/install-helpers.sh"

PASS=0
FAIL=0

run_test() {
  local desc="$1" result="$2" expected="$3"
  if [[ "$result" == "$expected" ]]; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc"
    echo "     Esperado: $expected"
    echo "     Obtenido: $result"
    FAIL=$((FAIL + 1))
  fi
}

TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

TEMPLATE="$TMP/template.json"
cat > "$TEMPLATE" <<'TMPL'
{
  "permissions": {
    "allow": ["Read(**)", "Bash(git *)"],
    "ask":   ["Bash(rm *)"],
    "deny":  ["Bash(*sudo*)"]
  }
}
TMPL

# Test 1: target ausente → se crea copiando el template
TARGET1="$TMP/t1/settings.json"
mkdir -p "$(dirname "$TARGET1")"
merge_settings "$TEMPLATE" "$TARGET1"
run_test "target ausente → crea el archivo" \
  "$(test -f "$TARGET1" && echo ok)" "ok"

# Test 2: nuevos allow del template se agregan al target existente
TARGET2="$TMP/t2/settings.json"
mkdir -p "$(dirname "$TARGET2")"
printf '{"permissions":{"allow":["Bash(git *)"],"ask":[],"deny":[]}}' > "$TARGET2"
merge_settings "$TEMPLATE" "$TARGET2"
run_test "nuevos allow del template se agregan" \
  "$(jq '.permissions.allow | contains(["Read(**)", "Bash(git *)"])' "$TARGET2")" "true"

# Test 3: nuevos deny del template se agregan al target
TARGET3="$TMP/t3/settings.json"
mkdir -p "$(dirname "$TARGET3")"
printf '{"permissions":{"allow":[],"ask":[],"deny":[]}}' > "$TARGET3"
merge_settings "$TEMPLATE" "$TARGET3"
run_test "nuevos deny del template se agregan" \
  "$(jq '.permissions.deny | contains(["Bash(*sudo*)"])' "$TARGET3")" "true"

# Test 4: allow ya existentes en el target sobreviven
TARGET4="$TMP/t4/settings.json"
mkdir -p "$(dirname "$TARGET4")"
printf '{"permissions":{"allow":["Read(**)", "Bash(git *)"],"ask":[],"deny":[]}}' > "$TARGET4"
merge_settings "$TEMPLATE" "$TARGET4"
run_test "allow existentes en target sobreviven" \
  "$(jq '.permissions.allow | contains(["Read(**)", "Bash(git *)"])' "$TARGET4")" "true"

# Test 5: allow custom del target (no en template) sobreviven
TARGET5="$TMP/t5/settings.json"
mkdir -p "$(dirname "$TARGET5")"
printf '{"permissions":{"allow":["Write(src/**)"],"ask":[],"deny":[]}}' > "$TARGET5"
merge_settings "$TEMPLATE" "$TARGET5"
run_test "allow custom del target sobreviven" \
  "$(jq '.permissions.allow | contains(["Write(src/**)"])' "$TARGET5")" "true"

# Test 6: idempotente — segunda corrida no cambia el contenido
TARGET6="$TMP/t6/settings.json"
mkdir -p "$(dirname "$TARGET6")"
cp "$TEMPLATE" "$TARGET6"
merge_settings "$TEMPLATE" "$TARGET6" >/dev/null
CONTENT1=$(jq -S . "$TARGET6")
merge_settings "$TEMPLATE" "$TARGET6" >/dev/null
CONTENT2=$(jq -S . "$TARGET6")
run_test "idempotente: segunda corrida no cambia nada" "$CONTENT1" "$CONTENT2"

# Test 7: campos no-permissions del target sobreviven (env y hooks)
TARGET7="$TMP/t7/settings.json"
mkdir -p "$(dirname "$TARGET7")"
printf '{"permissions":{"allow":[],"ask":[],"deny":[]},"env":{"MY_VAR":"hello"}}' > "$TARGET7"
merge_settings "$TEMPLATE" "$TARGET7"
run_test "env del target sobrevive" \
  "$(jq '.env.MY_VAR' "$TARGET7")" '"hello"'

# Test 8: no se crean duplicados si el permiso está en template y target
TARGET8="$TMP/t8/settings.json"
mkdir -p "$(dirname "$TARGET8")"
cp "$TEMPLATE" "$TARGET8"
merge_settings "$TEMPLATE" "$TARGET8"
run_test "no se crean duplicados en allow" \
  "$(jq '.permissions.allow | length' "$TARGET8")" \
  "$(jq '.permissions.allow | length' "$TEMPLATE")"

echo ""
echo "Resultados: $PASS ✅  $FAIL ❌"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
```

- [ ] **Step 2: Verificar que el test falla (merge_settings no existe aún)**

```bash
bash scripts/lib/test-merge-settings.sh
```

Expected: error `merge_settings: command not found` o similar — FAIL confirmado.

- [ ] **Step 3: Implementar `merge_settings()` en `install-helpers.sh`**

Agregar al final de `scripts/lib/install-helpers.sh`:

```bash
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
```

- [ ] **Step 4: Correr los tests y verificar que pasan**

```bash
bash scripts/lib/test-merge-settings.sh
```

Expected:
```
  ✅ target ausente → crea el archivo
  ✅ nuevos allow del template se agregan
  ✅ nuevos deny del template se agregan
  ✅ allow existentes en target sobreviven
  ✅ allow custom del target sobreviven
  ✅ idempotente: segunda corrida no cambia nada
  ✅ env del target sobrevive
  ✅ no se crean duplicados en allow

Resultados: 8 ✅  0 ❌
```

- [ ] **Step 5: Commit**

```bash
git add scripts/lib/install-helpers.sh scripts/lib/test-merge-settings.sh
git commit -m "feat(lib): agregar merge_settings() con 8 tests TDD"
```

---

### Task 2: Crear `scripts/install-global.sh`

**Files:**
- Create: `scripts/install-global.sh`

- [ ] **Step 1: Crear el script**

```bash
#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SOURCE_DIR/scripts/lib/install-helpers.sh"

echo ""
echo "🌐 Instalación global de Software Factory"
echo "   Destino: ~/.claude/"
echo ""

mkdir -p "$HOME/.claude/agents" "$HOME/.claude/skills"

# ── Permisos ──────────────────────────────────────────────────────────────────
echo "📋 Permisos"
merge_settings "$SOURCE_DIR/templates/settings.json.template" "$HOME/.claude/settings.json"
echo ""

# ── Agentes ───────────────────────────────────────────────────────────────────
echo "👤 Agentes"
for agent in db-query-agent qa-visual-agent research-agent; do
  if [[ -f "$HOME/.claude/agents/$agent.md" ]]; then
    cp "$SOURCE_DIR/.claude/agents/$agent.md" "$HOME/.claude/agents/$agent.md"
    echo "  🔄 actualizado: $agent.md"
  else
    cp "$SOURCE_DIR/.claude/agents/$agent.md" "$HOME/.claude/agents/$agent.md"
    echo "  ✅ instalado: $agent.md"
  fi
done
echo ""

# ── Skills vendorizadas ───────────────────────────────────────────────────────
echo "🛠️  Skills vendorizadas"
for skill in qa stop-slop; do
  if [[ -d "$HOME/.claude/skills/$skill" ]]; then
    rm -rf "$HOME/.claude/skills/$skill"
    cp -r "$SOURCE_DIR/.claude/skills/$skill" "$HOME/.claude/skills/$skill"
    echo "  🔄 actualizado: $skill/"
  else
    cp -r "$SOURCE_DIR/.claude/skills/$skill" "$HOME/.claude/skills/$skill"
    echo "  ✅ instalado: $skill/"
  fi
done
echo ""

# ── Plugins (no se pueden instalar desde bash) ────────────────────────────────
echo "🔌 Plugins (requieren Claude Code para instalar)"
if [[ -d "$HOME/.claude/plugins/cache/claude-plugins-official/superpowers" ]]; then
  echo "  ✅ Superpowers instalado"
else
  echo "  ⚠️  Superpowers no instalado (requerido)"
  echo "     → Dentro de Claude Code: /plugin install superpowers@claude-plugins-official"
fi

if [[ -d "$HOME/.claude/plugins/cache/claude-plugins-official/frontend-design" ]]; then
  echo "  ✅ frontend-design instalado"
else
  echo "  ℹ️  frontend-design no instalado (opcional)"
  echo "     → Dentro de Claude Code: /plugin install frontend-design@claude-plugins-official"
fi

if [[ -d "$HOME/.claude/plugins/cache/claude-plugins-official/remotion" ]]; then
  echo "  ✅ remotion instalado"
else
  echo "  ℹ️  remotion no instalado (opcional)"
  echo "     → Dentro de Claude Code: /plugin install remotion@claude-plugins-official"
fi
echo ""

# ── MCP servers ───────────────────────────────────────────────────────────────
echo "🌐 MCP servers"
if command -v claude &>/dev/null && claude mcp list 2>/dev/null | grep -q "context7"; then
  echo "  ✅ context7 configurado"
else
  echo "  ⚠️  context7 no configurado"
  echo "     → claude mcp add context7 -- npx -y @upstash/context7-mcp"
fi

if command -v claude &>/dev/null && claude mcp list 2>/dev/null | grep -q "playwright"; then
  echo "  ✅ playwright configurado"
else
  echo "  ⚠️  playwright no configurado"
  echo "     → claude mcp add playwright -- npx @playwright/mcp@latest"
fi

echo "  ℹ️  Gmail / Google Calendar: configurar desde claude.ai/settings"
echo ""

echo "✅ Instalación global completa."
echo ""
echo "Para proyectos nuevos:"
echo "  bash scripts/bootstrap.sh <ruta-al-proyecto>"
echo ""
echo "Para actualizar en otra máquina:"
echo "  git pull && bash scripts/install-global.sh"
echo ""
```

- [ ] **Step 2: Hacerlo ejecutable**

```bash
chmod +x scripts/install-global.sh
```

- [ ] **Step 3: Smoke test — primera corrida**

```bash
bash scripts/install-global.sh
```

Expected: output con secciones Permisos / Agentes / Skills / Plugins / MCP servers, sin errores.

- [ ] **Step 4: Smoke test — segunda corrida (idempotencia)**

```bash
bash scripts/install-global.sh
```

Expected: todas las líneas dicen `✅ ya sincronizado` o `🔄 actualizado` para agentes/skills (siempre sobreescriben, no hay estado "ya actualizado" para archivos).
Sin errores. Sin permisos nuevos agregados (0 allow, 0 deny).

- [ ] **Step 5: Verificar que `~/.claude/settings.json` tiene todos los permisos**

```bash
jq '.permissions.allow | length' ~/.claude/settings.json
```

Expected: mismo número que `jq '.permissions.allow | length' templates/settings.json.template`

- [ ] **Step 6: Commit**

```bash
git add scripts/install-global.sh
git commit -m "feat: agregar install-global.sh para configuración por máquina"
```

---

### Task 3: Simplificar `scripts/bootstrap.sh`

**Files:**
- Modify: `scripts/bootstrap.sh`
- Modify: `scripts/lib/install-helpers.sh` (actualizar `validate_installation`)

- [ ] **Step 1: Editar `bootstrap.sh` — eliminar fases que se mueven a global**

Cambios exactos a aplicar:

**Línea 33** — quitar `agents` y `skills` del mkdir (solo necesitamos `.claude` para el settings.json mínimo del proyecto):
```bash
# Antes:
mkdir -p "$TARGET_DIR/.claude/agents" "$TARGET_DIR/.claude/skills" "$TARGET_DIR/.github/workflows"

# Después:
mkdir -p "$TARGET_DIR/.claude" "$TARGET_DIR/.github/workflows"
```

**Línea 52** — eliminar la copia de settings.json (ya no se instala por proyecto):
```bash
# Eliminar esta línea:
copy_if_absent "$SOURCE_DIR/templates/settings.json.template" "$TARGET_DIR/.claude/settings.json"
```

**Fases 4 y 5 completas** — eliminar las secciones de skills y agentes (líneas 74-93):
```bash
# Eliminar todo este bloque:
# FASE 4: Vendorizar skills locales
echo ""
echo "🛠️  Fase 4: Vendorizar skills locales..."
for skill in qa stop-slop; do
  copy_if_absent "$SOURCE_DIR/.claude/skills/$skill" "$TARGET_DIR/.claude/skills/$skill"
done

# FASE 5: Vendorizar agentes
echo ""
echo "👤 Fase 5: Vendorizar agentes..."
for agent in db-query-agent qa-visual-agent research-agent; do
  copy_if_absent "$SOURCE_DIR/.claude/agents/$agent.md" "$TARGET_DIR/.claude/agents/$agent.md"
done
```

**Fase 6 completa** — eliminar la detección/instalación de Superpowers/frontend-design/remotion (líneas 96-123):
```bash
# Eliminar todo el bloque de Fase 6 (Detectar/instalar dependencias globales)
```

**Fase 7 → renombrar a Fase 4**, y agregar validación de instalación global antes:
```bash
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
```

**Resumen final** — actualizar el mensaje para reflejar el nuevo flujo:
```bash
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
```

- [ ] **Step 2: Actualizar `validate_installation()` en `install-helpers.sh`**

La función actualmente valida `.claude/skills`, `CLAUDE.md` y `.claude/settings.json`. Después del cambio, `settings.json` por proyecto es opcional y `.claude/skills` ya no existe en el proyecto. Actualizar:

```bash
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
```

- [ ] **Step 3: Eliminar funciones interactivas obsoletas de `install-helpers.sh`**

Las funciones `install_superpowers_if_needed`, `install_frontend_design_if_wanted` e
`install_remotion_if_wanted` quedaron sin uso al eliminar Fase 6 de bootstrap.sh
(la lógica de detección vive ahora en `install-global.sh`). Eliminar las tres
funciones de `scripts/lib/install-helpers.sh`.

Las funciones a eliminar ocupan las líneas 14-114 aproximadamente (desde
`install_superpowers_if_needed()` hasta el cierre de `install_remotion_if_wanted()`).
Verificar visualmente los límites exactos antes de eliminar.

- [ ] **Step 4: Verificar que bootstrap.sh es sintácticamente válido**

```bash
bash -n scripts/bootstrap.sh
```

Expected: sin output (sin errores de sintaxis).

- [ ] **Step 5: Smoke test — correr bootstrap en directorio temporal**

```bash
TMP_PROJ=$(mktemp -d)
bash scripts/bootstrap.sh "$TMP_PROJ" test-proyecto
ls "$TMP_PROJ"
ls "$TMP_PROJ/.claude"
rm -rf "$TMP_PROJ"
```

Expected:
- `CLAUDE.md`, `AGENT_WORKFLOW.md`, `POSTINSTALL_CHECKLIST.md` presentes
- `.claude/` existe (para settings.json futuro de post-setup)
- NO hay `.claude/skills/` ni `.claude/agents/` (ya no se crean)
- `.github/workflows/ci.yml` presente

- [ ] **Step 6: Commit**

```bash
git add scripts/bootstrap.sh scripts/lib/install-helpers.sh
git commit -m "refactor(bootstrap): mover settings/skills/agentes a install-global.sh"
```

---

## Verificación final

- [ ] Correr todos los tests:

```bash
bash scripts/lib/test-merge-settings.sh
bash scripts/lib/test-project-permissions.sh
```

Expected: todos pasan (0 ❌).

- [ ] Correr `install-global.sh` una vez más para confirmar idempotencia post-cambios:

```bash
bash scripts/install-global.sh
```

Expected: `✅ ya sincronizado: ~/.claude/settings.json` (0 permisos nuevos).

- [ ] Verificar que `fichasMontajeApp` sigue funcionando sin settings.json propio de permisos:

```bash
jq '.permissions.allow | length' ~/.claude/settings.json
```

Expected: ≥ 100 entradas (cubriendo todo lo que antes tenía el proyecto).
