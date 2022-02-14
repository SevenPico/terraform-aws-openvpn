#------------------------------------------------------------------------------
# EC2 VPN Auto Scale Group
#------------------------------------------------------------------------------
locals {
  ec2_asg_userdata_mysql = <<-USERDATA
#!/bin/bash
echo "export LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN=1" >> /etc/profile
USERDATA
}

module "ec2_asg" {
  source  = "registry.terraform.io/cloudposse/ec2-autoscale-group/aws"
  version = "0.29.0"
  context = module.ec2_asg_meta.context

  instance_type    = var.openvpn_instance_type
  max_size         = var.openvpn_max_count
  min_size         = var.openvpn_min_count
  desired_capacity = var.openvpn_desired_count
  subnet_ids       = var.openvpn_vpc_public_subnet_ids

  associate_public_ip_address             = true
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
  iam_instance_profile_name            = aws_iam_instance_profile.ec2_asg_instance_profile.name
  image_id                             = var.openvpn_asg_ami_image_id
  instance_initiated_shutdown_behavior = "terminate"
  instance_market_options              = null
  instance_refresh                     = null
  key_name                             = null
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
  security_group_ids                   = var.openvpn_security_group_id == null ? [module.ec2_asg_sg.id] : var.openvpn_security_group_id
  service_linked_role_arn              = ""
  suspended_processes                  = []
  tag_specifications_resource_types = [
    "instance",
    "volume"
  ]
  target_group_arns         = []
  termination_policies      = ["Default"]
  user_data_base64          = var.rds_mysql_instance_address != null ? base64encode(local.ec2_asg_userdata_mysql) : null
  wait_for_capacity_timeout = "10m"
  wait_for_elb_capacity     = 0
  warm_pool                 = null
}

#------------------------------------------------------------------------------
# EC2 VPN Auto Scale Security Group
#------------------------------------------------------------------------------
module "ec2_asg_sg" {
  source  = "registry.terraform.io/cloudposse/security-group/aws"
  version = "0.4.2"
  context = module.ec2_asg_sg_meta.context
  enabled = var.openvpn_security_group_id == null

  vpc_id = var.openvpn_vpc_id
  rules = [
    {
      key                      = 1
      type                     = "ingress"
      from_port                = var.openvpn_server_admin_ui_https_port
      to_port                  = var.openvpn_server_admin_ui_https_port
      protocol                 = "tcp"
      cidr_blocks              = ["0.0.0.0/0"]
      ipv6_cidr_blocks         = []
      source_security_group_id = null
      self                     = null
      description              = "Allow access to VPN Admin UI from anywhere"
    },
    {
      key                      = 2
      type                     = "ingress"
      from_port                = var.openvpn_server_daemon_udp_port
      to_port                  = var.openvpn_server_daemon_udp_port
      protocol                 = "udp"
      cidr_blocks              = ["0.0.0.0/0"]
      ipv6_cidr_blocks         = []
      source_security_group_id = null
      self                     = null
      description              = "Allow access to VPN from anywhere"
    },
    {
      key                      = 3
      type                     = "ingress"
      from_port                = var.openvpn_server_daemon_tcp_port
      to_port                  = var.openvpn_server_daemon_tcp_port
      protocol                 = "tcp"
      cidr_blocks              = ["0.0.0.0/0"]
      ipv6_cidr_blocks         = []
      source_security_group_id = null
      self                     = null
      description              = "Allow access to VPN from anywhere"
    },
    {
      key                      = 4
      type                     = "egress"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      cidr_blocks              = ["0.0.0.0/0"]
      ipv6_cidr_blocks         = []
      source_security_group_id = null
      self                     = null
      description              = "Allow https egress on 443 everywhere"
    },
    {
      key                      = 5
      type                     = "egress"
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      cidr_blocks              = ["0.0.0.0/0"]
      ipv6_cidr_blocks         = []
      source_security_group_id = null
      self                     = null
      description              = "Allow https egress on 80 everywhere"
    }
  ]
}


##------------------------------------------------------------------------------
## EC2 VPN Auto Scale LifeCycle Hooks
##------------------------------------------------------------------------------
#resource "aws_autoscaling_lifecycle_hook" "ec2_openvpn_asg_instance_launching" {
#  count                   = module.ec2_openvpn_meta.enabled ? 1 : 0
#  autoscaling_group_name  = module.ec2_openvpn_asg.autoscaling_group_name
#  lifecycle_transition    = "autoscaling:EC2_INSTANCE_LAUNCHING"
#  name                    = "${module.ec2_openvpn_meta.id}-instance-launching"
#  default_result          = "ABANDON"
#  heartbeat_timeout       = 300
#  notification_target_arn = aws_sns_topic.ec2_openvpn_asg[0].arn
#  role_arn                = aws_iam_role.ec2_openvpn_asg_iam_lifecycle.arn
#}
#
#resource "aws_autoscaling_lifecycle_hook" "ec2_openvpn_asg_instance_terminating" {
#  count                   = module.ec2_openvpn_meta.enabled ? 1 : 0
#  autoscaling_group_name  = module.ec2_openvpn_asg.autoscaling_group_name
#  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
#  name                    = "${module.ec2_openvpn_meta.id}-instance-terminating"
#  default_result          = "ABANDON"
#  heartbeat_timeout       = 300
#  notification_target_arn = aws_sns_topic.ec2_openvpn_asg[0].arn
#  role_arn                = aws_iam_role.ec2_openvpn_asg_iam_lifecycle.arn
#}











