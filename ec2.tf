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
##  ./ec2.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

#------------------------------------------------------------------------------
# EC2 VPN Auto Scale Group Locals
#------------------------------------------------------------------------------
locals {
  cloudflare_cidrs = [
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "108.162.192.0/18",
    "131.0.72.0/22",
    "141.101.64.0/18",
    "162.158.0.0/15",
    "172.64.0.0/13",
    "173.245.48.0/20",
    "188.114.96.0/20",
    "190.93.240.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17"
  ]
}


#------------------------------------------------------------------------------
# EC2 Cloudwatch Log Group
#------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ec2_autoscale_group" {
  count             = module.context.enabled && var.enable_ec2_cloudwatch_logs ? 1 : 0
  name              = "/aws/ec2/${module.context.id}"
  retention_in_days = var.cloudwatch_logs_expiration_days
}

#resource "aws_cloudwatch_log_group" "ec2_logs_group" { #FIXME creating log group for second time deployment fails saying log group exist.
#  count             = module.context.enabled && var.enable_ec2_cloudwatch_logs ? 1 : 0
#  name              = "/aws/ec2/${module.context.id}"
#  retention_in_days = var.cloudwatch_logs_expiration_days
#}


#------------------------------------------------------------------------------
# EC2 VPN Auto Scale Group
#------------------------------------------------------------------------------
module "ec2_autoscale_group" {
  source  = "registry.terraform.io/SevenPicoForks/ec2-autoscale-group/aws"
  version = "2.0.0"
  context = module.context.self

  instance_type    = var.ec2_autoscale_instance_type
  max_size         = var.ec2_autoscale_max_count
  min_size         = var.ec2_autoscale_min_count
  desired_capacity = var.ec2_autoscale_desired_count
  subnet_ids       = var.subnet_ids

  associate_public_ip_address             = var.ec2_associate_public_ip_address
  autoscaling_policies_enabled            = false
  block_device_mappings                   = []
  capacity_rebalance                      = false
  cpu_utilization_high_evaluation_periods = 2
  cpu_utilization_high_period_seconds     = 300
  cpu_utilization_high_statistic          = "Average"
  cpu_utilization_high_threshold_percent  = 90
  cpu_utilization_low_evaluation_periods  = 2
  cpu_utilization_low_period_seconds      = 300
  cpu_utilization_low_statistic           = "Average"
  cpu_utilization_low_threshold_percent   = 10
  credit_specification                    = null
  custom_alarms                           = {}
  default_alarms_enabled                  = true
  default_cooldown                        = 300
  disable_api_termination                 = false
  ebs_optimized                           = false
  elastic_gpu_specifications              = null
  enable_monitoring                       = true
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]
  force_delete                         = false
  health_check_grace_period            = 300
  health_check_type                    = "EC2"
  iam_instance_profile_name            = join("", aws_iam_instance_profile.ec2_autoscale_group_instance_profile.*.name)
  image_id                             = var.ec2_ami_id
  instance_initiated_shutdown_behavior = "terminate"
  instance_market_options              = null
  instance_refresh                     = null
  key_name                             = ""
  launch_template_version              = "$Latest"
  load_balancers                       = []
  max_instance_lifetime                = null
  metadata_http_endpoint_enabled       = true
  metadata_http_put_response_hop_limit = 2
  metadata_http_tokens_required        = true
  metrics_granularity                  = "1Minute"
  min_elb_capacity                     = 0
  mixed_instances_policy               = null
  placement                            = null
  placement_group                      = ""
  protect_from_scale_in                = false
  scale_down_adjustment_type           = "ChangeInCapacity"
  scale_down_cooldown_seconds          = 300
  scale_down_policy_type               = "SimpleScaling"
  scale_down_scaling_adjustment        = -1
  scale_up_adjustment_type             = "ChangeInCapacity"
  scale_up_cooldown_seconds            = 300
  scale_up_policy_type                 = "SimpleScaling"
  scale_up_scaling_adjustment          = 1
  security_group_ids                   = concat([module.ec2_autoscale_group_sg.id], var.ec2_additional_security_group_ids)
  service_linked_role_arn              = ""
  suspended_processes                  = []
  tag_specifications_resource_types = [
    "instance",
    "volume"
  ]
  target_group_arns         = var.create_nlb ? compact(aws_lb_target_group.nlb.*.arn) : []
  termination_policies      = ["Default"]
  user_data_base64          = base64encode("")
  wait_for_capacity_timeout = "10m"
  wait_for_elb_capacity     = 0
  warm_pool                 = null
}


#------------------------------------------------------------------------------
# EC2 VPN Auto Scale Security Group
#------------------------------------------------------------------------------
module "ec2_autoscale_group_sg" {
  source  = "registry.terraform.io/SevenPicoForks/security-group/aws"
  version = "3.0.0"
  context = module.context.self

  allow_all_egress              = var.ec2_security_group_allow_all_egress
  create_before_destroy         = true
  inline_rules_enabled          = false
  preserve_security_group_id    = true
  revoke_rules_on_delete        = false
  rule_matrix                   = []
  rules                         = var.ec2_security_group_rules
  rules_map                     = {}
  security_group_create_timeout = "10m"
  security_group_delete_timeout = "15m"
  security_group_description    = "Allows access to and from ${module.context.id}"
  security_group_name           = []
  target_security_group_id      = []
  vpc_id                        = var.vpc_id
}

# FIXME We need to add conditionally if egress is false.
#   {
#      key                      = 2
#      type                     = "egress"
#      from_port                = 443
#      to_port                  = 443
#      protocol                 = "tcp"
#      cidr_blocks              = local.cloudflare_cidrs
#      ipv6_cidr_blocks         = []
#      source_security_group_id = null
#      self                     = null
#      description              = "Allow https egress to Cloudflare."
#    }

resource "aws_security_group_rule" "ui_port" {
  count             = module.context.enabled && var.openvpn_ui_https_port != null ? 1 : 0
  from_port         = var.openvpn_ui_https_port
  protocol          = "tcp"
  security_group_id = module.ec2_autoscale_group_sg.id
  to_port           = var.openvpn_ui_https_port
  type              = "ingress"
  cidr_blocks       = var.openvpn_ui_ingress_blocks
  description       = "Allow access to OpenVPN Web UI."
}

resource "aws_security_group_rule" "daemon_tcp_port" {
  count             = module.context.enabled && var.openvpn_daemon_tcp_port != null ? 1 : 0
  from_port         = var.openvpn_daemon_tcp_port
  protocol          = "tcp"
  security_group_id = module.ec2_autoscale_group_sg.id
  to_port           = var.openvpn_daemon_tcp_port
  type              = "ingress"
  cidr_blocks       = var.openvpn_daemon_ingress_blocks
  description       = "Allow access to OpenVPN TCP Daemon."
}

resource "aws_security_group_rule" "daemon_udp" {
  count             = module.context.enabled && var.openvpn_daemon_udp_port != null ? 1 : 0
  from_port         = var.openvpn_daemon_udp_port
  protocol          = "udp"
  security_group_id = module.ec2_autoscale_group_sg.id
  to_port           = var.openvpn_daemon_udp_port
  type              = "ingress"
  cidr_blocks       = var.openvpn_daemon_ingress_blocks
  description       = "Allow access to OpenVPN UDP Daemon."
}
