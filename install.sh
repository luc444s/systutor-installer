#!/bin/bash
# install.sh — systutor-installer CLI v2.0
# Instala tu set de programación completo: tools, systutor, dotfiles, ADD.
#
# Uso:
#   bash install.sh <comando> [opciones]
#   ./install.sh --help
#
# Comandos:
#   systutor    Instalar systutor-core + systutor-shell
#   add         Instalar Atomic-Driven-Development (ADD)
#   tools       Instalar herramientas de desarrollo
#   dotfiles    Instalar configuraciones de shell
#   all         Instalar todo
#   diag        Diagnóstico del entorno

set -euo pipefail

# ── Resolver ruta del script (funciona con symlinks) ────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Cargar librerías ────────────────────────────────────────────────────────
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=lib/config.sh
source "$SCRIPT_DIR/lib/config.sh"

# ── Cargar comandos ─────────────────────────────────────────────────────────
# shellcheck source=commands/systutor.sh
source "$SCRIPT_DIR/commands/systutor.sh"
# shellcheck source=commands/tools.sh
source "$SCRIPT_DIR/commands/tools.sh"
# shellcheck source=commands/dotfiles.sh
source "$SCRIPT_DIR/commands/dotfiles.sh"
# shellcheck source=commands/add.sh
source "$SCRIPT_DIR/commands/add.sh"

# ── Diagnóstico ─────────────────────────────────────────────────────────────
cmd_diag() {
  step "Diagnóstico del entorno"

  local platform arch pm
  platform="$(get_platform)"
  arch="$(get_arch)"
  pm="$(detect_pkg_manager)"

  printf "  ${BOLD}%-15s${RESET} %s\n" "Plataforma:" "$platform"
  printf "  ${BOLD}%-15s${RESET} %s\n" "Arquitectura:" "$arch"
  printf "  ${BOLD}%-15s${RESET} %s\n" "Pkg manager:" "$pm"
  printf "  ${BOLD}%-15s${RESET} %s\n" "Shell:" "$SHELL"
  printf "  ${BOLD}%-15s${RESET} %s\n" "Home:" "$HOME"
  echo ""

  # Tools
  step "Herramientas detectadas"
  printf "  ${BOLD}%-20s %-30s${RESET}\n" "TOOL" "ESTADO"
  echo "  ─────────────────────────────────────────────"
  for entry in "${TOOLS[@]}"; do
    IFS=':' read -r name desc req <<< "$entry"
    if have "$name"; then
      local ver
      ver="$($name --version 2>/dev/null | head -1 || echo "?")"
      printf "  ${GREEN}✓${RESET} %-20s ${DIM}%s${RESET}\n" "$name" "$ver"
    elif [ "$req" = "1" ]; then
      printf "  ${RED}✗${RESET} %-20s ${RED}REQUERIDO — no encontrado${RESET}\n" "$name"
    else
      printf "  ${DIM}○${RESET} %-20s ${DIM}opcional — no encontrado${RESET}\n" "$name"
    fi
  done
  echo ""

  # Termux warnings
  if is_termux; then
    warn "Termux detectado: usa 'pkg install' en lugar de apt"
    have clang || warn "clang no encontrado — necesario para compilar asyncpg"
    have pg_config || warn "pg_config no encontrado — necesario para asyncpg"
  fi

  # Git
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "Directorio actual: repo git ($(basename "$(git rev-parse --show-toplevel)"))"
  else
    info "Directorio actual: no es un repo git"
  fi
}

# ── All ──────────────────────────────────────────────────────────────────────
cmd_all() {
  step "Instalación completa"

  set +e
  cmd_tools "$@"
  cmd_dotfiles install

  # systutor + add solo si estamos en un repo git
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    cmd_systutor "$@"
    cmd_add install
  else
    warn "No estás en un repo git — omitiendo systutor y add"
    info "  Entrá a tu proyecto y ejecutá: ./install.sh systutor"
  fi
  set -e

  echo ""
  ok "¡Instalación completa!"
  echo ""
  info "Próximos pasos:"
  info "  1. Abrí una nueva terminal (o: source ~/.bashrc)"
  info "  2. Entrá a tu proyecto systutor"
  info "  3. Ejecutá: ./install.sh systutor"
}

# ── Help ─────────────────────────────────────────────────────────────────────
usage() {
  banner
  cat <<'EOF'
Uso: install.sh <comando> [opciones]

Comandos:
  systutor [--core|--shell] [--web-dir DIR] [RUTA]
                         Instalar systutor-core + systutor-shell
  add [install|update|list|skills] [RUTA]
                         Instalar Atomic-Driven-Development (ADD)
  tools [--profile NAME] [--list] [--only tool...]
                         Instalar herramientas de desarrollo
  dotfiles [install|update|list]
                         Instalar/actualizar configuraciones de shell
  all [opciones]         Instalar todo (tools + dotfiles + systutor + add)
  diag                   Diagnóstico del entorno

Opciones globales:
  --dry-run              Mostrar qué se haría sin ejecutar
  --force                No pedir confirmaciones
  --verbose              Salida detallada
  -h, --help             Mostrar esta ayuda

Perfiles (para tools):
  dev        Git, Python, Node, curl, build-essential (default)
  full       Todo incluido Docker, zellij, tmux
  minimal    Solo Git, Python, Node, curl

Ejemplos:
  ./install.sh all                          # instala todo
  ./install.sh tools --profile full         # instala tools full
  ./install.sh tools --only docker git      # instala solo docker y git
  ./install.sh systutor /mi/proyecto        # monta systutor en un repo
  ./install.sh add /mi/proyecto             # clona ADD en un repo
  ./install.sh add skills                   # ver skills disponibles
  ./install.sh dotfiles update              # actualiza dotfiles
  ./install.sh diag                         # ver entorno actual

Variables de entorno:
  SYSTUTOR_CORE_URL     URL del repo core (default: GitHub)
  SYSTUTOR_SHELL_URL    URL del repo shell
  SYSTUTOR_DOTFILES_URL URL del repo dotfiles
  SYSTUTOR_ADD_URL      URL del repo ADD

Soportado: Linux x86_64/aarch64, macOS, Termux (Android)
EOF
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
  # Primero parsear flags globales
  local args=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run)  DRY_RUN=1; shift ;;
      --force)    FORCE=1; shift ;;
      --verbose)  VERBOSE=1; shift ;;
      -h|--help)  usage; exit 0 ;;
      --version)  echo "systutor-installer v2.0"; exit 0 ;;
      *)          args+=("$1"); shift ;;
    esac
  done

  # Si no hay argumentos, mostrar help
  if [ ${#args[@]} -eq 0 ]; then
    usage
    exit 0
  fi

  # El primer arg es el comando
  local cmd="${args[0]}"
  # Pasar el resto de args al comando
  local cmd_args=("${args[@]:1}")

  case "$cmd" in
    systutor)  cmd_systutor "${cmd_args[@]}" ;;
    add)       cmd_add "${cmd_args[@]}" ;;
    tools)     cmd_tools "${cmd_args[@]}" ;;
    dotfiles)  cmd_dotfiles "${cmd_args[@]}" ;;
    all)       cmd_all "${cmd_args[@]}" ;;
    diag)      cmd_diag ;;
    *)         err "comando desconocido: $cmd"; echo ""; usage; exit 1 ;;
  esac
}

main "$@"
