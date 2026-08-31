#!/bin/bash
# commands/tools.sh — instala herramientas de desarrollo

cmd_tools() {
  local profile=""
  local list_only=0
  local custom_tools=()

  while [ $# -gt 0 ]; do
    case "$1" in
      --profile|-p) profile="$2"; shift 2 ;;
      --list|-l) list_only=1; shift ;;
      --only) custom_tools+=("$2"); shift 2 ;;
      -*) err "opción desconocida: $1"; return 1 ;;
      *) custom_tools+=("$1"); shift ;;
    esac
  done

  if [ "$list_only" = 1 ]; then
    _tools_list
    return 0
  fi

  step "Tools — entorno de desarrollo"

  # Determinar qué instalar
  local tools_to_install=()
  if [ ${#custom_tools[@]} -gt 0 ]; then
    tools_to_install=("${custom_tools[@]}")
  elif [ -n "$profile" ]; then
    case "$profile" in
      dev)     tools_to_install=($PROFILE_DEV) ;;
      full)    tools_to_install=($PROFILE_FULL) ;;
      minimal) tools_to_install=($PROFILE_MINIMAL) ;;
      *)       die "perfil desconocido: $profile (usá --list para ver disponibles)" ;;
    esac
  else
    tools_to_install=($PROFILE_DEV)
  fi

  log "perfil: ${profile:-custom}"
  log "tools: ${tools_to_install[*]}"

  # Actualizar repos de paquetes
  log "actualizando repositorios de paquetes..."
  pkg_update 2>/dev/null || true

  # Instalar cada tool
  local installed=0 failed=0 skipped=0
  for tool in "${tools_to_install[@]}"; do
    if have "$tool"; then
      info "  ✓ $tool ($(command -v "$tool"))"
      ((skipped++))
    else
      log "instalando $tool..."
      if _install_tool "$tool"; then
        ok "  ✓ $tool instalado"
        ((installed++))
      else
        warn "  ✗ $tool no se pudo instalar"
        ((failed++))
      fi
    fi
  done

  echo ""
  ok "Tools: $installed instalados, $skipped ya existían, $failed fallaron"

  # Post-install: nvm para node si no está
  if ! have node && [ "$DRY_RUN" = 0 ]; then
    _suggest_node_install
  fi
}

_tools_list() {
  step "Tools disponibles"
  printf "${BOLD}%-25s %-40s %s${RESET}\n" "TOOL" "DESCRIPCIÓN" "REQUERIDO"
  echo "─────────────────────────────────────────────────────────────────────"
  for entry in "${TOOLS[@]}"; do
    IFS=':' read -r name desc req <<< "$entry"
    if [ "$req" = "1" ]; then
      printf "%-25s %-40s ${GREEN}sí${RESET}\n" "$name" "$desc"
    else
      printf "%-25s %-40s ${DIM}no${RESET}\n" "$name" "$desc"
    fi
  done
  echo ""
  log "perfiles: dev (default), full, minimal"
}

_install_tool() {
  local tool="$1"
  case "$tool" in
    git)              pkg_install git ;;
    python3)          pkg_install python3 ;;
    pip)              pkg_install python3-pip ;;
    node|npm)         _install_node ;;
    curl)             pkg_install curl ;;
    wget)             pkg_install wget ;;
    build-essential)  _install_build_essential ;;
    docker)           _install_docker ;;
    docker-compose)   _install_docker_compose ;;
    jq)               pkg_install jq ;;
    tree)             pkg_install tree ;;
    htop)             pkg_install htop ;;
    unzip)            pkg_install unzip ;;
    zellij)           _install_zellij ;;
    tmux)             pkg_install tmux ;;
    clang)            pkg_install clang ;;
    *)                warn "tool '$tool' no tiene installer automático"; return 1 ;;
  esac
}

_install_node() {
  if is_termux; then
    pkg_install nodejs
  elif is_macos; then
    brew install node
  else
    # Preferir nvm si está disponible
    if [ -f "$HOME/.nvm/nvm.sh" ]; then
      log "usando nvm para instalar node..."
      if [ "$DRY_RUN" = 0 ]; then
        . "$HOME/.nvm/nvm.sh"
        nvm install --lts
        nvm use --lts
      fi
    else
      # Fallback: NodeSource
      log "instalando via NodeSource..."
      pkg_install ca-certificates curl gnupg
      if [ "$DRY_RUN" = 0 ]; then
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
          | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null || true
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
          > /etc/apt/sources.list.d/nodesource.list 2>/dev/null || true
        pkg_update 2>/dev/null || true
        pkg_install nodejs || warn "NodeSource falló — instalá manualmente"
      fi
    fi
  fi
}

_install_build_essential() {
  if is_termux; then
    pkg_install build-essential
  elif is_macos; then
    xcode-select --install 2>/dev/null || true
  else
    pkg_install build-essential
  fi
}

_install_docker() {
  if is_termux; then
    warn "Docker no está disponible en Termux"
    return 1
  elif is_macos; then
    brew install --cask docker
  else
    # Docker official install
    log "instalando Docker..."
    pkg_install ca-certificates curl gnupg
    if [ "$DRY_RUN" = 0 ]; then
      install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
      chmod a+r /etc/apt/keyrings/docker.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        > /etc/apt/sources.list.d/docker.list 2>/dev/null || true
      pkg_update 2>/dev/null || true
      pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
        || warn "Docker install falló — instalá manualmente"
    fi
  fi
}

_install_docker_compose() {
  if is_termux; then
    warn "docker-compose no está disponible en Termux"
    return 1
  elif is_macos; then
    brew install docker-compose
  else
    # Si Docker se instaló via official, compose ya viene como plugin
    if have docker && docker compose version >/dev/null 2>&1; then
      log "docker compose ya disponible como plugin"
      return 0
    fi
    pkg_install docker-compose || warn "docker-compose no disponible — usa 'docker compose'"
  fi
}

_install_zellij() {
  if is_termux; then
    warn "Zellij no está disponible en Termux — usa tmux"
    return 1
  elif is_macos; then
    brew install zellij
  else
    # Intentar con cargo si está, sino binario
    if have cargo; then
      log "instalando zellij via cargo..."
      run cargo install zellij
    else
      log "descargando zellij binario..."
      if [ "$DRY_RUN" = 0 ]; then
        local arch
        arch="$(get_arch)"
        local os="unknown-linux-musl"
        local url="https://github.com/zellij-org/zellij/releases/latest/download/zellij-${arch}-${os}.tar.gz"
        curl -fsSL "$url" | tar xz -C /usr/local/bin 2>/dev/null \
          || warn "Zellij install falló — descargá manualmente desde https://github.com/zellij-org/zellij"
      fi
    fi
  fi
}

_suggest_node_install() {
  if is_termux || is_macos; then return 0; fi
  echo ""
  info "Para instalar Node.js se recomienda nvm:"
  info "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash"
  info "  source ~/.bashrc"
  info "  nvm install --lts"
}
