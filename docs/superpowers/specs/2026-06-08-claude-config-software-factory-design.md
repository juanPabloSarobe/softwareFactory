# Diseño: configuración de Claude Code para la Software Factory (Fase 1)

> Spec derivada de `software_factory_ia_plan.md` (documento consolidado del proyecto).
> Define QUÉ skills, conectores, subagentes y permisos configurar en Claude Code para
> que el agente sea un buen desarrollador, ahorre tokens, y pueda construir de forma
> autónoma una vez que un proyecto está completamente definido y aprobado.
>
> Resultado esperado: spec (este documento) + plantillas/artefactos versionados en este
> repo, listos para instalarse en cualquier repo de trabajo (empezando por el piloto CO2).

-----

## 0. Idioma de trabajo — regla crítica y transversal

**El español es el idioma por defecto de absolutamente todo en la factory**:
respuestas del agente, commits, mensajes de PR, comentarios de código,
documentación, specs, planes, nombres descriptivos de ramas — cualquier texto
con forma de oración o prosa. Esto vale tanto para este repo "meta" como para
cada proyecto de trabajo que instale esta configuración.

Dos excepciones explícitas, ninguna contradice la regla:
- **Identificadores técnicos** (rutas, nombres de archivos/funciones/variables,
  comandos, claves JSON/YAML, nombres de skills/agentes) se mantienen en el
  idioma que corresponda al stack — la regla aplica a oraciones, no a tokens.
- **Contenido vendorizado de terceros** bajo licencia MIT (`.claude/skills/`,
  ver sección 2) se mantiene en su idioma original — traducirlo rompería la
  trazabilidad con el upstream y complicaría la atribución de licencia.

Esta regla se propaga de forma versionada vía `templates/CLAUDE.md.template`
(sección 7): cada repo que corra `scripts/bootstrap.sh` la recibe como
"no negociable" desde el primer día, y este mismo repo la declara en su propio
`CLAUDE.md`.

-----

## 1. Alcance y rol de este repo

`softwareFactory` cumple un doble rol:

1. **Repo "meta"**: acá se diseña, discute y documenta la configuración canónica
   (specs como esta, decisiones, aprendizajes de campo).
2. **Fuente de plantillas compartidas**: `.claude/`, `templates/` y `scripts/bootstrap.sh`
   viven acá, versionados, y se instalan/actualizan en los repos de trabajo
   (`fullcontrol-platform`, `fullcontrol-mobile`, módulo CO2, etc.) mediante un script
   de bootstrap — sin pisar lo que cada repo ya tenga de custom.

Cada aprendizaje de campo (como los de la sección 15 del documento original) se
incorpora primero acá, documentado, y desde acá se propaga. Esto convierte cada
piloto en una mejora versionada del "ADN" de la factory, coherente con la idea de
que "el proceso es también contenido" (material reusable para cursos/charlas).

### 1.1 Estructura de archivos propuesta

```text
softwareFactory/
├── docs/
│   └── superpowers/specs/        ← specs de diseño (este documento)
├── .claude/
│   ├── skills/                   ← Superpowers (ya instalado) + las que sumemos
│   ├── agents/                   ← definiciones de subagentes (sección 4)
│   └── settings.json             ← plantilla de permisos (3 tiers, sección 5)
├── templates/
│   ├── CLAUDE.md.template
│   ├── AGENT_WORKFLOW.md.template
│   ├── settings.json.template
│   └── github/
│       ├── workflows/ci.yml
│       └── pull_request_template.md
└── scripts/
    └── bootstrap.sh              ← instala/actualiza la config en un repo de trabajo
```

`bootstrap.sh <ruta-del-repo>` copia las plantillas, sustituye placeholders
(nombre del proyecto, stack detectado, etc.) y deja un `.claude/` funcional —
sin sobrescribir personalizaciones existentes.

-----

## 2. Skills: metodología base

**Decisión:** Superpowers (ya instalado en `.claude/skills/`) reemplaza la apuesta
original por gstack como metodología principal — cubre, sin dependencias externas
(sin Bun/Conductor/gbrain), casi todo lo que el documento original buscaba resolver:

| Necesidad | Cubierta por (Superpowers) |
|---|---|
| Forzar supuestos antes de codear | `brainstorming` |
| Plan técnico revisable, tareas chicas | `writing-plans` |
| Ejecutar el plan con revisión en dos etapas | `subagent-driven-development` / `executing-plans` |
| Disciplina TDD ("verde = correcto") | `test-driven-development`, `verification-before-completion` |
| Debugging riguroso (causa raíz) | `systematic-debugging` |
| Revisión de código (proceso) | `requesting-code-review`, `receiving-code-review` |

**Único cherry-pick de gstack: `/qa`** — QA visual con Playwright que además genera
tests de regresión automáticamente; no tiene equivalente en Superpowers y conecta
directo con la convención "todo bug → test de regresión" (secciones 10.3/15.2 del
documento original).

Quedan **fuera** de gstack: `/office-hours`, `/plan-eng-review`, `/review`, `/ship`,
`/freeze`/`/guard` — cubiertos igual o mejor por Superpowers + permisos nativos
(`deny` sobre `Edit(tests/**)` cumple el rol de `/freeze`/`/guard` sin tooling extra).

### 2.1 Skills adicionales a instalar

| Skill | Para qué | Por qué suma (no duplica) |
|---|---|---|
| **Frontend Design** (oficial Anthropic) | Decisiones estéticas concretas en UI — evita el "look genérico de IA" | Mejora directa de calidad visual de dashboards/frontend, sin proceso extra |
| **Remotion** | El agente escribe código React/Remotion para generar video programático | Sirve al objetivo de contenido para cursos/charlas (sección 4 del doc) — única pieza que cubre video |
| **Stop Slop** | Saca "tics de IA" de prosa (PRs, decision logs, material de cursos) | Mejora la calidad del contenido publicable que la factory genera como subproducto |

`simplify` (revisión de reuso/DRY/eficiencia de código) ya viene con el harness —
no requiere instalación, y complementa (no duplica) las skills de revisión de
Superpowers: una ataca el código ya escrito, las otras el *proceso* de revisión.

### 2.2 Evaluadas y descartadas (con razón documentada)

- **claude-mem**: descartado — ver sección 4.1 (riesgo de seguridad).
- **Sequential Thinking MCP**: redundante con el razonamiento extendido nativo +
  `brainstorming`/`systematic-debugging`/`writing-plans`. Sumarlo agregaría llamadas
  a herramienta (más tokens) por algo que ya está resuelto — va en contra del
  objetivo de ahorro de tokens.
- **UI/UX Pro Max**: redundante con Frontend Design (ambas atacan calidad de UI).
  Se revisita más adelante *específicamente* por su auditor de accesibilidad
  (contraste/ARIA), si llegara a ser una necesidad real para un producto que se
  vende a empresas.
- **NotebookLM MCP**: el beneficio (≈30% menos tokens consultando una base curada
  con citas) es real, pero el conector no tiene API oficial — funciona vía
  automatización de navegador contra APIs internas de Google (frágil, zona gris de
  ToS). Se evalúa en una fase posterior, cuando el flujo base esté estable.

-----

## 3. Conectores (MCP servers y herramientas)

| Necesidad | Conector / herramienta | Nota |
|---|---|---|
| GitHub | **MCP server oficial de GitHub** | Tool calls estructurados en vez de parsear texto de `gh` — más confiable, menos tokens de parsing. `gh` queda como respaldo |
| Datos (DB) | **NO** un MCP genérico — script auditado `db-query.sh` (diseño ya cerrado en sección 7 del doc original: replica + `agent_ro` + IAM + log) | Camino angosto: la única interfaz son `db-query-agent` + el script. Un MCP de DB genérico daría más superficie de la necesaria |
| Notificaciones | Telegram vía **Claude Code Channels** | Resuelve "avisame en checkpoint / duda bloqueante / PR listo" sin la superficie de riesgo de un orquestador completo |
| Diseño | **Figma Dev Mode MCP Server** (oficial) | El agente lee specs/componentes del diseño aprobado directamente — menos ida y vuelta en texto, UI más fiel |
| Monitoreo/observabilidad | Conector **read-only** al servicio en uso (Sentry/CloudWatch/Datadog/etc.) | Mismo patrón de mínimo privilegio que el diseño de DB: rol de solo lectura, acotado, auditado |
| QA visual | **Playwright MCP** | Da herramientas nativas de browser para `/qa` — más auditable que invocar un comando externo |
| Documentación de librerías | MCP de docs (ej. Context7) | El agente consulta la doc *actual* de una API en vez de adivinar desde su training o quemar tokens en búsqueda web genérica — pega directo en "ahorrar tokens" y "menos vueltas de corrección" |

### 3.1 Reemplazo de "memoria persistida" (sin instalar nada nuevo)

En vez de un plugin de memoria de terceros, la combinación de piezas **nativas**
cubre la misma necesidad sin exponer un servicio sin autenticación:

| Pieza | Qué cubre |
|---|---|
| **Auto Memory** (`MEMORY.md` nativo de Claude Code) | Memoria automática entre sesiones — archivo local, sin API HTTP expuesta |
| **`CLAUDE.md`** | Contexto persistente versionado, escrito a mano |
| **Decision log / ADR** (sección 4 del doc original) | Memoria del *por qué* — texto corto versionado, doble uso: contexto futuro + material de cursos |
| **Specs en `docs/`** (lo que produce `brainstorming`) | Memoria del *qué* se diseñó/aprobó |
| **GitHub Issues** (sección 12 del doc original) | Memoria del *estado* de cada unidad de trabajo |

Resultado: memoria igual de útil, pero **legible, auditable y versionada** — en vez
de una caja negra comprimida por IA corriendo en background.

### 3.2 Evaluado y descartado: claude-mem

Una auditoría comunitaria (feb-2026) calificó el riesgo como **ALTO**: su API HTTP
local (puerto 37777) no tiene autenticación — cualquier proceso de la máquina puede
leer todas las observaciones guardadas (incluidas API keys en texto plano) e
inyectar memorias arbitrarias. Esto choca de frente con todo el diseño de mínimo
privilegio de la sección 7 del documento original ("no hay secreto en disco" /
"todo auditado"). Instalarlo en la Mac mini anularía buena parte de ese trabajo.

-----

## 4. Subagentes especializados

La skill `subagent-driven-development` ya trae tres roles listos
(`implementer-prompt.md`, `spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`)
— el ciclo "implementador → revisor de spec → revisor de calidad" viene de fábrica,
no hay que redefinirlo.

Se agregan tres subagentes de **dominio**, cada uno con contrato de entrada/salida
angosto — diseñados para mantener el contexto del agente principal limpio
(leer/procesar mucho en un contexto aislado, devolver solo la síntesis):

| Subagente | Rol | Por qué como subagente |
|---|---|---|
| **`db-query-agent`** | Única interfaz a los datos: recibe una pregunta en lenguaje natural, corre `db-query.sh`, devuelve una respuesta sintetizada — nunca filas crudas | Materializa el "camino angosto" de la sección 7: la credencial vive solo acá. Evita que un resultado de miles de filas inunde el contexto principal |
| **`qa-visual-agent`** | Corre `/qa` (Playwright MCP), detecta roturas, y convierte cada hallazgo en test de regresión (convención secciones 10.3/15.2) | Una corrida de QA visual genera mucho ruido (screenshots, logs); aislarlo evita que compita por atención en el contexto de quien implementa |
| **`research-agent`** | Digiere documentos largos (specs de integración, docs de terceros) vía MCP de documentación, devuelve un resumen accionable | Antídoto directo a que una sesión larga se quede sin contexto por leer documentos completos |

### 4.1 Lo que NO se modela como subagente (y por qué)

- **Notificaciones (Telegram)**: no requiere razonamiento — un **hook** (evento → script
  → Telegram) lo resuelve gratis e instantáneo. Modelarlo como subagente sería gastar
  tokens en algo más barato de resolver de otra forma.
- **Decision log / ADR**: necesita el mismo contexto que ya tiene quien tomó la
  decisión — mejor como paso dentro de `writing-plans`/`finishing-a-development-branch`
  que como subagente aparte.

-----

## 5. Modelo de permisos (`settings.json`, los 3 tiers)

Traducción de la matriz de la sección 7 del documento original a patrones concretos.
**Nota:** las rutas (`frontend/**`, `backend/**`, `**/migrations/**`, etc.) son
ilustrativas — `bootstrap.sh` debe adaptarlas a la estructura real de cada repo de
trabajo al instalar la plantilla, no copiarse literal.

```jsonc
{
  "permissions": {
    "allow": [
      // Lectura, exploración, diagnóstico
      "Read(**)", "Grep", "Glob",
      "Bash(git status)", "Bash(git diff *)", "Bash(git log *)",
      "Bash(git checkout -b agent/*)",

      // Validación y levantar el proyecto
      "Bash(npm run lint*)", "Bash(npm test*)", "Bash(npm run build*)",
      "Bash(npm run dev*)",

      // Skills de metodología
      "Skill(brainstorming)", "Skill(writing-plans)", "Skill(test-driven-development)",
      "Skill(systematic-debugging)", "Skill(requesting-code-review)", "Skill(/qa)",

      // Conectores de solo-consulta / generación
      "mcp__github__pull_request_read", "mcp__github__create_pull_request",
      "mcp__figma__*", "mcp__playwright__*",
      "Task(db-query-agent)", "Task(qa-visual-agent)", "Task(research-agent)",

      // Frontend cuando la tarea lo habilita, documentación
      "Edit(frontend/**)", "Write(docs/**)"
    ],

    "ask": [
      "Bash(npm install*)", "Bash(npm uninstall*)",
      "Edit(backend/**)",
      "Edit(**/migrations/**)", "Edit(**/models/**)",
      "Edit(**/openapi.yaml)", "Edit(**/contracts/**)",
      "Edit(**/auth/**)",
      "Edit(tests/**)",
      "Edit(.github/workflows/**)", "Edit(**/deploy/**)",
      "Bash(git push *)"
    ],

    "deny": [
      "Bash(*prod*deploy*)", "Bash(*--env=production*)",
      "Bash(psql *)", "Bash(pg_dump *)", "Bash(mysql *)",
      "Bash(* DROP *)", "Bash(* TRUNCATE *)", "Bash(* DELETE FROM *)",
      "Read(.env*)", "Read(**/*.pem)", "Read(**/secrets/**)",
      "Bash(aws *)", "Bash(*route53*)", "Bash(*certbot*)",
      "Bash(git push * main)", "Bash(git push --force*)",
      "Bash(git branch -D main)", "Bash(git branch -D master)"
    ]
  }
}
```

**Tres decisiones a destacar:**

1. **`git push` en `ask`** (incluso a ramas `agent/*`): es el último paso antes de
   que el trabajo se vuelva visible/revisable. Un solo punto de confirmación ahí
   es barato y cierra el círculo de "autonomía controlada".
2. **Clientes de DB directos (`psql`, etc.) en `deny`**: no por desconfianza, sino
   para *forzar* que `db-query-agent` sea la única puerta — si existiera un atajo,
   alguna sesión lo tomaría "para ir más rápido".
3. **Edición de tests en `ask`**: mitigación directa al riesgo #1 de la sección 9
   del documento original (el agente "hace pasar" el test en vez de arreglar el bug).
   Preserva "verde = correcto".

### 5.1 Anticipar `ask`/`deny` durante la planificación, no solo reaccionar

Decisión que surgió de revisar el flujo completo con el dueño del proyecto: los
3 tiers garantizan que el agente *se frene* en el momento correcto (`ask`) o
*ni lo intente* (`deny`) — pero no garantizan que la persona sepa, **de
antemano**, cuándo va a hacer falta su presencia o qué parte del trabajo va a
quedar fuera del alcance del agente. Sin ese aviso anticipado, se entera a
mitad de la implementación, justo cuando menos conviene interrumpir un proceso
que venía corriendo solo.

Por eso `AGENT_WORKFLOW.md.template` debe incluir, en la fase de
"Descubrimiento" (antes de pedir "APROBADO PARA IMPLEMENTAR"), un paso
explícito: cruzar el plan propuesto contra `.claude/settings.json` y reportar
dos cosas por separado:

- **Qué partes van a requerir aprobación en el momento (`ask`)** — para que la
  persona sepa de antemano cuándo su presencia va a ser necesaria y pueda
  planificar su disponibilidad en consecuencia.
- **Qué partes son operaciones irreversibles bloqueadas de plano (`deny`)** —
  detectadas *en la planificación*, no descubiertas a mitad de camino. Para
  esas, el agente no se limita a decir "esto no lo puedo hacer": entrega un
  artefacto preciso y ya pensado (migración, script, runbook con pasos y
  validaciones) listo para que la persona lo ejecute por su cuenta, cuando
  quiera, con sus propias salvaguardas (backup, ambiente de staging). La
  diferencia frente a "andá y hacelo vos" es que el agente ya hizo el trabajo
  de pensar y escribir la operación — a la persona le queda apretar el gatillo
  con contexto completo, no investigar desde cero.

Esto no afloja ningún `deny` de la sección anterior — sigue siendo una pared
dura, por la misma razón que llevó a poner ahí los clientes de DB directos
(decisión #2 arriba): el costo de un error en una operación irreversible es
inaceptable, así que se le exige al agente el mismo cuidado que a la persona
más prudente del equipo, no menos. Lo único que cambia es *cuándo* se entera
la persona de que esa pared existe — antes de arrancar, no en medio del proceso.

-----

## 6. Estrategia de ahorro de tokens

No son piezas nuevas — es el criterio que amarra las decisiones de las secciones 2 a 5.
La premisa: gastar de más y perder calidad comparten la misma causa raíz (un contexto
saturado de cosas irrelevantes). Cuatro mecanismos:

1. **Aislar el ruido en subagentes** (sección 4): `db-query-agent`, `qa-visual-agent`
   y `research-agent` procesan volumen en un contexto descartable; solo la síntesis
   vuelve al agente principal.
2. **No sumar herramientas que el modelo ya resuelve nativamente**: el criterio que
   descartó Sequential Thinking MCP — antes de sumar una herramienta, preguntar si
   Claude ya lo resuelve solo (con razonamiento extendido + las skills instaladas).
3. **`CLAUDE.md` liviano que apunta, no que vuelca**: reglas estables y cortas
   (< ~200 líneas); specs, decision logs y contratos viven en `docs/` y se leen bajo
   demanda. Así ya funcionan `brainstorming` (escribe a `docs/superpowers/specs/`) y
   `db-query-agent` (la credencial vive en su propio tool, no en el contexto principal).
4. **Corridas chicas hasta un checkpoint** (riesgo #2, sección 9 del doc original):
   ya estaba decidido — "muchas corridas chicas > una gigante". `subagent-driven-development`
   lo formaliza: subagente fresco por tarea, contexto que no se arrastra.

-----

## 7. Próximos pasos / artefactos a generar

- [x] `templates/settings.json.template` a partir de la sección 5
- [x] `templates/CLAUDE.md.template` y `templates/AGENT_WORKFLOW.md.template`
      (siguiendo el criterio de "liviano que apunta", sección 6)
- [x] Definiciones de `db-query-agent`, `qa-visual-agent`, `research-agent` en `.claude/agents/`
- [x] Vendorizar las skills propias del repo: Stop Slop, `/qa` (gstack)
- [ ] Instalar por canal oficial las skills con licencia restrictiva: Frontend Design, Remotion
      (no se pueden vendorizar — quedan documentadas en `docs/external-setup-checklist.md`)
- [ ] Configurar conectores: GitHub MCP, Figma MCP, Playwright MCP, MCP de docs, Telegram Channels
      (necesitan credenciales vivas por máquina/cuenta — quedan documentados en `docs/external-setup-checklist.md`)
- [x] `scripts/bootstrap.sh` para instalar/actualizar esta config en repos de trabajo
- [x] `templates/github/workflows/ci.yml` y `pull_request_template.md`

-----

## 8. Trazabilidad

Esta spec es resultado de una sesión de brainstorming que partió de
`software_factory_ia_plan.md` (documento consolidado, junio 2026) y de la
instalación de las skills de Superpowers (commit `8e6c2d3`). Reemplaza, para el
alcance de "Fase 1: configuración de Claude", las definiciones pendientes que ese
documento dejaba abiertas en su sección 17 ("Pendientes"): selección de skills,
detalle fino de tiers de permisos, y artefactos base (`settings.json`, `AGENT_WORKFLOW.md`,
`CLAUDE.md`).
