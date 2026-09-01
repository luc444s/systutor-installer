#!/bin/bash
# commands/systutor.sh — instala systutor: dashboard + vendor + deps

cmd_systutor() {
  local target="${INSTALL_ROOT:-.}"

  while [ $# -gt 0 ]; do
    case "$1" in
      --core) DO_SHELL=0; shift ;;
      --shell) DO_CORE=0; shift ;;
      --web-dir) WEB_DIR="$2"; shift 2 ;;
      --no-dashboard) NO_DASHBOARD=1; shift ;;
      -*) err "opción desconocida: $1"; return 1 ;;
      *) target="$1"; shift ;;
    esac
  done

  step "Systutor — dashboard + vendor + deps"

  cd "$target" || return 1
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    die "$target no es un repositorio git"
  fi

  # 1. Clonar dashboard en apps/web (si no existe)
  [ "${NO_DASHBOARD:-0}" != 1 ] && _systutor_dashboard

  # 2. Clonar vendor (core, shell, themes)
  _systutor_core
  _systutor_shell
  _systutor_themes

  # 3. Instalar deps
  _systutor_pip_install
  _systutor_npm_install

  ok "Systutor instalado"
  echo ""
  info "Uso:"
  info "  npm run frontend    # arranca el frontend (vite dev)"
  info "  npm run services    # arranca el backend (uvicorn + postgres)"
  info "  npm run dev         # arranca ambos"
}

_systutor_dashboard() {
  if [ -d "$WEB_DIR" ]; then
    log "$WEB_DIR ya existe — omito clone del dashboard"
    return 0
  fi

  log "dashboard: $DASHBOARD_URL -> $WEB_DIR"
  run git clone --depth 1 "$DASHBOARD_URL" "$WEB_DIR"
}

_systutor_core() {
  log "kernel: $CORE_URL -> $CORE_PATH"

  if [ -d "$CORE_PATH" ]; then
    log "$CORE_PATH ya existe — omito clone"
    return 0
  fi

  run mkdir -p vendor
  run git clone --depth 1 "$CORE_URL" "$CORE_PATH"
}

_systutor_shell() {
  log "shell: $SHELL_URL -> $SHELL_PATH"

  if [ -d "$SHELL_PATH" ]; then
    log "$SHELL_PATH ya existe — omito clone"
    return 0
  fi

  run mkdir -p vendor
  run git clone --depth 1 "$SHELL_URL" "$SHELL_PATH"
}

_systutor_themes() {
  log "themes: $THEMES_URL -> $THEMES_PATH"

  if [ -d "$THEMES_PATH" ]; then
    log "$THEMES_PATH ya existe — omito clone"
    return 0
  fi

  run mkdir -p vendor
  run git clone --depth 1 "$THEMES_URL" "$THEMES_PATH"
}

_systutor_pip_install() {
  if [ ! -d "$CORE_PATH" ]; then
    warn "$CORE_PATH no existe — no se instala kernel"
    return 0
  fi

  log "pip install -e $CORE_PATH"
  if [ "$DRY_RUN" = 0 ]; then
    if [ ! -d ".venv" ]; then
      log "creando .venv..."
      python3 -m venv .venv
    fi
    # shellcheck disable=SC1091
    . .venv/bin/activate
    pip install -e "$CORE_PATH"
    ok "kernel instalado en .venv"
  fi
}

_systutor_npm_install() {
  if [ ! -d "$WEB_DIR" ]; then
    warn "$WEB_DIR no existe — no se instalan deps npm"
    return 0
  fi

  log "npm install en $WEB_DIR"
  if [ "$DRY_RUN" = 0 ]; then
    (cd "$WEB_DIR" && npm install --no-audit --no-fund) \
      || warn "npm install fallo — ejecutá manualmente: cd $WEB_DIR && npm install"
  fi
}
