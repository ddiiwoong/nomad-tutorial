# Setup data dir
data_dir = "/tmp/nomad/client3"

# Give the agent a unique name.
name = "client3"

# Enable the client
client {
  enabled = true
}

# Telemetry
telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}
