# Setup data dir
data_dir = "/tmp/nomad/client1"

# Give the agent a unique name.
name = "client1"

# Enable the client
client {
  enabled = true
  servers = ["nomad-server1.local:4647"]
}

# Telemetry
telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}
