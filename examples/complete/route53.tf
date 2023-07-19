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
##  ./examples/default/route53.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

data "aws_route53_zone" "root" {
  count = module.context.enabled ? 1 : 0
  name  = var.root_domain

}

resource "aws_route53_zone" "public" {
  count = module.context.enabled ? 1 : 0
  name  = module.context.domain_name
  tags  = module.context.tags
}

resource "aws_route53_record" "ns" {
  count   = module.context.enabled ? 1 : 0
  name    = module.context.domain_name
  type    = "NS"
  zone_id = join("", data.aws_route53_zone.root[*].id)
  records = length(aws_route53_zone.public) > 0 ? aws_route53_zone.public[0].name_servers : []
  ttl     = 300
}

resource "aws_route53_zone" "private" {
  count = module.context.enabled ? 1 : 0
  name  = module.context.domain_name
  vpc {
    vpc_id = module.vpc.vpc_id
  }
  tags = module.context.tags
}


# ------------------------------------------------------------------------------
# OpenVPN NLB DNS Records
# ------------------------------------------------------------------------------
#resource "aws_route53_record" "nlb" {
#  count   = module.openvpn_context.enabled ? 1 : 0
#  zone_id = aws_route53_zone.public[0].id
#  name    = module.openvpn_context.dns_name
#  type    = "A"
#  alias {
#    name                   = module.openvpn.nlb_dns_name
#    zone_id                = module.openvpn.nlb_zone_id
#    evaluate_target_health = true
#  }
#}

