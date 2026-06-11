#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/install-helpers.sh"

PASS=0
FAIL=0

run_test() {
  local desc="$1" result="$2" expected="$3"
  if [[ "$result" == "$expected" ]]; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc"
    echo "     Esperado: $expected"
    echo "     Obtenido: $result"
    FAIL=$((FAIL + 1))
  fi
}

TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

TEMPLATE="$TMP/template.json"
cat > "$TEMPLATE" <<'TMPL'
{
  "permissions": {
    "allow": ["Read(**)", "Bash(git *)"],
    "ask":   ["Bash(rm *)"],
    "deny":  ["Bash(*sudo*)"]
  }
}
TMPL

# Test 1: target ausente → se crea copiando el template
TARGET1="$TMP/t1/settings.json"
mkdir -p "$(dirname "$TARGET1")"
merge_settings "$TEMPLATE" "$TARGET1"
run_test "target ausente → crea el archivo" \
  "$(test -f "$TARGET1" && echo ok)" "ok"

# Test 2: nuevos allow del template se agregan al target existente
TARGET2="$TMP/t2/settings.json"
mkdir -p "$(dirname "$TARGET2")"
printf '{"permissions":{"allow":["Bash(git *)"],"ask":[],"deny":[]}}' > "$TARGET2"
merge_settings "$TEMPLATE" "$TARGET2"
run_test "nuevos allow del template se agregan" \
  "$(jq '.permissions.allow | contains(["Read(**)", "Bash(git *)"])' "$TARGET2")" "true"

# Test 3: nuevos deny del template se agregan al target
TARGET3="$TMP/t3/settings.json"
mkdir -p "$(dirname "$TARGET3")"
printf '{"permissions":{"allow":[],"ask":[],"deny":[]}}' > "$TARGET3"
merge_settings "$TEMPLATE" "$TARGET3"
run_test "nuevos deny del template se agregan" \
  "$(jq '.permissions.deny | contains(["Bash(*sudo*)"])' "$TARGET3")" "true"

# Test 4: allow ya existentes en el target sobreviven
TARGET4="$TMP/t4/settings.json"
mkdir -p "$(dirname "$TARGET4")"
printf '{"permissions":{"allow":["Read(**)", "Bash(git *)"],"ask":[],"deny":[]}}' > "$TARGET4"
merge_settings "$TEMPLATE" "$TARGET4"
run_test "allow existentes en target sobreviven" \
  "$(jq '.permissions.allow | contains(["Read(**)", "Bash(git *)"])' "$TARGET4")" "true"

# Test 5: allow custom del target (no en template) sobreviven
TARGET5="$TMP/t5/settings.json"
mkdir -p "$(dirname "$TARGET5")"
printf '{"permissions":{"allow":["Write(src/**)"],"ask":[],"deny":[]}}' > "$TARGET5"
merge_settings "$TEMPLATE" "$TARGET5"
run_test "allow custom del target sobreviven" \
  "$(jq '.permissions.allow | contains(["Write(src/**)"])' "$TARGET5")" "true"

# Test 6: idempotente — segunda corrida no cambia el contenido
TARGET6="$TMP/t6/settings.json"
mkdir -p "$(dirname "$TARGET6")"
cp "$TEMPLATE" "$TARGET6"
merge_settings "$TEMPLATE" "$TARGET6" >/dev/null
CONTENT1=$(jq -S . "$TARGET6")
merge_settings "$TEMPLATE" "$TARGET6" >/dev/null
CONTENT2=$(jq -S . "$TARGET6")
run_test "idempotente: segunda corrida no cambia nada" "$CONTENT1" "$CONTENT2"

# Test 7: campos no-permissions del target sobreviven (env)
TARGET7="$TMP/t7/settings.json"
mkdir -p "$(dirname "$TARGET7")"
printf '{"permissions":{"allow":[],"ask":[],"deny":[]},"env":{"MY_VAR":"hello"}}' > "$TARGET7"
merge_settings "$TEMPLATE" "$TARGET7"
run_test "env del target sobrevive" \
  "$(jq '.env.MY_VAR' "$TARGET7")" '"hello"'

# Test 8: no se crean duplicados si el permiso está en template y target
TARGET8="$TMP/t8/settings.json"
mkdir -p "$(dirname "$TARGET8")"
cp "$TEMPLATE" "$TARGET8"
merge_settings "$TEMPLATE" "$TARGET8"
run_test "no se crean duplicados en allow" \
  "$(jq '.permissions.allow | length' "$TARGET8")" \
  "$(jq '.permissions.allow | length' "$TEMPLATE")"

echo ""
echo "Resultados: $PASS ✅  $FAIL ❌"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
