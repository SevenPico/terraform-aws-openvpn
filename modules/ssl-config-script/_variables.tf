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
##  ./modules/ssl-config-script/_variables.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

variable "bucket_id" { type = string }
variable "script_name" { type = string }
variable "ec2_role_name" { type = string }

variable "ssl_secret_arn" { type = string }
variable "ssl_secret_kms_key_arn" { type = string }
variable "ssl_secret_certificate_bundle_keyname" { default = "CERTIFICATE_CHAIN" }
variable "ssl_secret_certificate_keyname" { default = "CERTIFICATE" }
variable "ssl_secret_certificate_private_key_keyname" { default = "CERTIFICATE_PRIVATE_KEY" }