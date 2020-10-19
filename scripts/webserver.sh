sudo echo "
job \"webserver\" {
  datacenters = [\"dc1\"]
  type = \"service\"

  group \"webserver\" {
    count = 3
    task \"webserver\" {
      driver = \"docker\"

      config {
        image = \"httpd\"
        force_pull = true
        port_map = {
          webserver_web = 80
        }

        logging {
          type = \"journald\"
          config {
            tag = \"WEBSERVER\"
          }
        }
      }

      service {
        name = \"webserver\"
        port = \"webserver_web\"
      }

      resources {
        network {
          port \"webserver_web\" {}
        }
      }
    }
  }
}" > /opt/nomad/webserver.nomad

