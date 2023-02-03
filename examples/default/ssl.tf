# ------------------------------------------------------------------------------
# SSL Certificate Meta
# ------------------------------------------------------------------------------
module "ssl_certificate_context" {
  source     = "app.terraform.io/SevenPico/context/null"
  version    = "1.1.0"
  context    = module.context.self
  attributes = ["ssl"]
}


# ------------------------------------------------------------------------------
# SSL Certificate
# ------------------------------------------------------------------------------
module "ssl_certificate" {
  source  = "app.terraform.io/SevenPico/ssl-certificate/aws"
  version = "7.2.0"
  context = module.ssl_certificate_context.self

  additional_dns_names              = []
  additional_secrets                = {}
  create_mode                       = "LetsEncrypt"
  create_secret_update_sns          = false
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
