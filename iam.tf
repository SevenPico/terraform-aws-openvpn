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
##  ./iam.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

module "ec2_autoscale_group_role_context" {
  source     = "app.terraform.io/SevenPico/context/null"
  version    = "1.0.2"
  context    = module.ec2_autoscale_group_context.self
  attributes = ["role"]
}

module "ec2_autoscale_group_lifecycle_role_context" {
  source          = "app.terraform.io/SevenPico/context/null"
  version         = "1.0.2"
  context         = module.ec2_autoscale_group_context.self
  attributes      = ["lifecycle", "role"]
  id_length_limit = 63
}

module "ec2_autoscale_group_lifecycle_policy_context" {
  source          = "app.terraform.io/SevenPico/context/null"
  version         = "1.0.2"
  context         = module.ec2_autoscale_group_context.self
  attributes      = ["lifecycle", "policy"]
  id_length_limit = 63
}

module "ec2_autoscale_group_sns_role_context" {
  source     = "app.terraform.io/SevenPico/context/null"
  version    = "1.0.2"
  context    = module.ec2_autoscale_group_sns_context.self
  attributes = ["role"]
}


#------------------------------------------------------------------------------
# EC2 VPN ASG IAM
#------------------------------------------------------------------------------
locals {
  #  secrets_arns_a = [one(data.aws_secretsmanager_secret.ssl.*.arn)]
  #  secrets_arns_b = [var.rds_secret_arn]
  current_region     = data.aws_region.current.name
  current_account_id = data.aws_caller_identity.current.account_id
}

data "aws_iam_policy_document" "ec2_autoscale_group_role_policy" {
  count   = module.ec2_autoscale_group_context.enabled ? 1 : 0
  version = "2012-10-17"

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectAcl"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${module.ec2_autoscale_group_scripts_bucket.bucket_id}",
      "arn:aws:s3:::${module.ec2_autoscale_group_scripts_bucket.bucket_id}/*"
    ]
  }
  statement {
    actions = [
      "s3:GetEncryptionConfiguration",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    effect = "Allow"
    resources = compact([
      "arn:aws:secretsmanager:${local.current_region}:${local.current_account_id}:secret:${module.ec2_autoscale_group_context.id}*",
      local.secret_arn,
    ])
  }
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ssm:UpdateInstanceInformation",
      "ssm:PutParameter"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.openvpn_ssm_association_output_bucket_name != null ? [1] : []
    content {
      actions = [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload",
      ]
      effect = "Allow"
      resources = [
        "arn:aws:s3:::${var.openvpn_ssm_association_output_bucket_name}",
        "arn:aws:s3:::${var.openvpn_ssm_association_output_bucket_name}/*"
      ]
    }
  }

  dynamic "statement" {
    for_each = local.secret_kms_key_arn != null ? [1] : []
    content {
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
      ]
      effect = "Allow"
      resources = compact([
        local.secret_kms_key_arn,
      ])
    }
  }
}

module "ec2_autoscale_group_role" {
  source  = "app.terraform.io/SevenPico/iam-role/aws"
  version = "0.16.2.1"
  context = module.ec2_autoscale_group_role_context.self

  assume_role_actions      = ["sts:AssumeRole"]
  assume_role_conditions   = []
  instance_profile_enabled = false
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
  max_session_duration  = 3600
  path                  = "/"
  permissions_boundary  = ""
  policy_description    = "VPN Server Permissions"
  policy_document_count = 1
  policy_documents      = concat([join("", data.aws_iam_policy_document.ec2_autoscale_group_role_policy.*.json)], var.ec2_additional_instance_role_policies)
  principals = {
    Service : [
      "ec2.amazonaws.com",
      "ssm.amazonaws.com"
    ]
  }
  role_description = "IAM role with permissions to perform actions required by the VPN Server"
  use_fullname     = true
}

resource "aws_iam_role_policy_attachment" "ec2_autoscale_group_ssm_management" {
  count      = module.ec2_autoscale_group_role_context.enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = module.ec2_autoscale_group_role.name
}

resource "aws_iam_instance_profile" "ec2_autoscale_group_instance_profile" {
  count = module.ec2_autoscale_group_role_context.enabled ? 1 : 0
  name  = "${module.ec2_autoscale_group_context.id}-instance-profile"
  role  = module.ec2_autoscale_group_role.name
}


#------------------------------------------------------------------------------
# EC2 VPN ASG Lifecycle IAM
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_autoscale_group_lifecycle_assume_role" {
  count = module.ec2_autoscale_group_lifecycle_role_context.enabled ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "autoscaling.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "ec2_autoscale_group_lifecycle_role" {
  count              = module.ec2_autoscale_group_lifecycle_role_context.enabled ? 1 : 0
  name               = module.ec2_autoscale_group_lifecycle_role_context.id
  assume_role_policy = one(data.aws_iam_policy_document.ec2_autoscale_group_lifecycle_assume_role[*].json)
}

data "aws_iam_policy_document" "ec2_autoscale_group_lifecycle_role_policy" {
  count = module.ec2_autoscale_group_lifecycle_role_context.enabled ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:DescribeTags",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:CompleteLifecycleAction"
    ]
    resources = [
      module.ec2_autoscale_group.autoscaling_group_arn
    ]
  }
  #  statement {
  #    effect = "Allow"
  #    actions = [
  #      "sns:Publish"
  #    ]
  #    resources = [
  #      aws_sns_topic.ec2_autoscale_group[*].arn
  #    ]
  #  }
}

resource "aws_iam_role_policy" "ec2_autoscale_group_lifecycle_policy" {
  count  = module.ec2_autoscale_group_lifecycle_role_context.enabled ? 1 : 0
  name   = module.ec2_autoscale_group_lifecycle_policy_context.id
  role   = one(aws_iam_role.ec2_autoscale_group_lifecycle_role[*].id)
  policy = one(data.aws_iam_policy_document.ec2_autoscale_group_lifecycle_role_policy[*].json)
}


#------------------------------------------------------------------------------
# EC2 VPN SNS IAM
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_autoscale_group_lifecycle_role_sns_policy" {
  count = module.ec2_autoscale_group_lifecycle_role_context.enabled && module.ec2_autoscale_group_sns_context.enabled ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      one(aws_sns_topic.ec2_autoscale_group[*].arn)
    ]
  }
}

resource "aws_iam_role_policy" "ec2_autoscale_group_lifecycle_sns_policy" {
  count  = module.ec2_autoscale_group_lifecycle_role_context.enabled && module.ec2_autoscale_group_sns_context.enabled ? 1 : 0
  name   = "${module.ec2_autoscale_group_lifecycle_policy_context.id}-sns"
  role   = one(aws_iam_role.ec2_autoscale_group_lifecycle_role[*].id)
  policy = one(data.aws_iam_policy_document.ec2_autoscale_group_lifecycle_role_sns_policy[*].json)
}

data "aws_iam_policy_document" "ec2_autoscale_group_sns_assume_role" {
  count = module.ec2_autoscale_group_sns_role_context.enabled ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "sns.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "ec2_autoscale_group_sns" {
  count              = module.ec2_autoscale_group_sns_role_context.enabled ? 1 : 0
  name               = module.ec2_autoscale_group_sns_role_context.id
  assume_role_policy = one(data.aws_iam_policy_document.ec2_autoscale_group_sns_assume_role[*].json)
}

data "aws_iam_policy_document" "ec2_autoscale_group_sns_policy" {
  count = module.ec2_autoscale_group_sns_role_context.enabled ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutMetricFilter",
      "logs:PutRetentionPolicy"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ec2_openvpn_asg_iam_sns_policy" {
  count  = module.ec2_autoscale_group_sns_role_context.enabled ? 1 : 0
  name   = "${module.ec2_autoscale_group_sns_role_context.id}-policy"
  role   = one(aws_iam_role.ec2_autoscale_group_sns[*].id)
  policy = one(data.aws_iam_policy_document.ec2_autoscale_group_sns_policy[*].json)
}
