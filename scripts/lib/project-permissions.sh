#!/usr/bin/env bash
# No se usa set -euo pipefail: esta lib es sourced desde otros scripts
# que ya tienen sus propias flags; agregar set aquí interferiría con el caller.

# Funciones de detección de estructura de proyecto para el wizard de permisos.

# detect_write_paths <dir>
# Imprime en stdout una línea por cada Write path detectado.
# Cubre: monorepo backend+frontend, single-app src/, app/, backend solo.
detect_write_paths() {
  [[ -z "${1:-}" ]] && { echo "Error: se requiere directorio" >&2; return 1; }
  local target_dir="$1"

  if [[ -d "$target_dir/backend/src" ]]; then
    echo "Write(backend/src/**)"
  elif [[ -d "$target_dir/backend" ]]; then
    echo "Write(backend/**)"
  fi

  if [[ -d "$target_dir/frontend/src" ]]; then
    echo "Write(frontend/src/**)"
  elif [[ -d "$target_dir/frontend" ]]; then
    echo "Write(frontend/**)"
  fi

  if [[ -d "$target_dir/frontend/e2e" ]]; then
    echo "Write(frontend/e2e/**)"
  fi

  # Single-app: solo src/ sin backend ni frontend
  if [[ -d "$target_dir/src" ]] && \
     [[ ! -d "$target_dir/backend" ]] && \
     [[ ! -d "$target_dir/frontend" ]]; then
    echo "Write(src/**)"
  fi

  if [[ -d "$target_dir/app" ]]; then
    echo "Write(app/**)"
  fi
}

# detect_dev_server_situation <dir>
# Imprime: "ok" | "needs_concurrently" | "unknown"
detect_dev_server_situation() {
  [[ -z "${1:-}" ]] && { echo "Error: se requiere directorio" >&2; return 1; }
  local target_dir="$1"

  if [[ -f "$target_dir/package.json" ]] && \
     jq -e '.scripts.dev' "$target_dir/package.json" > /dev/null 2>&1; then
    echo "ok"
    return
  fi

  local backend_has_dev=false
  local frontend_has_dev=false

  if [[ -f "$target_dir/backend/package.json" ]] && \
     jq -e '.scripts.dev' "$target_dir/backend/package.json" > /dev/null 2>&1; then
    backend_has_dev=true
  fi

  if [[ -f "$target_dir/frontend/package.json" ]] && \
     jq -e '.scripts.dev' "$target_dir/frontend/package.json" > /dev/null 2>&1; then
    frontend_has_dev=true
  fi

  if [[ "$backend_has_dev" == "true" ]] && [[ "$frontend_has_dev" == "true" ]]; then
    echo "needs_concurrently"
  else
    echo "unknown"
  fi
}
