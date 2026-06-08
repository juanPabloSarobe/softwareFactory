# Plan de implementación: artefactos de configuración de Claude

> **Para quien ejecute este plan como agente:** SUB-SKILL REQUERIDA: usá superpowers:subagent-driven-development (recomendada) o superpowers:executing-plans para implementar este plan tarea por tarea. Los pasos usan sintaxis de checkbox (`- [ ]`) para el seguimiento.

**Objetivo:** Producir las plantillas versionadas, definiciones de subagentes, skills vendorizadas y el script de bootstrap descritos en `docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md`, para que la configuración canónica de Claude Code de la Software Factory pueda instalarse en cualquier repo de trabajo.

**Arquitectura:** Trabajo puro de creación de archivos (sin runtime de aplicación). Cada tarea crea un artefacto autocontenido (plantilla, definición de agente, skill vendorizada o script) más un comando de verificación que prueba que el artefacto está bien formado — el equivalente, para archivos de configuración, del rojo/verde: escribir un chequeo que falla porque el archivo no existe, crear el archivo, ver que el chequeo pasa, commitear.

**Stack técnico:** Bash, JSON, YAML, Markdown con frontmatter YAML. Verificación vía `python3` (módulos `json`/`yaml`, ambos confirmados presentes), `jq` (confirmado presente), `bash -n`.

---

## Antes de empezar

Dos repos fuente se vendorizan bajo sus licencias MIT (mismo patrón que el `.claude/skills/` ya existente de Superpowers, ver commit `8e6c2d3`):
- `https://github.com/garrytan/gstack` → su directorio `qa/` (la skill `/qa` elegida en la sección 2 de la spec)
- `https://github.com/hardikpandya/stop-slop` → el repo completo (la skill `stop-slop`)

Ambos se verificaron como licenciados bajo MIT durante la planificación. **Frontend Design** (Anthropic, términos propietarios "todos los derechos reservados") y **Remotion** (licencia Remotion personalizada, restrictiva para empresas grandes) deliberadamente **no** se vendorizan — la Tarea 12 documenta cómo instalarlos por sus canales oficiales en su lugar.

**Idioma de los artefactos (decisión añadida en spec sección 0):** todo el
contenido que nosotros redactamos — plantillas, definiciones de subagentes,
notices, checklist, comentarios y mensajes de `bootstrap.sh` — va en español:
es prosa que alguien va a leer, no identificadores técnicos. El contenido
*vendorizado* de terceros (Tareas 9 y 10: los `SKILL.md`/`references/` que
vienen de `gstack` y `stop-slop`, igual que las skills de Superpowers ya
instaladas) se copia tal cual, en su idioma original — traducir contenido de
upstream rompería la trazabilidad y la atribución de licencia. Lo único que
redactamos nosotros dentro de esos directorios — el `THIRD-PARTY-NOTICE.md` —
sí va en español.

---

### Tarea 1: `templates/settings.json.template`

**Archivos:**
- Crear: `templates/settings.json.template`

- [ ] **Paso 1: Escribir el chequeo de verificación (debería fallar — el archivo todavía no existe)**

Ejecutar: `python3 -m json.tool templates/settings.json.template > /dev/null && echo VALID_JSON`
Resultado esperado: FALLA con "No such file or directory"

- [ ] **Paso 2: Crear la plantilla**

Escribir `templates/settings.json.template`:

```json
{
  "permissions": {
    "allow": [
      "Read(**)",
      "Grep",
      "Glob",
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(git checkout -b agent/*)",
      "Bash(npm run lint*)",
      "Bash(npm test*)",
      "Bash(npm run build*)",
      "Bash(npm run dev*)",
      "Skill(brainstorming)",
      "Skill(writing-plans)",
      "Skill(test-driven-development)",
      "Skill(systematic-debugging)",
      "Skill(requesting-code-review)",
      "Skill(qa)",
      "Task(db-query-agent)",
      "Task(qa-visual-agent)",
      "Task(research-agent)",
      "Write(docs/**)"
    ],
    "ask": [
      "Bash(npm install*)",
      "Bash(npm uninstall*)",
      "Edit(**/migrations/**)",
      "Edit(**/models/**)",
      "Edit(**/openapi.yaml)",
      "Edit(**/contracts/**)",
      "Edit(**/auth/**)",
      "Edit(tests/**)",
      "Edit(.github/workflows/**)",
      "Edit(**/deploy/**)",
      "Bash(git push *)"
    ],
    "deny": [
      "Bash(*prod*deploy*)",
      "Bash(*--env=production*)",
      "Bash(psql *)",
      "Bash(pg_dump *)",
      "Bash(mysql *)",
      "Bash(* DROP *)",
      "Bash(* TRUNCATE *)",
      "Bash(* DELETE FROM *)",
      "Read(.env*)",
      "Read(**/*.pem)",
      "Read(**/secrets/**)",
      "Bash(aws *)",
      "Bash(*route53*)",
      "Bash(*certbot*)",
      "Bash(git push * main)",
      "Bash(git push --force*)",
      "Bash(git branch -D main)",
      "Bash(git branch -D master)"
    ]
  }
}
```

> Nota: esta es la base genérica de la sección 5 de la spec. Omite a propósito
> rutas específicas de cada repo como `frontend/**`/`backend/**` — la Tarea 11
> (bootstrap.sh) le indica al operador agregarlas a mano según el layout real
> de cada repo.

- [ ] **Paso 3: Volver a correr el chequeo de verificación**

Ejecutar: `python3 -m json.tool templates/settings.json.template > /dev/null && echo VALID_JSON`
Resultado esperado: `VALID_JSON`

- [ ] **Paso 4: Commitear**

```bash
git add templates/settings.json.template
git commit -m "Agregar plantilla de settings.json con la base de permisos de 3 niveles"
```

---

### Tarea 2: `templates/CLAUDE.md.template`

**Archivos:**
- Crear: `templates/CLAUDE.md.template`

- [ ] **Paso 1: Escribir el chequeo de verificación (debería fallar)**

Ejecutar: `test -f templates/CLAUDE.md.template && wc -l < templates/CLAUDE.md.template`
Resultado esperado: FALLA ("No such file or directory")

- [ ] **Paso 2: Crear la plantilla**

Escribir `templates/CLAUDE.md.template`:

```markdown
# {{PROJECT_NAME}}

> Configuración del agente para {{PROJECT_NAME}}, parte del programa Skytrace /
> Software Factory. Mantené este archivo en menos de ~200 líneas — todo lo
> extenso va en `docs/`, enlazado desde acá, y se lee bajo demanda (ver
> "context engineering", spec sección 6).

## Idioma — regla crítica

Comunicate siempre en español: respuestas al usuario, commits, PRs, comentarios
de código, documentación nueva — cualquier texto en forma de oración. Los
identificadores técnicos (rutas, nombres de funciones, comandos, variables,
claves JSON) se mantienen en el idioma que corresponda al stack; la regla
aplica a la prosa, no a los tokens.

## Qué es este proyecto

{{ONE_PARAGRAPH_DESCRIPTION}}

## Dónde está cada cosa

- Arquitectura y decisiones: `docs/superpowers/specs/`
- Planes en curso: `docs/superpowers/plans/`
- Reglas de flujo de trabajo (ramas, PRs, qué necesita aprobación): `AGENT_WORKFLOW.md`
- Acceso a datos: nunca consultes la base de datos directamente — despachá al
  subagente `db-query-agent`. Los clientes de BD directos están denegados en
  `.claude/settings.json` a propósito.

## Stack

{{STACK_SUMMARY}}

## Comandos

- Lint: `{{LINT_COMMAND}}`
- Test: `{{TEST_COMMAND}}`
- Build: `{{BUILD_COMMAND}}`
- Servidor de desarrollo: `{{DEV_COMMAND}}`

## No negociables

- TDD: red, green, refactor. Nunca escribas implementación antes de un test que falle.
- Todo bug encontrado se convierte en test de regresión — sin excepciones (ver `qa-visual-agent`).
- Los tests no son tuyos para debilitar. Editar `tests/**` requiere preguntar antes.
- Nunca trabajes sobre `main`. Crea ramas como `agent/issue-<N>-<descripción-corta>`.
- Checkpoints chicos: parar en "un PR que funciona", no en "la épica completa".
```

- [ ] **Paso 3: Volver a correr el chequeo de verificación**

Ejecutar: `test -f templates/CLAUDE.md.template && wc -l < templates/CLAUDE.md.template`
Resultado esperado: un número menor que `65` (bien por debajo del presupuesto de ~200 líneas que la propia plantilla establece)

- [ ] **Paso 4: Commitear**

```bash
git add templates/CLAUDE.md.template
git commit -m "Agregar plantilla de CLAUDE.md (liviana, apunta a docs según el criterio de context engineering)"
```

---

### Tarea 3: `templates/AGENT_WORKFLOW.md.template`

**Archivos:**
- Crear: `templates/AGENT_WORKFLOW.md.template`

- [ ] **Paso 1: Escribir el chequeo de verificación (debería fallar)**

Ejecutar: `grep -c "APROBADO PARA IMPLEMENTAR" templates/AGENT_WORKFLOW.md.template`
Resultado esperado: FALLA ("No such file or directory")

- [ ] **Paso 2: Crear la plantilla**

Escribir `templates/AGENT_WORKFLOW.md.template`:

```markdown
# Flujo de trabajo del agente — {{PROJECT_NAME}}

## Reglas generales

- Nunca trabajes directamente sobre `main`. Crea ramas como `agent/issue-<N>-<descripción-corta>`.
- Nunca mergees tus propios PRs. Nunca despliegues. Nunca toques producción.
- Nunca modifiques archivos `.env` ni agregues dependencias sin aprobación explícita.
- Mantenete dentro del alcance — no toques el backend en una tarea de frontend, ni viceversa.

## Descubrimiento (antes de escribir código)

1. Leé completo el issue/spec vinculado.
2. Explorá los archivos relacionados. Seguí los patrones existentes — no inventes nuevos.
3. Preguntá lo que haga falta para eliminar ambigüedad, agrupado en preguntas
   funcionales, técnicas, de datos, de UX y de seguridad.
4. Proponé un plan y esperá las palabras literales **APROBADO PARA IMPLEMENTAR**
   antes de escribir cualquier código de implementación.

## Implementación

- TDD: escribí el test que falla, miralo fallar, escribí el código mínimo, miralo pasar, commiteá.
- Mantené el alcance acotado a un checkpoint — "un PR que funciona", no una épica completa.
- Convertí cada bug que encuentres — tuyo o preexistente — en un test de regresión.

## Validación (antes de abrir un PR)

- Corré lint, tests y build.
- Confirmá que la app arranca: el health check del backend responde, el frontend carga.
- Si hay un cambio de UI, despachá `qa-visual-agent` para QA visual.

## Entrega

Abrí un PR que incluya:
- Resumen funcional — qué cambió y por qué
- Archivos modificados
- Resultados de validación: lint / test / build / QA — pasó o falló, explícitamente
- Riesgos y pendientes
- URL de preview, si existe
```

- [ ] **Paso 3: Volver a correr el chequeo de verificación**

Ejecutar: `grep -c "APROBADO PARA IMPLEMENTAR" templates/AGENT_WORKFLOW.md.template`
Resultado esperado: `1`

- [ ] **Paso 4: Commitear**

```bash
git add templates/AGENT_WORKFLOW.md.template
git commit -m "Agregar plantilla de AGENT_WORKFLOW.md basada en el esqueleto de Fase 1 del plan original"
```

---

### Tarea 4: `templates/github/workflows/ci.yml`

**Archivos:**
- Crear: `templates/github/workflows/ci.yml`

- [ ] **Paso 1: Escribir el chequeo de verificación (debería fallar)**

Ejecutar: `python3 -c "import yaml; yaml.safe_load(open('templates/github/workflows/ci.yml'))" && echo VALID_YAML`
Resultado esperado: FALLA ("No such file or directory")

- [ ] **Paso 2: Crear el archivo de workflow**

Escribir `templates/github/workflows/ci.yml`:

```yaml
name: CI

on:
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - run: npm run lint --if-present
      - run: npm test --if-present
      - run: npm run build --if-present
```

- [ ] **Paso 3: Volver a correr el chequeo de verificación**

Ejecutar: `python3 -c "import yaml; yaml.safe_load(open('templates/github/workflows/ci.yml'))" && echo VALID_YAML`
Resultado esperado: `VALID_YAML`

- [ ] **Paso 4: Commitear**

```bash
git add templates/github/workflows/ci.yml
git commit -m "Agregar plantilla de workflow de CI (validación pre-merge: lint, test, build)"
```

---

### Tarea 5: `templates/github/pull_request_template.md`

**Archivos:**
- Crear: `templates/github/pull_request_template.md`

- [ ] **Paso 1: Escribir el chequeo de verificación (debería fallar)**

Ejecutar: `grep -c "URL de preview" templates/github/pull_request_template.md`
Resultado esperado: FALLA ("No such file or directory")

- [ ] **Paso 2: Crear la plantilla de PR**

Escribir `templates/github/pull_request_template.md`:

```markdown
## Resumen

<!-- Qué cambió y por qué, en 1-3 oraciones -->

## Validación

- [ ] Arranca el backend: OK / Error
- [ ] Arranca el frontend: OK / Error
- [ ] Health check: OK / Error
- [ ] Lint / Build / Tests: OK / Error
- [ ] QA visual (`qa-visual-agent`): OK / Observaciones

URL de preview:

## Riesgos / pendientes

<!-- Cualquier cosa a la que quien revisa deba prestarle especial atención -->
```

- [ ] **Paso 3: Volver a correr el chequeo de verificación**

Ejecutar: `grep -c "URL de preview" templates/github/pull_request_template.md`
Resultado esperado: `1`

- [ ] **Paso 4: Commitear**

```bash
git add templates/github/pull_request_template.md
git commit -m "Agregar plantilla de PR que replica el bloque de validación del plan original (sección 10.4)"
```

---

### Tarea 6: `.claude/agents/db-query-agent.md`

**Archivos:**
- Crear: `.claude/agents/db-query-agent.md`

- [ ] **Paso 1: Escribir el chequeo de verificación (debería fallar)**

Ejecutar:
```bash
python3 - <<'EOF'
import re
text = open('.claude/agents/db-query-agent.md').read()
fm = re.match(r'^---\n(.*?)\n---\n', text, re.S).group(1)
import yaml
data = yaml.safe_load(fm)
assert data['name'] == 'db-query-agent'
assert 'description' in data
print('VALID_AGENT_DEF')
EOF
```
Resultado esperado: FALLA ("No such file or directory")

- [ ] **Paso 2: Crear la definición del agente**

Escribir `.claude/agents/db-query-agent.md`:

```markdown
---
name: db-query-agent
description: Usalo cuando una tarea necesite una respuesta basada en datos de producción (sólo réplica de lectura) — traduce una pregunta en lenguaje natural a una consulta auditada de solo lectura y devuelve una respuesta sintetizada, nunca filas crudas.
tools: Bash
---

Sos la única interfaz entre el agente de desarrollo y la réplica de lectura de
la base de datos de producción. Este límite existe a propósito (ver spec
sección 7 / `docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md`):
la credencial que puede llegar a los datos vive sólo dentro de tu herramienta,
nunca en el contexto del agente padre.

## Reglas — no negociables

- Consultá exclusivamente a través de `scripts/db-query.sh`. Nunca invoques
  `psql`, `pg_dump`, `mysql` ni ningún otro cliente directo de base de datos —
  están denegados en `.claude/settings.json` precisamente para que este sea el
  único camino posible.
- Nunca devuelvas resultados crudos de la consulta. Resumí: cantidad de filas,
  agregados, como máximo 5 filas de ejemplo, y qué significan para la pregunta
  que se hizo.
- Si la pregunta requeriría escribir o alterar el esquema, rechazala y explicá
  que este camino es de solo lectura a propósito.
- Si un resultado es grande, describí su forma (cantidad de filas, columnas,
  rangos) en lugar de volcarlo entero — el contexto del agente padre es valioso.

## Proceso

1. Traducí la pregunta en lenguaje natural a una única sentencia `SELECT`,
   acotada al conjunto más chico de tablas/columnas que la responda.
2. Ejecutá: `scripts/db-query.sh "<tu sentencia SELECT>"`
3. Leé la salida (resultado limitado en filas + la entrada de auditoría que generó).
4. Respondé con una síntesis corta: qué muestran los datos, los números
   relevantes, y cualquier salvedad (p. ej. "muestra de N de M filas", "la
   réplica puede estar desfasada respecto de la primaria").
```

- [ ] **Paso 3: Volver a correr el chequeo de verificación**

Ejecutar el mismo script que en el Paso 1.
Resultado esperado: `VALID_AGENT_DEF`

- [ ] **Paso 4: Commitear**

```bash
git add .claude/agents/db-query-agent.md
git commit -m "Agregar db-query-agent: la interfaz angosta y auditada hacia los datos de producción"
```

---

### Tarea 7: `.claude/agents/qa-visual-agent.md`

**Archivos:**
- Crear: `.claude/agents/qa-visual-agent.md`

- [ ] **Paso 1: Escribir el chequeo de verificación (debería fallar)**

Ejecutar:
```bash
python3 - <<'EOF'
import re, yaml
text = open('.claude/agents/qa-visual-agent.md').read()
data = yaml.safe_load(re.match(r'^---\n(.*?)\n---\n', text, re.S).group(1))
assert data['name'] == 'qa-visual-agent'
assert 'description' in data
print('VALID_AGENT_DEF')
EOF
```
Resultado esperado: FALLA ("No such file or directory")

- [ ] **Paso 2: Crear la definición del agente**

Escribir `.claude/agents/qa-visual-agent.md`:

```markdown
---
name: qa-visual-agent
description: Usalo después de implementar un cambio de UI para verificarlo visualmente contra el preview local con un navegador real, y para convertir cada bug encontrado en un test de regresión en lugar de un simple reporte.
tools: Bash, Read, Write, Edit, Grep, Glob
---

Corrés QA visual contra el preview local usando la skill `qa` (basada en
Playwright) y convertís cada problema que encontrás en un test de regresión.
"Se ve bien" no es un hallazgo — un test que pasa o que falla, sí lo es.

## Proceso

1. Confirmá que los servidores locales ya están corriendo. Si no estás
   seguro, preguntale al agente padre en lugar de levantarlos vos mismo — eso
   es trabajo suyo, no tuyo.
2. Invocá la skill `qa`: modo `quick` para cambios chicos, modo `regression`
   cuando apuntás a un área específica, `full` solo si te lo piden explícitamente.
3. Por cada problema que encuentres:
   a. Escribí un test de regresión que falle y lo reproduzca, en el framework
      de tests y la ubicación que ya usa el proyecto — segui sus convenciones.
   b. Corré el test y confirmá que falla por la razón correcta (no por un
      error de configuración).
   c. Registrá el problema y la ruta del nuevo test. No arregles el código de
      la aplicación — esa decisión le corresponde a quien pidió el QA.
4. Respondé con un resumen estructurado: pasa/falla por vista revisada, rutas
   de capturas de pantalla, errores de consola observados, y la lista de tests
   de regresión que creaste.

## Lo que nunca debés hacer

- Modificar el código fuente de la aplicación.
- Debilitar, saltear o borrar un test existente para que un chequeo pase.
- Reportar algo como "OK" sin la captura de pantalla o el log de consola que lo
  respalde — evidencia antes que afirmaciones, siempre (ver `verification-before-completion`).
```

- [ ] **Paso 3: Volver a correr el chequeo de verificación**

Ejecutar el mismo script que en el Paso 1.
Resultado esperado: `VALID_AGENT_DEF`

- [ ] **Paso 4: Commitear**

```bash
git add .claude/agents/qa-visual-agent.md
git commit -m "Agregar qa-visual-agent: QA visual que produce tests de regresión, no solo reportes"
```

---

### Tarea 8: `.claude/agents/research-agent.md`

**Archivos:**
- Crear: `.claude/agents/research-agent.md`

- [ ] **Paso 1: Escribir el chequeo de verificación (debería fallar)**

Ejecutar:
```bash
python3 - <<'EOF'
import re, yaml
text = open('.claude/agents/research-agent.md').read()
data = yaml.safe_load(re.match(r'^---\n(.*?)\n---\n', text, re.S).group(1))
assert data['name'] == 'research-agent'
assert 'description' in data
print('VALID_AGENT_DEF')
EOF
```
Resultado esperado: FALLA ("No such file or directory")

- [ ] **Paso 2: Crear la definición del agente**

Escribir `.claude/agents/research-agent.md`:

```markdown
---
name: research-agent
description: Usalo cuando necesites digerir un documento largo, una spec, o la referencia de una API de terceros antes de empezar a trabajar, sin cargar todo eso en la conversación principal — devuelve un resumen enfocado, no una copia.
tools: Read, Grep, Glob, WebFetch
---

Leés material fuente extenso en un contexto aislado y devolvés sólo las partes
relevantes para la pregunta que te hicieron. Todo tu valor está en que el
agente padre no tenga que leer lo que vos leíste.

## Proceso

1. Repetí la pregunta exacta que te pidieron responder. Si es ambigua, decilo
   explícitamente en lugar de adivinar y producir un resumen genérico — un
   resumen vago anula el propósito de haberte despachado.
2. Leé el material fuente al que te apuntaron (ruta de archivo o URL).
3. Extraé sólo las secciones que se relacionan con esa pregunta.
4. Respondé con:
   - Una respuesta directa (2-5 oraciones)
   - Las citas o secciones específicas que la respaldan, con referencias de
     archivo:línea o sección a las que el agente padre pueda saltar si necesita más
   - Cualquier cosa que hayas encontrado que complique o contradiga una respuesta simple

## Lo que nunca debés hacer

- Pegar de vuelta el documento fuente, completo o en gran parte.
- Responder preguntas que no te hicieron ("ya que estaba ahí, también noté que...") —
  mantenerte en el alcance es lo que te hace barato de usar.
```

- [ ] **Paso 3: Volver a correr el chequeo de verificación**

Ejecutar el mismo script que en el Paso 1.
Resultado esperado: `VALID_AGENT_DEF`

- [ ] **Paso 4: Commitear**

```bash
git add .claude/agents/research-agent.md
git commit -m "Agregar research-agent: digiere material extenso en aislamiento y devuelve un resumen"
```

---

### Tarea 9: Vendorizar la skill `qa` de gstack

**Archivos:**
- Crear: `.claude/skills/qa/` (copiado de `garrytan/gstack`, licencia MIT)
- Crear: `.claude/skills/qa/THIRD-PARTY-NOTICE.md`

- [ ] **Paso 1: Escribir el chequeo de verificación (debería fallar)**

Ejecutar: `test -f .claude/skills/qa/SKILL.md && grep -c "^name: qa$" .claude/skills/qa/SKILL.md`
Resultado esperado: FALLA (`.claude/skills/qa/SKILL.md` no existe)

- [ ] **Paso 2: Clonar gstack, copiar el directorio de la skill `qa/` y su LICENSE**

```bash
git clone --depth 1 https://github.com/garrytan/gstack.git /tmp/gstack-vendor
cp -r /tmp/gstack-vendor/qa .claude/skills/qa
cp /tmp/gstack-vendor/LICENSE /tmp/gstack-license-qa.txt
rm -rf .claude/skills/qa/.git
rm -rf /tmp/gstack-vendor
```

- [ ] **Paso 3: Escribir el aviso de terceros**

Escribir `.claude/skills/qa/THIRD-PARTY-NOTICE.md`:

```markdown
# Aviso de terceros

Este directorio está vendorizado desde la skill `qa` de
[garrytan/gstack](https://github.com/garrytan/gstack) (licencia MIT,
copyright de Garry Tan), según la decisión de diseño documentada en
`docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md`
(spec sección 2: el `/qa` de gstack es la única pieza — QA visual basado en
Playwright que genera automáticamente tests de regresión — que Superpowers no cubre).

El contenido de la skill (`SKILL.md` y archivos asociados) se mantiene en su
idioma original: es contenido vendorizado de upstream, y traducirlo rompería
la trazabilidad con la fuente y la atribución de licencia (ver spec sección 0).

A continuación, la licencia original.

---
```

- [ ] **Paso 4: Agregar el texto de la licencia MIT original al aviso**

```bash
cat /tmp/gstack-license-qa.txt >> .claude/skills/qa/THIRD-PARTY-NOTICE.md
rm /tmp/gstack-license-qa.txt
```

- [ ] **Paso 5: Volver a correr el chequeo de verificación**

Ejecutar: `test -f .claude/skills/qa/SKILL.md && grep -c "^name: qa$" .claude/skills/qa/SKILL.md`
Resultado esperado: `1`

- [ ] **Paso 6: Commitear**

```bash
git add .claude/skills/qa/
git commit -m "Vendorizar la skill qa de gstack (MIT) — QA visual con Playwright + generación de tests de regresión"
```

---

### Tarea 10: Vendorizar la skill `stop-slop`

**Archivos:**
- Crear: `.claude/skills/stop-slop/` (copiado de `hardikpandya/stop-slop`, licencia MIT)
- Crear: `.claude/skills/stop-slop/THIRD-PARTY-NOTICE.md`

- [ ] **Paso 1: Escribir el chequeo de verificación (debería fallar)**

Ejecutar: `test -f .claude/skills/stop-slop/SKILL.md && grep -c "^name: stop-slop$" .claude/skills/stop-slop/SKILL.md`
Resultado esperado: FALLA (el archivo no existe)

- [ ] **Paso 2: Clonar, copiar, y guardar la licencia**

```bash
git clone --depth 1 https://github.com/hardikpandya/stop-slop.git /tmp/stop-slop-vendor
mkdir -p .claude/skills/stop-slop
cp /tmp/stop-slop-vendor/SKILL.md .claude/skills/stop-slop/
cp -r /tmp/stop-slop-vendor/references .claude/skills/stop-slop/
cp /tmp/stop-slop-vendor/LICENSE /tmp/stop-slop-license.txt
rm -rf /tmp/stop-slop-vendor
```

- [ ] **Paso 3: Escribir el aviso de terceros**

Escribir `.claude/skills/stop-slop/THIRD-PARTY-NOTICE.md`:

```markdown
# Aviso de terceros

Este directorio está vendorizado desde
[hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop)
(licencia MIT, copyright de Hardik Pandya), según la decisión de diseño
documentada en
`docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md`
(spec sección 2.1: elimina las "marcas de IA" de la prosa — PRs, registros de
decisiones, y el material de cursos/charlas que la factory va a producir como
subproducto).

El contenido de la skill (`SKILL.md` y `references/`) se mantiene en su idioma
original: es contenido vendorizado de upstream, y traducirlo rompería la
trazabilidad con la fuente y la atribución de licencia (ver spec sección 0).

A continuación, la licencia original.

---
```

- [ ] **Paso 4: Agregar el texto de la licencia MIT original**

```bash
cat /tmp/stop-slop-license.txt >> .claude/skills/stop-slop/THIRD-PARTY-NOTICE.md
rm /tmp/stop-slop-license.txt
```

- [ ] **Paso 5: Volver a correr el chequeo de verificación**

Ejecutar: `test -f .claude/skills/stop-slop/SKILL.md && grep -c "^name: stop-slop$" .claude/skills/stop-slop/SKILL.md`
Resultado esperado: `1`

- [ ] **Paso 6: Commitear**

```bash
git add .claude/skills/stop-slop/
git commit -m "Vendorizar la skill stop-slop (MIT) — elimina marcas de escritura de IA en prosa/PRs/material de cursos"
```

---

### Tarea 11: `scripts/bootstrap.sh`

**Archivos:**
- Crear: `scripts/bootstrap.sh`
- Prueba: dry run manual contra un directorio temporal (se muestra en el Paso 4 — bootstrap.sh es el propio artefacto bajo prueba, así que la "prueba" es una corrida end-to-end contra un destino descartable)

- [ ] **Paso 1: Escribir el chequeo de verificación (debería fallar)**

Ejecutar: `bash -n scripts/bootstrap.sh`
Resultado esperado: FALLA ("No such file or directory")

- [ ] **Paso 2: Crear el script**

Escribir `scripts/bootstrap.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Instala/actualiza la configuración canónica de Claude Code de la Software
# Factory en un repo de trabajo, sin pisar nada de lo que ya exista ahí.
#
# Uso: scripts/bootstrap.sh <ruta-al-repo-destino> [nombre-del-proyecto]

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:?Uso: bootstrap.sh <ruta-al-repo-destino> [nombre-del-proyecto]}"
PROJECT_NAME="${2:-$(basename "$TARGET_DIR")}"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "El directorio destino no existe: $TARGET_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR/.claude/agents" "$TARGET_DIR/.claude/skills" "$TARGET_DIR/.github/workflows"

copy_if_absent() {
  local src="$1" dest="$2"
  if [[ -e "$dest" ]]; then
    echo "ya existe, se omite: $dest"
  else
    cp -r "$src" "$dest"
    echo "creado:              $dest"
  fi
}

copy_if_absent "$SOURCE_DIR/templates/settings.json.template" "$TARGET_DIR/.claude/settings.json"
copy_if_absent "$SOURCE_DIR/templates/github/workflows/ci.yml" "$TARGET_DIR/.github/workflows/ci.yml"
copy_if_absent "$SOURCE_DIR/templates/github/pull_request_template.md" "$TARGET_DIR/.github/pull_request_template.md"

for f in CLAUDE.md AGENT_WORKFLOW.md; do
  dest="$TARGET_DIR/$f"
  if [[ -e "$dest" ]]; then
    echo "ya existe, se omite: $dest"
  else
    sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$SOURCE_DIR/templates/$f.template" > "$dest"
    echo "creado:              $dest (todavía faltan completar los placeholders {{...}} además de PROJECT_NAME)"
  fi
done

for agent in db-query-agent qa-visual-agent research-agent; do
  copy_if_absent "$SOURCE_DIR/.claude/agents/$agent.md" "$TARGET_DIR/.claude/agents/$agent.md"
done

for skill in qa stop-slop; do
  copy_if_absent "$SOURCE_DIR/.claude/skills/$skill" "$TARGET_DIR/.claude/skills/$skill"
done

cat <<EOF

Listo. Pasos manuales pendientes para $TARGET_DIR:
  1. Completar los placeholders {{...}} que quedaron en CLAUDE.md y AGENT_WORKFLOW.md.
  2. Agregar reglas allow/ask específicas de rutas en .claude/settings.json según
     la estructura real de directorios frontend/backend de este repo (la plantilla
     trae sólo lo genérico).
  3. Instalar las skills que no se pueden vendorizar por motivos de licencia
     (frontend-design, remotion) y configurar los conectores MCP —
     ver docs/external-setup-checklist.md en softwareFactory.
EOF
```

- [ ] **Paso 3: Hacerlo ejecutable y correr el chequeo de sintaxis**

Ejecutar: `chmod +x scripts/bootstrap.sh && bash -n scripts/bootstrap.sh && echo SYNTAX_OK`
Resultado esperado: `SYNTAX_OK`

- [ ] **Paso 4: Dry run end-to-end contra un directorio descartable**

```bash
rm -rf /tmp/bootstrap-dry-run && mkdir -p /tmp/bootstrap-dry-run
scripts/bootstrap.sh /tmp/bootstrap-dry-run test-project
test -f /tmp/bootstrap-dry-run/.claude/settings.json
test -f /tmp/bootstrap-dry-run/CLAUDE.md
test -f /tmp/bootstrap-dry-run/AGENT_WORKFLOW.md
test -f /tmp/bootstrap-dry-run/.claude/agents/db-query-agent.md
test -f /tmp/bootstrap-dry-run/.claude/skills/qa/SKILL.md
test -f /tmp/bootstrap-dry-run/.github/workflows/ci.yml
grep -q "^# test-project$" /tmp/bootstrap-dry-run/CLAUDE.md
echo ALL_FILES_PRESENT
rm -rf /tmp/bootstrap-dry-run
```
Resultado esperado: `ALL_FILES_PRESENT` (cada `test`/`grep` tiene que pasar —
acá no está activo `set -e`, así que corré cada uno por separado si necesitás
ver cuál falla)

- [ ] **Paso 5: Volver a correrlo contra el mismo directorio (ya poblado) para confirmar la idempotencia**

```bash
mkdir -p /tmp/bootstrap-dry-run-2
scripts/bootstrap.sh /tmp/bootstrap-dry-run-2 test-project > /tmp/run1.log
scripts/bootstrap.sh /tmp/bootstrap-dry-run-2 test-project > /tmp/run2.log
grep -q "ya existe, se omite:" /tmp/run2.log && echo IDEMPOTENT
rm -rf /tmp/bootstrap-dry-run-2 /tmp/run1.log /tmp/run2.log
```
Resultado esperado: `IDEMPOTENT`

- [ ] **Paso 6: Commitear**

```bash
git add scripts/bootstrap.sh
git commit -m "Agregar bootstrap.sh: instalador idempotente de la configuración canónica de Claude"
```

---

### Tarea 12: `docs/external-setup-checklist.md`

**Archivos:**
- Crear: `docs/external-setup-checklist.md`

Esto documenta las piezas que **no** se pueden scriptear ni vendorizar: skills
bajo licencias que no permiten copiar (Frontend Design, Remotion — ver "Antes
de empezar"), y conectores MCP que necesitan credenciales vivas por
máquina/cuenta.

- [ ] **Paso 1: Escribir el chequeo de verificación (debería fallar)**

Ejecutar: `grep -c "plugin install frontend-design" docs/external-setup-checklist.md`
Resultado esperado: FALLA ("No such file or directory")

- [ ] **Paso 2: Crear el checklist**

Escribir `docs/external-setup-checklist.md`:

```markdown
# Checklist de instalación externa (por máquina / por cuenta)

Estos ítems **no** se vendorizan ni se scriptean con `scripts/bootstrap.sh` —
cada uno requiere una licencia que no permite copiar archivos, o credenciales
vivas atadas a una persona/máquina/cuenta. Recorré esta lista una vez por
entorno (p. ej. una vez en la Mac mini), no una vez por repo.

Ver `docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md`
para la justificación detrás de cada elección.

## Skills que se instalan por canal oficial (no vendorizadas — licencia)

- [ ] **Frontend Design** (Anthropic, oficial). Los términos de Anthropic no
      permiten redistribuir los archivos, así que se instala directo desde el
      marketplace: `/plugin install frontend-design@claude-plugins-official`
- [ ] **Remotion**. Distribuida bajo la Remotion License (restrictiva para
      empresas grandes) — se instala con su propio instalador en lugar de
      copiar archivos: `npx skills add remotion`

## Conectores MCP (necesitan credenciales vivas — configurar por máquina)

- [ ] **GitHub MCP server** — servidor oficial; más completo y más eficiente
      en tokens que invocar `gh` por línea de comandos para PRs e issues.
- [ ] **Figma Dev Mode MCP Server** — le permite al agente leer specs de diseño
      aprobadas y componentes directamente, en vez de que se las describan en prosa.
- [ ] **Playwright MCP** — le da a `qa-visual-agent` herramientas de navegador
      nativas en lugar de invocar un proceso aparte.
- [ ] **MCP de documentación** (p. ej. Context7) — documentación actualizada de
      librerías/APIs bajo demanda, en lugar de adivinar a partir del
      entrenamiento o gastar tokens en búsquedas web genéricas.
- [ ] **Telegram vía Claude Code Channels** — notificaciones de checkpoints,
      preguntas bloqueantes y PRs, sin la superficie de riesgo de un
      orquestador completo (OpenClaw).

## Explícitamente NO instalados (decisión registrada, no volver a discutirlo)

- **claude-mem** — una auditoría comunitaria de febrero de 2026 lo calificó de
  riesgo ALTO: su API HTTP local (puerto 37777) no tiene autenticación, así que
  cualquier proceso de la máquina puede leer todas las observaciones guardadas
  (incluidas claves de API en texto plano) e inyectar memorias falsas. Esto
  contradice directamente el diseño de mínimo privilegio de la sección 7 de la
  spec. La memoria persistente queda cubierta en cambio por Auto Memory +
  `CLAUDE.md` + registros de decisiones + specs versionadas + GitHub Issues
  (spec sección 3.1) — todo nativo, todo auditable.
- **Sequential Thinking MCP** — redundante con el extended thinking nativo más
  las skills `brainstorming`/`systematic-debugging`/`writing-plans` que ya
  están instaladas; agregarlo gastaría tokens duplicando algo que ya está resuelto.
- **UI/UX Pro Max** — redundante con Frontend Design. Revisitarlo más adelante
  específicamente por su auditor de accesibilidad (contraste/ARIA) si eso se
  vuelve una necesidad real.
- **NotebookLM MCP** — ahorro de tokens real, pero sin API oficial (funciona
  vía automatización de navegador contra endpoints internos de Google — frágil,
  zona gris de ToS). Revisitarlo una vez que el flujo base esté estable.
```

- [ ] **Paso 3: Volver a correr el chequeo de verificación**

Ejecutar: `grep -c "plugin install frontend-design" docs/external-setup-checklist.md`
Resultado esperado: `1`

- [ ] **Paso 4: Commitear**

```bash
git add docs/external-setup-checklist.md
git commit -m "Agregar checklist de instalación externa para skills/conectores que no se pueden vendorizar ni scriptear"
```

---

## Chequeo final — todo junto

- [ ] **Correr la batería completa de verificación de una sola vez**

```bash
python3 -m json.tool templates/settings.json.template > /dev/null && echo "1: settings.json.template OK"
test -f templates/CLAUDE.md.template && echo "2: CLAUDE.md.template OK"
grep -q "APROBADO PARA IMPLEMENTAR" templates/AGENT_WORKFLOW.md.template && echo "3: AGENT_WORKFLOW.md.template OK"
python3 -c "import yaml; yaml.safe_load(open('templates/github/workflows/ci.yml'))" && echo "4: ci.yml OK"
grep -q "URL de preview" templates/github/pull_request_template.md && echo "5: pull_request_template.md OK"
for a in db-query-agent qa-visual-agent research-agent; do
  test -f ".claude/agents/$a.md" && echo "agent $a OK"
done
test -f .claude/skills/qa/SKILL.md && echo "9: qa skill vendorizada OK"
test -f .claude/skills/stop-slop/SKILL.md && echo "10: stop-slop skill vendorizada OK"
bash -n scripts/bootstrap.sh && echo "11: bootstrap.sh sintaxis OK"
grep -q "plugin install frontend-design" docs/external-setup-checklist.md && echo "12: external-setup-checklist.md OK"
```
Resultado esperado: 12 líneas "OK", sin errores

- [ ] **Actualizar el checklist de la spec (sección 7) para reflejar lo que se completó**

Abrir `docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md`
y tildar cada casillero de la sección "7. Próximos pasos / artefactos a generar"
que este plan completó (todos, excepto la configuración de conectores con
credenciales vivas, que la Tarea 12 ahora documenta en lugar de completar).

- [ ] **Commit final**

```bash
git add docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md
git commit -m "Marcar los artefactos de config de la Fase 1 como entregados en el checklist de la spec de diseño"
```
