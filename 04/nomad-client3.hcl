# Setup data dir
data_dir = "/tmp/nomad/client3"

# Give the agent a unique name.
name = "client3"

# Enable the client
client {
  enabled = true
  servers = ["nomad-server1.local:4647"]
}

# Advertise an accessible IP address so the server is reachable by other servers
# and clients. The IPs can be materialized by Terraform or be replaced by an
# init script.
# advertise {
#     http = "172.17.8.113:4646"
#     rpc = "172.17.8.113:4647"
#     serf = "172.17.8.113:4648"
# }
# Telemetry
telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}
