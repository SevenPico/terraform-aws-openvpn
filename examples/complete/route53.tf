data "aws_route53_zone" "root" {
  count = module.dns_meta.enabled ? 1 : 0
  name  = var.root_domain
}


module "dns_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.this.context

  namespace           = var.common_name
  stage               = null
  name                = null
  attributes          = []
  delimiter           = "."
  regex_replace_chars = "/[^a-zA-Z0-9-.]/"
  label_order         = ["name", "namespace"]
}

resource "aws_route53_zone" "public" {
  count = module.dns_meta.enabled && module.vpc_meta.enabled ? 1 : 0
  name  = module.dns_meta.id
  tags  = module.dns_meta.tags
}

resource "aws_route53_record" "ns" {
  count   = module.dns_meta.enabled && module.vpc_meta.enabled ? 1 : 0
  name    = module.dns_meta.id
  type    = "NS"
  zone_id = join("", data.aws_route53_zone.root[*].id)
  records = length(aws_route53_zone.public) > 0 ? aws_route53_zone.public[0].name_servers : []
  ttl     = 300
}

resource "aws_route53_zone" "private" {
  count = module.dns_meta.enabled && module.vpc_meta.enabled ? 1 : 0
  name  = module.dns_meta.id
  vpc {
    vpc_id = module.vpc.vpc_id
  }
  tags = module.dns_meta.tags
}


