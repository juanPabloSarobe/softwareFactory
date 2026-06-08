# Checklist de instalación externa (por máquina / por cuenta)

Estos ítems **no** se vendorizan ni se scriptean con `scripts/bootstrap.sh` — cada uno requiere una licencia que no permite copiar archivos, o credenciales vivas atadas a una persona/máquina/cuenta. Recorré esta lista una sola vez por entorno (p. ej. una vez en tu Mac), no una vez por repo.

Ver `docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md` para la justificación detrás de cada elección.

---

## Skill base: Superpowers (instalar una sola vez a nivel global)

**Qué es:** La base de todo el flujo de trabajo de la factory: brainstorming, writing-plans, subagent-driven-development, TDD, debugging, code review — el ciclo completo.

**Instalación:**

```bash
/plugin install superpowers@claude-plugins-official
```

**Verificación:** Abrí Claude Code y escribí `/brainstorming` — debería verse disponible.

**Documentación:** https://github.com/obra/superpowers

---

## Skills por canal oficial (instalar cuando sea necesario)

### Frontend Design (Anthropic)

**Qué es:** Revisión visual de diseños, auditoría de accesibilidad (WCAG), consistencia visual.

**Instalación:**

```bash
/plugin install frontend-design@claude-plugins-official
```

O preguntale a bootstrap.sh que lo instale:
```bash
scripts/bootstrap.sh <ruta-proyecto> nombre-proyecto
# Respondé "sí" cuando pregunte por skills adicionales
```

**Documentación:** https://github.com/anthropics/frontend-design

---

### Remotion

**Qué es:** Generación de videos/animaciones programáticas en React.

**Instalación:**

```bash
npx skills add remotion
```

O preguntale a bootstrap.sh que lo instale:
```bash
scripts/bootstrap.sh <ruta-proyecto> nombre-proyecto
# Respondé "sí" cuando pregunte por skills adicionales
```

**Requiere:** Node.js + npm. Descargá en https://nodejs.org/

**Documentación:** https://www.remotion.dev/

---

## MCP Servers (por máquina, credenciales vivas)

Estos se instalan con `/mcp install` desde Claude Code. Se piden credenciales/tokens una sola vez.

### GitHub MCP

**Qué es:** Leer/crear/comentar issues y PRs directo desde Claude sin usar `gh`.

**Instalación:**

```bash
/mcp install github
```

**Configuración:** Necesitás un Personal Access Token (PAT):

1. Visitá: https://github.com/settings/tokens/new
2. Scope mínimo: `repo`, `read:user`
3. Generá el token y guardalo en un lugar seguro
4. Claude Code te pedirá el token en la primera ejecución

**Verificación:** `mcp list` o intenta crear un issue desde un PR

---

### Context7 (recomendado para desarrollo)

**Qué es:** Documentación actualizada de librerías/APIs on-demand, en lugar de adivinar a partir del entrenamiento.

**Instalación:**

```bash
/mcp install context7
```

**Configuración:** Necesitás una API key:

1. Visitá: https://context7.ai/
2. Registrate y generá una API key
3. Claude Code te pedirá la key en la primera ejecución

**Uso:** Escribe `/context7 python requests` para documentación actualizada de requests library.

---

### Playwright MCP

**Qué es:** Herramientas de navegación y testing automatizado (si usás Playwright).

**Instalación:**

```bash
/mcp install playwright
```

**Requiere:** Bun instalado (https://bun.sh/)

---

### Figma Dev Mode MCP

**Qué es:** Leer specs de diseño y componentes directo de Figma Dev Mode.

**Instalación:** (No hay instalador oficial aún — usar GitHub Actions workflow personalizado si es necesario)

---

## Servicios/Herramientas NO instalados (decisión registrada)

### ❌ claude-mem

Auditoría de febrero de 2026: riesgo ALTO. Su API HTTP local (puerto 37777) no tiene autenticación, así que cualquier proceso de la máquina puede leer todas las observaciones (incluidas claves de API en texto plano) e inyectar memorias falsas.

**Alternativa:** Usamos Auto Memory + CLAUDE.md + specs versionadas + GitHub Issues.

---

### ❌ Sequential Thinking MCP

Redundante con extended thinking nativo + las skills brainstorming/systematic-debugging/writing-plans.

---

### ❌ UI/UX Pro Max

Redundante con Frontend Design. Revisitar si necesitamos auditoría de accesibilidad específica (WCAG).

---

### ❌ NotebookLM MCP

Ahorro de tokens real, pero sin API oficial (funciona vía automatización de navegador contra endpoints internos de Google — frágil, zona gris de ToS).

---

## Troubleshooting

### "Plugin not found" al ejecutar `/plugin install`

**Causa:** Claude Code no reconoce el comando.

**Solución:** Actualiza Claude Code a la última versión:
```bash
/gstack-upgrade
```

---

### "/plugin: command not found"

**Causa:** No estás dentro de Claude Code.

**Solución:** Abrí Claude Code (desktop app o https://claude.com/claude-code) e intenta de nuevo.

---

### "Personal Access Token inválido" en GitHub MCP

**Causa:** Token expirado o permisos insuficientes.

**Solución:** Regenerá el token en https://github.com/settings/tokens/new

---

### "Context7 API key not accepted"

**Causa:** Key incorrecto o expirado.

**Solución:** 
1. Visitá https://context7.ai/ y verificá tu key
2. Ejecutá `/mcp install context7` de nuevo
3. Pegá el key correcto

---

## Resumen de instala total (orden recomendado)

1. **Superpowers global** (una sola vez): `/plugin install superpowers@claude-plugins-official`
2. **En cada proyecto nuevo:**
   - Ejecutá: `scripts/bootstrap.sh <ruta-proyecto> nombre-proyecto`
   - Respondé interactivamente qué skills/MCPs instalar
3. **Luego:** `scripts/post-setup.sh` para guía interactiva completa

---

## Referencias

- **Factory design:** `docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md`
- **Plan de bootstrap:** `docs/superpowers/plans/2026-06-08-bootstrap-improvements.md`
- **Bootstrap script:** `scripts/bootstrap.sh`
- **Post-setup script:** `scripts/post-setup.sh`
