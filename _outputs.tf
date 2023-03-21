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
##  ./_outputs.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

output "autoscale_group_arn" {
  value = module.ec2_autoscale_group.autoscaling_group_arn
}

output "autoscale_group_id" {
  value = module.ec2_autoscale_group.autoscaling_group_id
}

output "autoscale_group_name" {
  value = module.ec2_autoscale_group.autoscaling_group_name
}

output "security_group_id" {
  value = module.ec2_autoscale_group_sg.id
}

output "security_group_name" {
  value = module.ec2_autoscale_group_sg.name
}

output "autoscale_sns_topic_arn" {
  value = join("", aws_sns_topic.ec2_autoscale_group.*.arn)
}

output "role_arn" {
  value = module.ec2_autoscale_group_role.arn
}

output "role_name" {
  value = module.ec2_autoscale_group_role.name
}

output "lifecycle_role_arn" {
  value = join("", aws_iam_role.ec2_autoscale_group_lifecycle_role.*.arn)
}

output "sns_role_arn" {
  value = join("", aws_iam_role.ec2_autoscale_group_sns.*.arn)
}

output "ssm_script_bucket_arn" {
  value = module.ec2_autoscale_group_scripts_bucket.bucket_arn
}

output "ssm_script_bucket_id" {
  value = module.ec2_autoscale_group_scripts_bucket.bucket_id
}

output "nlb_dns_name" {
  value = one(module.nlb[*].nlb_dns_name)
}

output "nlb_zone_id" {
  value = one(module.nlb[*].nlb_zone_id)
}

output "secret_arn" {
  value = local.secret_arn
}

output "secret_kms_key_arn" {
  value = local.secret_kms_key_arn
}

output "instance_name" {
  value = module.context.id
}

output "ui_https_port" {
  value = var.openvpn_ui_https_port
}
