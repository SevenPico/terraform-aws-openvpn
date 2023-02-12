## ----------------------------------------------------------------------------
##  Copyright 2023 SevenPico, Inc.
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.
## ----------------------------------------------------------------------------

## ----------------------------------------------------------------------------
##  ./ssm.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

module "ec2_autoscale_group_ssm_initialization_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.ec2_autoscale_group_context.self
  attributes = ["initialization"]
}

module "ec2_autoscale_group_ssm_vpn_restore_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.ec2_autoscale_group_context.self
  attributes = ["restore"]
}

module "ec2_autoscale_group_ssm_vpn_backup_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.ec2_autoscale_group_context.self
  attributes = ["backup"]
  enabled    = var.ec2_backup_enabled && module.ec2_autoscale_group_context.enabled
}

module "ec2_autoscale_group_ssm_ssl_certificate_refresh_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
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
  content = templatefile("${path.module}/scripts/ssm-vpn-initialize.tftpl", {
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

#------------------------------------------------------------------------------
# EC2 VPN SSM Document for VPN Back Up
#------------------------------------------------------------------------------
resource "aws_ssm_document" "ec2_autoscale_group_ssm_vpn_backup" {
  count           = module.ec2_autoscale_group_ssm_vpn_backup_context.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_vpn_backup_context.id
  document_format = "JSON"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_vpn_backup_context.tags
  content = templatefile("${path.module}/scripts/ssm-vpn-backup.tftpl", {
    region        = one(data.aws_region.current[*].name)
    s3_bucket     = module.ec2_autoscale_group_scripts_bucket.bucket_id
    s3_backup_key = "backups/openvpn_backup.tar.gz"
  })
}

resource "aws_ssm_association" "ec2_autoscale_ssm_vpn_backup" {
  count                       = module.ec2_autoscale_group_ssm_vpn_backup_context.enabled ? 1 : 0
  association_name            = module.ec2_autoscale_group_ssm_vpn_backup_context.id
  name                        = one(aws_ssm_document.ec2_autoscale_group_ssm_vpn_backup[*].name)
  schedule_expression         = var.ec2_backup_schedule_expression
  apply_only_at_cron_interval = true
  compliance_severity         = "HIGH"
  parameters = {
    S3BUCKET    = module.ec2_autoscale_group_scripts_bucket.bucket_id
    S3BACKUPKEY = "backups/openvpn_backup_scheduled.tar.gz"
  }

  targets {
    key    = "tag:Name"
    values = [module.ec2_autoscale_group_context.id]
  }
  dynamic "output_location" {
    for_each = var.openvpn_ssm_association_output_bucket_name != null ? [1] : []
    content {
      s3_bucket_name = var.openvpn_ssm_association_output_bucket_name
      s3_key_prefix  = one(aws_ssm_document.ec2_autoscale_group_ssm_vpn_backup[*].name)
    }
  }
}


#------------------------------------------------------------------------------
# EC2 VPN SSM Document for VPN Restoration from Back Up
#------------------------------------------------------------------------------
resource "aws_ssm_document" "ec2_autoscale_group_ssm_vpn_restore" {
  count           = module.ec2_autoscale_group_context.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_vpn_restore_context.id
  document_format = "JSON"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_vpn_restore_context.tags
  content = templatefile("${path.module}/scripts/ssm-vpn-restore.tftpl", {
    region            = one(data.aws_region.current[*].name)
    s3_bucket         = module.ec2_autoscale_group_scripts_bucket.bucket_id
    s3_backup_key     = "backups/openvpn_backup.tar.gz"
    backup_version_id = ""
  })
}

