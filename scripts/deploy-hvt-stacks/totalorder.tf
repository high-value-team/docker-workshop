
resource "rancher_stack" "totalorder" {
  name = "totalorder"
  description = "A service that's always happy"
  start_on_create = true
  environment_id = "${var.rancher_environment_id}"

  docker_compose = <<EOF
version: '2'
services:
  backend:
    image: hvt1/totalorder-backend
    environment:
      TOTALORDER_BACKEND_DATABASEPATH: mnt
    stdin_open: true
    tty: true
    labels:
      io.rancher.container.pull_image: always
  frontend:
    image: hvt1/totalorder-frontend
    environment:
      REACT_APP_BACKEND_URL: http://totalorder-backend.hvt.zone
    stdin_open: true
    tty: true
    labels:
      io.rancher.container.pull_image: always
EOF

  rancher_compose = <<EOF
version: '2'
services:
  backend:
    scale: 1
    start_on_create: true
  frontend:
    scale: 1
    start_on_create: true
EOF

  finish_upgrade = true

  environment {
    STARTED = "${timestamp()}"
  }
}


