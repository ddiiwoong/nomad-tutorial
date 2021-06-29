# Setup data dir
data_dir = "/tmp/nomad/server"

# Give the agent a unique name.
name = "server"

# Enable the server
server {
  enabled = true
  bootstrap_expect = 1
}

# Telemetry
telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}
