#!/bin/bash
# commands/dotfiles.sh — clona e instala dotfiles

cmd_dotfiles() {
  local subcmd="${1:-install}"
  shift 2>/dev/null || true

  case "$subcmd" in
    install) _dotfiles_install "$@" ;;
    update)  _dotfiles_update "$@" ;;
    list)    _dotfiles_list ;;
    *)       err "subcomando desconocido: $subcmd (usá: install, update, list)"; return 1 ;;
  esac
}

_dotfiles_install() {
  step "Dotfiles — configs de shell y herramientas"

  # Clonar si no existe
  if [ ! -d "$DOTFILES_PATH" ]; then
    log "clonando $DOTFILES_URL..."
    run git clone --depth 1 "$DOTFILES_URL" "$DOTFILES_PATH"
  else
    log "dotfiles ya clonados en $DOTFILES_PATH"
  fi

  # Ejecutar el install.sh de dotfiles
  if [ -f "$DOTFILES_PATH/install.sh" ]; then
    log "ejecutando dotfiles/install.sh..."
    if [ "$DRY_RUN" = 1 ]; then
      info "  (dry-run) bash $DOTFILES_PATH/install.sh"
    else
      bash "$DOTFILES_PATH/install.sh"
    fi
    ok "Dotfiles instalados"
  else
    warn "No se encontró $DOTFILES_PATH/install.sh — instalando manualmente"
    _dotfiles_manual
  fi
}

_dotfiles_update() {
  step "Dotfiles — actualizando"

  if [ ! -d "$DOTFILES_PATH" ]; then
    die "dotfiles no instalados — ejecutá: systutor-installer dotfiles install"
  fi

  log "actualizando repositorio..."
  run git -C "$DOTFILES_PATH" pull --ff-only

  # Re-ejecutar install
  if [ -f "$DOTFILES_PATH/install.sh" ]; then
    log "re-ejecutando install.sh..."
    if [ "$DRY_RUN" = 1 ]; then
      info "  (dry-run) bash $DOTFILES_PATH/install.sh"
    else
      bash "$DOTFILES_PATH/install.sh"
    fi
  fi

  ok "Dotfiles actualizados"
}

_dotfiles_list() {
  step "Dotfiles — archivos incluidos"

  if [ ! -d "$DOTFILES_PATH/configs" ]; then
    warn "dotfiles no clonados — ejecutá: systutor-installer dotfiles install"
    return 0
  fi

  info "Configs disponibles:"
  for f in "$DOTFILES_PATH"/configs/*; do
    local name
    name="$(basename "$f")"
    if [ -d "$f" ]; then
      printf "  ${CYAN}%-20s${RESET} (directorio)\n" "$name/"
    else
      printf "  %-20s\n" "$name"
    fi
  done
}

_dotfiles_manual() {
  # Instalación manual fallback si no hay install.sh
  local configs="$DOTFILES_PATH/configs"
  [ -d "$configs" ] || return 0

  [ -f "$configs/bashrc" ]    && link_file "$configs/bashrc" "$HOME/.bashrc"
  [ -f "$configs/gitconfig" ] && link_file "$configs/gitconfig" "$HOME/.gitconfig"
  [ -f "$configs/tmux.conf" ] && link_file "$configs/tmux.conf" "$HOME/.tmux.conf"

  # Zellij
  if [ -d "$configs/zellij" ]; then
    mkdir -p "$HOME/.config/zellij"
    [ -f "$configs/zellij/config.kdl" ] && link_file "$configs/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
    if [ -d "$configs/zellij/themes" ]; then
      mkdir -p "$HOME/.config/zellij/themes"
      for theme in "$configs/zellij/themes/"*.kdl; do
        [ -f "$theme" ] && link_file "$theme" "$HOME/.config/zellij/themes/$(basename "$theme")"
      done
    fi
  fi

  # Termux
  if is_termux; then
    mkdir -p "$HOME/.termux"
    [ -f "$configs/termux/colors.properties" ] && link_file "$configs/termux/colors.properties" "$HOME/.termux/colors.properties"
    [ -f "$configs/termux/font.ttf" ]          && link_file "$configs/termux/font.ttf" "$HOME/.termux/font.ttf"
    [ -f "$configs/termux/termux.properties" ] && link_file "$configs/termux/termux.properties" "$HOME/.termux/termux.properties"
    have termux-reload-settings && run termux-reload-settings
  fi

  # Bash local override
  [ ! -e "$HOME/.bashrc.local" ] && run touch "$HOME/.bashrc.local"
  [ ! -e "$HOME/.gitconfig.local" ] && run touch "$HOME/.gitconfig.local"

  ok "Dotfiles instalados (manual)"
}
