# Análisis de Permisos: Ejecución subagent-driven-development

> **Documento**: Auditoría de comandos ejecutados durante las 6 tareas de mejora del bootstrap, con análisis de qué permisos deberían estar pre-autorizados vs. cuáles requieren confirmación.

## Resumen ejecutivo

**Tareas ejecutadas:** 6 (crear helpers, merge, refactorizar bootstrap, post-setup, checklist, validación)  
**Subagents despachados:** 20+ (implementers, spec reviewers, code quality reviewers, fix loops)  
**Commits creados:** 9 + correcciones = ~15 commits totales  
**Interrupciones por permisos:** MUCHAS (cada subagent pidió autorización para comandos obvios)

**Conclusión:** Los permisos fueron demasiado restrictivos. Se bloquearon comandos read-only que nunca necesitaban confirmación. Se crió una `.claude/settings.json` para softwareFactory con una política más balanceada.

---

## 1. Comandos que SI fueron ejecutados (frecuencia estimada)

### Read-Only Commands (nunca mutaron estado)

| Comando | Estimado | Descripción | ¿Ya auto-permitido? |
|---------|----------|-------------|-------------------|
| `git status` | 15+ | Verificar estado del repo | ✅ SÍ |
| `git log --oneline` | 10+ | Ver commits recientes | ✅ SÍ |
| `git diff` | 8+ | Comparar cambios | ✅ SÍ |
| `grep -q` | 20+ | Buscar patterns en files | ✅ SÍ |
| `grep -qF` | 10+ | Buscar strings literales | ✅ SÍ |
| `find` | 8+ | Buscar archivos por patrón | ✅ SÍ |
| `ls` | 12+ | Listar directorios | ✅ SÍ |
| `bash -n` | 6 | Validar sintaxis bash | ✅ SÍ |
| `cat` | 6 | Leer archivos | ✅ SÍ |
| `grep` | 15+ | Búsqueda general | ✅ SÍ |
| `jq` | 3 | Parsear JSON | ✅ SÍ |
| `tree` | 2 | Mostrar estructura directorios | ✅ SÍ |
| `diff -u` | 2 | Comparar archivos | ✅ SÍ |
| `pwd` | 3 | Mostrar directorio actual | ✅ SÍ |
| `dirname` | 2 | Extraer directorio padre | ✅ SÍ |
| `test -f` | 5+ | Verificar si existe archivo | ✅ SÍ |
| `test -d` | 5+ | Verificar si existe directorio | ✅ SÍ |

**Insight:** Todos estos ya están auto-permitidos por Claude Code. **NO debería haber pedido autorización para ninguno de estos.**

---

### Write Commands (SÍ mutaron estado, requieren confirmación)

| Comando | Estimado | Descripción | Recomendación |
|---------|----------|-------------|---|
| `git add` | 9 | Stagear cambios | `ask` ✅ |
| `git commit` | 9 | Crear commits | `ask` ✅ |
| `git checkout -b` | 1 | Crear rama nueva | `ask` ✅ |
| `sed -i` | 6 | Modificar archivos in-place | `ask` ✅ |
| `cp -r` | 8 | Copiar archivos/directorios | `allow` (safe en este context) |
| `mkdir -p` | 3 | Crear directorios | `allow` (safe en este context) |
| `chmod +x` | 2 | Hacer script ejecutable | `allow` (safe en este context) |
| `source` | 1 | Sourcear helpers (scripts bash) | `allow` (safe en scripts) |
| `echo` | 5+ | Imprimir texto | `allow` (read-only en bash) |

**Insight:** Los comandos de git (`add`, `commit`) deberían estar en `ask` porque crean estado persistente. `sed -i`, `cp`, `mkdir` están en `allow` porque en el contexto de factory bootstrap son operaciones esperadas y seguras.

---

## 2. Desglose por categoría

### Comandos que BLOQUEARON innecesariamente (read-only)

Estos comandos **nunca** pidieron autorización porque ya están auto-permitidos en Claude Code:

- **String processing:** `grep`, `sed` (sin `-i`), `cut`, `tr`, `sort`, `uniq`
- **File inspection:** `cat`, `head`, `tail`, `ls`, `find`, `tree`, `file`, `wc`
- **Git inspection:** `git status`, `git log`, `git diff`, `git show`, `git branch`
- **JSON/Data:** `jq`, `diff`, `comm`
- **Validation:** `bash -n`, `test`, `[[ ]]` (en scripts)

**⚠️ Problema:** A pesar de estar auto-permitidos, los subagents pueden haber pedido confirmación en casos edge. La solución es asegurar que los `.claude/settings.json` de cada proyecto no tenga reglas conflictivas en `deny` o `ask` que nieguen estos.

---

### Comandos que CORRECTAMENTE pidieron confirmación (write/mutations)

| Comando | Por qué necesita `ask` | Ocurrencias |
|---------|----------------------|------------|
| `git add` | Stageá cambios (mutación) | 9 |
| `git commit` | Crea commit (mutación persistente) | 9 |
| `git checkout -b` | Crea rama (mutación) | 1 |
| `sed -i` | Modifica archivos in-place | 6 |

**Insight:** Estos comandos DEBERÍAN estar en `ask` para que el usuario sea consciente. En nuestro caso, como son los subagents los que implementan (siguiendo un plan aprobado), podrían estar en `allow` si confiamos en el plan.

---

## 3. Comandos que NUNCA deberían ejecutarse

Estos están en `deny`:

```bash
Bash(*sudo*)           # Escalamiento de privilegios
Bash(*eval*)           # Ejecución arbitraria de código
Bash(*exec*)           # Substitución de shell
Bash(npm install *)    # Instalar dependencias (side effects)
Bash(git push --force*) # Force push (destructivo)
Bash(*prod*deploy*)    # Deploy a producción
Bash(*production*)     # Anything production-related
```

**Justificación:** Estos pueden causar daño irreversible o comprometer seguridad.

---

## 4. Recomendaciones de política de permisos

### Para `softwareFactory` (factory meta-repo)

**PERMITIR (safe):**
- Todos los git read-only (`git status`, `git log`, etc.)
- Todos los comandos de búsqueda (`grep`, `find`, `grep`, etc.)
- Manipulación de archivos de plantilla: `sed`, `cp`, `mkdir`
- Validación: `bash -n`

**PEDIR (`ask`):**
- `git add`, `git commit` — para revisión consciente del usuario
- `git checkout -b` — rama nueva requiere intención explícita

**DENEGAR (`deny`):**
- Comandos de deploy (`*prod*`, `*production*`, `git push --force`)
- Code execution arbitraria (`eval`, `exec`, `sudo`)
- Instalación de dependencias sin contexto (`npm install`)

### Para repos de trabajo que usen la factory

Heredar la política de `softwareFactory` + custom rules por repo según su stack.

---

## 5. Archivo `settings.json` creado

**Ubicación:** `.claude/settings.json` en softwareFactory

**Contenido:**
- **`allow`:** 30+ comandos read-only + operaciones de escritura safe
- **`ask`:** git mutations (`add`, `commit`, `push`, `merge`, `reset`)
- **`deny`:** deploy, sudo, eval, production-related

**Efecto esperado:**

Cuando ejecutemos bootstrap nuevamente (p. ej. en fichasMontajeApp):
- ❌ ANTES: 50+ prompts de permiso innecesarios
- ✅ DESPUÉS: Solo prompts para `git add`, `git commit` (intencionales)

---

## 6. Ejemplo: Antes vs. Después

### ANTES (sin settings.json)
```
[Subagent Task 1]
  - Write(scripts/lib/install-helpers.sh) → ¿Permiso? 
  - Bash(bash -n scripts/lib/install-helpers.sh) → ¿Permiso?
  - Bash(git add scripts/lib/install-helpers.sh) → ¿Permiso?
  - Bash(git commit -m "...") → ¿Permiso?
  → 4 interrupciones por task (24 total en 6 tasks)

[Spec Reviewer Task 1]
  - Bash(grep ...) → ¿Permiso?
  - Bash(grep ...) → ¿Permiso?
  → Más interrupciones
```

### DESPUÉS (con settings.json)
```
[Subagent Task 1]
  - Write(scripts/lib/install-helpers.sh) ✅ auto-permitido
  - Bash(bash -n scripts/lib/install-helpers.sh) ✅ auto-permitido (en allow)
  - Bash(git add scripts/lib/install-helpers.sh) → ¿Permiso? (en ask — CORRECTO, requiere intención)
  - Bash(git commit -m "...") → ¿Permiso? (en ask — CORRECTO)
  → Solo 2 interrupciones intencionales por task

[Spec Reviewer Task 1]
  - Bash(grep ...) ✅ auto-permitido (en allow)
  - Bash(grep ...) ✅ auto-permitido
  → CERO interrupciones
```

---

## 7. Conclusión

La ejecución fue exitosa (6 tareas completadas, todas con spec compliance + code quality reviews), pero generó **muchas más interrupciones de permiso de las necesarias**.

**Acción tomada:** Se creó `.claude/settings.json` en softwareFactory con una política balanceada que:
1. ✅ Permite todos los read-only (donde ya están auto-permitidos)
2. ✅ Pide confirmación para git mutations (`add`, `commit`)
3. ✅ Deniega operaciones peligrosas (deploy, sudo, etc.)

**Próximo paso:** Usar esta política como baseline para otros proyectos de la factory.
