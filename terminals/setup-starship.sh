#!/usr/bin/env bash
# Sets up per-terminal Starship configs:
#   - symlinks starship-*.toml into ~/.config/
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

link_config "$TERMINALS_DIR/starship-minimal.toml" "$CONFIG_DIR/starship-minimal.toml"
link_config "$TERMINALS_DIR/starship-vscode.toml"  "$CONFIG_DIR/starship-vscode.toml"

# ── Update ~/.bashrc ───────────────────────────────────────────────────────────
MARKER="STARSHIP_CONFIG"

if grep -qF "$MARKER" "$BASHRC" 2>/dev/null; then
  success "~/.bashrc already has STARSHIP_CONFIG detection — skipping"
elif grep -qF 'starship init bash' "$BASHRC" 2>/dev/null; then
  # starship init exists but no config switching — append detection only
  # STARSHIP_CONFIG is read at prompt-draw time so appending after init is fine
  info "Adding STARSHIP_CONFIG detection after existing starship init..."
  cat >> "$BASHRC" <<'EOF'

# Per-terminal Starship config (vscode -> compact, Windows Terminal -> no icons, WezTerm -> full)
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  export STARSHIP_CONFIG="$HOME/.config/starship-vscode.toml"
elif [[ -n "$WT_SESSION" ]]; then
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
  # vscode -> compact, Windows Terminal -> no icons, WezTerm -> full (default)
  if [[ "$TERM_PROGRAM" == "vscode" ]]; then
    export STARSHIP_CONFIG="$HOME/.config/starship-vscode.toml"
  elif [[ -n "$WT_SESSION" ]]; then
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

echo ""
echo "Done. Reload with: source ~/.bashrc"
