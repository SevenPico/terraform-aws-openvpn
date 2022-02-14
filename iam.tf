#------------------------------------------------------------------------------
# EC2 VPN ASG IAM
#------------------------------------------------------------------------------
locals {
  secrets_arns_a = [var.ssl_certificate_secretsmanager_version_arn]
  secrets_arns_b = [var.rds_secretsmanager_version_arn]
  secrets_arns   = compact(concat(
    ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${module.vpn_ec2_meta.id}*"],
    local.secrets_arns_a,
    local.secrets_arns_b
  ))
}
data "aws_iam_policy_document" "ec2_openvpn_asg_policy" {
  count   = module.vpn_ec2_meta.enabled ? 1 : 0
  version = "2012-10-17"
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    effect = "Allow"
    resources = compact([
      var.ssl_certificate_secretsmanager_kms_key_arn,
      var.rds_secretsmanager_kms_key_arn,
      module.ec2_vpn_asg_kms_key.key_arn
    ])
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
      "arn:aws:s3:::${module.ec2_openvpn_scripts_bucket.bucket_id}",
      "arn:aws:s3:::${module.ec2_openvpn_scripts_bucket.bucket_id}/*"
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
    resources = local.secrets_arns
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

module "ec2_openvpn_asg_role" {
  source  = "registry.terraform.io/cloudposse/iam-role/aws"
  version = "0.13.0"
  context = module.asg_ec2_openvpn_role_meta.context

  policy_description    = "VPN Server Permissions"
  role_description      = "IAM role with permissions to perform actions required by the VPN Server"
  assume_role_actions   = ["sts:AssumeRole"]
  max_session_duration  = 3600
  policy_document_count = 1
  policy_documents = [
    data.aws_iam_policy_document.ec2_openvpn_asg_policy[0].json
  ]
  principals = {
    Service : [
      "ec2.amazonaws.com",
      "ssm.amazonaws.com"
    ]
  }
  use_fullname = true
}

resource "aws_iam_role_policy_attachment" "ec2_openvpn_asg_ssm_management" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = module.ec2_openvpn_asg_role.name
}

resource "aws_iam_instance_profile" "ec2_openvpn_asg_instance_profile" {
  name = "${module.vpn_ec2_meta.id}-instance-profile"
  role = module.ec2_openvpn_asg_role.name
}


#------------------------------------------------------------------------------
# EC2 VPN ASG Lifecycle IAM
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_openvpn_asg_iam_lifecycle" {
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

resource "aws_iam_role" "ec2_openvpn_asg_iam_lifecycle" {
  name               = module.asg_ec2_openvpn_lifecycle_role_meta.id
  assume_role_policy = data.aws_iam_policy_document.ec2_openvpn_asg_iam_lifecycle.json
}

data "aws_iam_policy_document" "ec2_openvpn_asg_iam_lifecycle_policy" {
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:DescribeTags",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:CompleteLifecycleAction"
    ]
    resources = [
      module.asg_ec2_openvpn.autoscaling_group_arn
    ]
  }
  #  statement {
  #    effect    = "Allow"
  #    actions   = [
  #      "sns:Publish"
  #    ]
  #    resources = [
  #      aws_sns_topic.ec2_openvpn_asg[0].arn
  #    ]
  #  }
}

resource "aws_iam_role_policy" "ec2_openvpn_asg_iam_lifecycle_policy" {
  name   = module.asg_ec2_openvpn_lifecycle_policy_meta.id
  role   = aws_iam_role.ec2_openvpn_asg_iam_lifecycle.id
  policy = data.aws_iam_policy_document.ec2_openvpn_asg_iam_lifecycle_policy.json
}


#------------------------------------------------------------------------------
# EC2 VPN SNS IAM
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_openvpn_asg_iam_sns" {
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

#resource "aws_iam_role" "ec2_openvpn_asg_iam_sns" {
#  name               = module.sns.id
#  assume_role_policy = data.aws_iam_policy_document.ec2_openvpn_asg_iam_sns.json
#}
#
#data "aws_iam_policy_document" "ec2_openvpn_asg_iam_sns_policy" {
#  statement {
#    effect    = "Allow"
#    actions   = [
#      "logs:CreateLogGroup",
#      "logs:CreateLogStream",
#      "logs:PutLogEvents",
#      "logs:PutMetricFilter",
#      "logs:PutRetentionPolicy"
#    ]
#    resources = ["*"]
#  }
#}
#
#resource "aws_iam_role_policy" "ec2_openvpn_asg_iam_sns_policy" {
#  name   = module.ec2_openvpn_asg_sns_policy_meta.id
#  role   = aws_iam_role.ec2_openvpn_asg_iam_sns.id
#  policy = data.aws_iam_policy_document.ec2_openvpn_asg_iam_sns_policy.json
#}
