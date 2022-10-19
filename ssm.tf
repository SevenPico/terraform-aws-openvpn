module "ec2_autoscale_group_ssm_initialization_context" {
  source     = "app.terraform.io/SevenPico/context/null"
  version    = "1.0.2"
  context    = module.ec2_autoscale_group_context.self
  attributes = ["initialization"]
}

module "ec2_autoscale_group_ssm_ssl_certificate_refresh_context" {
  source     = "app.terraform.io/SevenPico/context/null"
  version    = "1.0.2"
  context    = module.ec2_autoscale_group_context.self
  attributes = ["ssl", "certificate", "refresh"]
}

#------------------------------------------------------------------------------
# EC2 VPN SSM Document for VPN Initialization
#------------------------------------------------------------------------------
resource "aws_ssm_document" "ec2_autoscale_group_initialization" {
  count           = module.ec2_autoscale_group_context.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_initialization_context.id
  document_format = "JSON"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_initialization_context.tags
  content = templatefile("${path.module}/scripts/ssm.tftpl", {
    environment       = module.ec2_autoscale_group_ssm_initialization_context.environment
    scripts_bucket_id = module.ec2_autoscale_group_scripts_bucket.bucket_id
    region            = one(data.aws_region.current[*].name)
    config_cmds       = local.openvpn_config_scripts
    time_zone         = var.openvpn_time_zone
  })
}

resource "aws_ssm_association" "ec2_autoscale_group_initialization" {
  count               = module.ec2_autoscale_group_context.enabled ? 1 : 0
  association_name    = module.ec2_autoscale_group_ssm_initialization_context.id
  name                = one(aws_ssm_document.ec2_autoscale_group_initialization[*].name)
  schedule_expression = var.ec2_initialization_schedule_expression
  targets {
    key    = "tag:Name"
    values = [module.ec2_autoscale_group_context.id]
  }
  dynamic "output_location" {
    for_each = var.openvpn_ssm_association_output_bucket_name != null ? [1] : []
    content {
      s3_bucket_name = var.openvpn_ssm_association_output_bucket_name
      s3_key_prefix  = one(aws_ssm_document.ec2_autoscale_group_initialization[*].name)
    }
  }
}
