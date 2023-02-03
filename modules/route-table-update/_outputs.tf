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
##  ./modules/route-table-update/_outputs.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

output "security_group_id" {
  value       = join("", aws_security_group.default.*.id)
  description = "Security Group ID of the Lambda Function"
}

output "lambda_function_arn" {
  value       = join("", aws_lambda_function.this.*.arn)
  description = "ARN of the Lambda Function"
}

output "lambda_function_source_code_size" {
  value       = join("", aws_lambda_function.this.*.source_code_size)
  description = "The size in bytes of the function .zip file"
}

output "iam_role_arn" {
  value = join("", aws_iam_role.this.*.arn)
}

output "iam_role_name" {
  value = join("", aws_iam_role.this.*.name)
}

