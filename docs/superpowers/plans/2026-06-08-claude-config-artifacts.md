# Claude Config Artifacts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce the versioned templates, subagent definitions, vendored skills and bootstrap script described in `docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md`, so the canonical Claude Code configuration for the Software Factory can be installed in any work repo.

**Architecture:** Pure file-creation work (no application runtime). Each task creates one self-contained artifact (template, agent definition, vendored skill, or script) plus a verification command that proves the artifact is well-formed — the config-file equivalent of red/green: write a check that fails because the file doesn't exist, create the file, watch the check pass, commit.

**Tech Stack:** Bash, JSON, YAML, Markdown with YAML frontmatter. Verification via `python3` (`json`/`yaml` modules, both confirmed present), `jq` (confirmed present), `bash -n`.

---

## Before you start

Two source repos get vendored under their MIT licenses (same pattern as the existing `.claude/skills/` from Superpowers, see commit `8e6c2d3`):
- `https://github.com/garrytan/gstack` → its `qa/` directory (the `/qa` skill picked in spec section 2)
- `https://github.com/hardikpandya/stop-slop` → the whole repo (the `stop-slop` skill)

Both were verified MIT-licensed during planning. **Frontend Design** (Anthropic, proprietary "all rights reserved" terms) and **Remotion** (custom Remotion License, restrictive for large companies) are deliberately **not** vendored — Task 12 documents installing them through their official channels instead.

---

### Task 1: `templates/settings.json.template`

**Files:**
- Create: `templates/settings.json.template`

- [ ] **Step 1: Write the verification check (it should fail — file doesn't exist yet)**

Run: `python3 -m json.tool templates/settings.json.template > /dev/null && echo VALID_JSON`
Expected: FAIL with "No such file or directory"

- [ ] **Step 2: Create the template**

Write `templates/settings.json.template`:

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

> Note: this is the generic baseline from spec section 5. It deliberately omits
> repo-specific paths like `frontend/**`/`backend/**` — Task 11 (bootstrap.sh)
> tells the operator to add those by hand for each repo's actual layout.

- [ ] **Step 3: Run the verification check again**

Run: `python3 -m json.tool templates/settings.json.template > /dev/null && echo VALID_JSON`
Expected: `VALID_JSON`

- [ ] **Step 4: Commit**

```bash
git add templates/settings.json.template
git commit -m "Add settings.json template with 3-tier permission baseline"
```

---

### Task 2: `templates/CLAUDE.md.template`

**Files:**
- Create: `templates/CLAUDE.md.template`

- [ ] **Step 1: Write the verification check (should fail)**

Run: `test -f templates/CLAUDE.md.template && wc -l < templates/CLAUDE.md.template`
Expected: FAIL ("No such file or directory")

- [ ] **Step 2: Create the template**

Write `templates/CLAUDE.md.template`:

```markdown
# {{PROJECT_NAME}}

> Agent configuration for {{PROJECT_NAME}}, part of the Skytrace / Software Factory
> program. Keep this file under ~200 lines — anything long-form belongs in `docs/`,
> linked from here, and read on demand (see "context engineering", spec section 6).

## What this project is

{{ONE_PARAGRAPH_DESCRIPTION}}

## Where things live

- Architecture & decisions: `docs/superpowers/specs/`
- Plans in flight: `docs/superpowers/plans/`
- Workflow rules (branching, PRs, what needs approval): `AGENT_WORKFLOW.md`
- Data access: never query the database directly — dispatch the `db-query-agent`
  subagent. Direct DB clients are denied in `.claude/settings.json` on purpose.

## Stack

{{STACK_SUMMARY}}

## Commands

- Lint: `{{LINT_COMMAND}}`
- Test: `{{TEST_COMMAND}}`
- Build: `{{BUILD_COMMAND}}`
- Dev server: `{{DEV_COMMAND}}`

## Non-negotiables

- TDD: red, green, refactor. Never write implementation before a failing test.
- Every bug found becomes a regression test — no exceptions (see `qa-visual-agent`).
- Tests are not yours to weaken. Editing `tests/**` requires asking first.
- Never work on `main`. Branch as `agent/issue-<N>-<short-description>`.
- Small checkpoints: stop at "a PR that works", not "the whole epic".
```

- [ ] **Step 3: Run the verification check again**

Run: `test -f templates/CLAUDE.md.template && wc -l < templates/CLAUDE.md.template`
Expected: a number less than `60` (well under the ~200 line budget the template itself prescribes)

- [ ] **Step 4: Commit**

```bash
git add templates/CLAUDE.md.template
git commit -m "Add CLAUDE.md template (lightweight, points to docs per context-engineering criteria)"
```

---

### Task 3: `templates/AGENT_WORKFLOW.md.template`

**Files:**
- Create: `templates/AGENT_WORKFLOW.md.template`

- [ ] **Step 1: Write the verification check (should fail)**

Run: `grep -c "APROBADO PARA IMPLEMENTAR" templates/AGENT_WORKFLOW.md.template`
Expected: FAIL ("No such file or directory")

- [ ] **Step 2: Create the template**

Write `templates/AGENT_WORKFLOW.md.template`:

```markdown
# Agent Workflow — {{PROJECT_NAME}}

## General rules

- Never work directly on `main`. Branch as `agent/issue-<N>-<short-description>`.
- Never merge your own PRs. Never deploy. Never touch production.
- Never modify `.env` files or add dependencies without explicit approval.
- Stay in scope — don't touch the backend on a frontend-only task, or vice versa.

## Discovery (before writing any code)

1. Read the linked issue/spec completely.
2. Explore the related files. Follow existing patterns — don't invent new ones.
3. Ask whatever is needed to remove ambiguity, grouped as: functional, technical,
   data, UX, security questions.
4. Propose a plan and wait for the literal words **APROBADO PARA IMPLEMENTAR**
   before writing any implementation code.

## Implementation

- TDD: write the failing test, watch it fail, write minimal code, watch it pass, commit.
- Keep the run scoped to one checkpoint — "a PR that works", not an entire epic.
- Convert every bug you find — yours or pre-existing — into a regression test.

## Validation (before opening a PR)

- Run lint, tests, and build.
- Confirm the app starts: backend health check responds, frontend loads.
- If there is a UI change, dispatch `qa-visual-agent` for visual QA.

## Delivery

Open a PR that includes:
- Functional summary — what changed and why
- Files modified
- Validation results: lint / test / build / QA — pass or fail, explicitly
- Risks and pending items
- Preview URL, if there is one
```

- [ ] **Step 3: Run the verification check again**

Run: `grep -c "APROBADO PARA IMPLEMENTAR" templates/AGENT_WORKFLOW.md.template`
Expected: `1`

- [ ] **Step 4: Commit**

```bash
git add templates/AGENT_WORKFLOW.md.template
git commit -m "Add AGENT_WORKFLOW.md template based on the Phase 1 skeleton from the original plan"
```

---

### Task 4: `templates/github/workflows/ci.yml`

**Files:**
- Create: `templates/github/workflows/ci.yml`

- [ ] **Step 1: Write the verification check (should fail)**

Run: `python3 -c "import yaml; yaml.safe_load(open('templates/github/workflows/ci.yml'))" && echo VALID_YAML`
Expected: FAIL ("No such file or directory")

- [ ] **Step 2: Create the workflow file**

Write `templates/github/workflows/ci.yml`:

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

- [ ] **Step 3: Run the verification check again**

Run: `python3 -c "import yaml; yaml.safe_load(open('templates/github/workflows/ci.yml'))" && echo VALID_YAML`
Expected: `VALID_YAML`

- [ ] **Step 4: Commit**

```bash
git add templates/github/workflows/ci.yml
git commit -m "Add CI workflow template (pre-merge validation: lint, test, build)"
```

---

### Task 5: `templates/github/pull_request_template.md`

**Files:**
- Create: `templates/github/pull_request_template.md`

- [ ] **Step 1: Write the verification check (should fail)**

Run: `grep -c "Preview URL" templates/github/pull_request_template.md`
Expected: FAIL ("No such file or directory")

- [ ] **Step 2: Create the PR template**

Write `templates/github/pull_request_template.md`:

```markdown
## Summary

<!-- What changed and why, in 1-3 sentences -->

## Validation

- [ ] Backend starts: OK / Error
- [ ] Frontend starts: OK / Error
- [ ] Health check: OK / Error
- [ ] Lint / Build / Tests: OK / Error
- [ ] Visual QA (`qa-visual-agent`): OK / Observations

Preview URL:

## Risks / pending items

<!-- Anything the reviewer should pay extra attention to -->
```

- [ ] **Step 3: Run the verification check again**

Run: `grep -c "Preview URL" templates/github/pull_request_template.md`
Expected: `1`

- [ ] **Step 4: Commit**

```bash
git add templates/github/pull_request_template.md
git commit -m "Add PR template matching the validation block from the original plan (section 10.4)"
```

---

### Task 6: `.claude/agents/db-query-agent.md`

**Files:**
- Create: `.claude/agents/db-query-agent.md`

- [ ] **Step 1: Write the verification check (should fail)**

Run:
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
Expected: FAIL ("No such file or directory")

- [ ] **Step 2: Create the agent definition**

Write `.claude/agents/db-query-agent.md`:

```markdown
---
name: db-query-agent
description: Use when a task needs an answer grounded in production data (read-replica only) — translates a natural-language question into an audited read-only query and returns a synthesized answer, never raw rows.
tools: Bash
---

You are the only interface between the development agent and the production
database read replica. This boundary exists on purpose (see spec section 7 /
`docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md`):
the credential that can reach the data lives only inside your tool, never in the
parent agent's context.

## Rules — non-negotiable

- Query exclusively through `scripts/db-query.sh`. Never invoke `psql`, `pg_dump`,
  `mysql`, or any other direct database client — those are denied in
  `.claude/settings.json` precisely so this is the only path.
- Never return raw query results. Summarize: row counts, aggregates, at most 5
  example rows, and what they mean for the question that was asked.
- If the question would require writing or altering schema, refuse and explain
  that this path is intentionally read-only.
- If a result set is large, describe its shape (row count, columns, ranges)
  instead of dumping it — the parent agent's context is precious.

## Process

1. Translate the natural-language question into a single `SELECT` statement,
   scoped to the smallest set of tables/columns that answers it.
2. Run: `scripts/db-query.sh "<your SELECT statement>"`
3. Read the output (row-capped result + the audit log entry it produced).
4. Reply with a short synthesis: what the data shows, the relevant numbers, and
   any caveats (e.g., "sample of N of M rows", "replica may lag the primary").
```

- [ ] **Step 3: Run the verification check again**

Run the same script as Step 1.
Expected: `VALID_AGENT_DEF`

- [ ] **Step 4: Commit**

```bash
git add .claude/agents/db-query-agent.md
git commit -m "Add db-query-agent: the narrow, audited interface to production data"
```

---

### Task 7: `.claude/agents/qa-visual-agent.md`

**Files:**
- Create: `.claude/agents/qa-visual-agent.md`

- [ ] **Step 1: Write the verification check (should fail)**

Run:
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
Expected: FAIL ("No such file or directory")

- [ ] **Step 2: Create the agent definition**

Write `.claude/agents/qa-visual-agent.md`:

```markdown
---
name: qa-visual-agent
description: Use after implementing a UI change to visually verify it against the local preview with a real browser, and to turn every bug found into a regression test rather than a report.
tools: Bash, Read, Write, Edit, Grep, Glob
---

You run visual QA against the local preview using the `qa` skill (Playwright-backed)
and convert every issue you find into a regression test. "Looks fine" is not a
finding — a passing or failing test is.

## Process

1. Confirm the local servers are already running. If you're not sure, ask the
   parent agent rather than starting them yourself — that's its job, not yours.
2. Invoke the `qa` skill: `quick` mode for small changes, `regression` mode when
   targeting a specific area, `full` only when explicitly asked to.
3. For every issue you find:
   a. Write a failing regression test that reproduces it, in the project's
      existing test framework and location — follow its conventions.
   b. Run it and confirm it fails for the right reason (not a setup error).
   c. Record the issue and the new test's file path. Do not fix the application
      code — that decision belongs to whoever requested the QA pass.
4. Reply with a structured summary: pass/fail per view checked, screenshot paths,
   console errors observed, and the list of regression tests you created.

## What you must never do

- Modify application source code.
- Weaken, skip, or delete an existing test to make a check pass.
- Report something as "OK" without the screenshot or console-log evidence that
  backs it up — evidence before assertions, always (see `verification-before-completion`).
```

- [ ] **Step 3: Run the verification check again**

Run the same script as Step 1.
Expected: `VALID_AGENT_DEF`

- [ ] **Step 4: Commit**

```bash
git add .claude/agents/qa-visual-agent.md
git commit -m "Add qa-visual-agent: visual QA that produces regression tests, not just reports"
```

---

### Task 8: `.claude/agents/research-agent.md`

**Files:**
- Create: `.claude/agents/research-agent.md`

- [ ] **Step 1: Write the verification check (should fail)**

Run:
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
Expected: FAIL ("No such file or directory")

- [ ] **Step 2: Create the agent definition**

Write `.claude/agents/research-agent.md`:

```markdown
---
name: research-agent
description: Use when you need to digest a long document, spec, or third-party API reference before starting work, without loading the whole thing into the main conversation — returns a focused brief, not a copy.
tools: Read, Grep, Glob, WebFetch
---

You read long source material in an isolated context and return only the parts
relevant to the question you were asked. Your entire value is that the parent
agent doesn't have to read what you read.

## Process

1. Restate the exact question you were asked to answer. If it's ambiguous, say
   so explicitly rather than guessing and producing a generic summary — a vague
   brief defeats the purpose of dispatching you.
2. Read the source material you were pointed at (file path or URL).
3. Extract only the sections that bear on that question.
4. Reply with:
   - A direct answer (2-5 sentences)
   - The specific quotes or sections that support it, with file:line or section
     references the parent agent can jump to if it needs more
   - Anything you found that complicates or contradicts a simple answer

## What you must never do

- Paste the source document back, in whole or in large part.
- Answer questions you weren't asked ("while I was in there, I also noticed...") —
  staying scoped is what makes you cheap to use.
```

- [ ] **Step 3: Run the verification check again**

Run the same script as Step 1.
Expected: `VALID_AGENT_DEF`

- [ ] **Step 4: Commit**

```bash
git add .claude/agents/research-agent.md
git commit -m "Add research-agent: digests long material in isolation, returns a brief"
```

---

### Task 9: Vendor the `qa` skill from gstack

**Files:**
- Create: `.claude/skills/qa/` (copied from `garrytan/gstack`, MIT licensed)
- Create: `.claude/skills/qa/THIRD-PARTY-NOTICE.md`

- [ ] **Step 1: Write the verification check (should fail)**

Run: `test -f .claude/skills/qa/SKILL.md && grep -c "^name: qa$" .claude/skills/qa/SKILL.md`
Expected: FAIL (`.claude/skills/qa/SKILL.md` doesn't exist)

- [ ] **Step 2: Clone gstack, copy the `qa/` skill directory and its LICENSE**

```bash
git clone --depth 1 https://github.com/garrytan/gstack.git /tmp/gstack-vendor
cp -r /tmp/gstack-vendor/qa .claude/skills/qa
cp /tmp/gstack-vendor/LICENSE /tmp/gstack-license-qa.txt
rm -rf .claude/skills/qa/.git
rm -rf /tmp/gstack-vendor
```

- [ ] **Step 3: Write the third-party notice**

Write `.claude/skills/qa/THIRD-PARTY-NOTICE.md`:

```markdown
# Third-party notice

This directory is vendored from the `qa` skill in
[garrytan/gstack](https://github.com/garrytan/gstack) (MIT licensed,
copyright Garry Tan), per the design decision in
`docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md`
(spec section 2: gstack's `/qa` is the one piece — Playwright-backed visual QA
that auto-generates regression tests — that Superpowers doesn't cover).

Original license follows.

---
```

- [ ] **Step 4: Append the original MIT license text to the notice**

```bash
cat /tmp/gstack-license-qa.txt >> .claude/skills/qa/THIRD-PARTY-NOTICE.md
rm /tmp/gstack-license-qa.txt
```

- [ ] **Step 5: Run the verification check again**

Run: `test -f .claude/skills/qa/SKILL.md && grep -c "^name: qa$" .claude/skills/qa/SKILL.md`
Expected: `1`

- [ ] **Step 6: Commit**

```bash
git add .claude/skills/qa/
git commit -m "Vendor gstack's qa skill (MIT) — Playwright visual QA + regression test generation"
```

---

### Task 10: Vendor the `stop-slop` skill

**Files:**
- Create: `.claude/skills/stop-slop/` (copied from `hardikpandya/stop-slop`, MIT licensed)
- Create: `.claude/skills/stop-slop/THIRD-PARTY-NOTICE.md`

- [ ] **Step 1: Write the verification check (should fail)**

Run: `test -f .claude/skills/stop-slop/SKILL.md && grep -c "^name: stop-slop$" .claude/skills/stop-slop/SKILL.md`
Expected: FAIL (file doesn't exist)

- [ ] **Step 2: Clone, copy, and capture the license**

```bash
git clone --depth 1 https://github.com/hardikpandya/stop-slop.git /tmp/stop-slop-vendor
mkdir -p .claude/skills/stop-slop
cp /tmp/stop-slop-vendor/SKILL.md .claude/skills/stop-slop/
cp -r /tmp/stop-slop-vendor/references .claude/skills/stop-slop/
cp /tmp/stop-slop-vendor/LICENSE /tmp/stop-slop-license.txt
rm -rf /tmp/stop-slop-vendor
```

- [ ] **Step 3: Write the third-party notice**

Write `.claude/skills/stop-slop/THIRD-PARTY-NOTICE.md`:

```markdown
# Third-party notice

This directory is vendored from
[hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop)
(MIT licensed, copyright Hardik Pandya), per the design decision in
`docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md`
(spec section 2.1: removes "AI tells" from prose — PRs, decision logs, and the
course/conference material the factory is expected to produce as a byproduct).

Original license follows.

---
```

- [ ] **Step 4: Append the original MIT license text**

```bash
cat /tmp/stop-slop-license.txt >> .claude/skills/stop-slop/THIRD-PARTY-NOTICE.md
rm /tmp/stop-slop-license.txt
```

- [ ] **Step 5: Run the verification check again**

Run: `test -f .claude/skills/stop-slop/SKILL.md && grep -c "^name: stop-slop$" .claude/skills/stop-slop/SKILL.md`
Expected: `1`

- [ ] **Step 6: Commit**

```bash
git add .claude/skills/stop-slop/
git commit -m "Vendor stop-slop skill (MIT) — removes AI writing tells from prose/PRs/course material"
```

---

### Task 11: `scripts/bootstrap.sh`

**Files:**
- Create: `scripts/bootstrap.sh`
- Test: manual dry run against a temp directory (shown in Step 4 — bootstrap.sh is itself the artifact under test, so the "test" is an end-to-end run against a throwaway target)

- [ ] **Step 1: Write the verification check (should fail)**

Run: `bash -n scripts/bootstrap.sh`
Expected: FAIL ("No such file or directory")

- [ ] **Step 2: Create the script**

Write `scripts/bootstrap.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Installs/updates the canonical Software Factory Claude Code configuration
# into a work repo, without overwriting anything that's already there.
#
# Usage: scripts/bootstrap.sh <path-to-target-repo> [project-name]

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:?Usage: bootstrap.sh <path-to-target-repo> [project-name]}"
PROJECT_NAME="${2:-$(basename "$TARGET_DIR")}"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Target directory does not exist: $TARGET_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR/.claude/agents" "$TARGET_DIR/.claude/skills" "$TARGET_DIR/.github/workflows"

copy_if_absent() {
  local src="$1" dest="$2"
  if [[ -e "$dest" ]]; then
    echo "skip (exists):   $dest"
  else
    cp -r "$src" "$dest"
    echo "created:         $dest"
  fi
}

copy_if_absent "$SOURCE_DIR/templates/settings.json.template" "$TARGET_DIR/.claude/settings.json"
copy_if_absent "$SOURCE_DIR/templates/github/workflows/ci.yml" "$TARGET_DIR/.github/workflows/ci.yml"
copy_if_absent "$SOURCE_DIR/templates/github/pull_request_template.md" "$TARGET_DIR/.github/pull_request_template.md"

for f in CLAUDE.md AGENT_WORKFLOW.md; do
  dest="$TARGET_DIR/$f"
  if [[ -e "$dest" ]]; then
    echo "skip (exists):   $dest"
  else
    sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$SOURCE_DIR/templates/$f.template" > "$dest"
    echo "created:         $dest (placeholders besides PROJECT_NAME still need filling in)"
  fi
done

for agent in db-query-agent qa-visual-agent research-agent; do
  copy_if_absent "$SOURCE_DIR/.claude/agents/$agent.md" "$TARGET_DIR/.claude/agents/$agent.md"
done

for skill in qa stop-slop; do
  copy_if_absent "$SOURCE_DIR/.claude/skills/$skill" "$TARGET_DIR/.claude/skills/$skill"
done

cat <<EOF

Done. Remaining manual steps for $TARGET_DIR:
  1. Fill in the {{...}} placeholders left in CLAUDE.md and AGENT_WORKFLOW.md.
  2. Add path-specific allow/ask rules to .claude/settings.json for this repo's
     actual frontend/backend directory layout (the template ships generic-only).
  3. Install the skills that can't be vendored for licensing reasons
     (frontend-design, remotion) and configure MCP connectors —
     see docs/external-setup-checklist.md in softwareFactory.
EOF
```

- [ ] **Step 3: Make it executable and run the syntax check**

Run: `chmod +x scripts/bootstrap.sh && bash -n scripts/bootstrap.sh && echo SYNTAX_OK`
Expected: `SYNTAX_OK`

- [ ] **Step 4: End-to-end dry run against a throwaway directory**

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
Expected: `ALL_FILES_PRESENT` (every `test`/`grep` must pass — `set -e` is not in
effect here, so run them one at a time if you need to see which one fails)

- [ ] **Step 5: Run it again against the same (now populated) directory to confirm idempotency**

```bash
mkdir -p /tmp/bootstrap-dry-run-2
scripts/bootstrap.sh /tmp/bootstrap-dry-run-2 test-project > /tmp/run1.log
scripts/bootstrap.sh /tmp/bootstrap-dry-run-2 test-project > /tmp/run2.log
grep -q "skip (exists):" /tmp/run2.log && echo IDEMPOTENT
rm -rf /tmp/bootstrap-dry-run-2 /tmp/run1.log /tmp/run2.log
```
Expected: `IDEMPOTENT`

- [ ] **Step 6: Commit**

```bash
git add scripts/bootstrap.sh
git commit -m "Add bootstrap.sh: idempotent installer for the canonical Claude config"
```

---

### Task 12: `docs/external-setup-checklist.md`

**Files:**
- Create: `docs/external-setup-checklist.md`

This documents the pieces that **cannot** be scripted or vendored: skills under
licenses that don't permit copying (Frontend Design, Remotion — see "Before you
start"), and MCP connectors that need live credentials per machine/account.

- [ ] **Step 1: Write the verification check (should fail)**

Run: `grep -c "plugin install frontend-design" docs/external-setup-checklist.md`
Expected: FAIL ("No such file or directory")

- [ ] **Step 2: Create the checklist**

Write `docs/external-setup-checklist.md`:

```markdown
# External setup checklist (per machine / per account)

These items are **not** vendored or scripted by `scripts/bootstrap.sh` —
each requires either a license that doesn't permit copying, or live credentials
tied to a person/machine/account. Run through this once per environment
(e.g., once on the Mac mini), not once per repo.

See `docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md`
for the rationale behind each choice.

## Skills installed via official channels (not vendored — licensing)

- [ ] **Frontend Design** (Anthropic, official). Anthropic's terms don't permit
      redistributing the files, so install it directly from the marketplace:
      `/plugin install frontend-design@claude-plugins-official`
- [ ] **Remotion**. Distributed under the Remotion License (restrictive for large
      companies) — install via its own installer rather than copying files:
      `npx skills add remotion`

## MCP connectors (need live credentials — configure per machine)

- [ ] **GitHub MCP server** — official server; richer and more token-efficient
      than shelling out to `gh` for PR/issue operations.
- [ ] **Figma Dev Mode MCP Server** — lets the agent read approved design specs
      and components directly instead of being told about them in prose.
- [ ] **Playwright MCP** — gives `qa-visual-agent` native browser tools instead
      of shelling out to a separate process.
- [ ] **Documentation MCP** (e.g. Context7) — current library/API docs on demand,
      instead of guessing from training data or burning tokens on generic web search.
- [ ] **Telegram via Claude Code Channels** — checkpoint / blocking-question / PR
      notifications, without the risk surface of a full orchestrator (OpenClaw).

## Explicitly NOT installed (decision recorded, don't re-litigate)

- **claude-mem** — a Feb-2026 community audit rated it HIGH risk: its local HTTP
  API (port 37777) has no authentication, so any process on the machine can read
  every stored observation (including API keys in cleartext) and inject fake
  memories. This directly contradicts the least-privilege design in spec section 7.
  Persistent memory is instead covered by Auto Memory + `CLAUDE.md` + decision logs
  + versioned specs + GitHub Issues (spec section 3.1) — all native, all auditable.
- **Sequential Thinking MCP** — redundant with native extended thinking plus the
  `brainstorming`/`systematic-debugging`/`writing-plans` skills already installed;
  adding it would spend tokens duplicating something already solved.
- **UI/UX Pro Max** — redundant with Frontend Design. Revisit later specifically
  for its accessibility auditor (contrast/ARIA) if that becomes a real need.
- **NotebookLM MCP** — real token-saving benefit, but no official API (works via
  browser automation against Google's internal endpoints — fragile, ToS gray area).
  Revisit once the base flow is stable.
```

- [ ] **Step 3: Run the verification check again**

Run: `grep -c "plugin install frontend-design" docs/external-setup-checklist.md`
Expected: `1`

- [ ] **Step 4: Commit**

```bash
git add docs/external-setup-checklist.md
git commit -m "Add external setup checklist for skills/connectors that can't be vendored or scripted"
```

---

## Final check — everything together

- [ ] **Run the full verification suite in one pass**

```bash
python3 -m json.tool templates/settings.json.template > /dev/null && echo "1: settings.json.template OK"
test -f templates/CLAUDE.md.template && echo "2: CLAUDE.md.template OK"
grep -q "APROBADO PARA IMPLEMENTAR" templates/AGENT_WORKFLOW.md.template && echo "3: AGENT_WORKFLOW.md.template OK"
python3 -c "import yaml; yaml.safe_load(open('templates/github/workflows/ci.yml'))" && echo "4: ci.yml OK"
grep -q "Preview URL" templates/github/pull_request_template.md && echo "5: pull_request_template.md OK"
for a in db-query-agent qa-visual-agent research-agent; do
  test -f ".claude/agents/$a.md" && echo "agent $a OK"
done
test -f .claude/skills/qa/SKILL.md && echo "9: qa skill vendored OK"
test -f .claude/skills/stop-slop/SKILL.md && echo "10: stop-slop skill vendored OK"
bash -n scripts/bootstrap.sh && echo "11: bootstrap.sh syntax OK"
grep -q "plugin install frontend-design" docs/external-setup-checklist.md && echo "12: external-setup-checklist.md OK"
```
Expected: 12 "OK" lines, no errors

- [ ] **Update the spec's checklist (section 7) to reflect what's done**

Open `docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md`
and check off every box in section "7. Próximos pasos / artefactos a generar"
that this plan completed (all of them, except the live-credential connector setup,
which Task 12 now documents instead of completing).

- [ ] **Final commit**

```bash
git add docs/superpowers/specs/2026-06-08-claude-config-software-factory-design.md
git commit -m "Mark Phase 1 config artifacts as delivered in the design spec checklist"
```
