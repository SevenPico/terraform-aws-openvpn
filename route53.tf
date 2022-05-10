#data "aws_route53_zone" "public" {
#  count =   module.this.enabled ? 1 : 0
#  zone_id = var.public_hosted_zone_id
#}

#module "dns_meta" {
#  source  = "registry.terraform.io/cloudposse/label/null"
#  version = "0.25.0"
#  context = module.this.context
#
#  namespace           = join("", data.aws_route53_zone.public.*.name)
#  stage               = null
#  name                = null
#  attributes          = []
#  delimiter           = "."
#  regex_replace_chars = "/[^a-zA-Z0-9-.]/"
#  label_order         = ["name", "namespace"]
#}





