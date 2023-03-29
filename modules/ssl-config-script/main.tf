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
##  ./modules/ssl-config-script/main.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

module "ssl_policy_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["ssl", "policy"]
}

data "aws_iam_role" "ec2_role" {
  count = module.ssl_policy_context.enabled ? 1 : 0
  name  = var.ec2_role_name
}

data "aws_iam_policy_document" "ssl_access" {
  count   = module.ssl_policy_context.enabled ? 1 : 0
  version = "2012-10-17"
  statement {
    sid = "DecryptSslKey"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    effect = "Allow"
    resources = [
      var.ssl_secret_kms_key_arn
    ]
  }
  statement {
    sid = "GetSslSecret"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    effect = "Allow"
    resources = [
      var.ssl_secret_arn
    ]
  }
}

resource "aws_iam_role_policy" "ssl_access" {
  count  = module.ssl_policy_context.enabled ? 1 : 0
  policy = join("", data.aws_iam_policy_document.ssl_access[*].json)
  role   = var.ec2_role_name
  name   = module.ssl_policy_context.id
}


#------------------------------------------------------------------------------
# SSM Document SSL Configuration Script
#------------------------------------------------------------------------------
resource "aws_ssm_document" "ssl_config_script" {
  count           = module.context.enabled ? 1 : 0
  name            = module.ssl_policy_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ssl_policy_context.tags
  content = templatefile("${path.module}/templates/ssm-composite-initializer.tftpl", {
    secret_arn                      = var.ssl_secret_arn,
    region                          = data.aws_region.current.name,
    certificate_keyname             = var.ssl_secret_certificate_keyname
    certificate_bundle_keyname      = var.ssl_secret_certificate_bundle_keyname
    certificate_private_key_keyname = var.ssl_secret_certificate_private_key_keyname
  })
}

resource "aws_ssm_association" "ssl_config_script" {
  count               = module.context.enabled ? 1 : 0
  association_name    = module.ssl_policy_context.id
  name                = one(aws_ssm_document.ssl_config_script[*].name)
  schedule_expression = var.ssm_documents_schedule_expression == null ? "" : var.ssm_documents_schedule_expression
  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
}

