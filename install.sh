#!/bin/bash

# Install packages
install_pkgs() {
  # Official
  local OFFICIAL=.official_pkgs.txt
  local NF_PKGS=$(wc -l <$OFFICIAL)

  # AUR
  local AUR=.aur_pkgs.txt
  while read -r pkg; do
    sudo pacman -S "$pkg" --noconfirm --needed
  done <"$OFFICIAL"

  echo -e "[+] Official packages installed"

  while read -r pkg; do
    yay -S "$pkg" --noconfirm --needed --answerdiff None --answerclean All
  done <"$AUR"

  echo "[+] AUR packages installed"
}

dotfiles_install() {
  echo "[+] Starting the dotfile linking process using GNU stow"
  for dir in */; do
    pkg="${dir%/}"

    if [ "$pkg" == ".git" ]; then
      continue
    fi

    if [ -e "$HOME/.config/$pkg" ] && [ ! -L "$HOME/.config/$pkg" ]; then
      echo "[!] Existing configuration found for $pkg. Backing up to $pkg.bak..."
      mv "$HOME/.config/$pkg" "$HOME/.config/$pkg.bak"
    fi

    if [ "$pkg" == "zsh" ] && [ -e "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
      echo "[!] Existing .zshrc found. Backing up..."
      mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
    fi

    if [ "$pkg" == "starship" ] && [ -e "$HOME/.config/starship.toml" ] && [ ! -L "$HOME/.config/starship.toml" ]; then
      echo "[!] Existing starship.toml found. Backing up..."
      mv "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak"
    fi

    echo "[+] --> Linking package $pkg"
    stow "$pkg"
  done
  echo "[+] Configuration applied successfully"
}

# Spiner
spiner() {
  local PID=$1
  local DELAY=0.1
  local SPIN='|/-\'
  echo -n "[+] Wait :) "
  tput civis
  while [ "$(ps a | awk '{print $1}' | grep $PID)" ]; do
    local temp=${SPIN#?}
    printf " [%c]  " "$SPIN"
    local SPIN=$temp${SPIN%"$temp"}
    sleep $DELAY
    printf "\b\b\b\b\b\b"
    printf "    \b\b\b\b"
  done
  tput cnorm
}

# Clean cursor
clean_cursor() {
  tput cnorm
  echo -e "\n "
  kill "$INSTALL_PID" >/dev/null
  echo "[+] Exit signal detected..."
  exit
}

# MAIN FUNCTION
main() {
  echo "[+] To continue with the installation, root permissions are required."
  sudo -v
  echo -e " "
  if ! uname -r | grep "cachy" >/dev/null; then
    echo -e "\n[+] This script is designed for CachyOS, it's not recommend use in other distros because is not completly tested. Conflicts with some critical system packages are likely."
    exit 1
  else
    echo "[+] Correct distro detected: CachyOS"
  fi

  echo "[+] The necessary packages will be installed from both the official repository and AUR. If the AUR is not installed, it will be installed..."

  if ! which "yay" >/dev/null; then
    sudo pacman -S yay
  fi

  install_pkgs &
  INSTALL_PID=$!
  spiner "$INSTALL_PID"
  dotfiles_install
}

# EXECUTION
trap clean_cursor SIGINT EXIT
main
