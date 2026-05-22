#!/usr/bin/env bash
# =============================================================================
# dotfiles/setup.sh
# Bootstrap script for new LXD instances.
# Usage: bash setup.sh        — interactive checkbox menu
#        bash setup.sh -y     — non-interactive (install everything)
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# CONFIG
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
# Checkbox menu
# Usage: checkbox_menu <result_nameref> "Label 1" "Label 2" ...
# Populates result array with 1 (selected) or 0 (deselected) per item.
# All items start checked. Requires bash 4.3+ (nameref).
# ---------------------------------------------------------------------------
checkbox_menu() {
  local -n _out="$1"; shift
  local items=("$@")
  local n=${#items[@]}
  local sel=() cur=0 i

  for ((i = 0; i < n; i++)); do sel[i]=1; done

  _cm_draw() {
    for ((i = 0; i < n; i++)); do
      local box="[ ]"; [[ "${sel[$i]}" == 1 ]] && box="[x]"
      if [[ "$i" == "$cur" ]]; then
        printf "\r\033[1;36m › %s  %s\033[0m\033[K\n" "$box" "${items[$i]}"
      else
        printf "\r   %s  %s\033[K\n" "$box" "${items[$i]}"
      fi
    done
    printf "\r\033[2m   ↑/↓ navigate · Space toggle · a all · n none · Enter confirm\033[0m\033[K"
  }

  local saved_tty
  saved_tty=$(stty -g)
  stty -echo -icanon min 1 time 0
  tput civis 2>/dev/null || true

  printf "\n"
  _cm_draw

  while true; do
    local key seq
    IFS= read -r -s -n1 key
    if [[ "$key" == $'\x1b' ]]; then
      IFS= read -r -s -n2 -t 0.1 seq 2>/dev/null || seq=""
      key="$key$seq"
    fi

    printf "\033[%dA" $n  # move cursor back to top of menu

    case "$key" in
      $'\x1b[A' | k) (( cur > 0   )) && (( cur-- )) || true ;;
      $'\x1b[B' | j) (( cur < n-1 )) && (( cur++ )) || true ;;
      ' ')
        [[ "${sel[$cur]}" == 1 ]] && sel[$cur]=0 || sel[$cur]=1 ;;
      a | A) for ((i = 0; i < n; i++)); do sel[i]=1; done ;;
      n | N) for ((i = 0; i < n; i++)); do sel[i]=0; done ;;
      $'\n' | $'\r') break ;;
    esac

    _cm_draw
  done

  stty "$saved_tty"
  tput cnorm 2>/dev/null || true
  printf "\n\n"

  _out=()
  for ((i = 0; i < n; i++)); do _out+=("${sel[$i]}"); done
}

# ---------------------------------------------------------------------------
# Select components
# ---------------------------------------------------------------------------
LABELS=(
  "tmux — terminal multiplexer"
  "fzf — fuzzy finder"
  "bat — syntax-highlighting cat"
  "ripgrep — fast grep (rg)"
  "nodejs + npm"
  "pnpm — Node.js package manager"
  "just — command runner"
  "uv — Python package manager"
  "atuin — shell history sync"
  "dotfile configs (.tmux.conf, .fzf.bash)"
)
KEYS=(tmux fzf bat ripgrep nodejs pnpm just uv atuin configs)

echo "============================================"
echo " dotfiles setup — select components to install"
echo "============================================"

declare -a SELECTED
if [[ "${1:-}" =~ ^(-y|--yes|--all)$ ]]; then
  # Non-interactive: select everything
  SELECTED=(1 1 1 1 1 1 1 1 1 1)
  info "Non-interactive mode — installing all components."
else
  checkbox_menu SELECTED "${LABELS[@]}"
fi

# Map selections to named variables
declare -A INSTALL
for ((i = 0; i < ${#KEYS[@]}; i++)); do
  INSTALL[${KEYS[$i]}]=${SELECTED[$i]}
done

# ---------------------------------------------------------------------------
# apt update — only if at least one apt-sourced package is selected
# ---------------------------------------------------------------------------
APT_NEEDED=$(( INSTALL[tmux] + INSTALL[fzf] + INSTALL[bat] + INSTALL[ripgrep] + INSTALL[nodejs] ))
if (( APT_NEEDED > 0 )); then
  info "Updating package index..."
  sudo apt-get update -qq
fi

# ---------------------------------------------------------------------------
# 1. tmux
# ---------------------------------------------------------------------------
if [[ "${INSTALL[tmux]}" == "1" ]]; then
  if command -v tmux &>/dev/null; then
    success "tmux already installed ($(tmux -V))"
  else
    info "Installing tmux..."
    sudo apt-get install -y tmux
    success "tmux installed ($(tmux -V))"
  fi
fi

# ---------------------------------------------------------------------------
# 2. fzf
# ---------------------------------------------------------------------------
if [[ "${INSTALL[fzf]}" == "1" ]]; then
  if command -v fzf &>/dev/null; then
    success "fzf already installed ($(fzf --version))"
  else
    info "Installing fzf..."
    if apt-cache show fzf &>/dev/null; then
      sudo apt-get install -y fzf
    else
      info "fzf not in apt, installing from GitHub..."
      git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
      ~/.fzf/install --all --no-update-rc
    fi
    success "fzf installed"
  fi
fi

# ---------------------------------------------------------------------------
# 3. bat
# ---------------------------------------------------------------------------
if [[ "${INSTALL[bat]}" == "1" ]]; then
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
    if ! command -v bat &>/dev/null && command -v batcat &>/dev/null; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
      info "Created symlink: ~/.local/bin/bat → $(command -v batcat)"
    fi
    success "bat installed ($(bat --version 2>/dev/null || batcat --version))"
  fi

  LOCAL_BIN_LINE='export PATH="$HOME/.local/bin:$PATH"'
  if ! grep -qF "$LOCAL_BIN_LINE" "$BASHRC" 2>/dev/null; then
    { echo ""; echo "# local user binaries (e.g. bat symlink)"; echo "$LOCAL_BIN_LINE"; } >> "$BASHRC"
    success "~/.local/bin added to PATH in $BASHRC"
  fi
fi

# ---------------------------------------------------------------------------
# 4. ripgrep
# ---------------------------------------------------------------------------
if [[ "${INSTALL[ripgrep]}" == "1" ]]; then
  if command -v rg &>/dev/null; then
    success "ripgrep already installed ($(rg --version | head -1))"
  else
    info "Installing ripgrep..."
    if apt-cache show ripgrep &>/dev/null 2>&1; then
      sudo apt-get install -y ripgrep
    else
      info "ripgrep not in apt, installing from GitHub releases..."
      RG_VERSION=$(curl -fsSL https://api.github.com/repos/BurntSushi/ripgrep/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4)
      RG_DEB="ripgrep_${RG_VERSION}_$(dpkg --print-architecture).deb"
      curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/${RG_DEB}" \
        -o "/tmp/${RG_DEB}"
      sudo dpkg -i "/tmp/${RG_DEB}"
      rm -f "/tmp/${RG_DEB}"
    fi
    success "ripgrep installed ($(rg --version | head -1))"
  fi
fi

# ---------------------------------------------------------------------------
# 5. Node.js + npm
# ---------------------------------------------------------------------------
if [[ "${INSTALL[nodejs]}" == "1" ]]; then
  if command -v node &>/dev/null; then
    success "Node.js already installed ($(node --version))"
  else
    info "Installing Node.js..."
    sudo apt install nodejs npm -y
    success "Node.js installed ($(node --version))"
  fi
fi

# ---------------------------------------------------------------------------
# 6. pnpm
# ---------------------------------------------------------------------------
if [[ "${INSTALL[pnpm]}" == "1" ]]; then
  if command -v pnpm &>/dev/null; then
    success "pnpm already installed ($(pnpm --version))"
  else
    info "Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | sh -
  fi
fi

# ---------------------------------------------------------------------------
# 7. just
# ---------------------------------------------------------------------------
if [[ "${INSTALL[just]}" == "1" ]]; then
  if command -v just &>/dev/null; then
    success "just already installed ($(just --version))"
  else
    info "Installing just..."
    sudo snap install just --classic
    success "just installed ($(just --version))"
  fi
fi

# ---------------------------------------------------------------------------
# 8. uv
# ---------------------------------------------------------------------------
if [[ "${INSTALL[uv]}" == "1" ]]; then
  if command -v uv &>/dev/null; then
    success "uv already installed ($(uv --version))"
  else
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    success "uv installed"
  fi
fi

# ---------------------------------------------------------------------------
# 9. atuin
# ---------------------------------------------------------------------------
if [[ "${INSTALL[atuin]}" == "1" ]]; then
  if command -v atuin &>/dev/null; then
    success "atuin already installed ($(atuin --version))"
  else
    info "Installing atuin..."
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
  fi
fi

# ---------------------------------------------------------------------------
# 10. Deploy configs — prefer local files, fall back to Gist download
# ---------------------------------------------------------------------------
if [[ "${INSTALL[configs]}" == "1" ]]; then
  deploy_config() {
    local src_local="$1" dest="$2" gist_url="$3"
    if [[ -f "$src_local" ]]; then
      info "Linking $(basename "$dest") from local repo..."
      ln -sf "$src_local" "$dest"
    elif [[ "$gist_url" != *"YOUR_USERNAME"* ]]; then
      info "Downloading $(basename "$dest") from Gist..."
      require_cmd curl
      curl -fsSL "$gist_url" -o "$dest"
    else
      info "Skipping $(basename "$dest") — no local file and Gist URL not configured."
      return
    fi
    success "$(basename "$dest") deployed → $dest"
  }

  deploy_config "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf" "$TMUX_CONF_URL"
  deploy_config "$DOTFILES_DIR/.fzf.bash"  "$HOME/.fzf.bash"  "$FZF_CONF_URL"

  FZF_SOURCE_LINE='[ -f ~/.fzf.bash ] && source ~/.fzf.bash'
  if ! grep -qF "$FZF_SOURCE_LINE" "$BASHRC" 2>/dev/null; then
    { echo ""; echo "# fzf key bindings and fuzzy completion"; echo "$FZF_SOURCE_LINE"; } >> "$BASHRC"
    success "fzf source line added to $BASHRC"
  fi
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo " Setup complete! Start a new shell or run:"
echo "   source ~/.bashrc"
echo "============================================"
