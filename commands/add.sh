#!/bin/bash
# commands/add.sh — clona e instala Atomic-Driven-Development (ADD)

cmd_add() {
  local subcmd="${1:-install}"
  shift 2>/dev/null || true

  case "$subcmd" in
    install) _add_install "$@" ;;
    update)  _add_update "$@" ;;
    list)    _add_list ;;
    skills)  _add_skills ;;
    *)       err "subcomando desconocido: $subcmd (usá: install, update, list, skills)"; return 1 ;;
  esac
}

_add_install() {
  local target="."

  while [ $# -gt 0 ]; do
    case "$1" in
      --target) target="$2"; shift 2 ;;
      --submodule) ADD_AS_SUBMODULE=1; shift ;;
      --local) ADD_LOCAL_PATH="$2"; shift 2 ;;
      -*) err "opción desconocida: $1"; return 1 ;;
      *) target="$1"; shift ;;
    esac
  done

  step "Atomic-Driven-Development (ADD)"

  cd "$target" || return 1

  # Determinar destino
  local dest="vendor/atomic-driven-development"
  if [ -d "$dest" ]; then
    log "ADD ya existe en $dest — ejecutá: ./install.sh add update"
    return 0
  fi

  # Clonar
  log "clonando $ADD_URL -> $dest"
  if [ "$DRY_RUN" = 1 ]; then
    info "  (dry-run) git clone $ADD_URL $dest"
  else
    git clone --depth 1 "$ADD_URL" "$dest"
  fi

  ok "ADD clonado en $dest"

  # Mostrar skills disponibles
  _add_list_skills_from "$dest"
}

_add_update() {
  local target="."

  while [ $# -gt 0 ]; do
    case "$1" in
      *) target="$1"; shift ;;
    esac
  done

  step "ADD — actualizando"

  cd "$target" || return 1
  local dest="vendor/atomic-driven-development"

  if [ ! -d "$dest" ]; then
    die "ADD no instalado — ejecutá: ./install.sh add install"
  fi

  log "actualizando..."
  run git -C "$dest" pull --ff-only

  ok "ADD actualizado"
}

_add_list() {
  step "ADD — skills disponibles"

  # Buscar en ubicaciones conocidas
  local add_dir=""
  for candidate in "vendor/atomic-driven-development" "../atomic-driven-development" "$ADD_PATH"; do
    if [ -d "$candidate/skills" ]; then
      add_dir="$candidate"
      break
    fi
  done

  if [ -z "$add_dir" ]; then
    warn "ADD no encontrado — ejecutá: ./install.sh add install"
    return 0
  fi

  _add_list_skills_from "$add_dir"
}

_add_skills() {
  _add_list
}

_add_list_skills_from() {
  local dir="$1"
  local skills_dir="$dir/skills"

  if [ ! -d "$skills_dir" ]; then
    info "No se encontró directorio skills/"
    return 0
  fi

  printf "  ${BOLD}%-30s %s${RESET}\n" "SKILL" "DESCRIPCIÓN"
  echo "  ──────────────────────────────────────────────────────"

  for skill_dir in "$skills_dir"/*/; do
    [ -d "$skill_dir" ] || continue
    local name
    name="$(basename "$skill_dir")"

    # Buscar el .md principal
    local md_file=""
    for f in "$skill_dir"*.md; do
      [ -f "$f" ] && md_file="$f" && break
    done

    local desc=""
    if [ -n "$md_file" ]; then
      # Primera línea que no esté vacía ni sea heading
      desc="$(head -5 "$md_file" | grep -v '^#' | grep -v '^$' | head -1 | sed 's/^[[:space:]]*//')"
    fi

    printf "  ${CYAN}%-30s${RESET} %s\n" "$name" "${desc:-(sin descripción)}"
  done
}
