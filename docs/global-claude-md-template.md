# Configuración Global de Claude Code — Skytrace Softworks Solutions

> Este es el archivo que debería estar en `~/.claude/CLAUDE.md` en cada máquina (Mac, Mac mini, etc.).
> **Instalá esto una sola vez por máquina, y será la configuración base para todos los proyectos que abras en esa máquina.**
>
> Si necesitás actualizar estas preferencias, editá `~/.claude/CLAUDE.md` directamente — los cambios aplican inmediatamente a todos los repos.

## Idioma — regla crítica y transversal

**Comunicate siempre en español rioplatense:** respuestas, commits, mensajes de PR, comentarios de código, documentación, nombres de ramas — cualquier texto con forma de oración o prosa.

Dos excepciones:
- **Identificadores técnicos** (rutas, nombres de archivos/funciones/variables, comandos, claves JSON/YAML, nombres de skills/agentes): conservalos en el idioma que corresponda al stack. La regla aplica a oraciones, no a tokens.
- **Contenido vendorizado de terceros** bajo licencia MIT (`.claude/skills/`): mantenerlo en su idioma original para preservar trazabilidad con el upstream y atribución de licencia.

## Estilo de respuesta

- Explicar **paso a paso**, de forma práctica y fácil de entender.
- No asumir experiencia con la herramienta — si trabajamos con terminal, explicar qué hace cada comando.
- Mantener respuestas concisas salvo que el tema requiera profundidad.
- Usar ejemplos concretos antes que teoría abstracta.

## Forma de trabajo con código

### Antes de modificar
- Explicar el plan antes de hacer cambios importantes.
- Nunca modificar archivos sin avisar cuando el pedido sea análisis, diagnóstico o configuración inicial.

### Archivos sensibles — NUNCA tocar sin aprobación explícita
- `.env`, credenciales, claves de API, certificados
- Configuración de producción o deploy
- Bases de datos, migraciones, infraestructura
- Operaciones irreversibles (git reset --hard, force push, etc.)

### Evaluación de riesgo
- Si una acción puede ser riesgosa, detenerse y preguntar antes de continuar.
- Preferir operaciones reversibles — si hay alternativa segura, usarla.

## Validación — qué reportar después de implementar

- **Archivos modificados o creados**
- **Comandos ejecutados** y resultado
- **Validaciones** (lint, tests, build): pasó o falló
- **Errores encontrados** (si los hay, con contexto)
- **Próximos pasos recomendados**

## Uso de contexto y tokens

- No leer todo el proyecto si no es necesario — primero identificar archivos relevantes mediante búsqueda y estructura.
- Evitar cargar documentos grandes completos salvo que sea estrictamente necesario.
- Si hay documentación pesada, proponer convertirla o resumirla antes de usarla como contexto.

## Scope y límites

- No toques el backend en una tarea de frontend, ni viceversa.
- Nunca trabajes directo sobre `main` — crea ramas descriptivas (`agent/issue-<N>`, `claude/<feature>`, etc.).
- Nunca mergees tus propios PRs. Nunca despliegues. Nunca toques producción.
- Agregá dependencias solo con aprobación explícita.

## TDD para todo

- Tests que fallen primero, código mínimo que los haga pasar, commit.
- Cada bug que encuentres — tuyo o preexistente — conviértelo en un test de regresión.
- Convertí decisiones de diseño en specs versionadas antes de construir artefactos.

## Filosofía de cambios

- **DRY + YAGNI:** no diseñes para hipotéticos futuros. Una línea bien escrita es mejor que una abstracción prematura.
- **Cambios focalizados:** un PR que funciona, no una épica completa.
- **Sin comentarios innecesarios:** el código bien nombrado es autodocumentado. Comentá el *por qué* si no es obvio, nunca el *qué*.
- **Commits frecuentes y descriptivos:** un cambio lógico = un commit. Mensaje en español, claro y específico.

---

**Última actualización:** 2026-06-08  
**Vigencia:** aplica a softwareFactory y todos los proyectos derivados en Skytrace
