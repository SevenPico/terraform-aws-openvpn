#------------------------------------------------------------------------------
# OpenVPN Labels
#------------------------------------------------------------------------------
module "openvpn_context" {
  source  = "app.terraform.io/SevenPico/context/null"
  version = "1.0.2"
  context = module.context.self
  name    = "vpn"
}


#------------------------------------------------------------------------------
# OpenVPN
#------------------------------------------------------------------------------
module "openvpn" {
  source  = "../.."
  context = module.openvpn_context.self

  # Required
  create_nlb                 = true
  openvpn_dhcp_option_domain = module.context.domain_name
  openvpn_hostname           = module.openvpn_context.dns_name
  subnet_ids                 = module.vpc_subnets.public_subnet_ids
  vpc_cidr_blocks            = [module.vpc.vpc_cidr_block]
  vpc_id                     = module.vpc.vpc_id

  # Optional
  create_openvpn_secret           = true
  nlb_acm_certificate_arn         = module.ssl_certificate.acm_certificate_arn
  nlb_deletion_protection_enabled = false
  nlb_subnet_ids                  = module.vpc_subnets.public_subnet_ids
}

#------------------------------------------------------------------------------
# OpenVPN Configuration Scripts
#------------------------------------------------------------------------------
locals {
  reverse_routing_script_name = "reverse-routing.sh"
  ssl_config_script_name      = "ssl-config.sh"
}

module "openvpn_reverse_routing_script" {
  source  = "app.terraform.io/SevenPico/openvpn/aws//modules/reverse-routing-script"
  version = "3.1.3"
  context = module.openvpn_context.self

  bucket_id                  = module.openvpn.ssm_script_bucket_id
  script_name                = local.reverse_routing_script_name
  ec2_role_name              = module.openvpn.role_name
  openvpn_client_cidr_blocks = ["172.27.0.0/16"]
  vpc_cidr_blocks            = [module.vpc.vpc_cidr_block]
}

module "openvpn_ssl_config_script" {
  source     = "app.terraform.io/SevenPico/openvpn/aws//modules/ssl-config-script"
  version    = "3.1.3"
  context    = module.openvpn_context.self
  depends_on = [module.openvpn]

  bucket_id              = module.openvpn.ssm_script_bucket_id
  ec2_role_name          = module.openvpn.role_name
  script_name            = local.ssl_config_script_name
  ssl_secret_arn         = module.ssl_certificate.secret_arn
  ssl_secret_kms_key_arn = module.ssl_certificate.kms_key_arn
}

# Delays VPN initialization until all resources are in place
resource "null_resource" "openvpn_set_autoscale_counts" {
  provisioner "local-exec" {
    command = join(" ", [
      "aws", "autoscaling", "update-auto-scaling-group",
      "--auto-scaling-group-name", module.openvpn.autoscale_group_name,
      "--desired-capacity", 1,
      "--profile", "7pi.io" # FIXME - profile should be a var?
    ])
  }

  depends_on = [
    module.openvpn
  ]
}


# ------------------------------------------------------------------------------
# OpenVPN NLB DNS Records
# ------------------------------------------------------------------------------
resource "aws_route53_record" "openvpn_nlb" {
  count   = module.openvpn_context.enabled ? 1 : 0
  zone_id = aws_route53_zone.public[0].id
  name    = module.openvpn_context.dns_name
  type    = "A"
  alias {
    name                   = module.openvpn.nlb_dns_name
    zone_id                = module.openvpn.nlb_zone_id
    evaluate_target_health = true
  }
}
