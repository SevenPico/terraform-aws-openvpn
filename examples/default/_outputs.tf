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
##  ./examples/default/_outputs.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

output "autoscaling_group_arn" {
  value = module.openvpn.autoscale_group_arn
}

output "ec2_security_group_id" {
  value = module.openvpn.security_group_id
}

output "autoscaling_role_arn" {
  value = module.openvpn.role_arn
}

output "autoscaling_lifecycle_role_arn" {
  value = module.openvpn.lifecycle_role_arn
}

output "autoscaling_sns_role_arn" {
  value = module.openvpn.sns_role_arn
}

output "openvpn_ui_url" {
  value = "https://${module.openvpn.nlb_dns_name}:${module.openvpn.ui_https_port}"
}


