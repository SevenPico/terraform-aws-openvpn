module "ssl_certificate_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.this.context
  name    = "ssl"
  enabled = var.ssl_certificate_enabled && module.this.enabled
}

module "ssl_certificate" {
  source = "../../../terraform-aws-ssl-certificate"
  context = module.ssl_certificate_meta.context

  ssl_certificate_common_name        = var.common_name
  ssl_certificate_create_letsencrypt = true
}
