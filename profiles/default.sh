#!/bin/bash
# profiles/default.sh — perfil de instalación por defecto

# Herramientas esenciales para el desarrollo con systutor
DEFAULT_PROFILE_TOOLS=(
  git
  python3
  pip
  node
  npm
  curl
  build-essential
  jq
  tree
  unzip
)

# Configuración de dotfiles a instalar
DEFAULT_DOTFILES=(
  bashrc
  gitconfig
  tmux.conf
)

# Configuración de zellij
DEFAULT_ZELLIJ=1
