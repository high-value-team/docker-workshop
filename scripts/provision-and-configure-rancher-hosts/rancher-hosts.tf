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
data "template_file" "install_rancher_host" {
  template = <<EOF
#cloud-config
write_files:
  - path: /etc/rc.local
    permissions: "0755"
    owner: root
    content: |
      #!/bin/bash
      wait-for-docker
      ${rancher_registration_token.default.command}
EOF
}


# AWS ec2 launch instance and install rancher server
# source:
# * https://www.terraform.io/docs/providers/aws/d/instance.html
# * https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html
resource "aws_instance" "rancher_host_instance" {
  ami = "${lookup(var.rancheros_amis, var.aws_region)}"
  instance_type = "t2.small"
  tags = { Name = "rancher-host" }
  security_groups = ["${var.aws_security_group}"]
  user_data = "${data.template_file.install_rancher_host.rendered}"
  key_name = "${var.aws_ssh_key_name}"
  root_block_device = {
    volume_size = "50"
    delete_on_termination = true
  }
}


# Configure the Rancher provider
provider "rancher" {
  api_url = "${var.rancher_url}"
  access_key = "${var.rancher_access_key}"
  secret_key = "${var.rancher_secret_key}"
}

# Create a new Rancher environment
resource "rancher_environment" "default" {
  name = "default"
  description = "The staging environment"
  orchestration = "cattle"
}

# Create a new Rancher registration token
resource "rancher_registration_token" "default" {
  name           = "default_token"
  description    = "Registration token for the default environment"
  environment_id = "1a5"

  host_labels    {
    orchestration = "true",
    etcd          = "true",
    compute       = "true"
  }
}

# Manage an existing Rancher host
resource rancher_host "foo" {
  name           = "foo"
  description    = "The foo node"
  environment_id = "1a5"
  hostname       = "${aws_instance.rancher_host_instance.private_dns}"
}

