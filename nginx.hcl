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

              location /.well-known/walletconnect.txt {
                return 200 "eea2da54-0516-4128-99df-be42da100bc0=11b7a27f2d96e4a9d83163d516e76bf068babbdfe6a6c37c79d740dcf0090d9e";
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
        static = 8000
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
              # ip_hash;
                {{ range service "service-engine-prod" }}
                server {{ .Address }}:{{ .Port }};
            {{ else }}server 127.0.0.1:65535; force a 502
                {{ end }}
            }

            server {
              listen 8000;

              location / {

                  real_ip_header X-Real-IP;

                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection 'upgrade';
                  proxy_set_header Host $host;
                  proxy_set_header X-Real_IP $remote_addr;

                  proxy_cache_bypass $http_upgrade;

                  proxy_http_version 1.1;
                  proxy_pass http://engine-prod;
              }
          }
        EOF

        destination   = "local/load-balancer.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }

  // waffle
  group "waffle-prod" {
    count = 1

    network {
      port "http" {
        static = 4000
      }
    }

    service {
      name = "waffle-prod"
      port = "http"
    }

    task "waffle-prod" {
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
          upstream waffle-prod {
                  {{ range service "service-waffle-web-prod" }}
                  server {{ .Address }}:{{ .Port }};
              {{ else }}server 127.0.0.1:65535; force a 502
                  {{ end }}
              }

              server {
                listen 4000;

                location / {
                    proxy_pass http://waffle-prod;
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

  group "waffle-engine-prod" {
    count = 1

    network {
      port "http" {
        static = 7000
      }
    }

    service {
      name = "waffle-engine-prod"
      port = "http"
    }

    task "waffle-engine-prod" {
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
            upstream waffle-engine-prod {
              # ip_hash;
                {{ range service "service-waffle-engine-prod" }}
                server {{ .Address }}:{{ .Port }};
            {{ else }}server 127.0.0.1:65535; force a 502
                {{ end }}
            }

            server {
              listen 7000;

              location / {

                  real_ip_header X-Real-IP;

                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection 'upgrade';
                  proxy_set_header Host $host;
                  proxy_set_header X-Real_IP $remote_addr;

                  proxy_cache_bypass $http_upgrade;

                  proxy_http_version 1.1;
                  proxy_pass http://waffle-engine-prod;
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
