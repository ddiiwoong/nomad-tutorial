# Setup data dir
data_dir = "/tmp/nomad/client2"

# Give the agent a unique name.
name = "client2"

# Enable the client
client {
  enabled = true
  servers = ["nomad-server1.local:4647"]
}

# Advertise an accessible IP address so the server is reachable by other servers
# and clients. The IPs can be materialized by Terraform or be replaced by an
# init script.
# advertise {
#     http = "172.17.8.112:4646"
#     rpc = "172.17.8.112:4647"
#     serf = "172.17.8.112:4648"
# }

# Telemetry
telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}
