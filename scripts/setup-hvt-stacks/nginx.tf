
resource "rancher_stack" "nginx" {
  name = "nginx"
  description = "A service that's always happy"
  start_on_create = true
  environment_id = "${var.rancher_environment_id}"

  docker_compose = <<EOF
version: '2'
services:
  nginx:
    image: nginx
    stdin_open: true
    tty: true
    ports:
    - 8181:80/tcp
    labels:
      io.rancher.container.pull_image: always
EOF

  rancher_compose = <<EOF
version: '2'
services:
  nginx:
    scale: 1
    start_on_create: true
EOF

  finish_upgrade = true

  environment {
    STARTED = "${timestamp()}"
  }
}


