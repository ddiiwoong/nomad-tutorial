# Setup data dir
data_dir = "/tmp/nomad/client1"

# Give the agent a unique name.
name = "client1"

# Enable the client
client {
    enabled = true
    servers = ["172.17.8.101:4647"]
}

# Advertise an accessible IP address so the server is reachable by other servers
# and clients. The IPs can be materialized by Terraform or be replaced by an
# init script.
advertise {
    http = "172.17.8.111:4646"
    rpc = "172.17.8.111:4647"
    serf = "172.17.8.111:4648"
}