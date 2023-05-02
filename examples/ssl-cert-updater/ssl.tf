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
##  ./examples/default/ssl.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# SSL Certificate Meta
# ------------------------------------------------------------------------------
module "ssl_certificate_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["ssl"]
}


# ------------------------------------------------------------------------------
# SSL Certificate
# ------------------------------------------------------------------------------
module "ssl_certificate" {
  source  = "registry.terraform.io/SevenPico/ssl-certificate/aws"
  version = "8.0.7"
  context = module.ssl_certificate_context.self

  additional_dns_names              = []
  additional_secrets                = {}
  create_mode                       = "LetsEncrypt"
  create_secret_update_sns          = true
  import_filepath_certificate       = null
  import_filepath_certificate_chain = null
  import_filepath_private_key       = null
  import_secret_arn                 = null
  keyname_certificate               = "CERTIFICATE"
  keyname_certificate_chain         = "CERTIFICATE_CHAIN"
  keyname_private_key               = "CERTIFICATE_PRIVATE_KEY"
  kms_key_deletion_window_in_days   = 10
  kms_key_enable_key_rotation       = false
  secret_read_principals            = {}
  secret_update_sns_pub_principals  = {}
  secret_update_sns_sub_principals  = {}
  zone_id                           = null
}
