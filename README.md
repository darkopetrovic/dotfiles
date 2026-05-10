# dotfiles

Personal dotfiles for bootstrapping LXD instances (and any Ubuntu/Debian machine) with fzf and tmux.

## What's included

| File | Purpose |
|---|---|
| `setup.sh` | Bootstrap script — installs packages and deploys configs |
| `.tmux.conf` | tmux config (Catppuccin-inspired theme, vim-style bindings) |
| `.fzf.bash` | fzf options, key bindings, completions, and helper functions |

## Usage on a new LXD instance

### Option A — clone the repo (recommended)

```bash
git clone https://github.com/darkopetrovic/dotfiles.git ~/dotfiles
bash ~/dotfiles/setup.sh
source ~/.bashrc
```

### Option B — one-liner without cloning (uses Gist URLs in setup.sh)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/darkopetrovic/dotfiles/main/setup.sh)
```

### LXD cloud-init integration

Add this to your LXD profile to run the script automatically on every new instance:

```yaml
config:
  user.user-data: |
    #cloud-config
    runcmd:
      - su - ubuntu -c "git clone https://github.com/darkopetrovic/dotfiles.git ~/dotfiles && bash ~/dotfiles/setup.sh"
```

Apply the profile:

```bash
lxc profile edit default
# or create a dedicated profile:
lxc profile create dotfiles
lxc profile edit dotfiles   # paste the yaml above
lxc launch ubuntu:24.04 myinstance --profile default --profile dotfiles
```

## Pushing configs to GitHub Gist

After customising `.tmux.conf` and `.fzf.bash`, upload them to Gists:

```bash
# Install GitHub CLI if needed
sudo apt install gh
gh auth login

# Create gists
gh gist create --public ~/dotfiles/.tmux.conf --desc "tmux config"
gh gist create --public ~/dotfiles/.fzf.bash  --desc "fzf config"
```

Then paste the raw URLs into the `TMUX_CONF_URL` and `FZF_CONF_URL` variables at the top of `setup.sh`.

## Key bindings

### tmux (prefix: `C-a`)

| Keys | Action |
|---|---|
| `C-a \|` | Split horizontally |
| `C-a -` | Split vertically |
| `C-a h/j/k/l` | Navigate panes |
| `C-a H/J/K/L` | Resize panes |
| `C-a r` | Reload config |

### fzf

| Keys | Action |
|---|---|
| `C-r` | Fuzzy search shell history |
| `C-t` | Fuzzy insert file path |
| `Alt-c` | Fuzzy cd into directory |
| `fh` | Execute command from history |
| `fkill` | Fuzzy kill a process |
| `fcd` | Fuzzy cd |
