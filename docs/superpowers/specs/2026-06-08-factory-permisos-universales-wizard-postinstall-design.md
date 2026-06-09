# Spec: Permisos universales, wizard de Write paths y POSTINSTALL_CHECKLIST

**Fecha:** 2026-06-08
**Origen:** Retrospectiva de instalación en fichasMontajeApp — tarea de 40 min que tomó 4 horas por falta de permisos pre-configurados, principalmente durante la fase de QA visual con Playwright.

---

## Contexto y problema

El `settings.json.template` actual cubre comandos bash básicos y rutas de lectura genéricas, pero no incluye:

- Las 22 herramientas del Playwright MCP que usa `qa-visual-agent`
- Los MCPs de context7, Gmail y Google Calendar
- Patrones bash de Python y npm que los agentes invocan frecuentemente
- Directorios ocultos (`.claude/`, `.github/`) que `Read(**)` no cubre en todos los contextos
- Write paths proyecto-específicos (no pueden ser genéricos en el template)

Resultado: cada tool no pre-aprobada detiene la ejecución y espera confirmación manual, convirtiendo flujos autónomos en sesiones interactivas.

---

## Decisión de diseño

**Enfoque C — Capas + wizard híbrido:**

- El `settings.json.template` incorpora todos los permisos invariantes (todo lo que cualquier proyecto con ese MCP necesitará, siempre)
- El `post-setup.sh` agrega un wizard híbrido que auto-detecta la estructura del proyecto y propone los Write paths para confirmación
- El `POSTINSTALL_CHECKLIST.md.template` cubre lo que el código no puede resolver: decisiones de configuración, deuda técnica de testing, y el ritual `/fewer-permission-prompts`

---

## Sección 1 — Cambios a `templates/settings.json.template`

### 1a. Playwright MCP — mover de ausente a `allow`

Las 22 herramientas no destructivas del Playwright MCP. Sin estas, `qa-visual-agent` queda bloqueado en cada tool call.

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

Agregar a `deny` (ejecuta código arbitrario):
```json
"mcp__plugin_playwright_playwright__browser_run_code_unsafe"
```

### 1b. Context7 MCP — agregar a `allow`

Los agentes de brainstorming y writing-plans llaman a context7 para resolver documentación de librerías en tiempo real.

```json
"mcp__plugin_context7_context7__resolve-library-id",
"mcp__plugin_context7_context7__query-docs"
```

### 1c. Gmail y Google Calendar MCP — agregar a `allow`

Solo los flujos de autenticación. Sin estos, el primer intento de conexión queda bloqueado esperando aprobación.

```json
"mcp__claude_ai_Gmail__authenticate",
"mcp__claude_ai_Gmail__complete_authentication",
"mcp__claude_ai_Google_Calendar__authenticate",
"mcp__claude_ai_Google_Calendar__complete_authentication"
```

### 1d. Bash patterns faltantes

**Agregar a `allow`:**
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

`npx` y `curl` aparecen en health checks y setup de herramientas. Los comandos Python cubren tanto scripts internos de gstack/Superpowers como proyectos con backend Python.

**Agregar a `ask`** (instalan paquetes — efecto de lado real, misma política que `npm install`):
```json
"Bash(pip install *)",
"Bash(uv add *)",
"Bash(poetry add *)"
```

### 1e. Directorios ocultos — lectura explícita

`Read(**)` no garantiza match de directorios que empiezan con `.` en todos los contextos de Claude Code. Agregar reglas explícitas:

```json
"Read(.claude/**)",
"Read(.github/**)"
```

`.env*`, `**/*.pem` y `**/secrets/**` permanecen en `deny`.

---

## Sección 2 — Wizard híbrido en `scripts/post-setup.sh`

Nueva fase que se ejecuta después de la fase de MCP servers. Auto-detecta la estructura del proyecto y propone Write paths. Solo pregunta cuando no puede inferir.

### Lógica de detección

```
¿Existe backend/?
  ├─ ¿Tiene backend/src/?  → propone Write(backend/src/**)
  └─ Si no                 → propone Write(backend/**)

¿Existe frontend/?
  ├─ ¿Tiene frontend/src/? → propone Write(frontend/src/**)
  ├─ ¿Tiene frontend/e2e/? → agrega Write(frontend/e2e/**)
  └─ Si no                 → propone Write(frontend/**)

¿Solo existe src/ en la raíz (sin backend/ ni frontend/)?
  └─ propone Write(src/**)

¿Existe app/?
  └─ propone Write(app/**)

Directorios con nombres no estándar (api/, webapp/, client/, etc.)
  └─ pregunta: "¿Querés pre-aprobar escrituras en <dir>/? (s/n)"
```

### Interacción típica (happy path)

```
📁 Detecté la siguiente estructura:
   backend/src/   ✓
   frontend/src/  ✓
   frontend/e2e/  ✓

📝 Voy a agregar a .claude/settings.json:
   Write(backend/src/**)
   Write(frontend/src/**)
   Write(frontend/e2e/**)

¿Confirmás? (s/n/editar)
```

### Detección de dev server

```
¿Root package.json tiene script "dev"?
  ├─ Sí → no hace nada
  └─ No → ¿backend/ y frontend/ tienen "dev" cada uno?
       ├─ Sí → ofrece agregar concurrently al root package.json
       └─ No → avisa que hay que configurar dev server manualmente
```

El wizard propone el comando pero **no ejecuta `npm install`** ni modifica `package.json` sin confirmación explícita.

### Integración en `post-setup.sh`

La nueva fase se inserta antes de la sección de MCP servers, como "Fase X: Permisos de escritura proyecto-específicos". Usa `jq` para mergear en el `.claude/settings.json` existente sin pisar lo que ya haya.

---

## Sección 3 — `templates/POSTINSTALL_CHECKLIST.md.template`

Documento que `bootstrap.sh` copia a `POSTINSTALL_CHECKLIST.md` en la raíz del proyecto. Cubre lo que el código no puede resolver automáticamente.

### Estructura del template

```
## 0. Qué hizo el bootstrap automáticamente
   Referencia de los permisos pre-configurados: Playwright,
   context7, Gmail, Calendar, Python, npm, hidden dirs.
   (No requiere acción — es solo documentación de estado inicial)

## 1. Infraestructura de testing frontend [VERIFICAR]
   - ¿Está vitest/jest configurado?
   - Comando de instalación si falta
   - Sin esto: TDD no funciona, el agente solo valida por QA visual

## 2. Conflicto eval/gstack [DECISIÓN DEL OWNER]
   - Qué pasa: deny Bash(*eval*) bloquea scripts internos de gstack
   - Opción A: dejarlo (gstack falla silencioso, flujo principal OK)
   - Opción B: afinar el deny → solo negar eval con args arbitrarios
   - El owner elige y documenta su decisión acá

## 3. Ritual post-primera-sesión [EJECUTAR]
   - /fewer-permission-prompts
   - Repetir cada vez que se agregue una skill nueva
   - Captura patrones reales que el template genérico no prevé

## 4. Smoke test de entorno [VERIFICAR]
   - Servidores: npm run dev + curl health check
   - Tests: npm test
   - Lint: npm run lint
   - Permisos: jq '.permissions.allow | length' .claude/settings.json
   - Esperado: >= 80 entradas en permissions.allow

## 5. Historial
   | Fecha | Qué pasó | Resolución |
   (se completa a medida que aparecen casos nuevos)
```

### Dónde vive en el factory

- Fuente: `templates/POSTINSTALL_CHECKLIST.md.template`
- Destino: `POSTINSTALL_CHECKLIST.md` en la raíz del proyecto destino
- Quién lo copia: `scripts/bootstrap.sh` — misma mecánica que `AGENT_WORKFLOW.md`
- Comportamiento si ya existe: skip (respeta lo que el proyecto ya tenga)

---

## Archivos a crear/modificar

| Archivo | Tipo de cambio |
|---------|---------------|
| `templates/settings.json.template` | Agregar grupos 1a–1e al `allow` y al `deny` |
| `templates/POSTINSTALL_CHECKLIST.md.template` | Crear nuevo |
| `scripts/bootstrap.sh` | Agregar `copy_if_absent` para el checklist |
| `scripts/post-setup.sh` | Agregar fase de Write paths + wizard dev server |

---

## Criterio de éxito

Un proyecto nuevo instalado con `bootstrap.sh` + `post-setup.sh` debe poder completar un ciclo completo (brainstorming → plan → implementación → QA visual → finishing branch) **sin ninguna interrupción por permisos**, salvo las que corresponden a decisiones reales del owner (push a main, drop de base de datos, etc.).
