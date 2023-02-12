## ----------------------------------------------------------------------------
##  Copyright 2023 SevenPico, Inc.
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.
## ----------------------------------------------------------------------------

## ----------------------------------------------------------------------------
##  ./examples/default/openvpn.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

#------------------------------------------------------------------------------
# OpenVPN Labels
#------------------------------------------------------------------------------
module "openvpn_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
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
  efs_enabled                     = true
  create_openvpn_secret           = true
  nlb_acm_certificate_arn         = module.ssl_certificate.acm_certificate_arn
  nlb_deletion_protection_enabled = false
  nlb_subnet_ids                  = module.vpc_subnets.public_subnet_ids
  openvpn_daemon_tcp_port         = null
  openvpn_ui_https_port           = 443

  openvpn_config_scripts_additional = [
    local.nat_routing_script_name,
    local.ssl_script_name
  ]
}

#------------------------------------------------------------------------------
# OpenVPN Configuration Scripts
#------------------------------------------------------------------------------
locals {
  nat_routing_script_name = "nat-routing.sh"
  ssl_script_name         = "ssl-config.sh"
}

module "openvpn_nat_routing_script" {
  source  = "../../modules/nat-routing-script"
  context = module.openvpn_context.self

  bucket_id                  = module.openvpn.ssm_script_bucket_id
  script_name                = local.nat_routing_script_name
  ec2_role_name              = module.openvpn.role_name
  openvpn_client_cidr_blocks = ["172.27.0.0/16"]
  vpc_cidr_blocks            = [module.vpc.vpc_cidr_block]
}

module "openvpn_ssl_config_script" {
  source     = "../../modules/ssl-config-script"
  context    = module.openvpn_context.self
  depends_on = [module.openvpn]

  bucket_id              = module.openvpn.ssm_script_bucket_id
  ec2_role_name          = module.openvpn.role_name
  script_name            = local.ssl_script_name
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
