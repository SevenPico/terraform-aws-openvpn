#------------------------------------------------------------------------------
# Secrets Manager Labels
#------------------------------------------------------------------------------
module "secret_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.this.context
  enabled = module.this.enabled && var.create_openvpn_secret
  attributes = ["secret"]
}

module "secret_kms_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.secret_meta.context
}

locals {
  secret_arn = module.secret_meta.enabled ? one(aws_secretsmanager_secret.this[*].arn) : var.openvpn_secret_arn
  secret_kms_key_arn = module.secret_meta.enabled  ? module.secret_kms_key.key_arn : var.openvpn_secret_kms_key_arn
}


#------------------------------------------------------------------------------
# Secrets Manager KMS Key
#------------------------------------------------------------------------------
module "secret_kms_key" {
  source  = "registry.terraform.io/cloudposse/kms-key/aws"
  version = "0.12.1"
  context = module.secret_kms_meta.context

  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 30
  description              = "KMS key for ${module.secret_meta.id}"
  enable_key_rotation      = var.openvpn_secret_enable_kms_key_rotation
  key_usage                = "ENCRYPT_DECRYPT"
}


#------------------------------------------------------------------------------
# Secrets Manager
#------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "this" {
  count       = module.secret_meta.enabled ? 1 : 0
  name_prefix = "${module.secret_meta.id}-"
  tags        = module.secret_meta.tags
  kms_key_id  = module.secret_kms_key.key_id
  description = "Secrets and environment variables for ${module.this.id}"
  lifecycle {
    ignore_changes  = [name, description, tags]
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  count     = module.secret_meta.enabled ? 1 : 0
  secret_id = one(aws_secretsmanager_secret.this[*].id)
  lifecycle {
    ignore_changes  = [secret_string, secret_binary]
    prevent_destroy = false
  }
  secret_string = jsonencode(merge(
    {
      ADMIN_USERNAME = "openvpn"
      "${var.openvpn_secret_admin_password_key}" = one(random_password.admin[*].result)
  }))
}

resource "random_password" "admin" {
  count   = module.secret_meta.enabled ? 1 : 0
  length  = 32
  special = false
}
