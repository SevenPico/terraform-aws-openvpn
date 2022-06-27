#------------------------------------------------------------------------------
# OpenVPN Labels
#------------------------------------------------------------------------------
module "openvpn_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.this.context
}

module "openvpn_dns_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.dns_meta.context
  name    = "vpn"
}


#------------------------------------------------------------------------------
# OpenVPN
#------------------------------------------------------------------------------
module "openvpn" {
  source     = "../.."
  context    = module.openvpn_meta.context
  depends_on = [module.ssl_certificate]

  # Required
  subnet_ids                 = module.vpc_subnets.private_subnet_ids
  vpc_cidr_blocks            = [module.vpc.vpc_cidr_block]
  vpc_id                     = module.vpc.vpc_id
  openvpn_dhcp_option_domain = var.common_name
  openvpn_hostname           = module.openvpn_dns_meta.id

  #Optional
  autoscale_min_count     = 0
  autoscale_desired_count = 0
  create_admin_secret     = true
  create_nlb              = true
  nlb_access_logs_enabled = false
  nlb_subnet_ids          = module.vpc_subnets.public_subnet_ids
  nlb_acm_certificate_arn = module.ssl_certificate.acm_certificate_arn
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
  zone_id = aws_route53_zone.public[0].id
  name    = module.openvpn_dns_meta.id
  type    = "A"
  alias {
    name                   = module.openvpn.nlb_dns_name
    zone_id                = module.openvpn.nlb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "openvpn_nlb_private_zone" {
  zone_id = aws_route53_zone.private[0].id
  name    = module.openvpn_dns_meta.id
  type    = "A"
  alias {
    name                   = module.openvpn.nlb_dns_name
    zone_id                = module.openvpn.nlb_zone_id
    evaluate_target_health = true
  }
}
