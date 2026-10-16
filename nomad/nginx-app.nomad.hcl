variable "image" {
  type        = string
  description = "GHCR image to deploy"
  default     = "ghcr.io/harshal-112/devops-intern-final:latest"
}

job "nginx-app" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = 1
    shutdown_delay = "5s"

    network {
      port "http" {
        to = 8080
      }
    }

    service {
      name     = "nginx-app"
      provider = "consul"
      port     = "http"

      check {
        name     = "nginx-health"
        type     = "http"
        path     = "/healthz"
        interval = "10s"
        timeout  = "2s"
      }
    }

    update {
      max_parallel      = 1
      min_healthy_time  = "10s"
      healthy_deadline  = "2m"
      auto_revert       = true
    }

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    reschedule {
      attempts       = 3
      interval       = "1h"
      delay          = "15s"
      delay_function = "exponential"
      max_delay      = "5m"
      unlimited      = false
    }

    task "nginx" {
      driver = "docker"

      config {
        image = var.image
        ports = ["http"]
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
