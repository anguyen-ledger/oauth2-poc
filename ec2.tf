module "ledger_ips" {
  source = "git::ssh://git@github.com/LedgerHQ/tf-ledgerips-module.git?ref=v1.7.0"
}

module "oauth_poc_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "3.18.0"
  name                = "hsm-controller-sg"
  vpc_id              = "vpc-04e8c037e44a386fc"
  ingress_cidr_blocks = concat(module.ledger_ips.trusted_locations, module.ledger_ips.infra_vpn,["212.106.106.198/32"])
  ingress_rules       = ["ssh-tcp","http-8080-tcp","https-443-tcp"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
}

data "template_file" "oauth_poc_data" {
  template = file("user_data/bootstrap.tpl")
}

module "oauth_poc_ec2" {
  source         = "terraform-aws-modules/ec2-instance/aws"
  version        = "2.21.0"
  name           = "oauth_poc_poc"
  instance_count = 1
  key_name       = aws_key_pair.this.key_name
  ami            = "ami-0d2a4a5d69e46ea0b" # Ubuntu, 20.04 LTS, amd64 focal image build on 2022-06-10
  user_data      = data.template_file.oauth_poc_data.rendered
  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 20
    }
  ]
  instance_type          = "t3.small"
  vpc_security_group_ids = [module.oauth_poc_sg.this_security_group_id]
  subnet_id              = "subnet-0e98bc39b4851d072"
}

resource "null_resource" "ansible_inventory" {
  provisioner "local-exec" {
    command = "echo -e \"[all]\n${module.oauth_poc_ec2.public_ip[0]} ansible_ssh_user=ubuntu\" > ansible/inventory/hosts"
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "aws_key_pair" "this" {
  key_name   = "oauth_poc_poc"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCm+SOTMt1xhaof8DC6+XnEWODEXwo+m08R3JXn1cKvYQf15aFpv6BMyfgVAWe7YJj7rFtKE4tL6AfpaZw8yXjBgfKt+Wc3FYL0CEcE+pScH2wCVNFvlLOajaRCMop77RAtHrCam+V4Raf5tGKjejcBC4MoZjrMIOoXil41j/28crBGv9HStSkZC38NL4NhuGQbh2FpogjISbxppMbHSblLOYE2HAAkNsaTuxwJ63MYddeACPz2yLi/xxYSiM2gLOXqHFFjz1BJyq7yhti50VxAQuxeTpYRO5cSc7qoEZqAz5ncNmjzJPgU6OKz43SH9m7V6HWOFARQuEfnjORi89Qj anguyen@LPPS0094"
}
