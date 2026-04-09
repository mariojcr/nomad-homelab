job "node-exporter" {
  datacenters = __DATACENTER__
  type        = "system"
  priority    = 100

  group "node-exporter" {
    volume "host-root" {
      source    = "host-root"
      type      = "host"
      read_only = true
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "vm-agent-monitoring"
        }
      }
    }

    update {
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    service {
      name         = "node-exporter"
      port         = 9100
      provider     = "nomad"
      address_mode = "alloc"
      tags = [
        "metrics=true"
      ]
      check {
        address_mode = "alloc"
        type         = "http"
        path         = "/metrics"
        interval     = "10s"
        timeout      = "2s"
      }
    }

    task "network-rules" {
      driver = "podman"
      lifecycle {
        hook    = "prestart"
        sidecar = true
      }
      config {
        image      = "ghcr.io/mariojcr/net-nomad:1.0.0"
        cap_add    = ["NET_ADMIN"]
      }
      template {
        data        = var.firewall_config
        destination = "local/firewall.env"
        env         = true
      }
      resources {
        cpu        = 10
        memory     = 10
        memory_max = 16
      }
    }

    task "node-exporter" {
      driver = "podman"

      config {
        image        = "docker.io/prom/node-exporter:v1.11.1"
        args = [
          "--path.rootfs=/host",
          "--path.procfs=/host/proc/",
          "--path.sysfs=/host/sys",
          "--web.listen-address=0.0.0.0:9100",
          "--collector.cpu",
          "--collector.cpufreq",
          "--collector.loadavg",
          "--collector.meminfo",
          "--collector.diskstats",
          "--collector.filesystem",
          "--collector.netdev",
          "--collector.netstat",
          "--collector.tcpstat",
          "--collector.uname",
          "--collector.vmstat",
          "--collector.processes",
          "--collector.interrupts",
          "--collector.schedstat",
          "--collector.stat",
          "--collector.arp",
          "--no-collector.bcache",
          "--no-collector.bonding",
          "--no-collector.btrfs",
          "--no-collector.edac",
          "--no-collector.fibrechannel",
          "--no-collector.infiniband",
          "--no-collector.ipvs",
          "--no-collector.mdadm",
          "--no-collector.nfs",
          "--no-collector.nfsd",
          "--no-collector.nvme",
          "--no-collector.powersupplyclass",
          "--no-collector.rapl",
          "--no-collector.tapestats",
          "--no-collector.textfile",
          "--no-collector.systemd",
          "--no-collector.xfs",
          "--no-collector.zfs"
        ]
      }

      volume_mount {
        volume      = "host-root"
        destination = "/host"
        read_only   = true
      }

      resources {
        cpu    = 125
        memory = 160
      }
    }
  }
}
