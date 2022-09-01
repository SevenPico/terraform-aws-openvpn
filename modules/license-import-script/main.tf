module "license_sh_context" {
  source     = "app.terraform.io/SevenPico/context/null"
  version    = "1.0.2"
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

resource "aws_s3_object" "this" {
  count  = module.license_sh_context.enabled ? 1 : 0
  bucket = var.bucket_id
  key    = "license.sh"
  content = templatefile("${path.module}/license.sh.tftpl", {
    secret_arn = var.secrets_arn
    keyname    = var.secrets_licence_keyname
    region     = data.aws_region.current[0].name
  })
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

