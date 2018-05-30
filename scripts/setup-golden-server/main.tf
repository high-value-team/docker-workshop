provider "aws" {
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
	region     = "${var.aws_region}"
}

# A look up for rancheros_ami by region
# source:
# * https://github.com/rancher/os
variable "rancheros_amis" {
  default = {
      "eu-west-2" = "ami-80bd58e7"
      "eu-west-1" = "ami-69187010"
      "eu-central-1" = "ami-28422647"
      "us-east-1" = "ami-a7151cdd"
      "us-east-2" = "ami-a383b6c6"
      "us-west-1" = "ami-c4b3bca4"
      "us-west-2" = "ami-6e1a9e16"
  }
  type = "map"
}

# this creates a cloud-init script that registers the server
# as a rancher server when it starts up
data "template_file" "install_rancher_server" {
  template = <<EOF
#cloud-config
write_files:
  - path: /etc/rc.local
    permissions: "0755"
    owner: root
    content: |
      #!/bin/bash
      wait-for-docker
      sudo docker run -d --restart=unless-stopped -p 8080:8080 rancher/server:v1.6.17
EOF
}


# AWS ec2 launch instance and install rancher server
# source:
# * https://www.terraform.io/docs/providers/aws/d/instance.html
# * https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html
resource "aws_instance" "rancher_server_instance" {
  ami = "${lookup(var.rancheros_amis, var.aws_region)}"
  instance_type = "t2.medium"
  tags = { Name = "rancher-server" }
  security_groups = ["${var.aws_security_group}"]
  user_data = "${data.template_file.install_rancher_server.rendered}"
  key_name = "${var.aws_ssh_key_name}"
  root_block_device = {
    volume_size = "50"
    delete_on_termination = true
  }
  provisioner "local-exec" {
    command = <<EOF
until [[ $(curl -s -o /dev/null -w "%{http_code}" http://${aws_instance.rancher_server_instance.public_ip}:8080) == "200" ]]
do
echo waiting for rancher server API
sleep 5
done
echo rancher server API up and running;
EOF
  }
}

data "aws_route53_zone" "selected" {
  name = "${var.aws_hosted_zone}"
}

resource "aws_route53_record" "basic_hvt_zone" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.rancher_server_instance.public_ip}"]
}

resource "aws_route53_record" "prefix_hvt_zone" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "*.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.rancher_server_instance.public_ip}"]
}

provider "abc" { }

resource "abc_api_keys" "hallo" {
  rancher_server_url = "http://${aws_instance.rancher_server_instance.public_ip}:8080"
}

resource "abc_access_control" "hallo" {
  rancher_server_url = "http://${aws_instance.rancher_server_instance.public_ip}:8080"
  username = "${var.rancher_username}"
  password = "${var.rancher_password}"
}

output "rancher_url" {
  value = "http://${aws_instance.rancher_server_instance.public_ip}:8080"
}
output "rancher_access_key" {
  value = "${abc_api_keys.hallo.rancher_access_key}"
}
output "rancher_secret_key" {
  value = "${abc_api_keys.hallo.rancher_secret_key}"
}
output "rancher_server_private_dns" {
  value = "${aws_instance.rancher_server_instance.private_dns}"
}
output "rancher_server_ip" {
  value = "${aws_instance.rancher_server_instance.public_ip}"
}