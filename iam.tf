module "ec2_autoscale_group_role_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.ec2_autoscale_group_meta.context
  attributes = ["role"]
}


module "ec2_autoscale_group_lifecycle_role_meta" {
  source          = "registry.terraform.io/cloudposse/label/null"
  version         = "0.25.0"
  context         = module.ec2_autoscale_group_meta.context
  attributes      = ["lifecycle", "role"]
  id_length_limit = 63
}

module "ec2_autoscale_group_lifecycle_policy_meta" {
  source          = "registry.terraform.io/cloudposse/label/null"
  version         = "0.25.0"
  context         = module.ec2_autoscale_group_meta.context
  attributes      = ["lifecycle", "policy"]
  id_length_limit = 63
}

module "ec2_autoscale_group_sns_role_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.ec2_autoscale_group_sns_meta.context
  attributes = ["role"]
}


#------------------------------------------------------------------------------
# EC2 VPN ASG IAM
#------------------------------------------------------------------------------
locals {
  #  secrets_arns_a = [one(data.aws_secretsmanager_secret.ssl.*.arn)]
  #  secrets_arns_b = [var.rds_secret_arn]
  current_region     = length(data.aws_region.current) > 0 ? one(data.aws_region.current[*].name) : ""
  current_account_id = length(data.aws_caller_identity.current) > 0 ? one(data.aws_caller_identity.current[*].account_id) : ""
}

data "aws_iam_policy_document" "ec2_autoscale_group_policy" {
  count   = module.ec2_autoscale_group_meta.enabled ? 1 : 0
  version = "2012-10-17"
  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    effect = "Allow"
    resources = [
      module.ec2_autoscale_group_secrets_kms_key.key_arn
    ]
  }

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
    resources = [
      "arn:aws:secretsmanager:${local.current_region}:${local.current_account_id}:secret:${module.ec2_autoscale_group_meta.id}*"
    ]
  }
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ssm:UpdateInstanceInformation"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

module "ec2_autoscale_group_role" {
  source  = "registry.terraform.io/cloudposse/iam-role/aws"
  version = "0.13.0"
  context = module.ec2_autoscale_group_role_meta.context

  policy_description    = "VPN Server Permissions"
  role_description      = "IAM role with permissions to perform actions required by the VPN Server"
  assume_role_actions   = ["sts:AssumeRole"]
  max_session_duration  = 3600
  policy_document_count = 1
  policy_documents = [
    join("", data.aws_iam_policy_document.ec2_autoscale_group_policy.*.json)
  ]
  principals = {
    Service : [
      "ec2.amazonaws.com",
      "ssm.amazonaws.com"
    ]
  }
  use_fullname = true
}

resource "aws_iam_role_policy_attachment" "ec2_autoscale_group_ssm_management" {
  count      = module.ec2_autoscale_group_role_meta.enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = module.ec2_autoscale_group_role.name
}

resource "aws_iam_instance_profile" "ec2_autoscale_group_instance_profile" {
  count = module.ec2_autoscale_group_role_meta.enabled ? 1 : 0
  name  = "${module.ec2_autoscale_group_meta.id}-instance-profile"
  role  = module.ec2_autoscale_group_role.name
}


#------------------------------------------------------------------------------
# EC2 VPN ASG Lifecycle IAM
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_autoscale_group_lifecycle_assume_role" {
  count = module.ec2_autoscale_group_lifecycle_role_meta.enabled ? 1 : 0
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
  count              = module.ec2_autoscale_group_lifecycle_role_meta.enabled ? 1 : 0
  name               = module.ec2_autoscale_group_lifecycle_role_meta.id
  assume_role_policy = data.aws_iam_policy_document.ec2_autoscale_group_lifecycle_assume_role[0].json
}

data "aws_iam_policy_document" "ec2_autoscale_group_lifecycle_role_policy" {
  count = module.ec2_autoscale_group_lifecycle_role_meta.enabled ? 1 : 0
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
  #      aws_sns_topic.ec2_autoscale_group[0].arn
  #    ]
  #  }
}

resource "aws_iam_role_policy" "ec2_autoscale_group_lifecycle_policy" {
  count  = module.ec2_autoscale_group_lifecycle_role_meta.enabled ? 1 : 0
  name   = module.ec2_autoscale_group_lifecycle_policy_meta.id
  role   = aws_iam_role.ec2_autoscale_group_lifecycle_role[0].id
  policy = data.aws_iam_policy_document.ec2_autoscale_group_lifecycle_role_policy[0].json
}


#------------------------------------------------------------------------------
# EC2 VPN SNS IAM
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_autoscale_group_lifecycle_role_sns_policy" {
  count = module.ec2_autoscale_group_lifecycle_role_meta.enabled && module.ec2_autoscale_group_sns_meta.enabled ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      aws_sns_topic.ec2_autoscale_group[0].arn
    ]
  }
}

resource "aws_iam_role_policy" "ec2_autoscale_group_lifecycle_sns_policy" {
  count  = module.ec2_autoscale_group_lifecycle_role_meta.enabled && module.ec2_autoscale_group_sns_meta.enabled ? 1 : 0
  name   = module.ec2_autoscale_group_lifecycle_policy_meta.id
  role   = aws_iam_role.ec2_autoscale_group_lifecycle_role[0].id
  policy = data.aws_iam_policy_document.ec2_autoscale_group_lifecycle_role_sns_policy[0].json
}

data "aws_iam_policy_document" "ec2_autoscale_group_sns_assume_role" {
  count = module.ec2_autoscale_group_sns_role_meta.enabled ? 1 : 0
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
  count              = module.ec2_autoscale_group_sns_role_meta.enabled ? 1 : 0
  name               = module.ec2_autoscale_group_sns_role_meta.id
  assume_role_policy = data.aws_iam_policy_document.ec2_autoscale_group_sns_assume_role[0].json
}

data "aws_iam_policy_document" "ec2_autoscale_group_sns_policy" {
  count = module.ec2_autoscale_group_sns_role_meta.enabled ? 1 : 0
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
  count  = module.ec2_autoscale_group_sns_role_meta.enabled ? 1 : 0
  name   = "${module.ec2_autoscale_group_sns_role_meta.id}-policy"
  role   = aws_iam_role.ec2_autoscale_group_sns[0].id
  policy = data.aws_iam_policy_document.ec2_autoscale_group_sns_policy[0].json
}
