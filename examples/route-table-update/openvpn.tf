#------------------------------------------------------------------------------
# OpenVPN Labels
#------------------------------------------------------------------------------
module "openvpn_context" {
  source  = "app.terraform.io/SevenPico/context/null"
  version = "1.0.2"
  context = module.context.self
  name    = "vpn"
}

module "openvpn_dns_context" {
  source  = "app.terraform.io/SevenPico/context/null"
  version = "1.0.2"
  context = module.dns_context.self
  name    = "vpn"
}


#------------------------------------------------------------------------------
# OpenVPN
#------------------------------------------------------------------------------
module "openvpn" {
  source  = "../../../terraform-aws-openvpn"
  context = module.openvpn_context.self

  # Required
  subnet_ids                 = module.vpc_subnets.public_subnet_ids
  vpc_cidr_blocks            = [module.vpc.vpc_cidr_block]
  vpc_id                     = module.vpc.vpc_id
  openvpn_dhcp_option_domain = var.common_name
  openvpn_hostname           = module.openvpn_dns_context.id

  # Optional
  create_ec2_autoscale_sns_topic = true
  ec2_autoscale_desired_count    = 0
  ec2_autoscale_max_count        = 1
  ec2_autoscale_min_count        = 0
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
