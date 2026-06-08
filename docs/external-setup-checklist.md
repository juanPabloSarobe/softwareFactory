# Checklist de instalación externa (por máquina / por cuenta)

Estos ítems **no** se vendorizan ni se scriptean con `scripts/bootstrap.sh` —
cada uno requiere una licencia que no permite copiar archivos, o credenciales
vivas atadas a una persona/máquina/cuenta. Recorré esta lista una vez por
entorno (p. ej. una vez en la Mac mini), no una vez por repo.

Ver `docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md`
para la justificación detrás de cada elección.

## Skill base (instalar una sola vez, a nivel global — no por proyecto)

- [ ] **Superpowers** (`obra/superpowers`, MIT). Es la base de todo el flujo de
      trabajo de esta factory: `brainstorming`, `writing-plans`,
      `subagent-driven-development`, `using-git-worktrees`,
      `test-driven-development`, `finishing-a-development-branch`, etc. — el
      ciclo completo de "planificar → aprobar → implementar con revisión en dos
      etapas → cerrar la rama" que usamos para construir esta misma factory.
      En `softwareFactory` está vendorizada a nivel de proyecto (commit
      `8e6c2d3`, en `.claude/skills/`) porque acá es lo que se diseña y
      documenta — pero **`scripts/bootstrap.sh` no la copia** a los repos de
      trabajo, y copiarla a mano en cada uno duplicaría el mismo conjunto de
      skills repo por repo y los iría desincronizando con cada actualización
      del proyecto original. La instalás **una sola vez, a nivel de usuario**
      (`~/.claude/skills/`, según el instalador de
      https://github.com/obra/superpowers): Claude Code resuelve skills tanto
      a nivel de usuario como de proyecto, así que con esa única instalación
      global el flujo completo queda disponible automáticamente en
      `softwareFactory` y en cualquier proyecto real que abras en esa máquina,
      sin que `bootstrap.sh` tenga que ocuparse de ella.

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
