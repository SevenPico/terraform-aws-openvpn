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
  value = var.create_openvpn_secret
}


