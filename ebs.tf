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
##  ./ebs.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

resource "aws_ebs_volume" "openvpn_ebs_volume" {
  count             = module.context.enabled && var.ebs_enable ? 1 : 0
  availability_zone = var.availibilty_zone
  encrypted         = true
  kms_key_id        = module.secret_kms_key.key_id
  size              = 10
  type              = "standard"
}