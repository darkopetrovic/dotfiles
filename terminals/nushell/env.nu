# env.nu
#
# Installed by:
# version = "0.112.2"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.

# Don't use stale COLUMNS/LINES inherited from bash; nushell queries terminal size via ioctl
if "COLUMNS" in $env { hide-env COLUMNS }
if "LINES" in $env { hide-env LINES }

# Editor
$env.EDITOR = "nano"
$env.VISUAL = "nano"

# Starship prompt — icons work in WezTerm (Nerd Font), fall back to minimal elsewhere
# TMUX check: tmux strips TERM_PROGRAM, but tmux runs inside WezTerm so Nerd Fonts are available
$env.STARSHIP_CONFIG = if ($env.TERM_PROGRAM? | default "") == "WezTerm" or ("TMUX" in $env) {
    $"($env.HOME)/.config/starship-nushell.toml"
} else {
    $"($env.HOME)/.config/starship-minimal.toml"
}
$env.STARSHIP_SHELL = "nu"
$env.STARSHIP_SESSION_KEY = (random chars -l 16)
$env.PROMPT_INDICATOR = {|| ""}
$env.PROMPT_MULTILINE_INDICATOR = {||
    ^starship prompt --continuation
}
$env.PROMPT_COMMAND = {||
    let duration = if $env.CMD_DURATION_MS == "0823" { 0 } else { $env.CMD_DURATION_MS }
    ^starship prompt --cmd-duration $duration $"--status=($env.LAST_EXIT_CODE)" --terminal-width (term size).columns
}
$env.PROMPT_COMMAND_RIGHT = {||
    let duration = if $env.CMD_DURATION_MS == "0823" { 0 } else { $env.CMD_DURATION_MS }
    ^starship prompt --right --cmd-duration $duration $"--status=($env.LAST_EXIT_CODE)" --terminal-width (term size).columns
}