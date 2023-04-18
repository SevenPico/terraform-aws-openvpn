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
## ---------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Composite Installer Script
#------------------------------------------------------------------------------
module "composite_installer_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["composite", "installer"]
}

resource "aws_ssm_document" "composite_installer" {
  count           = module.composite_installer_context.enabled ? 1 : 0
  name            = module.composite_installer_context.id
  document_format = "YAML"
  document_type   = "Command"
  tags            = module.composite_installer_context.tags
  content = templatefile("${path.module}/templates/ssm-composite-initializer.tftpl", {
    ec2_initialization = try(aws_ssm_document.ec2_initialization[0].name, "")
    ec2_upgrade        = try(aws_ssm_document.ec2_upgrade[0].name, "")
    install_document   = try(!var.enable_efs ? aws_ssm_document.install_default[0].name  : aws_ssm_document.install_with_efs[0].name, "")
    configure_service  = try(aws_ssm_document.configure_service[0].name, "")
    configure_routing  = try(var.enable_nat ? aws_ssm_document.configure_nat_routing[0].name : aws_ssm_document.configure_reverse_routing[0].name, "")
    configure_ssl      = var.enable_custom_ssl ? try(aws_ssm_document.configure_ssl[0].name, "") : ""
    configure_license  = var.enable_licensing ? try(aws_ssm_document.configure_license[0].name, "") : ""
  })
}

resource "aws_ssm_association" "composite_installer" {
  count               = module.composite_installer_context.enabled ? 1 : 0
  association_name    = module.composite_installer_context.id
  name                = one(aws_ssm_document.composite_installer[*].name)
  schedule_expression = var.ec2_initialization_schedule_expression
  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
  dynamic "output_location" {
    for_each = var.openvpn_ssm_association_output_bucket_name != null ? [1] : []
    content {
      s3_bucket_name = var.openvpn_ssm_association_output_bucket_name
      s3_key_prefix  = one(aws_ssm_document.composite_installer[*].name)
    }
  }
}


#------------------------------------------------------------------------------
# EC2 Initialization
#------------------------------------------------------------------------------
module "ec2_initialization_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["ec2", "initialization"]
}

resource "aws_ssm_document" "ec2_initialization" {
  count           = module.ec2_initialization_context.enabled ? 1 : 0
  name            = module.ec2_initialization_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_initialization_context.tags
  content = templatefile("${path.module}/templates/ssm-ec2-initialization.tftpl", {
    hostname  = var.openvpn_hostname
    time_zone = var.openvpn_time_zone
    region    = try(data.aws_region.current[0].name, "")
  })
}


#------------------------------------------------------------------------------
# Upgrade EC2 OS
#------------------------------------------------------------------------------
module "ec2_upgrade_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["ec2", "upgrade"]
}

resource "aws_ssm_document" "ec2_upgrade" {
  count           = module.ec2_upgrade_context.enabled ? 1 : 0
  name            = module.ec2_upgrade_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags    = module.ec2_upgrade_context.tags
  content = templatefile("${path.module}/templates/ssm-ec2-upgrade.tftpl", {})

}

resource "aws_ssm_association" "ec2_upgrade" {
  count               = module.context.enabled ? 1 : 0
  association_name    = module.ec2_upgrade_context.id
  name                = one(aws_ssm_document.ec2_upgrade[*].name)
  schedule_expression = var.ec2_upgrade_schedule_expression
  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
  apply_only_at_cron_interval = true
}


#------------------------------------------------------------------------------
# Install with Defaults
#------------------------------------------------------------------------------
module "install_with_defaults_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled && !var.enable_efs
  attributes = ["install", "with", "defaults"]
}

resource "aws_ssm_document" "install_default" {
  count           = module.install_with_defaults_context.enabled ? 1 : 0
  name            = module.install_with_defaults_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.install_with_defaults_context.tags
  content = templatefile("${path.module}/templates/ssm-install-default.tftpl", {
    openvpnas_version = var.openvpn_version
  })
}


#------------------------------------------------------------------------------
# Install with EFS
#------------------------------------------------------------------------------
module "install_with_efs_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled && var.enable_efs
  attributes = ["install", "with", "efs"]
}

resource "aws_ssm_document" "install_with_efs" {
  count           = module.install_with_efs_context.enabled && var.enable_efs ? 1 : 0
  name            = module.install_with_efs_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.install_with_efs_context.tags

  content = templatefile("${path.module}/templates/ssm-install-with-efs.tftpl", {
    openvpnas_version         = var.openvpn_version
    efs_mount_target_dns_name = module.efs.mount_target_dns_names[0]
    s3_backup_bucket          = module.backups_bucket.bucket_id
    s3_backup_key             = "backups/openvpn_backup_pre_install.tar.gz"
  })
}


#------------------------------------------------------------------------------
# Configure Openvpn
#------------------------------------------------------------------------------
module "configure_openvpn_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled && var.enable_nat
  attributes = ["configuration"]
}

resource "aws_ssm_document" "configure_service" {
  count           = module.configure_openvpn_context.enabled ? 1 : 0
  name            = module.configure_openvpn_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.configure_openvpn_context.tags
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
# Configure NAT Routing
#------------------------------------------------------------------------------
module "configure_nat_routing_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled && var.enable_nat
  attributes = ["nat", "routing"]
}

resource "aws_ssm_document" "configure_nat_routing" {
  count           = module.configure_nat_routing_context.enabled ? 1 : 0
  name            = module.configure_nat_routing_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.configure_nat_routing_context.tags
  content = templatefile("${path.module}/templates/ssm-configure-nat-routing.tftpl", {
    #    client_dhcp_network          = var.openvpn_client_dhcp_network,
    #    client_dhcp_network_mask     = var.openvpn_client_dhcp_network_mask,
    openvpn_client_cidr_blocks = join(" ", var.openvpn_client_cidr_blocks),
    vpc_cidr_blocks            = join(" ", var.vpc_cidr_blocks)
  })
}


#------------------------------------------------------------------------------
# Configure Reverse Routing
#------------------------------------------------------------------------------
module "configure_reverse_routing_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled && !var.enable_nat
  attributes = ["reverse", "routing"]
}

resource "aws_ssm_document" "configure_reverse_routing" {
  count           = module.configure_reverse_routing_context.enabled ? 1 : 0
  name            = module.configure_reverse_routing_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.configure_reverse_routing_context.tags
  content = templatefile("${path.module}/templates/ssm-configure-reverse-routing.tftpl", {
    #    client_dhcp_network          = var.openvpn_client_dhcp_network,
    #    client_dhcp_network_mask     = var.openvpn_client_dhcp_network_mask,
    openvpn_client_cidr_blocks = join(" ", var.openvpn_client_cidr_blocks),
    vpc_cidr_blocks            = join(" ", var.vpc_cidr_blocks)
  })
}

#------------------------------------------------------------------------------
# Configure SSL
#------------------------------------------------------------------------------
module "configure_ssl_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled && var.enable_custom_ssl
  attributes = ["ssl", "policy"]
}

resource "aws_ssm_document" "configure_ssl" {
  count           = module.configure_ssl_context.enabled ? 1 : 0
  name            = module.configure_ssl_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.configure_ssl_context.tags
  content = templatefile("${path.module}/templates/ssm-configure-ssl.tftpl", {
    secret_arn                      = var.ssl_secret_arn,
    region                          = try(data.aws_region.current[0].name, ""),
    certificate_keyname             = var.ssl_secret_certificate_keyname,
    certificate_bundle_keyname      = var.ssl_secret_certificate_bundle_keyname,
    certificate_private_key_keyname = var.ssl_secret_certificate_private_key_keyname
  })
}

resource "aws_ssm_association" "configure_ssl" {
  count               = module.configure_ssl_context.enabled ? 1 : 0
  association_name    = module.configure_ssl_context.id
  name                = one(aws_ssm_document.configure_ssl[*].name)
  schedule_expression = "cron(0 00 00 ? * * *)"
  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
}


#------------------------------------------------------------------------------
# License Configuration
#------------------------------------------------------------------------------
module "configure_license_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled && var.enable_licensing
  attributes = ["license"]
}

resource "aws_ssm_document" "configure_license" {
  count           = module.configure_license_context.enabled ? 1 : 0
  name            = module.configure_license_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.configure_license_context.tags
  content = templatefile("${path.module}/templates/ssm-configure-license.tftpl", {
    secret_arn = var.openvpn_secret_arn
    keyname    = "OPENVPN_LICENSE"
    region     = try(data.aws_region.current[0].name, "")
  })
}

resource "aws_ssm_association" "configure_license" {
  count               = module.configure_license_context.enabled ? 1 : 0
  association_name    = module.configure_license_context.id
  name                = one(aws_ssm_document.configure_license[*].name)
  schedule_expression = "cron(0 00 00 ? * * *)"
  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
}


#------------------------------------------------------------------------------
# VPN Backup
#------------------------------------------------------------------------------
module "vpn_backup_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = var.enable_openvpn_backups && module.context.enabled
  attributes = ["backup"]
}

resource "aws_ssm_document" "vpn_backup" {
  count           = module.vpn_backup_context.enabled ? 1 : 0
  name            = module.vpn_backup_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.vpn_backup_context.tags
  content = templatefile("${path.module}/templates/ssm-vpn-backup.tftpl", {
    region        = try(data.aws_region.current[0].name, "")
    s3_bucket     = module.backups_bucket.bucket_id
    s3_backup_key = "backups/openvpn_backup.tar.gz"
  })
}

resource "aws_ssm_association" "vpn_backup" {
  count                       = module.vpn_backup_context.enabled ? 1 : 0
  association_name            = module.vpn_backup_context.id
  name                        = one(aws_ssm_document.vpn_backup[*].name)
  schedule_expression         = var.openvpn_backup_schedule_expression
  apply_only_at_cron_interval = true
  compliance_severity         = "HIGH"
  parameters = {
    S3BUCKET    = module.backups_bucket.bucket_id
    S3BACKUPKEY = "backups/openvpn_backup_scheduled.tar.gz"
    BACKUPVERSIONID = ""
  }

  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
  dynamic "output_location" {
    for_each = var.openvpn_ssm_association_output_bucket_name != null ? [1] : []
    content {
      s3_bucket_name = var.openvpn_ssm_association_output_bucket_name
      s3_key_prefix  = one(aws_ssm_document.vpn_backup[*].name)
    }
  }
}


#------------------------------------------------------------------------------
# VPN Restore
#------------------------------------------------------------------------------
module "vpn_restore_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled && var.enable_openvpn_backups
  attributes = ["restore"]
}

resource "aws_ssm_document" "vpn_restore" {
  count           = module.vpn_restore_context.enabled ? 1 : 0
  name            = module.vpn_restore_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.vpn_restore_context.tags
  content = templatefile("${path.module}/templates/ssm-vpn-restore.tftpl", {
    region            = one(data.aws_region.current[*].name)
    s3_bucket         = module.backups_bucket.bucket_id
    s3_backup_key     = "backups/openvpn_backup.tar.gz"
    backup_version_id = ""
  })
}
