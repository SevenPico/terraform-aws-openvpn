module "ssl_certificate_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.this.context
  name    = "ssl"
  enabled = var.ssl_certificate_enabled
}

module "ssl_certificate" {
  //source  = "app.terraform.io/SevenPico/ssl-certificate/aws"
  source = "../../../terraform-aws-ssl-certificate"
#  version = "0.0.1"
  context = module.ssl_certificate_meta.context

  ssl_certificate_common_name        = var.common_name
  ssl_certificate_create_self_signed = true
}
