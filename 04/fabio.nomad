job "fabio" {
  datacenters = ["dc1"]
  type = "system"

  group "fabio" {

    network {
      port "lb" {
        to = 9999
      }
      port "ui" {
        to = 9998
      }
    }

    task "fabio" {
      driver = "docker"
      config {
        image = "fabiolb/fabio"
        network_mode = "host"
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
