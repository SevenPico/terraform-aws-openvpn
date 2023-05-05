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

module "backups_bucket_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled && var.enable_openvpn_backups
  attributes = ["backups"]
}


# ------------------------------------------------------------------------------
# Openvpn S3 Bucket Policy
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "backups_bucket" {
  count                   = module.backups_bucket_context.enabled ? 1 : 0
  source_policy_documents = var.s3_source_policy_documents

  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      module.backups_bucket.bucket_arn,
      "${module.backups_bucket.bucket_arn}/*"
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
module "backups_bucket" {
  source  = "SevenPicoForks/s3-bucket/aws"
  version = "4.0.4"
  context = module.backups_bucket_context.self

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
  enable_mfa_delete             = false
  force_destroy                 = var.s3_force_destroy
  grants                        = []
  ignore_public_acls            = true
  kms_master_key_arn            = ""
  lifecycle_configuration_rules = var.s3_lifecycle_configuration_rules
  logging = var.s3_access_logs_s3_bucket_id != null ? {
    bucket_name = var.s3_access_logs_s3_bucket_id
    prefix      = var.s3_access_logs_prefix_override
  } : null
  object_lock_configuration     = null
  privileged_principal_actions  = []
  privileged_principal_arns     = []
  restrict_public_buckets       = true
  s3_object_ownership           = var.s3_object_ownership
  s3_replica_bucket_arn         = ""
  s3_replication_enabled        = false
  s3_replication_rules          = null
  s3_replication_source_roles   = []
  source_policy_documents       = data.aws_iam_policy_document.backups_bucket[*].json
  sse_algorithm                 = "AES256"
  transfer_acceleration_enabled = false
  user_enabled                  = false
  versioning_enabled            = var.s3_versioning_enabled
  website_inputs                = null
  wait_time_seconds             = 120
}
