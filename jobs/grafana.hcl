 job "grafana" {
  datacenters = ["dc1"]
  type = "service"
  group "grafana" {
    count = 1
    network {
      port "grafana_web" {
        to = 3000
        static = 3000
      }
    }
    task "grafana" {
      driver = "docker"
      config {
        image = "grafana/grafana"
        force_pull = true
        ports = ["grafana_web"]
        logging {
          type = "journald"
          config {
            tag = "GRAFANA"
          }
        }
      }
      service {
        name = "grafana"
      }
    }
  }
}