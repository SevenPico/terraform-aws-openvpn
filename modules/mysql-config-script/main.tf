module "ec2_rds_policy_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.this.context
  attributes = ["rds", "policy"]
}

resource "aws_s3_object" "openvpn_init_mysql_script" {
  count  = module.ec2_rds_policy_meta.enabled ? 1 : 0
  bucket = var.bucket_id
  key    = var.script_name
  content = templatefile("${path.module}/mysql.sh.tftpl", {
    rds_host               = var.rds_mysql_instance_address,
    rds_secret_arn         = var.rds_secret_arn
    rds_admin_username_key = var.rds_secret_admin_username_keyname
    rds_admin_password_key = var.rds_secret_admin_password_keyname
    rds_port_key           = var.rds_secret_port_keyname
    region                 = length(data.aws_region.current) > 0 ? one(data.aws_region.current[*].name) : ""
  })
}

data "aws_iam_role" "ec2_role" {
  count   = module.ec2_rds_policy_meta.enabled ? 1 : 0
  name = var.ec2_role_name
}

data "aws_iam_policy_document" "rds_secrets_access" {
  count   = module.ec2_rds_policy_meta.enabled ? 1 : 0
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
    resources = data.aws_iam_role.ec2_role.*.arn
  }
}

resource "aws_iam_role_policy" "rds_secrets_access" {
  count  = module.ec2_rds_policy_meta.enabled ? 1 : 0
  policy = join("", data.aws_iam_policy_document.rds_secrets_access[*].json)
  role   = var.ec2_role_name
  name   = module.ec2_rds_policy_meta.id
}
