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
##  ./modules/mysql-config-script/main.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

module "ec2_rds_policy_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["rds", "policy"]
}

resource "aws_s3_object" "openvpn_init_mysql_script" {
  count  = module.ec2_rds_policy_context.enabled ? 1 : 0
  bucket = var.bucket_id
  key    = var.script_name
  content = templatefile("${path.module}/mysql.sh.tftpl", {
    rds_host               = var.rds_mysql_instance_address,
    rds_secret_arn         = var.rds_secret_arn
    rds_admin_username_key = var.rds_secret_admin_username_keyname
    rds_admin_password_key = var.rds_secret_admin_password_keyname
    rds_port_key           = var.rds_secret_port_keyname
    region                 = data.aws_region.current.name
  })
}

data "aws_iam_role" "ec2_role" {
  count = module.ec2_rds_policy_context.enabled ? 1 : 0
  name  = var.ec2_role_name
}

data "aws_iam_policy_document" "rds_secrets_access" {
  count   = module.ec2_rds_policy_context.enabled ? 1 : 0
  version = "2012-10-17"
  statement {
    sid = "DecryptRdsSecretsKey"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    effect = "Allow"
    resources = [
      var.rds_secret_kms_key_arn
    ]
  }
  statement {
    sid = "GetRdsSecretValue"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    effect = "Allow"
    resources = [
      var.rds_secret_arn
    ]
  }
}

resource "aws_iam_role_policy" "rds_secrets_access" {
  count  = module.ec2_rds_policy_context.enabled ? 1 : 0
  policy = join("", data.aws_iam_policy_document.rds_secrets_access[*].json)
  role   = var.ec2_role_name
  name   = module.ec2_rds_policy_context.id
}
