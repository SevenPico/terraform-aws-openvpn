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
##  ./sns.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

module "ec2_autoscale_group_sns_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["ec2", "sns"]
  enabled    = var.create_ec2_autoscale_sns_topic && module.context.enabled
}


#------------------------------------------------------------------------------
# EC2 Auto Scaling Group SNS Topic
#------------------------------------------------------------------------------
resource "aws_sns_topic" "ec2_autoscale_group" {
  count                               = module.ec2_autoscale_group_sns_context.enabled ? 1 : 0
  name                                = module.ec2_autoscale_group_sns_context.id
  lambda_failure_feedback_role_arn    = one(aws_iam_role.ec2_autoscale_group_sns[*].arn)
  lambda_success_feedback_role_arn    = one(aws_iam_role.ec2_autoscale_group_sns[*].arn)
  lambda_success_feedback_sample_rate = 100
  tags                                = module.ec2_autoscale_group_sns_context.tags
}

resource "aws_cloudwatch_log_group" "sns" {
  count             = module.ec2_autoscale_group_sns_context.enabled ? 1 : 0
  name              = "sns/${data.aws_region.current[0].name}/${data.aws_caller_identity.current[0].account_id}/${module.ec2_autoscale_group_sns_context.id}"
  retention_in_days = var.cloudwatch_logs_expiration_days
  tags              = module.ec2_autoscale_group_sns_context.tags
}

resource "aws_autoscaling_lifecycle_hook" "ec2_autoscale_group_instance_launching" {
  count                   = module.ec2_autoscale_group_sns_context.enabled ? 1 : 0
  autoscaling_group_name  = module.ec2_autoscale_group.autoscaling_group_name
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_LAUNCHING"
  name                    = "${module.context.id}-instance-launching"
  default_result          = var.ec2_autoscale_sns_topic_default_result
  heartbeat_timeout       = var.ec2_autoscale_sns_topic_heartbeat_timeout
  notification_target_arn = one(aws_sns_topic.ec2_autoscale_group[*].arn)
  role_arn                = one(aws_iam_role.ec2_autoscale_group_lifecycle_role[*].arn)
}

resource "aws_autoscaling_lifecycle_hook" "ec2_autoscale_group_instance_terminating" {
  count                   = module.ec2_autoscale_group_sns_context.enabled ? 1 : 0
  autoscaling_group_name  = module.ec2_autoscale_group.autoscaling_group_name
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  name                    = "${module.context.id}-instance-terminating"
  default_result          = var.ec2_autoscale_sns_topic_default_result
  heartbeat_timeout       = var.ec2_autoscale_sns_topic_heartbeat_timeout
  notification_target_arn = one(aws_sns_topic.ec2_autoscale_group[*].arn)
  role_arn                = one(aws_iam_role.ec2_autoscale_group_lifecycle_role[*].arn)
}
