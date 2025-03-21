job "nginx" {
  datacenters = ["dc1"]

  // prod separator
  group "nginx-prod" {
    count = 1

    network {
      port "http" {
        static = 5173
      }
    }

    service {
      name = "nginx-prod"
      port = "http"
    }

    task "nginx-prod" {
      driver = "docker"

      config {
        image = "nginx"
        ports = ["http"]
        volumes = [
          "local:/etc/nginx/conf.d",
        ]
      }

      template {
        data = <<EOF
            upstream app-prod {
                {{ range service "service-web-prod" }}
                server {{ .Address }}:{{ .Port }};
            {{ else }}server 127.0.0.1:65535; force a 502
                {{ end }}
            }

            server {
              listen 5173;

              location / {
                  proxy_pass http://app-prod;
                  proxy_http_version 1.1;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection 'upgrade';
                  proxy_set_header Host $host;
                  proxy_cache_bypass $http_upgrade;
              }
          }
        EOF

        destination   = "local/load-balancer.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }

  group "engine-prod" {
    count = 1

    network {
      port "http" {
        static = 3000
      }
    }

    service {
      name = "engine-prod"
      port = "http"
    }

    task "engine-prod" {
      driver = "docker"

      config {
        image = "nginx"
        ports = ["http"]
        volumes = [
          "local:/etc/nginx/conf.d",
        ]
      }

      template {
        data = <<EOF
            upstream engine-prod {
                {{ range service "service-engine-prod" }}
                server {{ .Address }}:{{ .Port }};
            {{ else }}server 127.0.0.1:65535; force a 502
                {{ end }}
            }

            server {
              listen 3000;

              location / {
                  proxy_pass http://engine-prod;
                  proxy_http_version 1.1;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection 'upgrade';
                  proxy_set_header Host $host;
                  proxy_cache_bypass $http_upgrade;
              }
          }
        EOF

        destination   = "local/load-balancer.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }

}
