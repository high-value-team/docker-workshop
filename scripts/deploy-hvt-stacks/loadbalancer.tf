
resource "rancher_stack" "loadbalancer" {
  name = "loadbalancer"
  description = "A service that's always happy"
  start_on_create = true
  environment_id = "${var.rancher_environment_id}"

  docker_compose = <<EOF
version: '2'
services:
  loadbalancer:
    image: rancher/lb-service-haproxy:v0.9.1
    ports:
    - 80:80/tcp
    labels:
      io.rancher.container.agent.role: environmentAdmin,agent
      io.rancher.container.agent_service.drain_provider: 'true'
      io.rancher.container.create_agent: 'true'
      io.rancher.scheduler.global: 'true'
EOF

  rancher_compose = <<EOF
version: '2'
services:
  loadbalancer:
    start_on_create: true
    lb_config:
      certs: []
      port_rules:
      - hostname: hdr_end(host) -i totalorder.hvt.zone
        priority: 3
        protocol: http
        service: totalorder/frontend
        source_port: 80
        target_port: 80
      - hostname: hdr_end(host) -i featureforecast-backend.hvt.zone
        priority: 4
        protocol: http
        service: featureforecast/backend
        source_port: 80
        target_port: 80
      - hostname: hdr_end(host) -i totalorder-backend.hvt.zone
        path: ''
        priority: 5
        protocol: http
        service: totalorder/backend
        source_port: 80
        target_port: 80
      - hostname: hdr_end(host) -i groupbox.hvt.zone
        path: ''
        priority: 6
        protocol: http
        service: groupbox/frontend
        source_port: 80
        target_port: 80
      - hostname: hdr_end(host) -i groupbox-backend.hvt.zone
        path: ''
        priority: 7
        protocol: http
        service: groupbox/backend
        source_port: 80
        target_port: 80
      - hostname: ''
        priority: 11
        protocol: http
        service: hello/hello
        source_port: 80
        target_port: 80
      - hostname: hdr_end(host) -i featureforecast.hvt.zone
        priority: 12
        protocol: http
        service: featureforecast/frontend
        source_port: 80
        target_port: 80
      - hostname: hdr_end(host) -i drone.hvt.zone
        path: ''
        priority: 13
        protocol: http
        service: drone/server
        source_port: 80
        target_port: 8000
    health_check:
      healthy_threshold: 2
      response_timeout: 2000
      port: 42
      unhealthy_threshold: 3
      initializing_timeout: 60000
      interval: 2000
      reinitializing_timeout: 60000
EOF

  finish_upgrade = true

  depends_on = [
    "rancher_stack.drone",
    "rancher_stack.featureforecast",
    "rancher_stack.groupbox",
    "rancher_stack.hello",
    "rancher_stack.nginx",
    "rancher_stack.totalorder",
  ]

  environment {
    STARTED = "${timestamp()}"
  }
}


