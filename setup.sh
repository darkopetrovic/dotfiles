#!/usr/bin/env bash
# =============================================================================
# dotfiles/setup.sh
# Bootstrap script for new LXD instances.
# Usage: bash setup.sh
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# CONFIG — replace these with your actual Gist raw URLs after uploading
# ---------------------------------------------------------------------------
TMUX_CONF_URL="https://gist.githubusercontent.com/darkopetrovic/86275057e4794b9b353b93b2bdc5fd99/raw/.tmux.conf"
FZF_CONF_URL="https://gist.githubusercontent.com/darkopetrovic/77fcb58be54fdffa1c41d0fc1991359c/raw/.fzf.bash"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHRC="$HOME/.bashrc"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()    { echo "[INFO]  $*"; }
success() { echo "[OK]    $*"; }
error()   { echo "[ERROR] $*" >&2; exit 1; }

require_cmd() {
  command -v "$1" &>/dev/null || error "Required command not found: $1"
}

# ---------------------------------------------------------------------------
# 1. Update package index
# ---------------------------------------------------------------------------
info "Updating package index..."
sudo apt-get update -qq

# ---------------------------------------------------------------------------
# 2. Install tmux
# ---------------------------------------------------------------------------
if command -v tmux &>/dev/null; then
  success "tmux already installed ($(tmux -V))"
else
  info "Installing tmux..."
  sudo apt-get install -y tmux
  success "tmux installed ($(tmux -V))"
fi

# ---------------------------------------------------------------------------
# 3. Install fzf
# ---------------------------------------------------------------------------
if command -v fzf &>/dev/null; then
  success "fzf already installed ($(fzf --version))"
else
  info "Installing fzf..."
  # Install from apt (Ubuntu 20.04+) — falls back to git clone for older releases
  if apt-cache show fzf &>/dev/null; then
    sudo apt-get install -y fzf
  else
    info "fzf not in apt, installing from GitHub..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all --no-update-rc
  fi
  success "fzf installed"
fi

# ---------------------------------------------------------------------------
# 4. Install bat
# ---------------------------------------------------------------------------
if command -v bat &>/dev/null; then
  success "bat already installed ($(bat --version))"
else
  info "Installing bat..."
  if apt-cache show bat &>/dev/null 2>&1; then
    sudo apt-get install -y bat
  else
    info "bat not in apt, installing from GitHub releases..."
    BAT_VERSION=$(curl -fsSL https://api.github.com/repos/sharkdp/bat/releases/latest \
      | grep '"tag_name"' | cut -d'"' -f4)
    BAT_DEB="bat_${BAT_VERSION#v}_$(dpkg --print-architecture).deb"
    curl -fsSL "https://github.com/sharkdp/bat/releases/download/${BAT_VERSION}/${BAT_DEB}" \
      -o "/tmp/${BAT_DEB}"
    sudo dpkg -i "/tmp/${BAT_DEB}"
    rm -f "/tmp/${BAT_DEB}"
  fi
  # Ubuntu installs bat as 'batcat' due to a naming conflict; create a symlink
  if ! command -v bat &>/dev/null && command -v batcat &>/dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    info "Created symlink: ~/.local/bin/bat → $(command -v batcat)"
  fi
  success "bat installed ($(bat --version 2>/dev/null || batcat --version))"
fi

# Ensure ~/.local/bin is in PATH (needed for the bat symlink above)
LOCAL_BIN_LINE='export PATH="$HOME/.local/bin:$PATH"'
if ! grep -qF "$LOCAL_BIN_LINE" "$BASHRC" 2>/dev/null; then
  echo "" >> "$BASHRC"
  echo "# local user binaries (e.g. bat symlink)" >> "$BASHRC"
  echo "$LOCAL_BIN_LINE" >> "$BASHRC"
  success "~/.local/bin added to PATH in $BASHRC"
fi

# ---------------------------------------------------------------------------
# 5. Deploy configs — prefer local files, fall back to Gist download
# ---------------------------------------------------------------------------
deploy_config() {
  local src_local="$1"   # path inside this repo
  local dest="$2"         # destination in $HOME
  local gist_url="$3"     # fallback Gist raw URL

  if [[ -f "$src_local" ]]; then
    info "Linking $(basename "$dest") from local repo..."
    ln -sf "$src_local" "$dest"
  elif [[ "$gist_url" != *"YOUR_USERNAME"* ]]; then
    info "Downloading $(basename "$dest") from Gist..."
    require_cmd curl
    curl -fsSL "$gist_url" -o "$dest"
  else
    info "Skipping $(basename "$dest") — no local file and Gist URL not configured yet."
    return
  fi
  success "$(basename "$dest") deployed → $dest"
}

deploy_config "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"  "$TMUX_CONF_URL"
deploy_config "$DOTFILES_DIR/.fzf.bash"  "$HOME/.fzf.bash"   "$FZF_CONF_URL"

# ---------------------------------------------------------------------------
# 6. Source fzf config in .bashrc (idempotent)
# ---------------------------------------------------------------------------
FZF_SOURCE_LINE='[ -f ~/.fzf.bash ] && source ~/.fzf.bash'

if ! grep -qF "$FZF_SOURCE_LINE" "$BASHRC" 2>/dev/null; then
  echo "" >> "$BASHRC"
  echo "# fzf key bindings and fuzzy completion" >> "$BASHRC"
  echo "$FZF_SOURCE_LINE" >> "$BASHRC"
  success "fzf source line added to $BASHRC"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo " Setup complete! Start a new shell or run:"
echo "   source ~/.bashrc"
echo "============================================"
