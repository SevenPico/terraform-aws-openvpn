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
  enabled    = var.enable_openvpn_backups && module.context.enabled
}

module "ec2_autoscale_group_ssm_ssl_certificate_refresh_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["ssl", "certificate", "refresh"]
}

module "ec2_autoscale_group_ssm_upgrade_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["upgrade"]
}

module "license_sh_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["license"]
  enabled    = module.context.enabled && var.enable_licensing
}

module "nat_routing_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["nat", "routing"]
}

module "reverse_routing_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["reverse", "routing"]
}


module "ssl_policy_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["ssl", "policy"]
}


#------------------------------------------------------------------------------
# EC2 VPN SSM Document for VPN Initialization
#------------------------------------------------------------------------------
resource "aws_ssm_document" "composite_initializer" {
  count           = module.context.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_initialization_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_initialization_context.tags
  content = templatefile("${path.module}/templates/ssm-composite-initializer.tftpl", {
    environment       = module.ec2_autoscale_group_ssm_initialization_context.environment
    scripts_bucket_id = module.ec2_autoscale_group_scripts_bucket.bucket_id
    region            = try(data.aws_region.current[0].name, "")
    init_ec2_document = aws_ssm_document.init_ec2[0].name
    install_document  = !var.enable_efs ? aws_ssm_document.install_default[0].name : aws_ssm_document.install_with_efs[0].name
    configure_service = aws_ssm_document.configure_service[0].name
    upgrade_os        = aws_ssm_document.ec2_upgrade[0].name
    configure_routing = var.enable_nat ? aws_ssm_document.nat_routing_script[0].name : aws_ssm_document.reverse_routing_script[0].name
    configure_ssl     = var.enable_custom_ssl ? aws_ssm_document.ssl_config_script[0].name : ""
    license_import    = var.enable_licensing ? aws_ssm_document.license[0].name : ""
  })
}

resource "aws_ssm_association" "composite_initializer" {
  count               = module.context.enabled ? 1 : 0
  association_name    = module.ec2_autoscale_group_ssm_initialization_context.id
  name                = one(aws_ssm_document.composite_initializer[*].name)
  schedule_expression = var.ec2_initialization_schedule_expression
  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
  dynamic "output_location" {
    for_each = var.openvpn_ssm_association_output_bucket_name != null ? [1] : []
    content {
      s3_bucket_name = var.openvpn_ssm_association_output_bucket_name
      s3_key_prefix  = one(aws_ssm_document.composite_initializer[*].name)
    }
  }
}

resource "aws_ssm_document" "init_ec2" {
  count           = module.context.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_initialization_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_initialization_context.tags
  content = templatefile("${path.module}/templates/ssm-ec2-initialization.tftpl", {
    hostname = var.openvpn_hostname
    time_zone         = var.openvpn_time_zone
    region   = try(data.aws_region.current[0].name, "")
  })
}


#------------------------------------------------------------------------------
# EC2 VPN SSM Document for Installing with Defaults
#------------------------------------------------------------------------------
resource "aws_ssm_document" "install_default" {
  count           = module.context.enabled && !var.enable_efs ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_initialization_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_initialization_context.tags
  content = templatefile("${path.module}/templates/ssm-install-default.tftpl", {
    openvpnas_version = var.openvpn_version
  })
}


#------------------------------------------------------------------------------
# EC2 VPN SSM Document for Installing with EFS mount
#------------------------------------------------------------------------------
resource "aws_ssm_document" "install_with_efs" {
  count           = module.context.enabled && var.enable_efs ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_vpn_restore_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_vpn_restore_context.tags

  content = templatefile("${path.module}/templates/ssm-install-with-efs.tftpl", {
    openvpnas_version         = var.openvpn_version
    efs_mount_target_dns_name = module.efs.mount_target_dns_names[0]
    s3_backup_bucket          = module.ec2_autoscale_group_scripts_bucket.bucket_id
    s3_backup_key             = "backups/openvpn_backup_pre_install.tar.gz"
  })
}


#------------------------------------------------------------------------------
# EC2 VPN SSM Document for Configuring Service
#------------------------------------------------------------------------------
resource "aws_ssm_document" "configure_service" {
  count           = module.context.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_initialization_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_initialization_context.tags
  content = templatefile("${path.module}/templates/ssm-configure-service.tftpl", {
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
# EC2 VPN SSM Document for Sqlite Backup
#------------------------------------------------------------------------------
resource "aws_ssm_document" "ssm_backup_sqlite" {
  count           = module.ec2_autoscale_group_ssm_vpn_backup_context.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_vpn_backup_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_vpn_backup_context.tags
  content = templatefile("${path.module}/templates/ssm-vpn-backup.tftpl", {
    region        = try(data.aws_region.current[0].name,"")
    s3_bucket     = module.ec2_autoscale_group_scripts_bucket.bucket_id
    s3_backup_key = "backups/openvpn_backup.tar.gz"
  })
}

resource "aws_ssm_association" "ssm_vpn_backup" {
  count                       = module.ec2_autoscale_group_ssm_vpn_backup_context.enabled ? 1 : 0
  association_name            = module.ec2_autoscale_group_ssm_vpn_backup_context.id
  name                        = one(aws_ssm_document.ssm_backup_sqlite[*].name)
  schedule_expression         = var.openvpn_backup_schedule_expression
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
      s3_key_prefix  = one(aws_ssm_document.ssm_backup_sqlite[*].name)
    }
  }
}


#------------------------------------------------------------------------------
# EC2 VPN SSM Document for Sqlite Restoration from Back Up
#------------------------------------------------------------------------------
resource "aws_ssm_document" "ssm_vpn_restore" {
  count           = module.context.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_vpn_restore_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_vpn_restore_context.tags
  content = templatefile("${path.module}/templates/ssm-vpn-restore.tftpl", {
    region            = one(data.aws_region.current[*].name)
    s3_bucket         = module.ec2_autoscale_group_scripts_bucket.bucket_id
    s3_backup_key     = "backups/openvpn_backup.tar.gz"
    backup_version_id = ""
  })
}


#------------------------------------------------------------------------------
# EC2 VPN SSM Document for apt upgrade
#------------------------------------------------------------------------------
resource "aws_ssm_document" "ec2_upgrade" {
  count           = module.context.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_upgrade_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags    = module.ec2_autoscale_group_ssm_upgrade_context.tags
  content = templatefile("${path.module}/templates/ssm-ec2-upgrade.tftpl",{})

}

resource "aws_ssm_association" "ec2_upgrade" {
  count               = module.context.enabled ? 1 : 0
  association_name    = module.ec2_autoscale_group_ssm_upgrade_context.id
  name                = one(aws_ssm_document.ec2_upgrade[*].name)
  schedule_expression = var.ec2_upgrade_schedule_expression
  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
  apply_only_at_cron_interval = true
}


#------------------------------------------------------------------------------
# SSM Document  License
#------------------------------------------------------------------------------
resource "aws_ssm_document" "license" {
  count           = module.context.enabled && var.enable_licensing ? 1 : 0
  name            = module.license_sh_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.license_sh_context.tags
  content = templatefile("${path.module}/templates/ssm-configure-license.tftpl", {
    secret_arn = var.openvpn_secret_arn
    keyname    = "OPENVPN_LICENSE"
    region     = try(data.aws_region.current[0].name, "")
  })
}

resource "aws_ssm_association" "license" {
  count               = module.context.enabled && var.enable_licensing ? 1 : 0
  association_name    = module.license_sh_context.id
  name                = one(aws_ssm_document.license[*].name)
  schedule_expression = "cron(0 00 00 ? * * *)"
  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
}


#------------------------------------------------------------------------------
# SSM Document NAT Routing Configuration
#------------------------------------------------------------------------------
resource "aws_ssm_document" "nat_routing_script" {
  count           = module.context.enabled && var.enable_nat ? 1 : 0
  name            = module.nat_routing_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.nat_routing_context.tags
  content = templatefile("${path.module}/templates/ssm-configure-nat-routing.tftpl", {
    #    client_dhcp_network          = var.openvpn_client_dhcp_network,
    #    client_dhcp_network_mask     = var.openvpn_client_dhcp_network_mask,
    openvpn_client_cidr_blocks = join(" ", var.openvpn_client_cidr_blocks),
    vpc_cidr_blocks            = join(" ", var.vpc_cidr_blocks)
  })
}

resource "aws_ssm_association" "nat_routing_script" {
  count               = module.context.enabled && var.enable_nat ? 1 : 0
  association_name    = module.nat_routing_context.id
  name                = one(aws_ssm_document.nat_routing_script[*].name)
  schedule_expression = "cron(0 00 00 ? * * *)"
  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
}


#------------------------------------------------------------------------------
# SSM Document Reverse Routing Configuration
#------------------------------------------------------------------------------
resource "aws_ssm_document" "reverse_routing_script" {
  count           = module.context.enabled && !var.enable_nat ? 1 : 0
  name            = module.reverse_routing_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.reverse_routing_context.tags
  content = templatefile("${path.module}/templates/ssm-configure-reverse-routing.tftpl", {
    #    client_dhcp_network          = var.openvpn_client_dhcp_network,
    #    client_dhcp_network_mask     = var.openvpn_client_dhcp_network_mask,
    openvpn_client_cidr_blocks = join(" ", var.openvpn_client_cidr_blocks),
    vpc_cidr_blocks            = join(" ", var.vpc_cidr_blocks)
  })
}

resource "aws_ssm_association" "reverse_routing_script" {
  count               = module.context.enabled ? 1 : 0
  association_name    = module.reverse_routing_context.id
  name                = one(aws_ssm_document.reverse_routing_script[*].name)
  schedule_expression = "cron(0 00 00 ? * * *)"
  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
}


#------------------------------------------------------------------------------
# SSM Document SSL Configuration Script
#------------------------------------------------------------------------------
resource "aws_ssm_document" "ssl_config_script" {
  count           = module.context.enabled && var.enable_custom_ssl ? 1 : 0
  name            = module.ssl_policy_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ssl_policy_context.tags
  content = templatefile("${path.module}/templates/ssm-configure-ssl.tftpl", {
    secret_arn                      = var.ssl_secret_arn,
    region                          = try(data.aws_region.current[0].name, ""),
    certificate_keyname             = var.ssl_secret_certificate_keyname,
    certificate_bundle_keyname      = var.ssl_secret_certificate_bundle_keyname,
    certificate_private_key_keyname = var.ssl_secret_certificate_private_key_keyname
  })
}

resource "aws_ssm_association" "ssl_config_script" {
  count               = module.context.enabled ? 1 : 0
  association_name    = module.ssl_policy_context.id
  name                = one(aws_ssm_document.ssl_config_script[*].name)
  schedule_expression = "cron(0 00 00 ? * * *)"
  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
}
