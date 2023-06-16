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
##  ./efs.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

module "efs" {
  source     = "cloudposse/efs/aws"
  version    = "0.32.7"
  context    = module.context.legacy
  enabled    = var.enable_efs && module.context.enabled
  attributes = ["efs"]

  access_points = {
    "config" = {
      posix_user = {
        gid = "1000"
        uid = "1000"
      }
      creation_info = {
        gid         = "1000"
        uid         = "1000"
        permissions = "0777"
      }
    }
  }

  additional_security_group_rules      = []
  allowed_cidr_blocks                  = []
  allowed_security_group_ids           = [module.ec2_autoscale_group_sg.id]
  associated_security_group_ids        = []
  availability_zone_name               = null
  create_security_group                = var.enable_efs && module.context.enabled //cloudposse module has a bug
  dns_name                             = ""
  efs_backup_policy_enabled            = false
  encrypted                            = true
  kms_key_id                           = null
  mount_target_ip_address              = null
  performance_mode                     = "generalPurpose"
  provisioned_throughput_in_mibps      = 0
  region                               = local.region
  security_group_create_before_destroy = true
  security_group_create_timeout        = "10m"
  security_group_delete_timeout        = "15m"
  security_group_description           = "EFS Security Group"
  security_group_name                  = []
  security_groups                      = []
  subnets                              = var.subnet_ids
  throughput_mode                      = "bursting"
  transition_to_ia                     = ["AFTER_30_DAYS"]
  transition_to_primary_storage_class  = []
  vpc_id                               = var.vpc_id
  zone_id                              = []
}
