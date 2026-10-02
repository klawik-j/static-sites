variable "aws_region" {
  description = "AWS region where the origin buckets are created."
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Lowercase prefix used for bucket names and tags."
  type        = string
  default     = "static-sites"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name may contain only lowercase letters, numbers, and hyphens."
  }
}

variable "sites" {
  description = <<-EOT
    Sites to publish. Each key must match a directory under ../sites.
    Leave domain_names empty to serve the site on its CloudFront domain only.
    Supplying domain_names also requires route53_zone_id, which is used for
    certificate validation and the alias records.
    redirects maps an exact request path to the path it should 301 to on the
    canonical host. It is applied by the canonical-host function, so it needs
    domain_names as well.
  EOT

  type = map(object({
    domain_names    = optional(list(string), [])
    route53_zone_id = optional(string)
    redirects       = optional(map(string), {})
  }))

  default = {
    client-1 = {
      domain_names    = ["lewhanna.com", "www.lewhanna.com"]
      route53_zone_id = "Z07911732CKCCC0OA87PL"

      # Pages of the previous multi-page site. The ones with Search history are
      # /kontakt, /kontakt.html, /kalendarium and /kalendarium.html.
      redirects = {
        "/hanna-lewandowska"                      = "/"
        "/indexENG.html"                          = "/"
        "/kontakt"                                = "/#contact"
        "/kontakt.html"                           = "/#contact"
        "/kontakt.php"                            = "/#contact"
        "/kontaktENG.html"                        = "/#contact"
        "/kalendarium"                            = "/#calendar"
        "/kalendarium.html"                       = "/#calendar"
        "/baza-danych-odpadow"                    = "/#services"
        "/baza-danych-odpadow.html"               = "/#services"
        "/ewidencja-odpadow"                      = "/#services"
        "/ewidencja-odpadow.html"                 = "/#services"
        "/pomiar-zanieczyszczenia-powietrza"      = "/#services"
        "/pomiar-zanieczyszczenia-powietrza.html" = "/#services"
        "/pozwolenie-zintegrowane"                = "/#services"
        "/pozwolenie-zintegrowane.html"           = "/#services"
      }
    }
    client-2 = {
      domain_names    = ["nasiona-zietarscy.pl", "www.nasiona-zietarscy.pl"]
      route53_zone_id = "Z05544002629RK849CHOL"
    }
  }

  validation {
    condition     = alltrue([for site in var.sites : site.route53_zone_id != null if length(site.domain_names) > 0])
    error_message = "Every site with domain_names must also set route53_zone_id."
  }

  validation {
    condition     = alltrue([for site in var.sites : length(site.domain_names) > 0 if length(site.redirects) > 0])
    error_message = "redirects are served by the canonical-host function, which only exists for sites with domain_names."
  }

  validation {
    condition = alltrue(flatten([
      for site in var.sites : [for from, to in site.redirects : startswith(from, "/") && startswith(to, "/")]
    ]))
    error_message = "Every redirect source and target must be a path starting with /."
  }
}

variable "error_document" {
  description = "Object served for 403 and 404 responses, relative to the site root."
  type        = string
  default     = "index.html"
}

variable "cloudfront_price_class" {
  description = "CloudFront edge locations to use. PriceClass_100 covers North America and Europe."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "cloudfront_price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}
