# Spec: Configuración global por máquina

**Fecha:** 2026-06-09
**Origen:** La configuración actual requiere ejecutar `bootstrap.sh` en cada proyecto
para instalar permisos, agentes y skills. En un contexto de un solo desarrollador
con múltiples máquinas (Mac Mini + MacBook), esto es fricción innecesaria: la
configuración debería instalarse una sola vez por máquina, y proyectos nuevos solo
necesitan su contexto específico (CLAUDE.md, AGENT_WORKFLOW.md).

---

## Contexto y problema

El factory actual instala en cada proyecto:
- `.claude/settings.json` — permisos (84-115 entradas)
- `.claude/agents/` — db-query-agent, qa-visual-agent, research-agent
- `.claude/skills/` — qa, stop-slop

Esto genera dos problemas:
1. **Fricción por proyecto**: hay que correr bootstrap en cada repo, y si el template
   mejora, hay que propagar los cambios a todos los proyectos existentes (el problema
   de merge incremental que motivó esta discusión).
2. **Sync entre máquinas**: no existe mecanismo para llevar la configuración de
   Mac Mini a MacBook de forma reproducible.

La causa raíz: la configuración que es **universal** (cómo trabaja Claude en cualquier
proyecto de esta máquina) se trata como si fuera **específica de cada proyecto**.

---

## Decisión de diseño

**Separar configuración universal de configuración específica del proyecto:**

| Tipo | Qué incluye | Dónde vive | Quién lo instala |
|------|-------------|-----------|-----------------|
| **Universal** | permisos, agentes, skills | `~/.claude/` | `install-global.sh` |
| **Específico** | CLAUDE.md, AGENT_WORKFLOW.md, .github/, Write paths | `<proyecto>/` | `bootstrap.sh` + `post-setup.sh` |

Claude Code mergea automáticamente `~/.claude/settings.json` con `.claude/settings.json`
del proyecto. Los Write paths específicos del proyecto (que `post-setup.sh` agrega)
complementan los permisos globales sin pisarlos.

---

## Sección 1 — Nuevo script `scripts/install-global.sh`

Script idempotente que instala o actualiza la configuración universal en `~/.claude/`.

### 1a. Merge de permisos en `~/.claude/settings.json`

Usa la misma lógica de union-merge que se diseñó para bootstrap:
- Si `~/.claude/settings.json` no existe: copia el template
- Si existe: union-merge de `allow`, `ask`, `deny` con `jq | unique`
- Preserva campos no-permissions del archivo global existente (`hooks`, `env`, etc.)
- Escritura atómica: `mktemp` + `mv`
- Reporta cuántos permisos nuevos se agregaron

Salida esperada:
```
✅ creado: ~/.claude/settings.json
# o si ya existía:
🔄 sincronizado: ~/.claude/settings.json (+12 allow, +0 ask, +2 deny)
# o si ya estaba al día:
✅ ya sincronizado: ~/.claude/settings.json
```

### 1b. Agentes en `~/.claude/agents/`

Copia todos los agentes de `.claude/agents/` del factory a `~/.claude/agents/`.
El factory es la fuente de verdad: **siempre sobreescribe** (a diferencia del
bootstrap de proyectos que usa skip-if-exists).

Agentes que se instalan:
- `db-query-agent.md`
- `qa-visual-agent.md`
- `research-agent.md`

Salida esperada:
```
✅ agente instalado: db-query-agent.md
🔄 agente actualizado: qa-visual-agent.md
```

### 1c. Skills vendorizadas en `~/.claude/skills/`

Copia los directorios de skills de `.claude/skills/` del factory a `~/.claude/skills/`.
Misma política: siempre sobreescribe.

Skills que se instalan:
- `qa/`
- `stop-slop/`

### 1d. Crear `~/.claude/` si no existe

El script crea la estructura necesaria antes de copiar:
```bash
mkdir -p ~/.claude/agents ~/.claude/skills
```

### 1e. Output final

```
🌐 Instalación global de Software Factory
   Destino: ~/.claude/

✅ ~/.claude/settings.json (sincronizado: +12 allow, +2 deny)
✅ ~/.claude/agents/db-query-agent.md (actualizado)
✅ ~/.claude/agents/qa-visual-agent.md (actualizado)
✅ ~/.claude/agents/research-agent.md (actualizado)
✅ ~/.claude/skills/qa (actualizado)
✅ ~/.claude/skills/stop-slop (actualizado)

✅ Instalación global completa.

Para nuevos proyectos:
  bash scripts/bootstrap.sh <ruta-al-proyecto>

Para sync a otra máquina:
  git clone <factory> && bash scripts/install-global.sh
```

---

## Sección 2 — Función `merge_settings()` en `scripts/lib/install-helpers.sh`

Función reutilizable que usan tanto `install-global.sh` como (si se necesita)
cualquier otro script. No es parte de `bootstrap.sh`.

Firma: `merge_settings <template_path> <target_path>`

Lógica:
```bash
merge_settings() {
  local template="$1" target="$2"
  if [[ ! -f "$target" ]]; then
    cp "$template" "$target"
    echo "  ✅ creado: $target"
    return 0
  fi
  local before_allow before_deny
  before_allow=$(jq '.permissions.allow | length' "$target")
  before_deny=$(jq '.permissions.deny | length' "$target")
  local TMP
  TMP=$(mktemp)
  jq -s '
    .[0] as $tmpl | .[1] as $proj |
    ($proj | del(.permissions)) + {
      permissions: {
        allow: ((($tmpl.permissions.allow // []) + ($proj.permissions.allow // [])) | unique),
        ask:   ((($tmpl.permissions.ask   // []) + ($proj.permissions.ask   // [])) | unique),
        deny:  ((($tmpl.permissions.deny  // []) + ($proj.permissions.deny  // [])) | unique)
      }
    }
  ' "$template" "$target" > "$TMP" && mv "$TMP" "$target"
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

TDD: `scripts/lib/test-merge-settings.sh` con 8 tests (detalle en Sección 5).

---

## Sección 3 — Cambios en `scripts/bootstrap.sh`

### Lo que se elimina

- `copy_if_absent` para `.claude/settings.json`
- Fase 4 (vendorización de skills)
- Fase 5 (vendorización de agentes)

### Lo que queda

- Fase 1: crear directorios base (`.github/`, docs, etc.)
- Fase 2: copiar plantillas (POSTINSTALL_CHECKLIST, CI, PR template)
- Fase 3: merge inteligente de CLAUDE.md
- Fase 4 (nueva): copiar AGENT_WORKFLOW.md si no existe
- Fase 5 (nueva): validar que `~/.claude/` tiene la instalación global

La validación de instalación global avisa si `install-global.sh` no fue corrido:
```
⚠️  ~/.claude/settings.json no encontrado.
   Ejecutá primero: bash scripts/install-global.sh
```

### Bootstrap resultante (flujo típico)

```
bootstrap.sh fichasMontajeApp
→ ✅ CLAUDE.md mergeado
→ ✅ AGENT_WORKFLOW.md creado
→ ✅ .github/ configurado
→ ✅ POSTINSTALL_CHECKLIST.md creado
→ ⚠️  ~/.claude/settings.json no encontrado → ejecutá install-global.sh primero
```

---

## Sección 4 — `post-setup.sh` — sin cambios de concepto

El wizard de Write paths sigue igual: detecta la estructura del proyecto y agrega
los Write paths específicos al `.claude/settings.json` del proyecto (un archivo
mínimo, solo con lo específico de ese repo).

Claude Code mergea automáticamente los settings globales (`~/.claude/settings.json`)
con los del proyecto (`.claude/settings.json`). Los Write paths del proyecto
complementan los permisos globales.

---

## Sección 5 — TDD para `merge_settings()`

8 tests en `scripts/lib/test-merge-settings.sh`:

1. Target ausente → lo crea copiando el template
2. Nuevos `allow` del template se agregan al target existente
3. Nuevos `deny` del template se agregan al target existente
4. `allow` ya existentes en el target sobreviven
5. `allow` custom del target (no en template) sobreviven
6. Idempotente: segunda corrida produce output idéntico
7. Campos no-permissions del target (`hooks`, `env`) sobreviven
8. No se crean duplicados si el mismo permiso está en template y target

---

## Sección 6 — Sync entre máquinas

### Primera instalación en máquina nueva

```bash
git clone git@github.com:juanPabloSarobe/softwareFactory.git
cd softwareFactory
bash scripts/install-global.sh
```

### Actualizar máquina existente con mejoras del factory

```bash
cd softwareFactory
git pull
bash scripts/install-global.sh
# → 🔄 sincronizado: ~/.claude/settings.json (+N allow)
# → 🔄 agente actualizado: qa-visual-agent.md
```

### Retroalimentación: proyecto → factory → otra máquina

Si en `fichasMontajeApp` se descubre un permiso nuevo:
1. Se agrega al template `templates/settings.json.template` en el factory
2. `git push` al factory
3. En la otra máquina: `git pull && bash scripts/install-global.sh`

---

## Archivos a crear/modificar

| Archivo | Tipo de cambio |
|---------|---------------|
| `scripts/install-global.sh` | Crear nuevo |
| `scripts/lib/install-helpers.sh` | Agregar `merge_settings()` |
| `scripts/lib/test-merge-settings.sh` | Crear nuevo (8 tests) |
| `scripts/bootstrap.sh` | Eliminar settings/skills/agents, agregar validación global |

---

## Criterio de éxito

1. `bash scripts/install-global.sh` en Mac Mini instala todo en `~/.claude/`
2. Un proyecto nuevo con solo `bootstrap.sh` (sin install-global previo) avisa claramente
3. `bash scripts/install-global.sh` es idempotente: segunda corrida no produce cambios
4. En MacBook: `git clone + install-global.sh` replica la configuración completa
5. `fichasMontajeApp` funciona sin `.claude/settings.json` propio (solo Write paths)
6. Los 8 tests de `test-merge-settings.sh` pasan

---

## Limitación conocida

En Claude Code, `deny` tiene precedencia sobre `allow` sin importar en qué nivel
de settings esté declarado. Si la configuración global tiene un `deny` para un
comando que un proyecto específico necesita (por ej. `Bash(aws *)`), la única
solución es remover ese `deny` del archivo global `~/.claude/settings.json` o
moverlo a un settings local del proyecto. No se puede contrarrestar un `deny`
global con un `allow` por proyecto. Este caso se resuelve manualmente.
