data "aws_route53_zone" "root" {
  count = module.dns_context.enabled ? 1 : 0
  name  = var.root_domain

}


module "dns_context" {
  source  = "app.terraform.io/SevenPico/context/null"
  version = "1.0.2"
  context = module.context.self

  namespace           = var.common_name
  stage               = null
  name                = null
  attributes          = []
  delimiter           = "."
  regex_replace_chars = "/[^a-zA-Z0-9-.]/"
  label_order         = ["name", "namespace"]
  descriptor_formats = {
    FQDN = {
      labels = ["name", "namespace"]
      format = "%v.%v"
    }
  }
}

resource "aws_route53_zone" "public" {
  count = module.dns_context.enabled && module.vpc_context.enabled ? 1 : 0
  name  = module.dns_context.id
  tags  = module.dns_context.tags
}

resource "aws_route53_record" "ns" {
  count   = module.dns_context.enabled && module.vpc_context.enabled ? 1 : 0
  name    = module.dns_context.id
  type    = "NS"
  zone_id = join("", data.aws_route53_zone.root[*].id)
  records = length(aws_route53_zone.public) > 0 ? aws_route53_zone.public[0].name_servers : []
  ttl     = 300
}

resource "aws_route53_zone" "private" {
  count = module.dns_context.enabled && module.vpc_context.enabled ? 1 : 0
  name  = module.dns_context.id
  vpc {
    vpc_id = module.vpc.vpc_id
  }
  tags = module.dns_context.tags
}


