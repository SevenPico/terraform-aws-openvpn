#------------------------------------------------------------------------------
# OpenVpn Secret Labels
#------------------------------------------------------------------------------
module "openvpn_secret_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.this.context
  stage      = "openvpn"
  attributes = ["configuration"]
}

module "openvpn_secret_kms_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.openvpn_secret_meta.context
}


#------------------------------------------------------------------------------
# OpenVpn Secret KMS Key
#------------------------------------------------------------------------------
module "openvpn_secret_kms_key" {
  source  = "registry.terraform.io/cloudposse/kms-key/aws"
  version = "0.12.1"
  context = module.openvpn_secret_kms_meta.context

  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 30
  description              = "KMS key for ${module.openvpn_secret_meta.id}"
  enable_key_rotation      = false
  key_usage                = "ENCRYPT_DECRYPT"
}


#------------------------------------------------------------------------------
# OpenVpn Secret
#------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "openvpn" {
  count       = module.openvpn_secret_meta.enabled ? 1 : 0
  name_prefix = "${module.openvpn_secret_meta.id}-"
  tags        = module.openvpn_secret_meta.tags
  kms_key_id  = module.openvpn_secret_kms_key.key_id
  description = "Environment Variables for OpenVPN"
  lifecycle {
    ignore_changes  = [name, description, tags]
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "openvpn" {
  count     = module.openvpn_secret_meta.enabled ? 1 : 0
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
  count   = module.openvpn_secret_meta.enabled ? 1 : 0
  length  = 32
  special = false
}
