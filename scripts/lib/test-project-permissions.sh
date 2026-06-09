#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/project-permissions.sh" 2>/dev/null || { echo "FAIL — project-permissions.sh no existe"; exit 1; }

PASS=0
FAIL=0

run_test() {
  local desc="$1"
  local result="$2"
  local expected="$3"
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

# Fixtures
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

# Test 1: monorepo con backend/src y frontend/src y frontend/e2e
mkdir -p "$TMP/t1/backend/src" "$TMP/t1/frontend/src" "$TMP/t1/frontend/e2e"
result=$(detect_write_paths "$TMP/t1")
run_test "monorepo completo incluye backend/src" "$(echo "$result" | grep -c "Write(backend/src/\*\*)")" "1"
run_test "monorepo completo incluye frontend/src" "$(echo "$result" | grep -c "Write(frontend/src/\*\*)")" "1"
run_test "monorepo completo incluye frontend/e2e" "$(echo "$result" | grep -c "Write(frontend/e2e/\*\*)")" "1"

# Test 2: single-app con solo src/
mkdir -p "$TMP/t2/src"
result=$(detect_write_paths "$TMP/t2")
run_test "single-app detecta Write(src/**)" "$(echo "$result" | grep -c "Write(src/\*\*)")" "1"
run_test "single-app no propone backend" "$(echo "$result" | grep -c "Write(backend")" "0"

# Test 3: backend sin src/ (usa backend/**)
mkdir -p "$TMP/t3/backend"
result=$(detect_write_paths "$TMP/t3")
run_test "backend sin src usa backend/**" "$(echo "$result" | grep -c "Write(backend/\*\*)")" "1"

echo ""
echo "Resultado: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
