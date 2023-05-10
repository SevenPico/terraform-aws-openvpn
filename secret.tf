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
  enabled    = module.context.enabled && var.create_openvpn_secret
  attributes = ["secret"]
}

module "secret_kms_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context = module.secret_context.self
}

locals {
  secret_arn         = module.secret_context.enabled ? one(aws_secretsmanager_secret.this[*].arn) : var.openvpn_secret_arn
  secret_kms_key_arn = module.secret_context.enabled ? module.secret_kms_key.key_arn : var.openvpn_secret_kms_key_arn
}


#------------------------------------------------------------------------------
# Secrets Manager KMS Key
#------------------------------------------------------------------------------
module "secret_kms_key" {
  source  = "cloudposse/kms-key/aws"
  version = "0.12.1"
  context = module.secret_kms_context.legacy

  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 30
  description              = "KMS key for ${module.secret_context.id}"
  enable_key_rotation      = var.openvpn_secret_enable_kms_key_rotation
  key_usage                = "ENCRYPT_DECRYPT"
}


#------------------------------------------------------------------------------
# Secrets Manager
#------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "this" {
  count       = module.secret_context.enabled ? 1 : 0
  name_prefix = "${module.secret_context.id}-"
  tags        = module.secret_context.tags
  kms_key_id  = module.secret_kms_key.key_id
  description = "Secrets and environment variables for ${module.context.id}"
  lifecycle {
    ignore_changes  = [name, description, tags]
    prevent_destroy = false
  }
}

locals {
  license_key = var.enable_licensing ? { "${var.ssl_license_key_keyname}" : "" } : {}
}

resource "aws_secretsmanager_secret_version" "this" {
  count     = module.secret_context.enabled ? 1 : 0
  secret_id = one(aws_secretsmanager_secret.this[*].id)
  lifecycle {
    ignore_changes  = [secret_string, secret_binary]
    prevent_destroy = false
  }
  secret_string = jsonencode(merge(
    {
      ADMIN_USERNAME                             = "openvpn"
      "${var.openvpn_secret_admin_password_key}" = one(random_password.admin[*].result)
    },
    local.license_key
  ))
}

resource "random_password" "admin" {
  count   = module.secret_context.enabled ? 1 : 0
  length  = 32
  special = false
}
