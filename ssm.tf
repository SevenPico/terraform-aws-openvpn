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
