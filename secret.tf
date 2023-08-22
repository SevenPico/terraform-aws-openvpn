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
##  ./secret.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Secrets Manager Labels
#------------------------------------------------------------------------------
module "secret_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled && var.create_openvpn_secret || var.preserve_if_disabled
  attributes = ["secret"]
}

locals {
  secret_arn         = module.secret_context.enabled || var.preserve_if_disabled ? module.secret.arn : var.openvpn_secret_arn
  secret_kms_key_arn = module.secret_context.enabled || var.preserve_if_disabled ? module.secret.key_arn : var.openvpn_secret_kms_key_arn
}


#------------------------------------------------------------------------------
# Secrets Manager
#------------------------------------------------------------------------------
locals {
  license_key = var.enable_licensing ? { "${var.ssl_license_key_keyname}" : "" } : {}
}

module "secret" {
  source  = "registry.terraform.io/SevenPico/secret/aws"
  version = "3.2.7"
  context = module.secret_context.self
  enabled = module.secret_context.enabled || var.preserve_if_disabled

  create_sns                      = false
  description                     = "Openvpn Username, Password and License Key"
  kms_key_deletion_window_in_days = var.openvpn_secret_kms_key_deletion_window_in_days
  kms_key_enable_key_rotation     = var.openvpn_secret_enable_kms_key_rotation
  kms_key_multi_region            = false
  secret_ignore_changes           = false
  secret_read_principals          = {}
  secret_string                   = jsonencode(merge(
    {
      ADMIN_USERNAME                             = "openvpn"
      "${var.openvpn_secret_admin_password_key}" = one(random_password.admin[*].result)
    },
    local.license_key
  ))
  sns_pub_principals              = {}
  sns_sub_principals              = {}
}

resource "random_password" "admin" {
  count   = module.secret_context.enabled || var.preserve_if_disabled ? 1 : 0
  length  = 32
  special = false
}
