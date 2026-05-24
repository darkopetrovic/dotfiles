# AGENT.md

Personal dotfiles for bootstrapping LXD instances and Ubuntu/Debian machines. Two independent setup scripts handle different layers of configuration.

## Setup Scripts

**Main bootstrap** (`setup.sh`):
```bash
bash setup.sh        # interactive checkbox menu (all items pre-checked)
bash setup.sh -y     # non-interactive, installs everything
```

**Terminal configs** (`terminals/setup.sh`):
```bash
bash terminals/setup.sh   # symlinks Starship/Nushell configs, patches ~/.bashrc
```

After either script: `source ~/.bashrc`

## Architecture

### Config deployment strategy

`setup.sh` uses a `deploy_config` function that prefers symlinks from the local repo over downloading from Gist URLs. If a file exists locally it is symlinked; if not and the Gist URL is configured, it is downloaded via `curl`. Local edits are live immediately without re-running setup.

### Gist sync (post-commit hook)

`scripts/post-commit` is a git hook that automatically pushes `.fzf.bash` and `.tmux.conf` to their respective GitHub Gists after every commit that touches those files. The Gist URLs in `setup.sh` (for the one-liner install) must match the Gist IDs in `scripts/post-commit`. When adding a new config file to this sync workflow, update both files.

Install the hook: `cp scripts/post-commit .git/hooks/post-commit && chmod +x .git/hooks/post-commit`

### Starship per-terminal config switching

`terminals/setup.sh` adds a `STARSHIP_CONFIG` block to `~/.bashrc` that selects one of three Starship profiles at prompt-draw time based on `$TERM_PROGRAM`:
- `vscode` → `starship-vscode.toml` (compact, no icons)
- `WezTerm` → default (uses Nerd Font icons)
- Everything else → `starship-minimal.toml`

The three `.toml` files live in `terminals/starship/` and are symlinked into `~/.config/`.

### Nushell configs

`terminals/nushell/env.nu` and `config.nu` are symlinked into `~/.config/nushell/`. If `atuin` is installed, the setup script also generates `~/.config/nushell/atuin.nu` via `atuin init nu`.
