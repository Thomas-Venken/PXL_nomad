job "prometheus" {
	datacenters = ["dc1"] 
	type = "service"

	group "prometheus" {
		count = 1
		network {
			port "prometheus_ui" {
			to = 9090
			static = 9090
			}
		}
	  task "prometheus" {
		driver = "docker"
		config {
			image = "prom/prometheus:latest"
			ports = ["prometheus_ui"]
			logging {
				type = "journald"
				config {
					tag = "PROMETHEUS"
				}
			}
		}
		service {
			name = "prometheus"
		}
	  }
	}
}

