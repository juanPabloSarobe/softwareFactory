# Settings.json — Política de Permisos Explicada

> **Filosofía:** Definís TODO de antemano en el plan → los subagents ejecutan sin interrupciones innecesarias → solo pedir confirmación para decisiones no previstas.

---

## Nueva configuración: `.claude/settings.json`

```json
{
  "permissions": {
    "allow": [45 reglas],
    "ask": [8 reglas],
    "deny": [9 reglas]
  }
}
```

---

## 📋 ALLOW (45 reglas) — Se ejecutan sin preguntar

### Lectura de archivos (nunca mutación)
```json
"Read(**)",              // Leer ANY archivo
"Grep",                  // Herramienta grep nativa
"Glob"                   // Glob nativa
```

### Edición de documentación (seguro)
```json
"Write(docs/**)",        // Crear/modificar docs
"Write(scripts/**)",     // Crear/modificar scripts en scripts/
"Edit(scripts/**)",      // Editar scripts
"Edit(templates/**)",    // Editar templates (CLAUDE.md.template, etc)
"Edit(docs/**)",         // Editar docs
"Edit(.claude/skills/**)",   // Editar skills vendorizadas
"Edit(.claude/agents/**)"    // Editar agentes
```

**¿Por qué están?** Todo esto está pre-definido en los planes. Los subagents no hacen decisiones arquitectónicas acá, solo siguen el plan.

### Git — Lectura (inspección)
```json
"Bash(git status)",      // Ver estado del repo
"Bash(git log *)",       // Ver historial (cualquier flag)
"Bash(git diff *)",      // Comparar cambios
"Bash(git branch)",      // Listar ramas
"Bash(git show)",        // Mostrar commit
"Bash(git ls-files)"     // Listar archivos tracked
```

**¿Por qué están?** Son read-only, nunca mutaban estado, siempre usados para inspeccionar.

### Git — Escritura (está en el plan)
```json
"Bash(git add *)",       // Stagear cambios ← AQUÍ ESTÁ LA DIFERENCIA
"Bash(git commit *)",    // Crear commits ← AQUÍ ESTÁ LA DIFERENCIA
"Bash(git checkout -b *)" // Crear ramas feature
```

**¿Por qué ahora `allow`?**
- El plan especifica exactamente qué archivos se crean (helpers, scripts, docs)
- El plan especifica exactamente qué commits se hacen (7 commits específicos)
- Los subagents siguen el plan fielmente, no deciden por su cuenta
- **Ya lo revisaste en el plan ANTES de ejecutar** — no hay sorpresas
- Las interrupciones no agregan valor porque no las lees, solo aceptas

### Bash — Validación (nunca mutación)
```json
"Bash(bash -n *)",       // Validar sintaxis bash
"Bash(test -f *)",       // Test si archivo existe
"Bash(test -d *)",       // Test si directorio existe
"Bash(test -z *)"        // Test si string está vacío
```

### Bash — Búsqueda (read-only)
```json
"Bash(grep *)",          // Buscar text (cualquier forma)
"Bash(grep -q *)",       // Grep silencioso
"Bash(grep -qF *)",      // Grep literal
"Bash(find *)",          // Buscar archivos
"Bash(ls *)",            // Listar directorios
"Bash(cat *)",           // Leer archivos
"Bash(head *)",          // Primeras líneas
"Bash(tail *)",          // Últimas líneas
"Bash(tree *)",          // Estructura de directorios
"Bash(jq *)",            // Parsear JSON
"Bash(diff *)",          // Comparar archivos
```

### Bash — Manipulación de archivos (está en el plan)
```json
"Bash(sed -e *)",        // Sed read-only (buscar)
"Bash(sed -i *)",        // Sed modifica archivos ← EN EL PLAN
"Bash(mkdir -p *)",      // Crear directorios ← EN EL PLAN
"Bash(chmod +x *)",      // Hacer ejecutable ← EN EL PLAN
"Bash(cp -r *)",         // Copiar archivos ← EN EL PLAN
"Bash(mv *)",            // Mover/renombrar archivos
```

**¿Por qué están?** Todos estos están explícitamente en el plan:
- `sed -i` → plan dice "reemplazar placeholders en CLAUDE.md"
- `mkdir -p` → plan dice "crear .claude/skills, .claude/agents"
- `cp -r` → plan dice "vendorizar skills y agentes"
- `mv` → plan dice "mover archivos"

### Bash — Utilidades (nunca riesgo)
```json
"Bash(pwd)",             // Mostrar directorio actual
"Bash(dirname *)",       // Extraer directorio padre
"Bash(basename *)",      // Extraer nombre de archivo
"Bash(echo *)",          // Imprimir texto
"Bash(printf *)",        // Imprimir con formato
"Bash(source *)",        // Sourcear scripts (en bash ← EN EL PLAN)
"Bash(command -v *)",    // Buscar comando en PATH
"Bash(wc -l *)"          // Contar líneas
```

---

## ⚠️ ASK (8 reglas) — Pedir confirmación

### Git — Operaciones riesgosas
```json
"Bash(git push *)",      // Publicar commits a remoto
"Bash(git merge *)",     // Mergear ramas
"Bash(git reset *)",     // Deshacer commits (parcial)
"Bash(git rebase *)"     // Rebase (reescribir historia)
```

**¿Por qué en `ask`?**
- No están en el plan normal (el plan NO hace push, merge, rebase)
- Si un subagent decide hacer esto, **necesitas saber**
- Podrían afectar ramas remotas o historia de git
- Son decisiones fuera del scope original

### Bash — Operaciones destructivas
```json
"Bash(rm -rf *)",        // Borrar recursivamente (⚠️ PELIGROSO)
"Bash(rm *)"             // Borrar archivos
```

**¿Por qué en `ask`?**
- No está en el plan (no debes borrar nada durante bootstrap)
- Si ocurre, algo salió muy mal
- Mejor pedir confirmación: "¿Estás seguro de borrar X?"

### Edición — Archivos críticos
```json
"Edit(CLAUDE.md)",       // Modificar CLAUDE.md root
"Edit(.claude/settings.json)" // Modificar settings
```

**¿Por qué en `ask`?**
- CLAUDE.md define reglas del proyecto → cambios importantes
- settings.json define permisos → cambios de seguridad
- Aunque el plan lo especifique, una última verificación no cuesta nada

---

## 🚫 DENY (9 reglas) — Completamente bloqueado

### Escalamiento de privilegios
```json
"Bash(*sudo*)",          // Sudo (ejecutar como root)
"Bash(*eval*)",          // Eval (código arbitrario)
"Bash(*exec*)"           // Exec (reemplazar shell)
```

**¿Por qué denegar?**
- Escalamiento de privilegios = riesgo de seguridad
- Código arbitrario = impredecible
- Nunca debería ser parte de un plan

### Manejo de dependencias
```json
"Bash(npm install *)",   // Instalar dependencias
"Bash(npm uninstall *)"  // Desinstalar dependencias
```

**¿Por qué denegar?**
- No está en el plan de factory
- npm install tiene side effects (baja Internet, modifica node_modules)
- Si lo necesitas, lo pedís explícitamente

### Git — Operaciones ultra-riesgosas
```json
"Bash(git push --force*)",   // Force push = sobrescribir historia remota
"Bash(git reset --hard*)"    // Reset hard = descartar cambios locales
```

**¿Por qué denegar?**
- Force push destruye historia colaborativa
- Reset hard descarta trabajo
- Si realmente necesitas esto, merece una conversación aparte

### Deploy/Producción
```json
"Bash(*prod*deploy*)",   // Deploy a producción
"Bash(*production*)"     // Cualquier cosa production-related
```

**¿Por qué denegar?**
- Factory es para development/staging
- Deploy a prod es decisión del usuario, no del plan
- Si quieres deployar, lo pedís explícitamente

---

## Comparativa: Antes vs. Después

### ANTES (versión restrictiva)
```json
"allow": [
  git status, git log, git diff, grep, find, ls, cat,
  bash -n, sed (sin -i), cp, mkdir, chmod
],
"ask": [
  git add ⚠️,          ← INTERRUPCIONES FRECUENTES
  git commit ⚠️,       ← INTERRUPCIONES FRECUENTES
  sed -i, mkdir, cp,   ← INTERRUPCIONES OCASIONALES
  rm, git push, git reset
],
"deny": [...]
```

**Resultado:** ~18 interrupciones en 6 tareas

### DESPUÉS (versión con confianza en plan)
```json
"allow": [
  git status, git log, git diff,
  git add ✅,          ← SIN INTERRUPCIONES (EN EL PLAN)
  git commit ✅,       ← SIN INTERRUPCIONES (EN EL PLAN)
  grep, find, ls, cat, bash -n,
  sed (con/sin -i), cp, mkdir, chmod, mv, source
],
"ask": [
  git push, git merge, git rebase, git reset,
  rm, rm -rf,
  Edit(CLAUDE.md), Edit(settings.json)
],
"deny": [...]
```

**Resultado:** 0 interrupciones innecesarias. Solo pedir si algo sale del plan.

---

## 🎯 Resumen por filosofía

| Regla | Lógica | Ejemplo |
|-------|--------|---------|
| **`allow`** | "Está en el plan, confío" | `git add`, `sed -i`, `mkdir` |
| **`ask`** | "No está en el plan, verifiquemos" | `git push`, `git reset`, `rm` |
| **`deny`** | "Nunca debería ocurrir" | `sudo`, `eval`, `npm install`, force push |

---

## 📌 Cómo usar esto

Cuando hagas un plan nuevo:

```markdown
# Plan: Feature X

## Tareas
1. Crear archivo helper
   - Comando: `mkdir -p scripts/lib`
   - Comando: `git add scripts/lib/`
   - Comando: `git commit -m "feat: add helper"`
   
2. Modificar bootstrap.sh
   - Comando: `sed -i "s/OLD/NEW/g" scripts/bootstrap.sh`
   - Comando: `git add scripts/bootstrap.sh`
   - Comando: `git commit -m "refactor: ..."`
```

**Resultado:** Todos esos comandos están en `allow` → ejecutan sin interrupciones.

Si el plan dice "hacer deploy", eso NO está, así que `git push` pediría confirmación (correcto).

---

## ✅ Checklist: ¿Es tu plan pre-aprobado?

- [ ] ¿Especifiqué qué archivos se crean/modifican?
- [ ] ¿Especifiqué qué commits se hacen?
- [ ] ¿No incluyo git push, git merge, git rebase?
- [ ] ¿No incluyo rm, npm install, deploy?
- [ ] ¿Incluyo comandos de lectura/validación sin restricción?

Si todo es SÍ → settings.json es la configuración correcta.
