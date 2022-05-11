output "autoscaling_group_arn" {
  value = module.ec2_autoscale_group.autoscaling_group_arn
}

output "autoscaling_group_id" {
  value = module.ec2_autoscale_group.autoscaling_group_id
}

output "autoscaling_group_name" {
  value = module.ec2_autoscale_group.autoscaling_group_name
}

output "security_group_id" {
  value = module.ec2_autoscale_group_sg.id
}

output "security_group_name" {
  value = module.ec2_autoscale_group_sg.name
}

output "secret_kms_key_arn" {
  value = module.ec2_autoscale_group_secrets_kms_key.key_arn
}

output "secret_version_arn" {
  value = join("", aws_secretsmanager_secret_version.ec2_autoscale_group.*.arn)
}

output "autoscaling_sns_topic_arn" {
  value = join("", aws_sns_topic.ec2_autoscale_group.*.arn)
}

output "autoscaling_role_arn" {
  value = module.ec2_autoscale_group_role.arn
}

output "autoscaling_role_name" {
  value = module.ec2_autoscale_group_role.name
}

output "autoscaling_lifecycle_role_arn" {
  value = join("", aws_iam_role.ec2_autoscale_group_lifecycle_role.*.arn)
}

output "autoscaling_sns_role_arn" {
  value = join("", aws_iam_role.ec2_autoscale_group_sns.*.arn)
}

output "ssm_script_bucket_arn" {
  value = module.ec2_autoscale_group_scripts_bucket.bucket_arn
}

output "ssm_script_bucket_id" {
  value = module.ec2_autoscale_group_scripts_bucket.bucket_id
}

