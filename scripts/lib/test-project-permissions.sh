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

# Test 4: detect_dev_server_situation — root package.json con script dev → "ok"
mkdir -p "$TMP/t_ok"
echo '{"scripts":{"dev":"node server.js"}}' > "$TMP/t_ok/package.json"
result=$(detect_dev_server_situation "$TMP/t_ok")
run_test "root dev script detecta ok" "$result" "ok"

# Test 5: detect_dev_server_situation — backend + frontend con dev, sin root → "needs_concurrently"
mkdir -p "$TMP/t_needs/backend" "$TMP/t_needs/frontend"
echo '{"scripts":{"dev":"node index.js"}}' > "$TMP/t_needs/backend/package.json"
echo '{"scripts":{"dev":"vite"}}' > "$TMP/t_needs/frontend/package.json"
result=$(detect_dev_server_situation "$TMP/t_needs")
run_test "backend+frontend sin root detecta needs_concurrently" "$result" "needs_concurrently"

# Test 6: detect_dev_server_situation — directorio vacío → "unknown"
mkdir -p "$TMP/t_unknown"
result=$(detect_dev_server_situation "$TMP/t_unknown")
run_test "directorio vacío detecta unknown" "$result" "unknown"

# Test 7: solo app/ → detect_write_paths incluye Write(app/**)
mkdir -p "$TMP/t_app/app"
result=$(detect_write_paths "$TMP/t_app")
run_test "solo app/ detecta Write(app/**)" "$(echo "$result" | grep -c "Write(app/\*\*)")" "1"

echo ""
echo "Resultado: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
