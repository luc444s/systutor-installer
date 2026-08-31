#!/bin/bash
# commands/systutor.sh — instala systutor-core + systutor-shell como submodules

cmd_systutor() {
  local target="."

  while [ $# -gt 0 ]; do
    case "$1" in
      --core) DO_SHELL=0; shift ;;
      --shell) DO_CORE=0; shift ;;
      --web-dir) WEB_DIR="$2"; shift 2 ;;
      -*) err "opción desconocida: $1"; return 1 ;;
      *) target="$1"; shift ;;
    esac
  done

  step "Systutor — kernel + shell"

  cd "$target" || return 1
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    die "$target no es un repositorio git"
  fi

  [ "${DO_CORE:-1}" = 1 ] && _systutor_core
  [ "${DO_SHELL:-1}" = 1 ] && _systutor_shell

  ok "Systutor instalado"
  log "pines: git submodule status"
  run git submodule status
}

_systutor_core() {
  log "kernel: $CORE_URL -> $CORE_PATH"

  if [ -f .gitmodules ] && grep -q "path = $CORE_PATH" .gitmodules 2>/dev/null; then
    log "submodule $CORE_PATH ya existe, omito add"
  else
    run git submodule add "$CORE_URL" "$CORE_PATH"
  fi

  log "pip install -e $CORE_PATH"
  if [ "$DRY_RUN" = 0 ]; then
    # Crear venv si no existe (requerido en macOS/Homebrew y sysaptops modernos)
    if [ ! -d ".venv" ]; then
      log "creando .venv..."
      python3 -m venv .venv
    fi
    # Activar venv e instalar
    # shellcheck disable=SC1091
    . .venv/bin/activate
    pip install -e "$CORE_PATH"
    ok "kernel instalado en .venv (activá con: source .venv/bin/activate)"
  fi
}

_systutor_shell() {
  log "shell: $SHELL_URL -> $SHELL_PATH"

  if [ -f .gitmodules ] && grep -q "path = $SHELL_PATH" .gitmodules 2>/dev/null; then
    log "submodule $SHELL_PATH ya existe, omito add"
  else
    run git submodule add "$SHELL_URL" "$SHELL_PATH"
  fi

  local vite_conf="$WEB_DIR/vite.config.ts"
  local ts_conf="$WEB_DIR/tsconfig.json"

  if [ ! -f "$vite_conf" ]; then
    warn "$vite_conf no existe — alias no configurado"
    return 0
  fi

  local rel
  rel="$(python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$SHELL_PATH" "$WEB_DIR" 2>/dev/null || echo "../$SHELL_PATH")"

  _patch_tsconfig "$ts_conf" "$rel"
  _patch_vite "$vite_conf" "$rel"
  [ -f "$WEB_DIR/tailwind.config.ts" ] && _patch_tailwind "$WEB_DIR/tailwind.config.ts" "$rel"

  log "npm: peer deps del shell"
  if [ "$DRY_RUN" = 0 ]; then
    (cd "$WEB_DIR" && npm install react react-dom clsx tailwind-merge lucide-react leaflet react-leaflet sonner @tanstack/react-query --no-audit --no-fund) \
      || warn "npm install fallo — instala peer deps manualmente"
  fi
}

_patch_tsconfig() {
  local file="$1" rel="$2"
  [ ! -f "$file" ] && return 0
  python3 - "$file" "$rel" <<'PY'
import json, sys
file, rel = sys.argv[1], sys.argv[2]
data = json.loads(open(file).read())
paths = data.setdefault("compilerOptions", {}).setdefault("paths", {})
if "@systutor/shell/*" in paths:
    print("  tsconfig paths ya presentes, omito")
else:
    paths["@systutor/shell/*"] = [rel + "/src/*"]
    open(file, "w").write(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    print(f"  paths agregados a {file}")
PY
}

_patch_vite() {
  local file="$1" rel="$2"
  [ ! -f "$file" ] && return 0
  local text
  text="$(cat "$file")"
  if echo "$text" | grep -q "@systutor/shell"; then
    log "  vite alias ya presente, omito"
    return 0
  fi
  if [ "$DRY_RUN" = 0 ]; then
    python3 - "$file" "$rel" <<'PY'
import sys
file, rel = sys.argv[1], sys.argv[2]
text = open(file).read()
marker = "alias: {"
alias_line = f'      "@systutor/shell": path.resolve(__dirname, "{rel}/src"),\n'
idx = text.index(marker) + len(marker)
text = text[:idx] + "\n" + alias_line + text[idx:]
open(file, "w").write(text)
print(f"  alias agregado a {file}")
PY
  fi
}

_patch_tailwind() {
  local file="$1" rel="$2"
  [ ! -f "$file" ] && return 0
  local text
  text="$(cat "$file")"
  local entry="${rel}/src/**/*.{ts,tsx}"
  if echo "$text" | grep -qF "$entry"; then
    log "  tailwind content ya presente, omito"
    return 0
  fi
  if [ "$DRY_RUN" = 0 ]; then
    python3 - "$file" "$rel" <<'PY'
import sys
file, rel = sys.argv[1], sys.argv[2]
text = open(file).read()
marker = "content: ["
entry = f'{rel}/src/**/*.{{ts,tsx}}'
if marker not in text:
    print("  no se encontro content: en tailwind.config — agregar manual")
    sys.exit(0)
idx = text.index(marker) + len(marker)
text = text[:idx] + f'\n    "{entry}",' + text[idx:]
open(file, "w").write(text)
print(f"  content agregado a {file}")
PY
  fi
}
