job "rabbitmq" {
  datacenters = ["dc1"]

  group "rabbitmq" {
    count = 1

    network {
      port "amqp" {
        static = 5672
      }
      port "management" {
        static = 15672
      }
    }

    service {
      name = "rabbitmq-service"
      port = "amqp"
    }

    service {
      name = "rabbitmq-service"
      port = "management"
    }

    task "rabbitmq" {
      driver = "docker"

      config {
        ports = ["amqp"]
        image = "rabbitmq:3.11.5-management"
      }

      # resources {
      #  cpu    = 500  # 500 MHz
      #  memory = 512  # 512MB
      # }
    }
  }
}
