module "ssl_certificate_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.this.context
  name    = "ssl"
}

module "ssl_certificate" {
  source  = "../../../terraform-aws-ssl-certificate"
  context = module.ssl_certificate_meta.context

  common_name        = var.common_name
  create_letsencrypt = true
}
