#------------------------------------------------------------------------------
# OpenVpn Secret Labels
#------------------------------------------------------------------------------
module "openvpn_secret_context" {
  source     = "app.terraform.io/SevenPico/context/null"
  version    = "1.0.2"
  context    = module.context.self
  stage      = "openvpn"
  attributes = ["configuration"]
}

module "openvpn_secret_kms_context" {
  source  = "app.terraform.io/SevenPico/context/null"
  version = "1.0.2"
  context = module.openvpn_secret_context.self
}


#------------------------------------------------------------------------------
# OpenVpn Secret KMS Key
#------------------------------------------------------------------------------
module "openvpn_secret_kms_key" {
  source  = "registry.terraform.io/cloudposse/kms-key/aws"
  version = "0.12.1"
  context = module.openvpn_secret_kms_context.self

  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 30
  description              = "KMS key for ${module.openvpn_secret_context.id}"
  enable_key_rotation      = false
  key_usage                = "ENCRYPT_DECRYPT"
}


#------------------------------------------------------------------------------
# OpenVpn Secret
#------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "openvpn" {
  count       = module.openvpn_secret_context.enabled ? 1 : 0
  name_prefix = "${module.openvpn_secret_context.id}-"
  tags        = module.openvpn_secret_context.tags
  kms_key_id  = module.openvpn_secret_kms_key.key_id
  description = "Environment Variables for OpenVPN"
  lifecycle {
    ignore_changes  = [name, description, tags]
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "openvpn" {
  count     = module.openvpn_secret_context.enabled ? 1 : 0
  secret_id = aws_secretsmanager_secret.openvpn[0].id
  lifecycle {
    ignore_changes  = [secret_string, secret_binary]
    prevent_destroy = false
  }
  secret_string = jsonencode(merge(
    {
      OPENVPN_LICENSE : ""
      ADMIN_USERNAME = "openvpn"
      ADMIN_PASSWORD = one(random_password.openvpn_admin[*].result)
  }))
}

resource "random_password" "openvpn_admin" {
  count   = module.openvpn_secret_context.enabled ? 1 : 0
  length  = 32
  special = false
}
