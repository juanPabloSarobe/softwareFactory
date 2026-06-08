# softwareFactory

> Repo "meta" de la Software Factory de Skytrace Softworks Solutions: acá se
> diseña, documenta y versiona la configuración canónica de Claude Code
> (specs, plantillas, subagentes, scripts de bootstrap) que después se instala
> en los repos de trabajo. Ver `docs/superpowers/specs/` para el diseño vigente
> y `docs/superpowers/plans/` para los planes en curso.

## Idioma — regla crítica y transversal

Comunicate siempre en español: respuestas al usuario, commits, mensajes de PR,
comentarios de código, documentación nueva, nombres descriptivos de ramas —
cualquier texto con forma de oración o prosa. Esta regla rige en este repo y se
propaga, vía `templates/CLAUDE.md.template`, a todos los proyectos de la factory
(decisión de diseño en `docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md`,
sección 0).

Dos excepciones, ninguna contradice la regla:
- **Identificadores técnicos** (rutas, nombres de archivos/funciones/variables,
  comandos, claves JSON/YAML, nombres de skills/agentes) van en el idioma que
  corresponda al stack — la regla aplica a oraciones, no a tokens.
- **Contenido vendorizado de terceros** bajo licencia MIT (`.claude/skills/`)
  se mantiene en su idioma original — traducirlo rompería la trazabilidad con
  el upstream y la atribución de licencia.

## Qué es este repo

Cumple un doble rol (spec sección 1): repo "meta" donde se diseña y documenta
la configuración canónica, y fuente de plantillas compartidas (`.claude/`,
`templates/`, `scripts/bootstrap.sh`) que se instalan y actualizan en los repos
de trabajo mediante `scripts/bootstrap.sh`, sin pisar lo que cada uno ya tenga.

## Dónde está cada cosa

- Specs y decisiones de diseño: `docs/superpowers/specs/`
- Planes de implementación: `docs/superpowers/plans/`
- Skills vendorizadas (Superpowers + qa + stop-slop): `.claude/skills/`
- Plantillas para los demás repos: `templates/`
- Subagentes: `.claude/agents/`

## No negociables

- TDD también para artefactos de configuración: el chequeo de verificación
  falla porque el archivo todavía no existe, creás el archivo, el chequeo pasa,
  commiteás.
- Cada decisión de diseño se documenta primero como spec versionada en
  `docs/superpowers/specs/`, y desde ahí se construye el artefacto correspondiente.
- Nunca trabajes directo sobre `main`.
