job "nginx" {
  datacenters = ["dc1"]

  group "nginx" {
    count = 1

    network {
      port "http" {
        static = 4000
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
upstream app {
    {{ range service "service-web" }}
    server {{ .Address }}:{{ .Port }};
{{ else }}server 127.0.0.1:65535; force a 502
    {{ end }}
}

server {
   listen 4000;

   location / {
      proxy_pass http://app;
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

  // prod separator
  group "nginx-prod" {
    count = 1

    network {
      port "http" {
        static = 3000
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
   listen 3000;

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
}
