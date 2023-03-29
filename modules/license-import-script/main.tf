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
##  ./modules/license-import-script/main.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

module "license_sh_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["license"]
}

data "aws_secretsmanager_secret" "this" {
  count = module.license_sh_context.enabled ? 1 : 0
  arn   = var.secrets_arn
}

data "aws_secretsmanager_secret_version" "this" {
  count         = module.license_sh_context.enabled ? 1 : 0
  secret_id     = data.aws_secretsmanager_secret.this[0].id
  version_stage = "AWSCURRENT"
}


data "aws_iam_role" "this" {
  count = module.license_sh_context.enabled ? 1 : 0
  name  = var.ec2_role_name
}

data "aws_iam_policy_document" "this" {
  count   = module.license_sh_context.enabled ? 1 : 0
  version = "2012-10-17"
  statement {
    sid = "DecryptSslKey"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    effect = "Allow"
    resources = [
      var.secrets_kms_key_arn
    ]
  }
  statement {
    sid = "GetSslSecret"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    effect = "Allow"
    resources = [
      var.secrets_arn
    ]
  }
}

resource "aws_iam_role_policy" "this" {
  count  = module.license_sh_context.enabled ? 1 : 0
  policy = join("", data.aws_iam_policy_document.this[*].json)
  role   = var.ec2_role_name
  name   = module.license_sh_context.id
}


#------------------------------------------------------------------------------
# SSM Document  License
#------------------------------------------------------------------------------
resource "aws_ssm_document" "license" {
  count           = module.context.enabled ? 1 : 0
  name            = module.license_sh_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.license_sh_context.tags
  content = templatefile("${path.module}/templates/ssm-composite-initializer.tftpl", {
    secret_arn = var.secrets_arn
    keyname    = var.secrets_licence_keyname
    region     = data.aws_region.current.name
  })
}

resource "aws_ssm_association" "license" {
  count               = module.context.enabled ? 1 : 0
  association_name    = module.license_sh_context.id
  name                = one(aws_ssm_document.license[*].name)
  schedule_expression = var.ssm_documents_schedule_expression == null ? "" : var.ssm_documents_schedule_expression
  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
}

