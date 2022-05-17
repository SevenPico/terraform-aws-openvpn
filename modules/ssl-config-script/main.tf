module "ssl_policy_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.this.context
  attributes = ["ssl", "policy"]
}

resource "aws_s3_object" "ssl_cert_sh" {
  count  = module.ssl_policy_meta.enabled ? 1 : 0
  bucket = var.bucket_id
  key    = var.script_name
  content = templatefile("${path.module}/ssl.sh.tftpl", {
    secret_arn                      = var.ssl_secret_arn,
    region                          = data.aws_region.current[0].name,
    certificate_keyname             = var.ssl_secret_certificate_keyname
    certificate_bundle_keyname      = var.ssl_secret_certificate_bundle_keyname
    certificate_private_key_keyname = var.ssl_secret_certificate_private_key_keyname
  })
}

data "aws_iam_role" "ec2_role" {
  count = module.ssl_policy_meta.enabled ? 1 : 0
  name  = var.ec2_role_name
}

data "aws_iam_policy_document" "ssl_access" {
  count   = module.ssl_policy_meta.enabled ? 1 : 0
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
  count  = module.ssl_policy_meta.enabled ? 1 : 0
  policy = join("", data.aws_iam_policy_document.ssl_access[*].json)
  role   = var.ec2_role_name
  name   = module.ssl_policy_meta.id
}

