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
##  ./modules/mysql-config-script/_variables.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

variable "ec2_role_name" { type = string }

variable "rds_mysql_instance_address" { type = string }
variable "rds_secret_arn" { type = string }
variable "rds_security_group_id" { type = string }
variable "rds_secret_kms_key_arn" { type = string }
variable "rds_secret_admin_password_keyname" { default = "ADMIN_PASSWORD" }
variable "rds_secret_admin_username_keyname" { default = "ADMIN_USERNAME" }
variable "rds_secret_port_keyname" { default = "PORT" }
variable "ssm_documents_schedule_expression" { default = "cron(0 00 00 ? * * *)" }

