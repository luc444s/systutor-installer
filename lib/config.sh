#!/bin/bash
# config.sh — configuración global de systutor-installer

# ── Repos ────────────────────────────────────────────────────────────────────
CORE_URL="${SYSTUTOR_CORE_URL:-https://github.com/luc444s/systutor-core.git}"
SHELL_URL="${SYSTUTOR_SHELL_URL:-https://github.com/luc444s/systutor-shell.git}"
THEMES_URL="${SYSTUTOR_THEMES_URL:-https://github.com/luc444s/systutor-themes.git}"
DOTFILES_URL="${SYSTUTOR_DOTFILES_URL:-https://github.com/luc444s/dotfiles.git}"
ADD_URL="${SYSTUTOR_ADD_URL:-https://github.com/luc444s/atomic-driven-development.git}"
DASHBOARD_URL="${SYSTUTOR_DASHBOARD_URL:-https://github.com/luc444s/systutor-dashboard-shell.git}"

# ── Paths dentro del proyecto ────────────────────────────────────────────────
CORE_PATH="vendor/systutor-core"
SHELL_PATH="vendor/systutor-shell"
THEMES_PATH="vendor/systutor-themes"
DOTFILES_PATH="/tmp/systutor-dotfiles"
ADD_PATH="vendor/atomic-driven-development"

# ── Defaults ─────────────────────────────────────────────────────────────────
WEB_DIR="apps/web"
DRY_RUN=0
FORCE=0
VERBOSE=0

# ── Tools disponibles (nombre:descripcion:requerido) ────────────────────────
TOOLS=(
  "git:control de versiones:1"
  "python3:lenguaje Python:1"
  "pip:gestor de paquetes Python:1"
  "node:runtime JavaScript:1"
  "npm:gestor de paquetes Node:1"
  "curl:cliente HTTP:1"
  "wget:descargador de archivos:0"
  "build-essential:compiladores C/C++:0"
  "docker:motor de contenedores:0"
  "docker-compose:orquestador Docker:0"
  "jq:procesador JSON:0"
  "tree:visualizar directorios:0"
  "htop:monitor de procesos:0"
  "unzip:descompresor:0"
  "zellij:multiplexor de terminales:0"
  "tmux:multiplexor de terminales:0"
)

# ── Perfiles predefinidos ───────────────────────────────────────────────────
# Cada perfil es una lista de tools separadas por espacio
PROFILE_DEV="git python3 pip node npm curl wget build-essential jq tree unzip"
PROFILE_FULL="git python3 pip node npm curl wget build-essential docker docker-compose jq tree htop unzip zellij tmux"
PROFILE_MINIMAL="git python3 pip node npm curl"
