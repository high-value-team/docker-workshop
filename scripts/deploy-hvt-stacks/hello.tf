
resource "rancher_stack" "hello" {
  name = "hello"
  description = "A service that's always happy"
  start_on_create = true
  environment_id = "${var.rancher_environment_id}"

  docker_compose = <<EOF
version: '2'
services:
  hello:
    image: hvt1/hello
    stdin_open: true
    tty: true
    labels:
      io.rancher.container.pull_image: always
EOF

  rancher_compose = <<EOF
version: '2'
services:
  hello:
    scale: 1
    start_on_create: true
EOF

  finish_upgrade = true

  environment {
    STARTED = "${timestamp()}"
  }
}


