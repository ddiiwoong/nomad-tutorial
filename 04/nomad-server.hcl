# Increase log verbosity
log_level = "DEBUG"

# Setup data dir
data_dir = "/tmp/nomad/server"

# bind_addr = "0.0.0.0" # the default

# Give the agent a unique name.
name = "server"

# Enable the server
server {
  enabled = true
  bootstrap_expect = 1
}

# Advertise an accessible IP address so the server is reachable by other servers
# and clients. The IPs can be materialized by Terraform or be replaced by an
# init script.
advertise {
    http = "nomad-server1.local:4646"
    rpc = "nomad-server1.local:4647"
    serf = "nomad-server1.local:4648"
}

# Telemetry
telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}
