job "nginx" {
  datacenters = ["dc1"]

  // prod separator
  group "nginx" {
    count = 1

    network {
      mode = "host"
      port "http" {
        static = 80
      }
    }

    service {
      name = "nginx"
      port = "http"
    }

    task "nginx" {
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
          upstream sugar-prod {
            {{ range service "service-web-prod" }}
              server {{ .Address }}:{{ .Port }};
            {{ else }}server 127.0.0.1:65535; force a 502
            {{ end }}
          }

          upstream engine-prod {
            {{ range service "service-engine-prod" }}
              server {{ .Address }}:{{ .Port }};
            {{ else }}server 127.0.0.1:65535; force a 502
            {{ end }}
          }

          upstream waffle-prod {
            {{ range service "service-waffle-web-prod" }}
              server {{ .Address }}:{{ .Port }};
            {{ else }}server 127.0.0.1:65535; force a 502
            {{ end }}
          }

          upstream waffle-engine-prod {
            {{ range service "service-waffle-engine-prod" }}
              server {{ .Address }}:{{ .Port }};
            {{ else }}server 127.0.0.1:65535; force a 502
            {{ end }}
          }

          upstream river-prod {
            {{ range service "service-river-web-prod" }}
              server {{ .Address }}:{{ .Port }};
            {{ else }}server 127.0.0.1:65535; force a 502
            {{ end }}
          }

          server {
            listen 80;
            server_name sugarhub.space;

            location / {
                proxy_pass http://sugar-prod;
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

          server {
            listen 80;
            server_name api.sugarhub.space;

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

          server {
            listen 80;
            server_name waffle.food;

            location / {
              proxy_pass http://waffle-prod;
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection 'upgrade';
              proxy_set_header Host $host;
              proxy_cache_bypass $http_upgrade;
            }

            location /.well-known/walletconnect.txt {
              return 200 "4f5074a5-bc1e-4bca-8911-851b023da159=8315b8a34584734def0c919c81a78eafdddbdfc2ae3dc1590669b2cbd94757ec";
            }
          }

          server {
            listen 80;
            server_name api.waffle.food;

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

          server {
            listen 80;
            server_name riverfi.xyz;

            location / {
              real_ip_header X-Real-IP;

              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection 'upgrade';
              proxy_set_header Host $host;
              proxy_set_header X-Real_IP $remote_addr;

              proxy_cache_bypass $http_upgrade;

              proxy_http_version 1.1;
              proxy_pass http://river-prod;
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
