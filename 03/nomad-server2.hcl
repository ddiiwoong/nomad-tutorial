# Increase log verbosity
log_level = "DEBUG"

# Setup data dir
data_dir = "/tmp/nomad/server2"

bind_addr = "0.0.0.0" # the default

# Enable the server
server {
  enabled = true
  bootstrap_expect = 3
  server_join {
    retry_join = ["nomad-server1.local"]
  }
}