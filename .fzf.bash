# =============================================================================
# ~/.fzf.bash
# fzf key bindings, fuzzy completion, and custom options
# Source this from ~/.bashrc:  [ -f ~/.fzf.bash ] && source ~/.fzf.bash
# =============================================================================

# Load fzf key bindings and completions (installed by fzf installer or apt)
if [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.bash       # apt install
elif [[ -f ~/.fzf/shell/key-bindings.bash ]]; then
  source ~/.fzf/shell/key-bindings.bash                       # git clone install
fi

if [[ -f /usr/share/doc/fzf/examples/completion.bash ]]; then
  source /usr/share/doc/fzf/examples/completion.bash
elif [[ -f ~/.fzf/shell/completion.bash ]]; then
  source ~/.fzf/shell/completion.bash
fi

# ---------------------------------------------------------------------------
# Default options
# ---------------------------------------------------------------------------
export FZF_DEFAULT_OPTS="
  --height=40%
  --layout=reverse
  --border=rounded
  --info=inline
  --prompt='> '
  --pointer='▶'
  --marker='✓'
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
"

# Use fd (fast find) as the default source if available, else fall back to find
if command -v fd &>/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
else
  export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/.git/*"'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Preview file content with bat (if available) or cat
if command -v bat &>/dev/null; then
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :100 {}'"
else
  export FZF_CTRL_T_OPTS="--preview 'cat {}'"
fi

# Alt-C: preview directory tree with tree (if available)
if command -v tree &>/dev/null; then
  export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -50'"
fi

# ---------------------------------------------------------------------------
# Useful shell functions powered by fzf
# ---------------------------------------------------------------------------

# fh — fuzzy search shell history and execute selected command
fh() {
  local cmd
  cmd=$(history | sort -rn | sed 's/^ *[0-9]* *//' | fzf --no-sort --query="$*" --prompt="history> ")
  [[ -n "$cmd" ]] && eval "$cmd"
}

# fkill — fuzzy-find and kill a process
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf --multi --prompt="kill> " | awk '{print $2}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill -"${1:-9}"
}

# fcd — fuzzy cd into any subdirectory
fcd() {
  local dir
  dir=$(find "${1:-.}" -type d 2>/dev/null | fzf --prompt="cd> " --preview 'ls {}') && cd "$dir"
}
