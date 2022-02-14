#------------------------------------------------------------------------------
# EC2 VPN Auto Scale Secrets - KMS Keys
#------------------------------------------------------------------------------
module "ec2_asg_kms_key" {
  source  = "registry.terraform.io/cloudposse/kms-key/aws"
  version = "0.12.1"
  context = module.asg_ec2_openvpn_secrets_kms_meta.context

  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 30
  description              = "KMS key for ${module.ec2_asg_secrets_meta.id}"
  enable_key_rotation      = false
  key_usage                = "ENCRYPT_DECRYPT"
}


#------------------------------------------------------------------------------
# EC2 VPN Auto Scale Secrets
#------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "ec2_asg" {
  count       = module.ec2_meta.enabled ? 1 : 0
  name_prefix = "${module.ec2_asg_secrets_meta.id}-"
  tags        = module.ec2_asg_secrets_meta.tags
  kms_key_id  = module.ec2_asg_kms_key.key_id
  description = "Environment Variables for the ${title(module.ec2_meta.id_full)}"
  lifecycle {
    ignore_changes  = [name, description, tags]
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "ec2_asg" {
  count     = module.ec2_meta.enabled ? 1 : 0
  secret_id = aws_secretsmanager_secret.ec2_asg[0].id
  lifecycle {
    ignore_changes  = [secret_string, secret_binary]
    prevent_destroy = false
  }
  secret_string = jsonencode({
    OPENVPN_LICENSE    = var.openvpn_license_filepath != null ? file(var.openvpn_license_filepath) : ""
    TIMEZONE           = var.openvpn_timezone
  })
}

data "aws_secretsmanager_secret_version" "ec2_asg" {
  count         = module.ec2_meta.enabled ? 1 : 0
  depends_on    = [aws_secretsmanager_secret_version.ec2_asg]
  secret_id     = aws_secretsmanager_secret.ec2_asg[0].id
  version_stage = "AWSCURRENT"
}
