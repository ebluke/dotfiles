#!/usr/bin/env bash
set -e

DOTFILES="$HOME/dotfiles"
PACLIST="$DOTFILES/applist.txt"

echo "==> Linking home dotfiles..."
# Symlink everything from dotfiles/home/.* to ~/
shopt -s dotglob
for file in "$DOTFILES/home"/.*; do
    base="$(basename "$file")"
    [[ "$base" == "." || "$base" == ".." ]] && continue
    target="$HOME/$base"

    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "Removing existing $target"
        rm -rf "$target"
    fi

    echo "Linking $file -> $target"
    ln -s "$file" "$target"
done
shopt -u dotglob

echo "==> Linking config files..."
mkdir -p "$HOME/.config"

shopt -s nullglob
for file in "$DOTFILES/config"/*; do
    base="$(basename "$file")"
    target="$HOME/.config/$base"

    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "Removing existing $target"
        rm -rf "$target"
    fi

    echo "Linking $file -> $target"
    ln -s "$file" "$target"
done
shopt -u nullglob

echo "==> Installing packages..."

# Split applist into repo packages and AUR packages
REPO_PKGS=()
AUR_PKGS=()

while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    if pacman -Si "$pkg" &>/dev/null; then
        REPO_PKGS+=("$pkg")
    else
        AUR_PKGS+=("$pkg")
    fi
done < "$PACLIST"

# Install repo packages
if [ ${#REPO_PKGS[@]} -gt 0 ]; then
    echo "Installing repo packages: ${REPO_PKGS[*]}"
    sudo pacman -S --needed "${REPO_PKGS[@]}"
fi

# Ensure yay exists before AUR installation
if [ ${#AUR_PKGS[@]} -gt 0 ]; then
    if ! command -v yay &>/dev/null; then
        echo "yay not found, installing yay..."
        sudo pacman -S --needed git base-devel
        tmpdir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
        (cd "$tmpdir/yay" && makepkg -si --noconfirm)
        rm -rf "$tmpdir"
    fi

    echo "Installing AUR packages: ${AUR_PKGS[*]}"
    yay -S --needed "${AUR_PKGS[@]}"
fi

echo "==> Setting up pacman hook symlink for applist.txt"
sudo ln -sf "$DOTFILES/update-applist.hook" /etc/pacman.d/hooks/update-applist.hook

echo "==> Done!"

