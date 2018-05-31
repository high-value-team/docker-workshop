provider "aws" {
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
	region     = "${var.aws_region}"
}

provider "rancher" {
  api_url = "${var.rancher_url}"
  access_key = "${var.rancher_access_key}"
  secret_key = "${var.rancher_secret_key}"
}

module "silver" {
  source = "./setup-silver-host"

  number_of_hosts    = "1"
  ranger_host_name   = "silver"
  aws_instance_type  = "t2.small"
  aws_region         = "${var.aws_region}"
  aws_ssh_key_name   = "${var.aws_ssh_key_name}"
  aws_security_group = "${var.aws_security_group}"

  providers = {
    aws = "aws"
    rancher = "rancher"
  }
}
