#!/usr/bin/env bash
# Sets up terminal configs (Starship, Nushell):
#   - symlinks starship/*.toml into ~/.config/
#   - symlinks nushell/*.nu into ~/.config/nushell/
#   - adds STARSHIP_CONFIG detection to ~/.bashrc (idempotent)
set -euo pipefail

TERMINALS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHRC="$HOME/.bashrc"
CONFIG_DIR="$HOME/.config"

info()    { echo "[INFO]  $*"; }
success() { echo "[OK]    $*"; }

# ── Symlink configs ────────────────────────────────────────────────────────────
mkdir -p "$CONFIG_DIR"

link_config() {
  local src="$1" dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    success "$(basename "$dst") already linked"
  else
    ln -sf "$src" "$dst"
    success "Linked $(basename "$dst") -> $dst"
  fi
}

link_config "$TERMINALS_DIR/starship/default.toml"   "$CONFIG_DIR/starship.toml"
link_config "$TERMINALS_DIR/starship/minimal.toml"   "$CONFIG_DIR/starship-minimal.toml"
link_config "$TERMINALS_DIR/starship/vscode.toml"    "$CONFIG_DIR/starship-vscode.toml"
link_config "$TERMINALS_DIR/starship/nushell.toml"   "$CONFIG_DIR/starship-nushell.toml"

# ── Nushell configs ────────────────────────────────────────────────────────────
NUSHELL_DIR="$HOME/.config/nushell"
if command -v nu &>/dev/null || [[ -d "$NUSHELL_DIR" ]]; then
  mkdir -p "$NUSHELL_DIR"
  link_config "$TERMINALS_DIR/nushell/env.nu"    "$NUSHELL_DIR/env.nu"
  link_config "$TERMINALS_DIR/nushell/config.nu" "$NUSHELL_DIR/config.nu"
  if command -v atuin &>/dev/null; then
    atuin init nu > "$NUSHELL_DIR/atuin.nu"
    success "Generated atuin.nu"
  else
    info "Atuin not found — skipping atuin.nu generation"
  fi
else
  info "Nushell not found — skipping nushell config symlinks"
fi

# ── Update ~/.bashrc ───────────────────────────────────────────────────────────
MARKER="STARSHIP_CONFIG"

if grep -qF "$MARKER" "$BASHRC" 2>/dev/null; then
  success "~/.bashrc already has STARSHIP_CONFIG detection — skipping"
elif grep -qF 'starship init bash' "$BASHRC" 2>/dev/null; then
  # starship init exists but no config switching — append detection only
  # STARSHIP_CONFIG is read at prompt-draw time so appending after init is fine
  info "Adding STARSHIP_CONFIG detection after existing starship init..."
  cat >> "$BASHRC" <<'EOF'

# Per-terminal Starship config (vscode -> compact, WezTerm -> full icons, everything else -> minimal)
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  export STARSHIP_CONFIG="$HOME/.config/starship-vscode.toml"
elif [[ "$TERM_PROGRAM" != "WezTerm" ]]; then
  export STARSHIP_CONFIG="$HOME/.config/starship-minimal.toml"
fi
EOF
  success "STARSHIP_CONFIG detection added to ~/.bashrc"
else
  # No starship init at all — add the full block
  info "Adding full starship block to ~/.bashrc..."
  cat >> "$BASHRC" <<'EOF'

# Starship prompt with per-terminal config
if command -v starship &>/dev/null; then
  # vscode -> compact, WezTerm -> full icons, everything else -> minimal
  if [[ "$TERM_PROGRAM" == "vscode" ]]; then
    export STARSHIP_CONFIG="$HOME/.config/starship-vscode.toml"
  elif [[ "$TERM_PROGRAM" != "WezTerm" ]]; then
    export STARSHIP_CONFIG="$HOME/.config/starship-minimal.toml"
  fi
  eval "$(starship init bash)"
  function __wezterm_osc7() {
    printf "\e]7;file://%s%s\e\\" "${HOSTNAME}" "${PWD// /%20}"
  }
  starship_precmd_user_func="__wezterm_osc7"
fi
EOF
  success "Starship block added to ~/.bashrc"
fi

# ── Windows WezTerm symlink (WSL only) ────────────────────────────────────────
if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
  WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
  if [[ -z "$WIN_USER" ]]; then
    info "Could not determine Windows username — skipping WezTerm Windows symlink"
  else
    WIN_CFG_DIR="/mnt/c/Users/${WIN_USER}/.config/wezterm"
    WIN_CFG_LUA="${WIN_CFG_DIR}/wezterm.lua"
    mkdir -p "$WIN_CFG_DIR"

    if [[ -L "$WIN_CFG_LUA" ]]; then
      success "Windows WezTerm symlink already exists → $WIN_CFG_LUA"
    elif [[ -f "$WIN_CFG_LUA" ]]; then
      info "Windows WezTerm config exists as a regular file — skipping (remove it and re-run to replace with symlink)"
    else
      info "Creating Windows symlink for WezTerm config..."
      WIN_DST="C:\\Users\\${WIN_USER}\\.config\\wezterm\\wezterm.lua"
      WIN_SRC="\\\\wsl.localhost\\${WSL_DISTRO_NAME}\\home\\${USER}\\dotfiles\\terminals\\wezterm\\wezterm.lua"
      if cmd.exe /c "mklink \"${WIN_DST}\" \"${WIN_SRC}\"" > /dev/null 2>&1; then
        success "Windows symlink: $WIN_DST → $WIN_SRC"
      else
        info "mklink failed (Windows Developer Mode may be required). Copying file instead..."
        cp "$TERMINALS_DIR/wezterm/wezterm.lua" "$WIN_CFG_LUA"
        success "Copied wezterm.lua → $WIN_CFG_LUA (re-run after enabling Developer Mode to get a live symlink)"
      fi
    fi
  fi
fi

echo ""
echo "Done. Reload with: source ~/.bashrc"
