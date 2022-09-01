module "ec2_autoscale_group_sns_context" {
  source     = "app.terraform.io/SevenPico/context/null"
  version    = "1.0.2"
  context    = module.ec2_autoscale_group_context.self
  attributes = ["sns"]
  enabled    = var.create_ec2_autoscale_sns_topic && module.ec2_autoscale_group_context.enabled
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
  name              = "sns/${one(data.aws_region.current[*].name)}/${one(data.aws_caller_identity.current[*].account_id)}/${module.ec2_autoscale_group_sns_context.id}"
  retention_in_days = var.cloudwatch_logs_expiration_days
  tags              = module.ec2_autoscale_group_sns_context.tags
}

resource "aws_autoscaling_lifecycle_hook" "ec2_autoscale_group_instance_launching" {
  count                   = module.ec2_autoscale_group_sns_context.enabled ? 1 : 0
  autoscaling_group_name  = module.ec2_autoscale_group.autoscaling_group_name
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_LAUNCHING"
  name                    = "${module.ec2_autoscale_group_context.id}-instance-launching"
  default_result          = var.ec2_autoscale_sns_topic_default_result
  heartbeat_timeout       = var.ec2_autoscale_sns_topic_heartbeat_timeout
  notification_target_arn = one(aws_sns_topic.ec2_autoscale_group[*].arn)
  role_arn                = one(aws_iam_role.ec2_autoscale_group_lifecycle_role[*].arn)
}

resource "aws_autoscaling_lifecycle_hook" "ec2_autoscale_group_instance_terminating" {
  count                   = module.ec2_autoscale_group_sns_context.enabled ? 1 : 0
  autoscaling_group_name  = module.ec2_autoscale_group.autoscaling_group_name
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  name                    = "${module.ec2_autoscale_group_context.id}-instance-terminating"
  default_result          = var.ec2_autoscale_sns_topic_default_result
  heartbeat_timeout       = var.ec2_autoscale_sns_topic_heartbeat_timeout
  notification_target_arn = one(aws_sns_topic.ec2_autoscale_group[*].arn)
  role_arn                = one(aws_iam_role.ec2_autoscale_group_lifecycle_role[*].arn)
}
