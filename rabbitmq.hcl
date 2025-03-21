job "rabbitmq" {
  datacenters = ["dc1"]

  group "rabbitmq" {
    count = 1

    network {
      port "amqp" {
        to = 5672
      }
      port "management" {
        to = 15672
      }
    }

    task "rabbitmq" {
      driver = "docker"

      config {
        image = "rabbitmq:3.11.5-management"
      }

      resources {
        cpu    = 500  # 500 MHz
        memory = 512  # 512MB
      }
    }
  }
}
