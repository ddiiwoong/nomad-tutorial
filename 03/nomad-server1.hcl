# Increase log verbosity
log_level = "DEBUG"

# Setup data dir
data_dir = "/tmp/nomad/server1"

# Give the agent a unique name.
name = "server1"

# Enable the server
server {
  enabled = true
  bootstrap_expect = 3
  server_join {
    retry_join = ["172.17.8.101:4647"]
  }
}

# Advertise an accessible IP address so the server is reachable by other servers
# and clients. The IPs can be materialized by Terraform or be replaced by an
# init script.
advertise {
    http = "172.17.8.101:4646"
    rpc = "172.17.8.101:4647"
    serf = "172.17.8.101:4648"
}