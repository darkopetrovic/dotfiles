# LXC container management commands

export def lxc-ls [] {
  lxc list -f json
  | from json
  | each {|c|
      $c
      | insert ipv4 (
          $c.state.network.eth0.addresses
          | where family == inet
          | get address
          | first
          | default ""
        )
    }
  | select name status ipv4 type
  | table --expand
}

export def lxc-stats [] {
  lxc list -f json
  | from json
  | each {|c|
      {
        name: $c.name
        status: $c.status
        memory: ($c.state.memory.usage? | default 0 | into filesize)
        processes: ($c.state.processes? | default 0)
        cpu_time: (
          ($c.state.cpu.usage? | default 0) / 1_000_000_000
          | math round --precision 2
        )
      }
    }
  | table --expand
}

export def lxc-df [name: string] {
  lxc exec $name -- df -h /
}

export def lxc-ports [name?: string] {
  let containers = (
    lxc list -f json
    | from json
    | if $name == null { $in } else { where name == $name }
  )

  $containers
  | each {|c|
      $c.devices
      | transpose device config
      | where {|d| $d.config.type? == proxy }
      | each {|d|
          {
            container: $c.name
            device: $d.device
            listen: $d.config.listen
            connect: $d.config.connect
          }
        }
    }
  | flatten
  | table --expand
}

export def lxcproxy [...args] {
  ^($env.HOME + "/.local/bin/lxcproxy.sh") ...$args
}

export def lxcsh [name: string] {
  lxc exec $name -- sudo --login --user ubuntu
}

export def lxc-devices [name?: string] {
  let containers = (
    lxc list -f json
    | from json
    | if $name == null { $in } else { where name == $name }
  )

  $containers
  | each {|c|
      $c.devices
      | transpose device config
      | each {|d|
          {
            container: $c.name
            device: $d.device
            type: ($d.config.type? | default "")
            listen: ($d.config.listen? | default "")
            connect: ($d.config.connect? | default "")
            path: ($d.config.path? | default "")
            source: ($d.config.source? | default "")
            network: ($d.config.network? | default "")
          }
        }
    }
  | flatten
  | table --expand
}