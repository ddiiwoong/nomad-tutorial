job "fabio" {
  datacenters = ["toronto"]
  type = "system"
  update {
    stagger = "5s"
    max_parallel = 1
  }

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