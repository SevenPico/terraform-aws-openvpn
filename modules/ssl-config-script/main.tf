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

resource "aws_s3_object" "ssl_cert_sh" {
  count  = module.ssl_policy_context.enabled ? 1 : 0
  bucket = var.bucket_id
  key    = var.script_name
  content = templatefile("${path.module}/ssl.sh.tftpl", {
    secret_arn                      = var.ssl_secret_arn,
    region                          = data.aws_region.current.name,
    certificate_keyname             = var.ssl_secret_certificate_keyname
    certificate_bundle_keyname      = var.ssl_secret_certificate_bundle_keyname
    certificate_private_key_keyname = var.ssl_secret_certificate_private_key_keyname
  })
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

