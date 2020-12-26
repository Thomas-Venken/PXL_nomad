 job "alertmanager" {
  datacenters = ["dc1"]
  type = "service"
  group "alertmanager" {
    count = 1
    network {
      port "alertmanager_port" {
        to = 9093
        static = 9093
      }
    }
    task "alertmanager" {
      driver = "docker"
      config {
        image = "prom/alertmanager"
        force_pull = true
        ports = ["alertmanager_port"]
        logging {
          type = "journald"
          config {
            tag = "ALERTMANAGER"
          }
        }
      }
      service {
        name = "alertmanager"
      }
    }
  }
}