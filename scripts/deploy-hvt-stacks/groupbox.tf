
resource "rancher_stack" "groupbox" {
  name = "groupbox"
  description = "A service that's always happy"
  start_on_create = true
  environment_id = "${var.rancher_environment_id}"

  docker_compose = <<EOF
version: '2'
services:
  backend:
    image: hvt1/groupbox-backend
    environment:
      HTTP_PORT: '80'
      MONGODB_URL: mongodb://mongo:27017
      GROUPBOX_ROOT_URI: http://groupbox.hvt.zone
#      # backend still works even if SMTP is not configured
#      - SMTP_NO_REPLY_EMAIL=no-reply-groupbox@ralfw.de
#      - SMTP_SERVER_ADDRESS=sslout.df.eu:587
#      - SMTP_USERNAME=TODO
#      - SMTP_PASSWORD=TODO
    stdin_open: true
    tty: true
    labels:
      io.rancher.container.pull_image: always
  mongo:
    image: mongo
    stdin_open: true
    tty: true
    labels:
      io.rancher.container.pull_image: always
  frontend:
    image: hvt1/groupbox-frontend
    environment:
      REACT_APP_BACKEND_URL: http://groupbox-backend.hvt.zone
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
  mongo:
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


