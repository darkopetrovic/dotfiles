# LXD

```bash
#!/usr/bin/env bash
# lxcproxy.sh - Add a proxy device to an LXD container
# Usage: lxcproxy.sh <container> <proxy-name> <port>
# The same port is used for both host and container

set -euo pipefail

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <container> <proxy-name> <port>"
    exit 1
fi

CONTAINER="$1"
NAME="$2"
PORT="$3"

lxc config device add "$CONTAINER" "$NAME" proxy \
    "listen=tcp:0.0.0.0:$PORT" \
    "connect=tcp:127.0.0.1:$PORT"

echo "Proxy added: $CONTAINER -> $NAME ($PORT -> $PORT)"
```

    sudo nano .bashrc

```bash
alias lxcproxy="$HOME/.local/bin/lxcproxy.sh"
lxcsh() { lxc exec "$1" -- sudo --login --user ubuntu; }
```