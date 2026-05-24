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

## Generate local certificate


```bash
WSL_IP=$(hostname -I | awk '{print $1}')

cat > /tmp/lxd-cert.cnf <<EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
x509_extensions = v3_req
distinguished_name = dn

[dn]
O = LXD
CN = root@CELESTITE

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = CELESTITE
IP.1 = 127.0.0.1
IP.2 = ::1
IP.3 = $WSL_IP
EOF
```

Generate the cert:

```bash
openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
  -keyout /tmp/lxd-server.key \
  -out /tmp/lxd-server.crt \
  -config /tmp/lxd-cert.cnf
```

Install it:

```bash
sudo cp /var/snap/lxd/common/lxd/server.crt /var/snap/lxd/common/lxd/server.crt.bak
sudo cp /var/snap/lxd/common/lxd/server.key /var/snap/lxd/common/lxd/server.key.bak

sudo cp /tmp/lxd-server.crt /var/snap/lxd/common/lxd/server.crt
sudo cp /tmp/lxd-server.key /var/snap/lxd/common/lxd/server.key
sudo chmod 600 /var/snap/lxd/common/lxd/server.key

sudo snap restart lxd
```

Copy the new cert to Windows and import it:

```bash
cp /tmp/lxd-server.crt /mnt/c/Users/Darko/Desktop/lxd-server.crt
```

Import it into: `Trusted Root Certification Authorities`