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
  context    = module.context.self
  attributes = ["initialization"]
}

module "ec2_autoscale_group_ssm_vpn_restore_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["restore"]
}

module "ec2_autoscale_group_ssm_vpn_backup_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["backup"]
  enabled    = var.ec2_backup_enabled && module.context.enabled
}

module "ec2_autoscale_group_ssm_ssl_certificate_refresh_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["ssl", "certificate", "refresh"]
}

#------------------------------------------------------------------------------
# EC2 VPN SSM Document for VPN Initialization
#------------------------------------------------------------------------------
resource "aws_ssm_document" "ec2_autoscale_group_initialization" {
  count           = module.context.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_initialization_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_initialization_context.tags
  content = templatefile("${path.module}/scripts/ssm-vpn-initialize.tftpl", {
    environment           = module.ec2_autoscale_group_ssm_initialization_context.environment
    scripts_bucket_id     = module.ec2_autoscale_group_scripts_bucket.bucket_id
    region                = one(data.aws_region.current[*].name)
    config_cmds           = local.openvpn_config_scripts
    time_zone             = var.openvpn_time_zone
    init_document         = aws_ssm_document.ec2_autoscale_group_init[0].name
    init_default_document = aws_ssm_document.ec2_autoscale_group_init_default[0].name
    openvpn_document      = aws_ssm_document.ec2_autoscale_group_openvpn[0].name
  })
}

resource "aws_ssm_association" "ec2_autoscale_group_initialization" {
  count               = module.context.enabled ? 1 : 0
  association_name    = module.ec2_autoscale_group_ssm_initialization_context.id
  name                = one(aws_ssm_document.ec2_autoscale_group_initialization[*].name)
  schedule_expression = var.ec2_initialization_schedule_expression
  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
  dynamic "output_location" {
    for_each = var.openvpn_ssm_association_output_bucket_name != null ? [1] : []
    content {
      s3_bucket_name = var.openvpn_ssm_association_output_bucket_name
      s3_key_prefix  = one(aws_ssm_document.ec2_autoscale_group_initialization[*].name)
    }
  }
}

resource "aws_ssm_document" "ec2_autoscale_group_init" {
  count           = module.context.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_initialization_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_initialization_context.tags
  content = templatefile("${path.module}/scripts/init.tftpl", {
    hostname = var.openvpn_hostname
    region   = data.aws_region.current.name
  })
}

resource "aws_ssm_document" "ec2_autoscale_group_init_default" {
  count           = module.context.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_initialization_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_initialization_context.tags
  content = templatefile("${path.module}/scripts/install-default.tftpl", {
    openvpnas_version = var.openvpn_version
  })
}

resource "aws_ssm_document" "ec2_autoscale_group_openvpn" {
  count           = module.context.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_initialization_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_initialization_context.tags
  content = templatefile("${path.module}/scripts/openvpn.tftpl", {
    hostname                   = var.openvpn_hostname
    webserver_name             = var.openvpn_web_server_name,
    ui_https_port              = var.openvpn_ui_https_port == null ? "" : var.openvpn_ui_https_port
    daemon_udp_port            = var.openvpn_daemon_udp_port == null ? "" : var.openvpn_daemon_udp_port
    daemon_tcp_port            = var.openvpn_daemon_tcp_port == null ? "" : var.openvpn_daemon_tcp_port
    dhcp_option_domain         = var.openvpn_dhcp_option_domain,
    client_dhcp_network        = var.openvpn_client_dhcp_network
    client_dhcp_network_mask   = var.openvpn_client_dhcp_network_mask
    openvpn_client_cidr_blocks = join(" ", var.openvpn_client_cidr_blocks),
    vpc_cidr_blocks            = join(" ", var.vpc_cidr_blocks)
    password_secret_arn        = local.secret_arn
    password_secret_key        = var.openvpn_secret_admin_password_key
    region                     = local.current_region
    tls_version_min            = var.openvpn_tls_version_min
    enable_vpn_server_nat      = var.openvpn_enable_server_nat
  })
}


#------------------------------------------------------------------------------
# EC2 VPN SSM Document for VPN Back Up
#------------------------------------------------------------------------------
resource "aws_ssm_document" "ec2_autoscale_group_ssm_vpn_backup" {
  count           = module.ec2_autoscale_group_ssm_vpn_backup_context.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_vpn_backup_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_vpn_backup_context.tags
  content = templatefile("${path.module}/scripts/ssm-vpn-backup.tftpl", {
    region        = one(data.aws_region.current[*].name)
    s3_bucket     = module.ec2_autoscale_group_scripts_bucket.bucket_id
    s3_backup_key = "backups/openvpn_backup.tar.gz"
    backup_sqlite_install = aws_ssm_document.ec2_autoscale_group_ssm_backup_sqlite[0].name
  })
}

resource "aws_ssm_document" "ec2_autoscale_group_ssm_backup_sqlite" {
  count           = module.ec2_autoscale_group_ssm_vpn_backup_context.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_vpn_backup_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_vpn_backup_context.tags
  content = templatefile("${path.module}/scripts/backup-sqlite-install.tftpl", {
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
    values = [module.context.id]
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
  count           = module.context.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_vpn_restore_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_vpn_restore_context.tags
  content = templatefile("${path.module}/scripts/ssm-vpn-restore.tftpl", {
    region            = one(data.aws_region.current[*].name)
    s3_bucket         = module.ec2_autoscale_group_scripts_bucket.bucket_id
    s3_backup_key     = "backups/openvpn_backup.tar.gz"
    backup_version_id = ""
  })
}


#------------------------------------------------------------------------------
# EC2 VPN SSM Document for EFS mount
#------------------------------------------------------------------------------
resource "aws_ssm_document" "ec2_autoscale_group_ssm_install_with_efs_sh" {
  count           = module.context.enabled && var.efs_enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_vpn_restore_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_vpn_restore_context.tags
  content = templatefile("${path.module}/scripts/install-with-efs.tftpl", {
    openvpnas_version         = var.openvpn_version
    efs_mount_target_dns_name = module.efs.mount_target_dns_names[0]
    s3_backup_bucket          = module.ec2_autoscale_group_scripts_bucket.bucket_id
    s3_backup_key             = "backups/openvpn_backup_pre_install.tar.gz"
  })
}


#------------------------------------------------------------------------------
# EC2 VPN SSM Document for EBS mount
#------------------------------------------------------------------------------
resource "aws_ssm_document" "ec2_autoscale_group_ssm_install_with_ebs" {
  count           = module.context.enabled && var.ebs_enable ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_vpn_restore_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_vpn_restore_context.tags
  content = templatefile("${path.module}/scripts/install-with-ebs.tftpl", {
    openvpnas_version     = var.openvpn_version
    efs_mount_target_name = "/dev/xvdf"
    s3_backup_bucket      = module.ec2_autoscale_group_scripts_bucket.bucket_id
    s3_backup_key         = "backups/openvpn_backup_pre_install.tar.gz"
  })
}

