# Factory: Permisos Universales + Wizard Write Paths + Postinstall Checklist

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que cada proyecto nuevo instalado con el factory pueda completar un ciclo completo (brainstorming → plan → implementación → QA visual → finishing branch) sin ninguna interrupción por permisos, salvo decisiones reales del owner.

**Architecture:** Tres capas: (1) `settings.json.template` con todos los permisos invariantes pre-aprobados, (2) wizard híbrido en `post-setup.sh` que auto-detecta Write paths proyecto-específicos, (3) `POSTINSTALL_CHECKLIST.md` que documenta lo no automatizable y se copia a cada proyecto en el bootstrap.

**Tech Stack:** bash, jq (ya disponible en el entorno), JSON templates

**Spec de referencia:** `docs/superpowers/specs/2026-06-08-factory-permisos-universales-wizard-postinstall-design.md`

---

## Mapa de archivos

| Archivo | Acción | Responsabilidad |
|---------|--------|-----------------|
| `templates/settings.json.template` | Modificar | Permisos genéricos pre-aprobados para todos los proyectos |
| `templates/POSTINSTALL_CHECKLIST.md.template` | Crear | Instrucciones no-automatizables que se copian a cada proyecto |
| `scripts/bootstrap.sh` | Modificar | Copiar POSTINSTALL_CHECKLIST.md al proyecto destino |
| `scripts/lib/project-permissions.sh` | Crear | Funciones de detección de estructura del proyecto (testables) |
| `scripts/post-setup.sh` | Modificar | Integrar wizard de Write paths y detección de dev server |

---

## Task 1: Playwright MCP en settings.json.template

**Files:**
- Modify: `templates/settings.json.template`

- [ ] **Step 1: Escribir el test que falla**

```bash
jq -e '
  [.permissions.allow[] | select(startswith("mcp__plugin_playwright_playwright__browser_"))] | length == 22
' templates/settings.json.template
```

Resultado esperado: `false` o error (las tools no están todavía).

- [ ] **Step 2: Agregar las 22 tools de Playwright a `allow` y `browser_run_code_unsafe` a `deny`**

Abrir `templates/settings.json.template`. En el array `permissions.allow`, agregar después de la última línea existente (antes del cierre `]`):

```json
"mcp__plugin_playwright_playwright__browser_navigate",
"mcp__plugin_playwright_playwright__browser_snapshot",
"mcp__plugin_playwright_playwright__browser_click",
"mcp__plugin_playwright_playwright__browser_type",
"mcp__plugin_playwright_playwright__browser_fill_form",
"mcp__plugin_playwright_playwright__browser_hover",
"mcp__plugin_playwright_playwright__browser_press_key",
"mcp__plugin_playwright_playwright__browser_select_option",
"mcp__plugin_playwright_playwright__browser_take_screenshot",
"mcp__plugin_playwright_playwright__browser_wait_for",
"mcp__plugin_playwright_playwright__browser_handle_dialog",
"mcp__plugin_playwright_playwright__browser_console_messages",
"mcp__plugin_playwright_playwright__browser_network_requests",
"mcp__plugin_playwright_playwright__browser_network_request",
"mcp__plugin_playwright_playwright__browser_evaluate",
"mcp__plugin_playwright_playwright__browser_navigate_back",
"mcp__plugin_playwright_playwright__browser_resize",
"mcp__plugin_playwright_playwright__browser_tabs",
"mcp__plugin_playwright_playwright__browser_close",
"mcp__plugin_playwright_playwright__browser_drag",
"mcp__plugin_playwright_playwright__browser_drop",
"mcp__plugin_playwright_playwright__browser_file_upload"
```

En el array `permissions.deny`, agregar:
```json
"mcp__plugin_playwright_playwright__browser_run_code_unsafe"
```

- [ ] **Step 3: Verificar que el test pasa**

```bash
jq -e '
  [.permissions.allow[] | select(startswith("mcp__plugin_playwright_playwright__browser_"))] | length == 22
' templates/settings.json.template && echo "allow: OK"

jq -e '
  .permissions.deny | contains(["mcp__plugin_playwright_playwright__browser_run_code_unsafe"])
' templates/settings.json.template && echo "deny: OK"
```

Resultado esperado: `true` en ambos + los dos "OK".

- [ ] **Step 4: Validar que el JSON completo sigue siendo válido**

```bash
jq -e '.' templates/settings.json.template > /dev/null && echo "JSON válido"
```

- [ ] **Step 5: Commit**

```bash
git add templates/settings.json.template
git commit -m "feat(template): pre-aprobar 22 tools de Playwright MCP en settings"
```

---

## Task 2: Context7, Gmail, Calendar, bash patterns e hidden dirs en settings.json.template

**Files:**
- Modify: `templates/settings.json.template`

- [ ] **Step 1: Escribir el test que falla**

```bash
jq -e '
  .permissions.allow | contains([
    "mcp__plugin_context7_context7__resolve-library-id",
    "mcp__plugin_context7_context7__query-docs",
    "mcp__claude_ai_Gmail__authenticate",
    "mcp__claude_ai_Google_Calendar__authenticate",
    "Bash(python *)",
    "Bash(npx *)",
    "Bash(curl *)",
    "Read(.claude/**)"
  ])
' templates/settings.json.template
```

Resultado esperado: `false` (ninguna de estas entradas existe todavía).

- [ ] **Step 2: Agregar Context7 y MCPs de Gmail/Calendar a `allow`**

En `permissions.allow`, agregar:

```json
"mcp__plugin_context7_context7__resolve-library-id",
"mcp__plugin_context7_context7__query-docs",
"mcp__claude_ai_Gmail__authenticate",
"mcp__claude_ai_Gmail__complete_authentication",
"mcp__claude_ai_Google_Calendar__authenticate",
"mcp__claude_ai_Google_Calendar__complete_authentication"
```

- [ ] **Step 3: Agregar bash patterns faltantes a `allow`**

En `permissions.allow`, agregar:

```json
"Bash(npm test *)",
"Bash(npm test)",
"Bash(node --check *)",
"Bash(lsof *)",
"Bash(claude mcp list)",
"Bash(npx *)",
"Bash(curl *)",
"Bash(python *)",
"Bash(python3 *)",
"Bash(pytest *)",
"Bash(uv run *)",
"Bash(ruff *)",
"Bash(black *)",
"Bash(mypy *)"
```

- [ ] **Step 4: Agregar bash patterns de instalación Python a `ask`**

En `permissions.ask` (ya existe con `Bash(rm *)`, `Bash(npm install*)`, etc.), agregar:

```json
"Bash(pip install *)",
"Bash(uv add *)",
"Bash(poetry add *)"
```

- [ ] **Step 5: Agregar lectura explícita de hidden dirs a `allow`**

En `permissions.allow`, agregar:

```json
"Read(.claude/**)",
"Read(.github/**)"
```

- [ ] **Step 6: Verificar que el test pasa**

```bash
jq -e '
  .permissions.allow | contains([
    "mcp__plugin_context7_context7__resolve-library-id",
    "mcp__plugin_context7_context7__query-docs",
    "mcp__claude_ai_Gmail__authenticate",
    "mcp__claude_ai_Google_Calendar__authenticate",
    "Bash(python *)",
    "Bash(npx *)",
    "Bash(curl *)",
    "Read(.claude/**)"
  ])
' templates/settings.json.template && echo "allow: OK"

jq -e '
  .permissions.ask | contains(["Bash(pip install *)"])
' templates/settings.json.template && echo "ask: OK"
```

Resultado esperado: `true` en ambos + los dos "OK".

- [ ] **Step 7: Verificar count total (referencia: >= 80 entradas)**

```bash
jq '.permissions.allow | length' templates/settings.json.template
```

- [ ] **Step 8: Validar JSON completo**

```bash
jq -e '.' templates/settings.json.template > /dev/null && echo "JSON válido"
```

- [ ] **Step 9: Commit**

```bash
git add templates/settings.json.template
git commit -m "feat(template): pre-aprobar context7, Gmail, Calendar, Python, bash patterns y hidden dirs"
```

---

## Task 3: POSTINSTALL_CHECKLIST.md.template + bootstrap.sh

**Files:**
- Create: `templates/POSTINSTALL_CHECKLIST.md.template`
- Modify: `scripts/bootstrap.sh`

- [ ] **Step 1: Escribir el test de bootstrap que falla**

```bash
tmp=$(mktemp -d)
git init "$tmp" > /dev/null
bash scripts/bootstrap.sh "$tmp" test-project > /dev/null 2>&1
test -f "$tmp/POSTINSTALL_CHECKLIST.md" && echo "PASS" || echo "FAIL — archivo no creado"
rm -rf "$tmp"
```

Resultado esperado: `FAIL — archivo no creado`.

- [ ] **Step 2: Crear `templates/POSTINSTALL_CHECKLIST.md.template`**

Crear el archivo con este contenido exacto:

```markdown
# Checklist post-instalación de Software Factory

> Ejecutar este checklist **una sola vez, justo después de instalar la factory**,
> para asegurarte de que el entorno está listo para flujos autónomos.

---

## 0. Qué hizo el bootstrap automáticamente

El `settings.json` del proyecto ya tiene pre-aprobados:

- **Playwright MCP** (22 tools) — qa-visual-agent corre sin interrupciones
- **Context7 MCP** — docs de librerías en brainstorming y writing-plans
- **Gmail y Google Calendar MCP** — flujos de autenticación
- **Python** — python, python3, pytest, uv run, ruff, black, mypy
- **npm extendido** — npm test, npm test *, npx *, node --check *
- **curl, lsof** — health checks y diagnóstico de puertos
- **Directorios ocultos** — lectura de .claude/ y .github/
- **Write paths del proyecto** — configurados por el wizard de post-setup.sh

No se requiere acción. Esta sección es solo documentación de estado inicial.

---

## 1. Infraestructura de testing frontend [VERIFICAR]

Si el proyecto usa React/Vue/Svelte, verificar que haya framework de test configurado.

```bash
cat frontend/package.json | jq '.devDependencies | keys | map(select(test("vitest|jest"))) | length > 0'
```

Si devuelve `false`:

```bash
npm install --save-dev vitest @testing-library/react @testing-library/jest-dom jsdom --prefix frontend
```

Agregar a `frontend/vite.config.js`:
```js
test: {
  environment: 'jsdom',
  globals: true,
  setupFiles: './src/test-setup.js'
}
```

**Sin esto:** TDD no funciona en frontend. El agente documenta la desviación y valida solo por QA visual — funciona, pero es deuda técnica.

---

## 2. Conflicto eval/gstack [DECISIÓN DEL OWNER]

Los scripts internos de gstack usan `eval "$(gstack-slug)"`. La regla `"Bash(*eval*)"` en `deny` los bloquea silenciosamente.

**Estado actual:** los scripts de telemetría de gstack fallan, pero el flujo principal de trabajo funciona.

**Opción A (default):** dejarlo como está. Impacto: solo falla la telemetría de gstack.

**Opción B:** cambiar `"Bash(*eval*)"` por reglas más específicas:
```json
"Bash(eval $(*))",
"Bash(eval \"*\")"
```
Esto bloquea `eval` con expresiones arbitrarias pero permite `eval "$(gstack-slug)"`.

**Decisión tomada:** [ ] Opción A &nbsp;&nbsp; [ ] Opción B &nbsp;&nbsp; Fecha: ___

---

## 3. Ritual post-primera-sesión [EJECUTAR]

Después de la primera sesión de trabajo real:

```
/fewer-permission-prompts
```

Esto escanea los transcripts y propone permisos basados en uso real, cubriendo patrones que el template genérico no puede prever.

**Repetir** cada vez que se agregue una skill nueva al proyecto.

---

## 4. Smoke test de entorno [VERIFICAR]

Correr antes del primer sprint:

```bash
# Servidores
npm run dev &
sleep 5
curl -s http://localhost:3000/health | jq .   # ajustar puerto según el proyecto
curl -s http://localhost:5173 | head -5

# Tests
npm test

# Lint
npm run lint

# Permisos — esperado: >= 80 entradas
cat .claude/settings.json | jq '.permissions.allow | length'
```

---

## 5. Historial

| Fecha | Qué pasó | Resolución |
|-------|----------|-----------|
| | | |
```

- [ ] **Step 3: Agregar `copy_if_absent` del checklist en `scripts/bootstrap.sh`**

En `bootstrap.sh`, después de la línea que copia `settings.json.template` (Fase 2), agregar:

```bash
copy_if_absent "$SOURCE_DIR/templates/POSTINSTALL_CHECKLIST.md.template" "$TARGET_DIR/POSTINSTALL_CHECKLIST.md"
```

La sección de Fase 2 quedará así:

```bash
copy_if_absent "$SOURCE_DIR/templates/settings.json.template" "$TARGET_DIR/.claude/settings.json"
copy_if_absent "$SOURCE_DIR/templates/POSTINSTALL_CHECKLIST.md.template" "$TARGET_DIR/POSTINSTALL_CHECKLIST.md"
copy_if_absent "$SOURCE_DIR/templates/github/workflows/ci.yml" "$TARGET_DIR/.github/workflows/ci.yml"
copy_if_absent "$SOURCE_DIR/templates/github/pull_request_template.md" "$TARGET_DIR/.github/pull_request_template.md"
```

- [ ] **Step 4: Verificar sintaxis de bootstrap.sh**

```bash
bash -n scripts/bootstrap.sh && echo "Sintaxis OK"
```

- [ ] **Step 5: Correr el test de bootstrap**

```bash
tmp=$(mktemp -d)
git init "$tmp" > /dev/null
bash scripts/bootstrap.sh "$tmp" test-project > /dev/null 2>&1
test -f "$tmp/POSTINSTALL_CHECKLIST.md" && echo "PASS" || echo "FAIL"
rm -rf "$tmp"
```

Resultado esperado: `PASS`.

- [ ] **Step 6: Commit**

```bash
git add templates/POSTINSTALL_CHECKLIST.md.template scripts/bootstrap.sh
git commit -m "feat(bootstrap): agregar POSTINSTALL_CHECKLIST.md.template y copiarlo en bootstrap"
```

---

## Task 4: scripts/lib/project-permissions.sh — funciones de detección

**Files:**
- Create: `scripts/lib/project-permissions.sh`

- [ ] **Step 1: Escribir el test que falla**

Crear el archivo de test `scripts/lib/test-project-permissions.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/project-permissions.sh" 2>/dev/null || { echo "FAIL — project-permissions.sh no existe"; exit 1; }

PASS=0
FAIL=0

run_test() {
  local desc="$1"
  local result="$2"
  local expected="$3"
  if [[ "$result" == "$expected" ]]; then
    echo "  ✅ $desc"
    ((PASS++))
  else
    echo "  ❌ $desc"
    echo "     Esperado: $expected"
    echo "     Obtenido: $result"
    ((FAIL++))
  fi
}

# Fixtures
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

# Test 1: monorepo con backend/src y frontend/src y frontend/e2e
mkdir -p "$TMP/t1/backend/src" "$TMP/t1/frontend/src" "$TMP/t1/frontend/e2e"
result=$(detect_write_paths "$TMP/t1")
run_test "monorepo completo incluye backend/src" "$(echo "$result" | grep -c "Write(backend/src/\*\*)")" "1"
run_test "monorepo completo incluye frontend/src" "$(echo "$result" | grep -c "Write(frontend/src/\*\*)")" "1"
run_test "monorepo completo incluye frontend/e2e" "$(echo "$result" | grep -c "Write(frontend/e2e/\*\*)")" "1"

# Test 2: single-app con solo src/
mkdir -p "$TMP/t2/src"
result=$(detect_write_paths "$TMP/t2")
run_test "single-app detecta Write(src/**)" "$(echo "$result" | grep -c "Write(src/\*\*)")" "1"
run_test "single-app no propone backend" "$(echo "$result" | grep -c "Write(backend")" "0"

# Test 3: backend sin src/ (usa backend/**)
mkdir -p "$TMP/t3/backend"
result=$(detect_write_paths "$TMP/t3")
run_test "backend sin src usa backend/**" "$(echo "$result" | grep -c "Write(backend/\*\*)")" "1"

echo ""
echo "Resultado: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

- [ ] **Step 2: Correr el test (debe fallar)**

```bash
bash scripts/lib/test-project-permissions.sh
```

Resultado esperado: `FAIL — project-permissions.sh no existe`.

- [ ] **Step 3: Crear `scripts/lib/project-permissions.sh`**

```bash
#!/usr/bin/env bash
# Funciones de detección de estructura de proyecto para el wizard de permisos.

# detect_write_paths <dir>
# Imprime en stdout una línea por cada Write path detectado.
# Cubre: monorepo backend+frontend, single-app src/, app/, backend solo.
detect_write_paths() {
  local target_dir="$1"

  if [[ -d "$target_dir/backend/src" ]]; then
    echo "Write(backend/src/**)"
  elif [[ -d "$target_dir/backend" ]]; then
    echo "Write(backend/**)"
  fi

  if [[ -d "$target_dir/frontend/src" ]]; then
    echo "Write(frontend/src/**)"
  elif [[ -d "$target_dir/frontend" ]]; then
    echo "Write(frontend/**)"
  fi

  if [[ -d "$target_dir/frontend/e2e" ]]; then
    echo "Write(frontend/e2e/**)"
  fi

  # Single-app: solo src/ sin backend ni frontend
  if [[ -d "$target_dir/src" ]] && \
     [[ ! -d "$target_dir/backend" ]] && \
     [[ ! -d "$target_dir/frontend" ]]; then
    echo "Write(src/**)"
  fi

  if [[ -d "$target_dir/app" ]]; then
    echo "Write(app/**)"
  fi
}

# detect_dev_server_situation <dir>
# Imprime: "ok" | "needs_concurrently" | "unknown"
detect_dev_server_situation() {
  local target_dir="$1"

  if [[ -f "$target_dir/package.json" ]] && \
     jq -e '.scripts.dev' "$target_dir/package.json" > /dev/null 2>&1; then
    echo "ok"
    return
  fi

  local backend_has_dev=false
  local frontend_has_dev=false

  if [[ -f "$target_dir/backend/package.json" ]] && \
     jq -e '.scripts.dev' "$target_dir/backend/package.json" > /dev/null 2>&1; then
    backend_has_dev=true
  fi

  if [[ -f "$target_dir/frontend/package.json" ]] && \
     jq -e '.scripts.dev' "$target_dir/frontend/package.json" > /dev/null 2>&1; then
    frontend_has_dev=true
  fi

  if [[ "$backend_has_dev" == "true" ]] && [[ "$frontend_has_dev" == "true" ]]; then
    echo "needs_concurrently"
  else
    echo "unknown"
  fi
}
```

- [ ] **Step 4: Correr el test (debe pasar)**

```bash
bash scripts/lib/test-project-permissions.sh
```

Resultado esperado: `Resultado: 6 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add scripts/lib/project-permissions.sh scripts/lib/test-project-permissions.sh
git commit -m "feat(lib): agregar project-permissions.sh con funciones de detección testeadas"
```

---

## Task 5: post-setup.sh — fase Write paths

**Files:**
- Modify: `scripts/post-setup.sh`

- [ ] **Step 1: Agregar el source del lib al inicio de post-setup.sh**

Después de las declaraciones de variables al inicio del script (después de `SETTINGS_JSON=...`), agregar:

```bash
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SOURCE_DIR/scripts/lib/project-permissions.sh"
```

- [ ] **Step 2: Agregar la nueva fase antes de la sección de hooks de notificación**

Buscar el comentario `# ============================================================================` que precede a la sección `# Sección: hooks de notificación` e insertar la nueva fase **antes** de esa sección:

```bash
# ============================================================================
# Fase: Write paths proyecto-específicos
# ============================================================================

echo ""
echo "✏️  Write paths: configurar permisos de escritura del proyecto..."
echo ""

# Directorios no estándar conocidos (se ignoran en la detección automática)
KNOWN_DIRS=("backend" "frontend" "src" "app" ".git" ".claude" ".github" "docs" "scripts" "templates" "node_modules" "dist" "build" ".next" ".nuxt" "coverage")

DETECTED_PATHS=()
while IFS= read -r line; do
  [[ -n "$line" ]] && DETECTED_PATHS+=("$line")
done < <(detect_write_paths "$PROJECT_DIR")

# Detectar directorios no estándar con código (tienen src/ o package.json)
NONSTANDARD_EXTRAS=()
for dir_path in "$PROJECT_DIR"/*/; do
  dir_name=$(basename "$dir_path")
  skip=false
  for known in "${KNOWN_DIRS[@]}"; do
    [[ "$dir_name" == "$known" ]] && skip=true && break
  done
  if [[ "$skip" == "false" ]] && \
     ([[ -d "$dir_path/src" ]] || [[ -f "$dir_path/package.json" ]] || [[ -f "$dir_path/pyproject.toml" ]]); then
    NONSTANDARD_EXTRAS+=("$dir_name")
  fi
done

# Preguntar por directorios no estándar
for dir_name in "${NONSTANDARD_EXTRAS[@]}"; do
  read -p "  Detecté '$dir_name/' con código — ¿pre-aprobar escrituras ahí? (s/n) " -n 1 -r
  echo ""
  [[ $REPLY =~ ^[Ss]$ ]] && DETECTED_PATHS+=("Write($dir_name/**)")
done

if [[ ${#DETECTED_PATHS[@]} -eq 0 ]]; then
  echo "  ℹ️  No detecté directorios de código. Configurá Write paths manualmente en .claude/settings.json"
else
  echo "  Voy a agregar a .claude/settings.json:"
  for p in "${DETECTED_PATHS[@]}"; do
    echo "    $p"
  done
  echo ""
  read -p "  ¿Confirmás? (s/n) " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Ss]$ ]]; then
    # Construir array JSON y mergear con jq
    JSON_ARRAY=$(printf '"%s"\n' "${DETECTED_PATHS[@]}" | jq -R . | jq -s .)
    UPDATED=$(jq --argjson paths "$JSON_ARRAY" '.permissions.allow += $paths' "$SETTINGS_JSON")
    echo "$UPDATED" > "$SETTINGS_JSON"
    echo "  ✅ Write paths agregados"
  fi
fi
```

- [ ] **Step 3: Verificar sintaxis**

```bash
bash -n scripts/post-setup.sh && echo "Sintaxis OK"
```

- [ ] **Step 4: Test de integración con fixture**

```bash
tmp=$(mktemp -d)
mkdir -p "$tmp/.claude" "$tmp/backend/src" "$tmp/frontend/src" "$tmp/frontend/e2e"
cp templates/settings.json.template "$tmp/.claude/settings.json"
touch "$tmp/CLAUDE.md" "$tmp/AGENT_WORKFLOW.md"

# Responder 's' a la pregunta de Write paths, 'n' al resto
printf "s\nn\nn\n" | bash scripts/post-setup.sh "$tmp" 2>/dev/null

jq -e '.permissions.allow | contains(["Write(backend/src/**)", "Write(frontend/src/**)", "Write(frontend/e2e/**)"])' \
  "$tmp/.claude/settings.json" && echo "PASS" || echo "FAIL"

rm -rf "$tmp"
```

Resultado esperado: `PASS`.

- [ ] **Step 5: Commit**

```bash
git add scripts/post-setup.sh
git commit -m "feat(post-setup): agregar wizard de Write paths con detección automática de estructura"
```

---

## Task 6: post-setup.sh — fase dev server

**Files:**
- Modify: `scripts/post-setup.sh`

- [ ] **Step 1: Agregar la fase de dev server después de la fase de Write paths**

Inmediatamente después del bloque de Write paths (antes del bloque de hooks de notificación), agregar:

```bash
# ============================================================================
# Fase: Dev server unificado
# ============================================================================

echo ""
echo "🚀 Dev server: verificando configuración..."
echo ""

DEV_SITUATION=$(detect_dev_server_situation "$PROJECT_DIR")

case "$DEV_SITUATION" in
  ok)
    echo "  ✅ Script 'dev' encontrado en el root — no se requiere acción"
    ;;
  needs_concurrently)
    echo "  ⚠️  No hay 'dev' en el root, pero backend/ y frontend/ tienen el suyo."
    echo "     Con concurrently podés levantar ambos con 'npm run dev' desde la raíz."
    echo ""
    echo "     Comando para instalar:"
    echo "       npm install --save-dev concurrently --prefix \"$PROJECT_DIR\""
    echo ""
    echo "     Script a agregar en package.json raíz:"
    echo '       "dev": "concurrently --names '\''backend,frontend'\'' \"npm run dev --prefix backend\" \"npm run dev --prefix frontend\""'
    echo ""
    read -p "  ¿Querés que instale concurrently ahora? (s/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
      npm install --save-dev concurrently --prefix "$PROJECT_DIR"
      echo "  ✅ concurrently instalado. Agregá el script 'dev' al package.json raíz manualmente."
    fi
    ;;
  unknown)
    echo "  ℹ️  No pude detectar la configuración del dev server."
    echo "     Revisá que existan scripts 'dev' en tus package.json y/o configurá npm run dev manualmente."
    ;;
esac
```

- [ ] **Step 2: Verificar sintaxis**

```bash
bash -n scripts/post-setup.sh && echo "Sintaxis OK"
```

- [ ] **Step 3: Test de integración — caso needs_concurrently**

```bash
tmp=$(mktemp -d)
mkdir -p "$tmp/.claude" "$tmp/backend" "$tmp/frontend"
cp templates/settings.json.template "$tmp/.claude/settings.json"
touch "$tmp/CLAUDE.md" "$tmp/AGENT_WORKFLOW.md"

# package.json de backend y frontend con script dev
echo '{"scripts":{"dev":"echo backend"}}' > "$tmp/backend/package.json"
echo '{"scripts":{"dev":"echo frontend"}}' > "$tmp/frontend/package.json"

# Responder 'n' a todo para no instalar nada
printf "n\nn\nn\nn\n" | bash scripts/post-setup.sh "$tmp" 2>/dev/null | grep -q "concurrently" && echo "PASS — muestra sugerencia de concurrently" || echo "FAIL"

rm -rf "$tmp"
```

Resultado esperado: `PASS — muestra sugerencia de concurrently`.

- [ ] **Step 4: Commit final**

```bash
git add scripts/post-setup.sh
git commit -m "feat(post-setup): agregar fase de detección y sugerencia de dev server unificado"
```

---

## Verificación final

Después de todos los tasks, correr:

```bash
# 1. Todos los tests de lib
bash scripts/lib/test-project-permissions.sh

# 2. JSON del template es válido y tiene >= 80 permisos
jq '.permissions.allow | length' templates/settings.json.template

# 3. Sintaxis de todos los scripts modificados
bash -n scripts/bootstrap.sh && bash -n scripts/post-setup.sh && echo "Todos los scripts OK"

# 4. Test de bootstrap completo (crea proyecto y verifica checklist)
tmp=$(mktemp -d) && git init "$tmp" > /dev/null && \
bash scripts/bootstrap.sh "$tmp" test-final > /dev/null 2>&1 && \
test -f "$tmp/POSTINSTALL_CHECKLIST.md" && \
jq -e '.permissions.allow | contains(["mcp__plugin_playwright_playwright__browser_navigate"])' "$tmp/.claude/settings.json" && \
echo "Verificación completa: PASS" && rm -rf "$tmp"
```
