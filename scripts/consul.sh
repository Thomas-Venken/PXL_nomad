sudo echo "data_dir = \"/opt/consul\"

client_addr= \"0.0.0.0\"

ui = true

server = true

bootstrap_expect=1

#retry_join = [\"consul.domain.internal\"]
#retry_join = [\"10.0.4.67\"]
#retry_join = [\"[::1]:8301\"]
#retry_join = [\"consul.domain.internal\", \"10.0.4.67\"]

bind_addr = \"192.168.2.15\"


" >> /etc/consul.d/consul.hcl
