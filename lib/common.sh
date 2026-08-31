#!/bin/bash
# common.sh — utilidades compartidas para systutor-installer
# POSIX-compatible, funciona en Linux, macOS y Termux.

set -euo pipefail

# ── Colores ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Logging ──────────────────────────────────────────────────────────────────
log()    { printf "${CYAN}[systutor]${RESET} %s\n" "$*"; }
ok()     { printf "${GREEN}[systutor]${RESET} %s\n" "$*"; }
warn()   { printf "${YELLOW}[systutor] WARN:${RESET} %s\n" "$*" >&2; }
err()    { printf "${RED}[systutor] ERROR:${RESET} %s\n" "$*" >&2; }
step()   { printf "${BOLD}${BLUE}── %s ──${RESET}\n" "$*"; }
info()   { printf "${DIM}%s${RESET}\n" "$*"; }
dry()    { if [ "$DRY_RUN" = 1 ]; then log "DRY-RUN: $*"; return 0; fi; return 1; }

die() { err "$*"; exit 1; }

# ── Ejecución con dry-run ───────────────────────────────────────────────────
run() {
  if [ "$DRY_RUN" = 1 ]; then
    info "  (dry-run) $*"
    return 0
  fi
  "$@"
}

# ── Detección de plataforma ─────────────────────────────────────────────────
is_termux() {
  [ -n "${PREFIX:-}" ] && case "$PREFIX" in *termux*) return 0;; esac
  return 1
}

is_macos() {
  [ "$(uname -s)" = "Darwin" ]
}

is_linux() {
  [ "$(uname -s)" = "Linux" ] && ! is_termux
}

get_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64)   echo "x86_64" ;;
    aarch64|arm64)   echo "aarch64" ;;
    armv7l|armhf)    echo "armv7" ;;
    i686|i386)       echo "i686" ;;
    *)               echo "$arch" ;;
  esac
}

get_platform() {
  if is_termux; then echo "termux"
  elif is_macos; then echo "macos"
  elif is_linux; then echo "linux"
  else echo "unknown"
  fi
}

# ── Gestor de paquetes ──────────────────────────────────────────────────────
detect_pkg_manager() {
  if is_termux; then echo "pkg"
  elif is_macos; then
    if command -v brew >/dev/null 2>&1; then echo "brew"
    else echo "none"
    fi
  elif is_linux; then
    if command -v apt-get >/dev/null 2>&1; then echo "apt"
    elif command -v dnf >/dev/null 2>&1; then echo "dnf"
    elif command -v pacman >/dev/null 2>&1; then echo "pacman"
    elif command -v apk >/dev/null 2>&1; then echo "apk"
    else echo "none"
    fi
  else echo "none"
  fi
}

pkg_install() {
  local pm
  pm="$(detect_pkg_manager)"
  case "$pm" in
    apt)    run sudo apt-get install -y "$@" || return 1 ;;
    dnf)    run sudo dnf install -y "$@" || return 1 ;;
    pacman) run sudo pacman -S --noconfirm "$@" || return 1 ;;
    apk)    run sudo apk add "$@" || return 1 ;;
    pkg)    run pkg install -y "$@" || return 1 ;;
    brew)   run brew install "$@" || return 1 ;;
    *)      warn "No se detectó gestor de paquetes — instala manualmente: $*"; return 1 ;;
  esac
}

pkg_update() {
  local pm
  pm="$(detect_pkg_manager)"
  case "$pm" in
    apt)    run sudo apt-get update -qq ;;
    dnf)    run sudo dnf check-update || true ;;
    pacman) run sudo pacman -Sy ;;
    apk)    run sudo apk update ;;
    pkg)    run pkg update -y ;;
    brew)   run brew update ;;
  esac
}

# ── Helpers ──────────────────────────────────────────────────────────────────
have() { command -v "$1" >/dev/null 2>&1; }

require() {
  local missing=0
  for cmd in "$@"; do
    if ! have "$cmd"; then
      err "requerido: $cmd no encontrado"
      missing=1
    fi
  done
  [ "$missing" = 0 ] || exit 1
}

confirm() {
  local prompt="${1:-¿Continuar?}"
  if [ "$FORCE" = 1 ]; then return 0; fi
  printf "${YELLOW}%s [y/N]: ${RESET}" "$prompt"
  read -r answer
  case "$answer" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

backup_file() {
  local file="$1"
  if [ -e "$file" ] && [ ! -L "$file" ]; then
    local bak="${file}.bak.$(date +%Y%m%d%H%M%S)"
    run mv "$file" "$bak"
    log "backup: $file -> $bak"
  fi
}

link_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    backup_file "$dest"
  fi
  run ln -sfn "$src" "$dest"
  log "linked: $dest -> $src"
}

# ── Banner ───────────────────────────────────────────────────────────────────
banner() {
  printf "${BOLD}${MAGENTA}"
  cat <<'EOF'
  ____                  _           _ ____  _  __
 / ___|  ___ _   _  ___| | ___  ___/ |  _ \| |/ /
| |  _ / _ \ | | |/ __| |/ _ \/ __| | | | | ' /
| |_| |  __/ |_| | (__| |  __/\__ \ | |_| | . \
 \____|\___|\__, |\___|_|\___||___/_|____/|_|\_\
            |___/
EOF
  printf "${RESET}"
  printf "${DIM}Installer v2.0 — instala tu set de programación${RESET}\n\n"
}
