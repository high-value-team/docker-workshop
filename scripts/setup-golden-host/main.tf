
# Configure the Rancher provider
provider "rancher" {
  api_url = "${var.rancher_url}"
  access_key = "${var.rancher_access_key}"
  secret_key = "${var.rancher_secret_key}"
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

resource "null_resource" "golden_host" {
  connection {
    type = "ssh"
    user = "rancher"
    private_key = "${file("${var.rancher_ssh_key_path}")}"
    host = "${var.rancher_server_ip}"
    agent = false
    timeout = "10s"
  }

  provisioner "remote-exec" {
    inline = [
      "${rancher_registration_token.default.command}",
    ]
  }
}

# find golden host and label it
resource rancher_host "gold" {
  name           = "gold"
  description    = "The gold node"
  environment_id = "1a5"
  hostname       = "${var.rancher_server_private_dns}"
}

