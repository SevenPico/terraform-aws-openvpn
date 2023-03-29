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
##  ./modules/nat-routing-script/main.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

module "nat_routing_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["nat", "routing"]
}


#------------------------------------------------------------------------------
# SSM Document NAT Routing Configuration
#------------------------------------------------------------------------------
resource "aws_ssm_document" "nat_routing_script" {
  count           = module.context.enabled ? 1 : 0
  name            = module.nat_routing_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.nat_routing_context.tags
  content = templatefile("${path.module}/templates/ssm-composite-initializer.tftpl", {
    #    client_dhcp_network          = var.openvpn_client_dhcp_network,
    #    client_dhcp_network_mask     = var.openvpn_client_dhcp_network_mask,
    openvpn_client_cidr_blocks = join(" ", var.openvpn_client_cidr_blocks),
    vpc_cidr_blocks            = join(" ", var.vpc_cidr_blocks)
  })
}

resource "aws_ssm_association" "ssl_config_script" {
  count               = module.context.enabled ? 1 : 0
  association_name    = module.nat_routing_context.id
  name                = one(aws_ssm_document.nat_routing_script[*].name)
  schedule_expression = var.ssm_documents_schedule_expression == null ? "" : var.ssm_documents_schedule_expression
  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
}
