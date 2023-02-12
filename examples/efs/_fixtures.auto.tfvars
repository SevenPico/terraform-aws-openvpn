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
##  ./examples/default/_fixtures.auto.tfvars
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

vpc_cidr_block     = "10.10.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Need to set required variables from module, even though these are not supplied to the implementation
openvpn_dhcp_option_domain = ""
vpc_cidr_blocks            = [""]
vpc_id                     = ""
subnet_ids                 = [""]
openvpn_hostname           = ""
