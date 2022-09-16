# ------------------------------------------------------------------------------
# SSL Certificate Meta
# ------------------------------------------------------------------------------
module "ssl_certificate_context" {
  source     = "app.terraform.io/SevenPico/context/null"
  version    = "1.0.2"
  context    = module.context.self
  attributes = ["ssl"]
}


# ------------------------------------------------------------------------------
# SSL Certificate
# ------------------------------------------------------------------------------
module "ssl_certificate" {
  source  = "../../../terraform-aws-ssl-certificate"
  context = module.ssl_certificate_context.self

  additional_secrets                = { EXAMPLE = "example value" }
  create_mode                       = "LetsEncrypt"
  create_secret_update_sns          = false
#  common_name                       = var.common_name
  import_filepath_certificate       = null
  import_filepath_certificate_chain = null
  import_filepath_private_key       = null
  import_secret_arn                 = null
  keyname_certificate               = "CERTIFICATE"
  keyname_certificate_chain         = "CERTIFICATE_CHAIN"
  keyname_private_key               = "CERTIFICATE_PRIVATE_KEY"
  secret_allowed_accounts           = []
  secret_update_sns_pub_principals  = {}
  secret_update_sns_sub_principals  = {}
  zone_id                           = module.ssl_certificate_context.enabled ? aws_route53_zone.public[0].id : null
}
