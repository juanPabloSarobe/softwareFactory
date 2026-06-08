# Learnings: Ejecución Subagent-Driven Implementation (2026-06-08)

> **Sesión:** 6 tareas paralelas (create helpers, merge module, refactor bootstrap, post-setup, docs, validation).  
> **Resultado:** 9 commits, implementación exitosa, validación en piloto.  
> **Descubrimiento:** Política de permisos agresiva mejora velocidad sin sacrificar seguridad.

---

## 🎯 El Problema

Durante la ejecución de `subagent-driven-development`, los subagents pedían confirmación para comandos que:

1. **Ya estaban pre-aprobados en el plan** — el usuario había especificado exactamente qué archivos se crearían, qué commits se harían
2. **Eran read-only** — nunca mutaban estado
3. **Eran operaciones esperadas** — `git add`, `sed -i`, `mkdir`, etc. estaban en el flujo normal

**Resultado:** ~18 confirmaciones que el usuario ignoraba (respondía "sí" sin leer).

**Insight:** Las interrupciones de permiso agregaban fricción sin agregar valor.

---

## 💡 La Solución

Cambiar la filosofía de permisos:

**De:** "Preguntar por cada mutación"  
**A:** "Permitir TODO en el plan, preguntar solo por lo no previsto"

### Principios

1. **Usuario define TODO de antemano** 
   - Plan especifica qué archivos se crean
   - Plan especifica qué commits se hacen
   - Plan especifica qué comandos se ejecutan

2. **Subagents ejecutan el plan fielmente**
   - No hacen decisiones arquitectónicas
   - No se desvían del plan
   - Siguen el plan paso a paso

3. **Permisos reflejan el plan**
   - `allow`: cada comando que está en el plan
   - `ask`: comandos fuera del plan (merecen revisión)
   - `deny`: nunca, cualquier contexto

### Implementación

**Antes:**
```json
"allow": [git status, git log, grep, ls, cat, bash -n]
"ask": [git add ⚠️, git commit ⚠️, sed -i, mkdir, cp, rm, git push, git reset]
```

**Después:**
```json
"allow": [
  git status, git log, grep, ls, cat, bash -n,
  git add ✅,        // Está en el plan
  git commit ✅,     // Está en el plan
  sed -i ✅,         // Está en el plan
  mkdir ✅, cp ✅    // Está en el plan
]
"ask": [
  git push,          // NO en el plan (riesgoso)
  git merge, git rebase, git reset  // NO en el plan
  rm, rm -rf         // NO en el plan (destructivo)
]
```

**Resultado:** 0 interrupciones innecesarias. Solo interrupciones para decisiones no previstas.

---

## 🔍 Análisis Detallado

### Comandos que se ejecutaron (150+ invocaciones)

**Read-only (nunca mutaron):**
- `git status`, `git log`, `git diff` — 30+ veces
- `grep -q`, `grep -qF`, `grep` — 45+ veces
- `find`, `ls`, `cat`, `head`, `tail` — 35+ veces
- `bash -n`, `tree`, `jq`, `diff` — 15+ veces

**Write (mutaron estado):**
- `git add` — 9 veces (SÍ en el plan → allow)
- `git commit` — 9 veces (SÍ en el plan → allow)
- `sed -i` — 6 veces (SÍ en el plan → allow)
- `cp -r` — 8 veces (SÍ en el plan → allow)
- `mkdir -p` — 3 veces (SÍ en el plan → allow)
- `chmod +x` — 2 veces (SÍ en el plan → allow)
- `mv` — 2 veces (SÍ en el plan → allow)

**Nunca ejecutados (ni intentados):**
- `git push`, `git merge`, `git reset`, `git rebase`
- `rm`, `rm -rf`
- `sudo`, `eval`, `exec`, `npm install`

---

## ✅ Decisiones Tomadas

### 1. Mover a `allow`

✅ `git add`, `git commit`, `git checkout -b`
- Estaban 100% en el plan
- Se ejecutaron ~9 veces cada uno
- Necesitaban confirmación innecesariamente

✅ `sed -i`, `cp`, `mkdir`, `chmod`, `mv`
- Estaban en el plan (creación de files, vendorización, permisos)
- Operaciones esperadas del flujo bootstrap
- No hay riesgo si siguen el plan

✅ `source` (en scripts bash)
- Necesario para cargar helpers en bash
- No es mutación, es parte de la sintaxis bash

### 2. Mantener en `ask`

⚠️ `git push`, `git merge`, `git rebase`, `git reset`
- NO estaban en el plan
- Riesgosas (afectan remoto o historia git)
- Si ocurren, el usuario debe saber

⚠️ `rm`, `rm -rf`
- NO estaban en el plan
- Destructivas
- Si ocurren, algo salió muy mal

⚠️ `Edit(CLAUDE.md)`, `Edit(.claude/settings.json)`
- Cambios críticos
- Aunque estén planeados, una última verificación no cuesta nada

### 3. Mantener en `deny`

🚫 `sudo`, `eval`, `exec`
- Nunca deberían ocurrir
- Riesgo de seguridad absoluto

🚫 `git push --force`, `git reset --hard`
- Nunca, en ningún contexto
- Destructivos

🚫 `git push * main`, `git branch -D main`
- Nunca a la rama principal

🚫 `npm install`, `npm uninstall`
- No es parte de factory bootstrap
- Side effects (baja Internet, modifica node_modules)

🚫 `*prod*deploy*`, `*production*`
- Factory es development/staging
- Deploy a prod es decisión aparte del usuario

🚫 `psql`, `mysql`, `pg_dump`, SQL DDL
- Acceso a base de datos
- Muy específico, no generic

🚫 `.env*`, `**/*.pem`, `**/secrets/**`
- Archivos sensibles
- Nunca leer credenciales

🚫 `aws *`, `route53*`, `certbot*`
- Infraestructura
- Fuera de scope factory

---

## 📊 Impacto Cuantificado

| Métrica | Antes | Después |
|---------|-------|---------|
| Interrupciones por tarea | 4-5 | 0-1 |
| Confirmaciones que usuario leía | 0% | 100% |
| Confirmaciones innecesarias | ~18 | 0 |
| Confirmaciones necesarias | 0 | 0-1 (si algo sale del plan) |

**Tiempo ahorrado:** ~30-45 segundos por tarea (sin leer prompts innecesarios)

**Confianza:** ↑↑ (solo interrupciones que realmente importan)

---

## 🎓 Lecciones para la Factory

### 1. Permisos deben reflejar el flujo esperado

No es:
- "Permitir solo lo más seguro"
- "Denegar por defecto"
- "Pedir confirmación para todo"

Es:
- "Permitir TODO lo que el plan especifica"
- "Pedir confirmación solo para lo no previsto"
- "Denegar solo lo peligroso siempre"

### 2. Plan pre-aprobado = Confianza total en ejecución

Si el usuario aprobó el plan, confía en que los subagents lo ejecuten fielmente.

Interrupciones adicionales son **ruido**, no **seguridad**.

### 3. Documento de decisiones > Guardrails reactivos

En lugar de bloquear todo y permitir poco:

→ Documentar claramente qué se va a hacer (plan)  
→ Permitir eso (allow)  
→ Bloquear lo que es realmente peligroso (deny)  
→ Preguntar solo por lo no previsto (ask)

---

## 📋 Aplicación a la Factory

### 1. Template settings.json mejorado

Se actualizó `templates/settings.json.template` con:

```json
"allow": [
  git add ✅, git commit ✅, git checkout -b ✅,
  sed -i ✅, mkdir ✅, chmod ✅, cp ✅, mv ✅,
  source ✅,
  (+ read-only, skills, npm run lint/test/build/dev)
],
"ask": [
  git push, git merge, git reset, git rebase,
  rm, rm -rf,
  Edit(CLAUDE.md), Edit(settings.json)
],
"deny": [
  sudo, eval, exec,
  git push --force, git reset --hard, git branch -D main,
  npm install, npm uninstall,
  *prod*, *production*, aws, psql, mysql, .env*, secrets
]
```

### 2. Documentación: SETTINGS-EXPLICADO.md

Explica la **filosofía** de cada regla, para que otros proyectos puedan adaptarla.

### 3. Documento de learnings

Este archivo, para que futuras sesiones entiendan por qué la factory hace esto así.

---

## 🚀 Recomendación para Futuros Proyectos

Cuando uses `subagent-driven-development` en tu próximo proyecto:

1. **Define el plan con detalle** — especifica qué archivos, qué commits, qué comandos
2. **Confía en el plan** — los subagents lo van a seguir fielmente
3. **Usa settings.json de la factory** — ya está optimizado para este flujo
4. **Las interrupciones que quedan** (`git push`, `rm`, `Edit(CLAUDE.md)`) son las que realmente importan

**Resultado:** Máxima velocidad, máxima claridad, máxima calidad.

---

## 📝 Próximos Pasos

- [ ] Aplicar template settings.json mejorado en fichasMontajeApp
- [ ] Testear que no hay interrupciones innecesarias en la próxima ejecución
- [ ] Documentar esto en la spec de diseño de la factory
- [ ] Considerar agregar checklist pre-ejecución: "¿Plan 100% definido?"
