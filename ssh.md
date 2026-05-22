# SSH into WSL over a Remote Windows Host

Goal:

Client machine → Windows host IP:2223/2224 → Windows portproxy → WSL sshd

Because WSL is not in mirrored mode, WSL distros share the same WSL VM/NAT IP. Use different SSH ports per distro.

## Example port layout

- Ubuntu: SSH port 2223
- Ubuntu-26.04: SSH port 2224

## 1. Configure SSH inside each WSL distro

### Ubuntu

Run inside the `Ubuntu` WSL distro:

    sudo systemctl disable --now ssh.socket 2>/dev/null || true
    sudo systemctl enable --now ssh.service

    sudo mkdir -p /etc/ssh/sshd_config.d

    cat <<'EOF' | sudo tee /etc/ssh/sshd_config.d/99-port.conf
    Port 2223
    ListenAddress 0.0.0.0
    EOF

    sudo sshd -t
    sudo systemctl restart ssh

    sudo ss -tlnp | grep ssh

Expected result:

    LISTEN ... 0.0.0.0:2223 ...

### Ubuntu-26.04

Run inside the `Ubuntu-26.04` WSL distro:

    sudo systemctl disable --now ssh.socket 2>/dev/null || true
    sudo systemctl enable --now ssh.service

    sudo mkdir -p /etc/ssh/sshd_config.d

    cat <<'EOF' | sudo tee /etc/ssh/sshd_config.d/99-port.conf
    Port 2224
    ListenAddress 0.0.0.0
    EOF

    sudo sshd -t
    sudo systemctl restart ssh

    sudo ss -tlnp | grep ssh

Expected result:

    LISTEN ... 0.0.0.0:2224 ...

## 2. Get the WSL IP from Windows

Run PowerShell as Administrator:

    wsl -l -v
    wsl -d Ubuntu hostname -I

Use the first `172.x.x.x` address, for example:

    172.25.214.200

## 3. Create Windows portproxy rules

Run in Administrator PowerShell:

    $wslIp = (wsl -d Ubuntu hostname -I).Trim().Split(" ")[0]

    netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=2223 2>$null
    netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=2224 2>$null

    netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=2223 connectaddress=$wslIp connectport=2223
    netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=2224 connectaddress=$wslIp connectport=2224

    netsh interface portproxy show all

## 4. Open Windows Firewall

Run in Administrator PowerShell:

    New-NetFirewallRule -DisplayName "WSL SSH 2223" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 2223
    New-NetFirewallRule -DisplayName "WSL SSH 2224" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 2224

## 5. Ensure IP Helper service is enabled

`netsh interface portproxy` depends on the IP Helper service.

Run in Administrator PowerShell:

    Start-Service iphlpsvc
    Set-Service iphlpsvc -StartupType Automatic
    Get-Service iphlpsvc

## 6. Connect from the client machine

    ssh -p 2223 your_user@WINDOWS_HOST_IP
    ssh -p 2224 your_user@WINDOWS_HOST_IP

Example:

    ssh -p 2223 darko@192.168.1.50
    ssh -p 2224 darko@192.168.1.50

## 7. Recreate portproxy after WSL IP changes

WSL NAT IP can change after reboot or `wsl --shutdown`.

Save this as `Reset-WslSshPortProxy.ps1` and run it as Administrator:

    $distro = "Ubuntu"
    $wslIp = (wsl -d $distro hostname -I).Trim().Split(" ")[0]

    $ports = @(2223, 2224)

    foreach ($port in $ports) {
      netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=$port 2>$null
      netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=$port connectaddress=$wslIp connectport=$port
    }

    netsh interface portproxy show all

## Troubleshooting

Check SSH listener inside WSL:

    sudo ss -tlnp | grep ssh

Check if `ssh.socket` is still active:

    systemctl status ssh.socket
    systemctl status ssh.service

If port `22` is still shown, disable socket activation:

    sudo systemctl disable --now ssh.socket
    sudo systemctl mask ssh.socket
    sudo systemctl restart ssh

Check Windows portproxy:

    netsh interface portproxy show all

Test Windows local connectivity:

    Test-NetConnection 127.0.0.1 -Port 2223
    Test-NetConnection 127.0.0.1 -Port 2224

Test from client:

    ssh -vvv -p 2223 your_user@WINDOWS_HOST_IP
    ssh -vvv -p 2224 your_user@WINDOWS_HOST_IP
