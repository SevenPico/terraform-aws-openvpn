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
##  ./modules/route-table-update/_variables.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------


variable "cloudwatch_log_retention_days" {default = 30}

variable "vpc_id" {
  type        = string
  description = "The VPC ID for the Lambda function"
}

variable "cidr_block_to_route" {
  type = string
  description = "The CIDR Block to route to Auto Scaled Instances."
}

variable "lambda_log_level" {
  type = string
  description = "Log level verbosity.  Values can be DEBUG, INFO, WARN, ERROR."
  default = "INFO"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the Lambda function"
}

variable "sns_source_topic_arn" {
  type = string
  description = "The SNS Topic that will invoke this lambda to perform updates."
}

variable "autoscale_group_arn" {
  type = string
  description = "The Autoscale Group that this lambda will manage route table updates for."
}


variable "results_sns_arn" {
  type        = string
  default     = ""
  description = "SNS ARN to publish alerts to."
}

variable "lambda_runtime" {
  type        = string
  default     = "python3.8"
  description = "The runtime environment for the lambda."
}

variable "lambda_timeout" {
  type        = number
  default     = 300
  description = "Timeout for Lambda function in seconds"
}

variable "lambda_environment_variables_map" {
  type = map(string)
  default = {}
  description = "Environment variables to pass into the container"
}

variable "artifact_url" {
  type        = string
  description = "URL template for the remote artifact"
  default     = "https://artifacts.cloudposse.com/$$${module_name}/$$${git_ref}/$$${filename}"
}

variable "artifact_git_ref" {
  type        = string
  description = "Git ref of the lambda artifact to use. Use latest version if null."
  default     = ""
}


variable "events_bucket_id" {
  type        = string
  description = "The S3 Bucket where events will be saved."
  default     = ""
}
