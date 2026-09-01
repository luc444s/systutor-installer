#!/bin/bash
# commands/start.sh — agrega scripts npm para correr frontend y backend

_add_npm_script() {
  local pkg_file="$1" script_name="$2" script_cmd="$3"
  if [ "$DRY_RUN" = 1 ]; then
    info "  (dry-run) agregar script '$script_name' a $pkg_file"
    return 0
  fi
  python3 - "$pkg_file" "$script_name" "$script_cmd" <<'PY'
import json, sys
file, name, cmd = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.loads(open(file).read())
scripts = data.setdefault("scripts", {})
if name in scripts:
    if scripts[name] == cmd:
        print(f"  script '{name}' ya existe con el mismo comando, omito")
    else:
        print(f"  script '{name}' existe con otro comando ({scripts[name]}) — no se sobreescribe")
    sys.exit(0)
scripts[name] = cmd
open(file, "w").write(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
print(f"  script '{name}' agregado a {file}")
PY
}

cmd_start() {
  local subcmd="${1:-setup}"
  shift 2>/dev/null || true

  case "$subcmd" in
    setup)  _start_setup "$@" ;;
    up)     _start_up "$@" ;;
    *)      err "subcomando desconocido: $subcmd (usá: setup, up)"; return 1 ;;
  esac
}

_start_setup() {
  local target="${INSTALL_ROOT:-.}"

  while [ $# -gt 0 ]; do
    case "$1" in
      --web-dir) WEB_DIR="$2"; shift 2 ;;
      -*) err "opción desconocida: $1"; return 1 ;;
      *) target="$1"; shift ;;
    esac
  done

  step "Start — configurando scripts npm"

  cd "$target" || return 1

  # Buscar package.json en la raíz
  local root_pkg="package.json"
  if [ ! -f "$root_pkg" ]; then
    log "creando package.json en la raíz..."
    if [ "$DRY_RUN" = 0 ]; then
      cat > "$root_pkg" <<'PKGJSON'
{
  "name": "systutor-project",
  "version": "0.1.0",
  "private": true,
  "scripts": {}
}
PKGJSON
    fi
  fi

  # Agregar scripts al package.json raíz
  _add_npm_script "$root_pkg" "frontend" "cd $WEB_DIR && npm run dev"
  _add_npm_script "$root_pkg" "services" "cd vendor/systutor-core && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
  _add_npm_script "$root_pkg" "db" "cd vendor/systutor-core && alembic upgrade head"
  _add_npm_script "$root_pkg" "dev" "npm run services & npm run frontend"
  _add_npm_script "$root_pkg" "typecheck" "cd $WEB_DIR && npx tsc --noEmit"

  ok "Scripts npm configurados"
  echo ""
  info "Uso:"
  info "  npm run frontend    # arranca el frontend (vite dev)"
  info "  npm run services    # arranca el backend (uvicorn)"
  info "  npm run dev         # arranca ambos"
  info "  npm run typecheck   # chequea tipos TypeScript"
}

_start_up() {
  local target="${INSTALL_ROOT:-.}"

  while [ $# -gt 0 ]; do
    case "$1" in
      --frontend) START_FE=1; shift ;;
      --backend)  START_BE=1; shift ;;
      -*) err "opción desconocida: $1"; return 1 ;;
      *) target="$1"; shift ;;
    esac
  done

  step "Start — arrancando servicios"

  cd "$target" || return 1

  local start_fe="${START_FE:-0}"
  local start_be="${START_BE:-0}"

  # Si no se especificó nada, arrancar ambos
  if [ "$start_fe" = 0 ] && [ "$start_be" = 0 ]; then
    start_fe=1
    start_be=1
  fi

  if [ "$start_be" = 1 ]; then
    log "arrancando backend (uvicorn)..."
    if [ "$DRY_RUN" = 1 ]; then
      info "  (dry-run) cd vendor/systutor-core && uvicorn app.main:app --reload"
    else
      # Activar venv si existe
      if [ -f ".venv/bin/activate" ]; then
        # shellcheck disable=SC1091
        . .venv/bin/activate
      fi
      cd vendor/systutor-core && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 &
    fi
  fi

  if [ "$start_fe" = 1 ]; then
    log "arrancando frontend (vite)..."
    if [ "$DRY_RUN" = 1 ]; then
      info "  (dry-run) cd $WEB_DIR && npm run dev"
    else
      cd "$WEB_DIR" && npm run dev &
    fi
  fi

  if [ "$DRY_RUN" = 0 ]; then
    log "servicios arrancados — Ctrl+C para detener"
    wait
  fi
}
