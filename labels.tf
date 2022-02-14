locals {
  asg_hostname_pattern = var.openvpn_asg_unique_instance_hostnames ? "vpn" : "vpn-#instance_id"
}

module "vpn_ec2_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.this.context
  stage    = "vpn"
  name = "asg"
}

module "dns_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.this.context

  namespace           = data.aws_route53_zone.public.name
  stage               = null
  name                = null
  attributes          = []
  delimiter           = "."
  regex_replace_chars = "/[^a-zA-Z0-9-.]/"
  label_order         = ["name", "namespace"]
}


#------------------------------------------------------------------------------
# EC2 VPN Auto Scale Group Labels
#------------------------------------------------------------------------------
module "asg_ec2_openvpn_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.vpn_ec2_meta.context
  tags = {
    "asg:hostname_pattern" : "${local.asg_hostname_pattern}.${data.aws_route53_zone.public.name}@${data.aws_route53_zone.public.id}"
  }
}

module "asg_ec2_openvpn_dns_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.dns_meta.context
  name    = "vpn"
}


#------------------------------------------------------------------------------
# EC2 VPN Auto Scale Group IAM Labels
#------------------------------------------------------------------------------
module "asg_ec2_openvpn_role_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.vpn_ec2_meta.context
  attributes = ["role"]
}


module "asg_ec2_openvpn_lifecycle_role_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.vpn_ec2_meta.context
  attributes = ["lifecycle", "role"]
}

module "asg_ec2_openvpn_lifecycle_policy_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.vpn_ec2_meta.context
  attributes = ["lifecycle", "policy"]
}

#module "ec2_openvpn_asg_sns_role_meta" {
#  source     = "registry.terraform.io/cloudposse/label/null"
#  version    = "0.25.0"
#  context    = module.ec2_openvpn_meta.context
#  attributes = ["sns", "role"]
#}
#
#module "ec2_openvpn_asg_sns_policy_meta" {
#  source     = "registry.terraform.io/cloudposse/label/null"
#  version    = "0.25.0"
#  context    = module.ec2_openvpn_meta.context
#  attributes = ["sns", "policy"]
#}


#------------------------------------------------------------------------------
# EC2 VPN Auto Scale Group Secrets Manager Labels
#------------------------------------------------------------------------------
module "asg_ec2_openvpn_secrets_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.vpn_ec2_meta.context
  attributes = ["configuration"]
}

module "asg_ec2_openvpn_secrets_kms_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.asg_ec2_openvpn_secrets_meta.context
}

#------------------------------------------------------------------------------
# EC2 VPN Auto Scale Group Security Group Labels
#------------------------------------------------------------------------------
module "asg_ec2_openvpn_sg_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.vpn_ec2_meta.context
  attributes = ["sg"]
}


#------------------------------------------------------------------------------
# EC2 VPN Auto Scale Group SSM Labels
#------------------------------------------------------------------------------
module "asg_ec2_openvpn_ssm_initialization_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.vpn_ec2_meta.context
  attributes = ["initialization"]
}

module "ec2_openvpn_asg_ssm_ssl_certificate_refresh_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.vpn_ec2_meta.context
  attributes = ["ssl", "certificate", "refresh"]
}


##------------------------------------------------------------------------------
## EC2 VPN Auto Scale Group Lambda Labels
##------------------------------------------------------------------------------
#module "ec2_openvpn_asg_sns_meta" {
#  source     = "registry.terraform.io/cloudposse/label/null"
#  version    = "0.25.0"
#  context    = module.ec2_openvpn_meta.context
#  attributes = ["handler"]
#}
#
#module "ec2_openvpn_asg_public_dns_handler_meta" {
#  source     = "registry.terraform.io/cloudposse/label/null"
#  version    = "0.25.0"
#  context    = module.ec2_openvpn_meta.context
#  attributes = ["public", "dns", "handler"]
#}
#
#module "ec2_openvpn_asg_private_dns_handler_meta" {
#  source     = "registry.terraform.io/cloudposse/label/null"
#  version    = "0.25.0"
#  context    = module.ec2_openvpn_meta.context
#  attributes = ["private", "dns", "handler"]
#}
#

#------------------------------------------------------------------------------
# EC2 VPN S3 Labels
#------------------------------------------------------------------------------
module "ec2_openvpn_scripts_bucket_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.vpn_ec2_meta.context
  name    = "scripts"
}

