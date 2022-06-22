output "security_group_id" {
  value = module.route_table_update.security_group_id
}

output "lambda_function_arn" {
  value = module.route_table_update.lambda_function_arn
}

output "lambda_function_source_code_size" {
  value = module.route_table_update.lambda_function_source_code_size
}

output "iam_role_arn" {
  value = module.route_table_update.iam_role_arn
}

output "iam_role_name" {
  value = module.route_table_update.iam_role_name
}

output "autoscaling_sns_topic_arn" {
  value = module.openvpn.autoscale_sns_topic_arn
}

output "autoscaling_sns_role_arn" {
  value = module.openvpn.sns_role_arn
}

output "autoscaling_sns_lifecycle_role_arn" {
  value = module.openvpn.lifecycle_role_arn
}
