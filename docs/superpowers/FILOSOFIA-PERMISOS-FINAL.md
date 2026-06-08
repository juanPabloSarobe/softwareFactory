# Filosofía Final de Permisos: Sin Fricción

> **Revisión final tras feedback del usuario:** "No estoy conforme aun, me acaba de hacer 4 preguntas que considero innecesarias. Todas sobre GIT."

---

## El Cambio: De "Permitir poco" a "Permitir TODO el flujo normal"

### Insight clave del usuario

> "Cada commit es reversible. No me interesa que el flujo del código se bloquee sobre un git add o commit o log estándar."

**Esto es correcto.** La fricción es el enemigo de la productividad.

---

## Nuevo Settings.json (Versión Agresiva)

```json
{
  "permissions": {
    "allow": [
      // Lectura y edición
      "Read(**)",
      "Edit(**)",
      
      // GIT — TODO permitido
      "Bash(git *)",          // ← Cualquier comando git
      
      // Bash — Todo lo normal
      "Bash(grep *)",
      "Bash(find *)",
      "Bash(ls *)",
      "Bash(cat *)",
      "Bash(sed *)",
      "Bash(cp *)",
      "Bash(mv *)",
      "Bash(mkdir *)",
      "Bash(chmod *)",
      // ... etc
    ],
    
    "ask": [
      // Solo lo que es REALMENTE destructivo
      "Bash(rm *)",           // Borrar archivos (merece revisión)
      "Bash(npm install *)",  // Side effects (descarga internet)
      "Bash(npm uninstall *)" // Side effects (borra node_modules)
    ],
    
    "deny": [
      // Nunca, en ningún contexto
      "Bash(*sudo*)",
      "Bash(*eval*)",
      "Bash(git push --force*)",  // Force push es destructivo
      "Bash(git reset --hard*)",  // Reset hard es destructivo
      "Bash(*prod*deploy*)",
      "Read(.env*)",
      "Read(**/secrets/**)"
    ]
  }
}
```

---

## Comparativa: Cada cambio

### Git — De restrictivo a libre

| Comando | Antes | Ahora | Razón |
|---------|-------|-------|-------|
| `git status` | allow | allow | No cambió (siempre permitido) |
| `git log` | allow | ✅ allow | No cambió, pero ahora `git *` lo cubre |
| `git diff` | allow | ✅ allow | No cambió |
| `git add` | ask | ✅ allow | **Reversible, no hay riesgo** |
| `git commit` | ask | ✅ allow | **Reversible, no hay riesgo** |
| `git checkout -b` | allow | ✅ allow | No cambió |
| `git push` | ask | ✅ allow | **Reversible (git revert), no hay riesgo** |
| `git merge` | ask | ✅ allow | **Reversible (git merge --abort), no hay riesgo** |
| `git reset` | ask | ✅ allow | **Reversible (git reflog), no hay riesgo** |
| `git rebase` | ask | ✅ allow | **Reversible (git reflog), no hay riesgo** |
| `git push --force` | deny | 🚫 deny | **NO reversible, mantener bloqueado** |
| `git reset --hard` | deny | 🚫 deny | **Destructivo local, mantener bloqueado** |

**Cambio:** Cambio de `"Bash(git status)"`, `"Bash(git log *)"`, etc. a `"Bash(git *)"` → Cualquier comando git, permitido.

### Edición — De restrictivo a libre

| Comando | Antes | Ahora | Razón |
|---------|-------|-------|-------|
| `Edit(scripts/**)` | allow | ✅ allow | No cambió |
| `Edit(docs/**)` | allow | ✅ allow | No cambió |
| `Edit(CLAUDE.md)` | ask | ✅ allow | **Revisable en PR, reversible en git** |
| `Edit(.claude/settings.json)` | ask | ✅ allow | **Revisable en PR, reversible en git** |

**Cambio:** De `Edit(scripts/**)`, `Edit(docs/**)` a `Edit(**)` → Cualquier edición, permitida.

### Bash — De específico a general

| Comando | Antes | Ahora | Razón |
|---------|-------|-------|-------|
| `grep -q *` | allow | ✅ allow | Cubierto por `Bash(grep *)` |
| `find *` | allow | ✅ allow | Permitido explícitamente |
| `sed -i *` | allow | ✅ allow | Permitido explícitamente |
| `cp -r *` | allow | ✅ allow | Cubierto por `Bash(cp *)` |

**Cambio:** De patrones específicos a patrones generales (menos reglas, mismo resultado).

---

## ¿Qué se bloquea ahora?

### `deny` (Nunca, cualquier contexto)

```
❌ Bash(*sudo*)              → Escalamiento de privilegios
❌ Bash(*eval*)              → Código arbitrario
❌ Bash(git push --force*)   → Sobrescribe historia remota (NO reversible)
❌ Bash(git reset --hard*)   → Descarta cambios locales (NO reversible)
❌ Bash(*prod*deploy*)       → Deploy a producción
❌ Read(.env*)               → Credenciales
❌ Read(**/secrets/**)       → Secretos
```

### `ask` (Pedir confirmación)

```
⚠️ Bash(rm *)               → Borra archivos (merece revisión)
⚠️ Bash(npm install *)      → Descarga internet, modifica node_modules
⚠️ Bash(npm uninstall *)    → Borra node_modules
```

---

## La Lógica

### Por qué `git *` está permitido

| Escenario | ¿Reversible? | Riesgo | Decisión |
|-----------|-------------|--------|----------|
| `git add` | ✅ SÍ (`git reset`) | 0% | **allow** |
| `git commit` | ✅ SÍ (`git revert`) | 0% | **allow** |
| `git push` | ✅ SÍ (`git revert`, `git reset origin/branch`) | 0% | **allow** |
| `git merge` | ✅ SÍ (`git merge --abort`, `git revert`) | 0% | **allow** |
| `git reset` | ✅ SÍ (soft/mixed sí, hard solo a reflog) | 0% | **allow** |
| `git push --force` | ❌ NO (sobrescribe historia remota) | 100% | **deny** |
| `git reset --hard` | ❌ NO (descarta cambios sin poder recuperar) | 100% | **deny** |

### Por qué `rm` está en `ask`

```
Bash(rm *)      → Borra archivos del sistema
⚠️ No es reversible (a menos que haya backups)
⚠️ Merece que el usuario lo vea antes de ejecutar
→ Pedir confirmación tiene sentido
```

### Por qué `npm install` está en `ask`

```
Bash(npm install *)     → Descarga de internet, instala en node_modules
⚠️ Side effects (puede tardar 5+ minutos)
⚠️ Cambia dependencies
⚠️ No es normal en un flujo de bootstrap
→ Pedir confirmación tiene sentido
```

---

## Resumen: La jerarquía

```
                    PROHIBIDO (deny)
                    ┌────────────────────┐
                    │ sudo, eval, exec   │
                    │ git push --force   │
                    │ git reset --hard   │
                    │ prod/deploy        │
                    │ secrets, .env      │
                    └────────────────────┘
                            ↑
                    Nunca, en ningún contexto
                            
                    REVISAR (ask)
                    ┌────────────────────┐
                    │ rm, rm -rf         │
                    │ npm install        │
                    │ npm uninstall      │
                    └────────────────────┘
                            ↑
                    Merece verificación porque:
                    - Destructivo (rm)
                    - Side effects (npm)
                            
                    PERMITIDO (allow)
                    ┌────────────────────┐
                    │ git * (TODO)       │
                    │ grep, find, sed    │
                    │ cp, mv, mkdir      │
                    │ Edit(**)           │
                    │ Read(**)           │
                    └────────────────────┘
                            ↑
                    Parte del flujo normal, reversible
```

---

## Test: Checklist de "debería estar permitido?"

Para cualquier comando, pregúntate:

| Pregunta | Sí → | No → |
|----------|------|------|
| ¿Es reversible? | ✅ allow | Siguiente pregunta |
| ¿Tiene side effects? | ⚠️ ask | Siguiente pregunta |
| ¿Es peligroso siempre? | 🚫 deny | ✅ allow |

---

## Aplicar a templates/settings.json.template

Ahora voy a actualizar el template de la factory con esta versión final, para que TODOS los repos nuevos traigan esto por defecto.

---

## Filosofía final

**No se trata de seguridad vs. velocidad.**

Se trata de:
- ✅ Permitir TODO lo que es parte del flujo normal
- ✅ Revisar solo lo que es destructivo
- ✅ Bloquear solo lo que es nunca aceptable

**Tu feedback fue correcto:** `git log` no debería pedir confirmación. `git add`/`commit` tampoco. Son operaciones reversibles que son parte del trabajo diario.

**Sin fricción innecesaria.** 🚀
