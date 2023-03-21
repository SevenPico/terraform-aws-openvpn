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
##  ./s3.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

module "ec2_autoscale_group_scripts_bucket_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["scripts"]
}


locals {
  #  static_sh           = try(join("", aws_s3_object.static_client_addresses_sh[*].key), "")

  openvpn_config_scripts = concat(compact([
    #    local.static_sh
  ]), var.openvpn_config_scripts_additional)
}

# ------------------------------------------------------------------------------
# Openvpn S3 Bucket Policy
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "deployer_artifacts_bucket" {
  count = module.context.enabled ? 1 : 0

  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      module.ec2_autoscale_group_scripts_bucket.bucket_arn,
      "${module.ec2_autoscale_group_scripts_bucket.bucket_arn}/*"
    ]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}


#------------------------------------------------------------------------------
# VPN ASG Scripts Bucket
#------------------------------------------------------------------------------
module "ec2_autoscale_group_scripts_bucket" {
  source  = "SevenPicoForks/s3-bucket/aws"
  version = "4.0.0"
  context = module.ec2_autoscale_group_scripts_bucket_context.self

  acl                          = "private"
  allow_encrypted_uploads_only = false
  allow_ssl_requests_only      = false
  allowed_bucket_actions = [
    "s3:PutObject",
    "s3:PutObjectAcl",
    "s3:GetObject",
    "s3:DeleteObject",
    "s3:ListBucket",
    "s3:ListBucketMultipartUploads",
    "s3:GetBucketLocation",
    "s3:AbortMultipartUpload"
  ]
  block_public_acls             = true
  block_public_policy           = true
  bucket_key_enabled            = false
  bucket_name                   = null
  cors_rule_inputs              = null
  enable_mfa_delete             = var.openvpn_enable_mfa_delete
  force_destroy                 = var.openvpn_s3_force_destroy
  grants                        = []
  ignore_public_acls            = true
  kms_master_key_arn            = ""
  lifecycle_configuration_rules = var.openvpn_s3_lifecycle_configuration_rules
  logging = var.openvpn_s3_access_logs_s3_bucket_id != null ? {
    bucket_name = var.openvpn_s3_access_logs_s3_bucket_id
    prefix      = var.openvpn_s3_access_logs_prefix_override
  } : null
  object_lock_configuration     = null
  privileged_principal_actions  = []
  privileged_principal_arns     = []
  restrict_public_buckets       = true
  s3_object_ownership           = var.openvpn_s3_object_ownership
  s3_replica_bucket_arn         = ""
  s3_replication_enabled        = false
  s3_replication_rules          = null
  s3_replication_source_roles   = []
  source_policy_documents       = concat([one(data.aws_iam_policy_document.deployer_artifacts_bucket[*].json)], var.openvpn_s3_source_policy_documents)
  sse_algorithm                 = "AES256"
  transfer_acceleration_enabled = false
  user_enabled                  = false
  versioning_enabled            = var.openvpn_s3_versioning_enabled
  website_inputs                = null
  wait_time_seconds             = 120
}

resource "aws_s3_object" "cloudwatch_config_json" {
  count  = module.ec2_autoscale_group_scripts_bucket_context.enabled && var.cloudwatch_enabled ? 1 : 0
  bucket = module.ec2_autoscale_group_scripts_bucket.bucket_id
  key    = "cloudwatch-config.json"
  content = templatefile("${path.module}/scripts/cloudwatch-config.json.tftpl", {
    metrics_namespace = module.context.id
    log_group_name    = aws_cloudwatch_log_group.ec2_logs_group[0].name
  })
  depends_on = [module.ec2_autoscale_group_scripts_bucket]
}

resource "aws_s3_object" "static_client_addresses_sh" {
  count  = module.ec2_autoscale_group_scripts_bucket_context.enabled && var.openvpn_client_static_addresses_enabled ? 1 : 0
  bucket = module.ec2_autoscale_group_scripts_bucket.bucket_id
  key    = "static-client-addresses.sh"
  content = templatefile("${path.module}/scripts/static-client-addresses.sh.tftpl", {
    client_static_network      = var.openvpn_client_static_network,
    client_static_network_mask = var.openvpn_client_static_network_mask
  })
  depends_on = [module.ec2_autoscale_group_scripts_bucket]
}
