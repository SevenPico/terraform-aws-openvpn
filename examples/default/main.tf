module "openvpn_dns_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.dns_meta.context
  name    = "vpn"
}


module "openvpn" {
  source  = "../.."
  context = module.this.context

  # Required
  subnet_ids                 = module.vpc_subnets.public_subnet_ids
  vpc_cidr_blocks            = [module.vpc.vpc_cidr_block]
  vpc_id                     = module.vpc.vpc_id
  openvpn_dhcp_option_domain = var.common_name
  openvpn_hostname           = module.openvpn_dns_meta.id

  #Optional
  openvpn_ui_alb_security_group_id = module.alb.security_group_id
  openvpn_ui_alb_target_groups     = [module.alb.default_target_group_arn]
  openvpn_daemon_nlb_target_groups = concat(
    aws_lb_target_group.tcp.*.arn,
    aws_lb_target_group.udp.*.arn
  )
}
