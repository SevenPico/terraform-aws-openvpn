#------------------------------------------------------------------------------
# Secrets Manager Labels
#------------------------------------------------------------------------------
module "secret_context" {
  source     = "app.terraform.io/SevenPico/context/null"
  version    = "1.0.2"
  context    = module.context.self
  enabled = module.context.enabled && var.create_openvpn_secret
  attributes = ["secret"]
}

module "secret_kms_context" {
  source  = "app.terraform.io/SevenPico/context/null"
  version = "1.0.2"
  context = module.secret_context.self
}

locals {
  secret_arn = module.secret_context.enabled ? one(aws_secretsmanager_secret.this[*].arn) : var.openvpn_secret_arn
  secret_kms_key_arn = module.secret_context.enabled  ? module.secret_kms_key.key_arn : var.openvpn_secret_kms_key_arn
}


#------------------------------------------------------------------------------
# Secrets Manager KMS Key
#------------------------------------------------------------------------------
module "secret_kms_key" {
  source  = "registry.terraform.io/cloudposse/kms-key/aws"
  version = "0.12.1"
  context = module.secret_kms_context.self

  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 30
  description              = "KMS key for ${module.secret_context.id}"
  enable_key_rotation      = var.openvpn_secret_enable_kms_key_rotation
  key_usage                = "ENCRYPT_DECRYPT"
}


#------------------------------------------------------------------------------
# Secrets Manager
#------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "this" {
  count       = module.secret_context.enabled ? 1 : 0
  name_prefix = "${module.secret_context.id}-"
  tags        = module.secret_context.tags
  kms_key_id  = module.secret_kms_key.key_id
  description = "Secrets and environment variables for ${module.context.id}"
  lifecycle {
    ignore_changes  = [name, description, tags]
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  count     = module.secret_context.enabled ? 1 : 0
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
  count   = module.secret_context.enabled ? 1 : 0
  length  = 32
  special = false
}
