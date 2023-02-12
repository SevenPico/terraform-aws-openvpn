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
##  ./modules/reverse-routing-script/main.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

module "reverse_routing_sh_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["reverse", "routing"]
}

resource "aws_s3_object" "reverse_routing_sh" {
  count  = module.reverse_routing_sh_context.enabled ? 1 : 0
  bucket = var.bucket_id
  key    = "reverse-routing.sh"
  content = templatefile("${path.module}/reverse-routing.sh.tftpl", {
    #    client_dhcp_network          = var.openvpn_client_dhcp_network,
    #    client_dhcp_network_mask     = var.openvpn_client_dhcp_network_mask,
    openvpn_client_cidr_blocks = join(" ", var.openvpn_client_cidr_blocks),
    vpc_cidr_blocks            = join(" ", var.vpc_cidr_blocks)
  })
}
