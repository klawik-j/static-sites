locals {
  sites_with_domains = { for name, site in var.sites : name => site if length(site.domain_names) > 0 }
}

resource "aws_acm_certificate" "site" {
  provider = aws.us_east_1
  for_each = local.sites_with_domains

  domain_name               = each.value.domain_names[0]
  subject_alternative_names = slice(each.value.domain_names, 1, length(each.value.domain_names))
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  certificate_validation_records = merge([
    for site_name, certificate in aws_acm_certificate.site : {
      for option in certificate.domain_validation_options :
      "${site_name}/${option.domain_name}" => {
        zone_id = var.sites[site_name].route53_zone_id
        name    = option.resource_record_name
        type    = option.resource_record_type
        record  = option.resource_record_value
      }
    }
  ]...)
}

resource "aws_route53_record" "certificate_validation" {
  for_each = local.certificate_validation_records

  zone_id         = each.value.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "site" {
  provider = aws.us_east_1
  for_each = local.sites_with_domains

  certificate_arn = aws_acm_certificate.site[each.key].arn

  validation_record_fqdns = [
    for key, record in aws_route53_record.certificate_validation : record.fqdn
    if startswith(key, "${each.key}/")
  ]
}

locals {
  site_aliases = merge([
    for site_name, site in local.sites_with_domains : {
      for domain in site.domain_names :
      "${site_name}/${domain}" => {
        site_name = site_name
        domain    = domain
        zone_id   = site.route53_zone_id
      }
    }
  ]...)

  alias_record_types = ["A", "AAAA"]

  site_alias_records = merge([
    for key, alias in local.site_aliases : {
      for record_type in local.alias_record_types :
      "${key}/${record_type}" => merge(alias, { record_type = record_type })
    }
  ]...)
}

resource "aws_route53_record" "site" {
  for_each = local.site_alias_records

  zone_id = each.value.zone_id
  name    = each.value.domain
  type    = each.value.record_type

  alias {
    name                   = aws_cloudfront_distribution.site[each.value.site_name].domain_name
    zone_id                = aws_cloudfront_distribution.site[each.value.site_name].hosted_zone_id
    evaluate_target_health = false
  }
}
