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
  EOT

  type = map(object({
    domain_names    = optional(list(string), [])
    route53_zone_id = optional(string)
  }))

  default = {
    client-1 = {
      domain_names  = ["lewhanna.com", "www.lewhanna.com"]
      route53_zone_id = "Z07911732CKCCC0OA87PL"
    }
    client-2 = {
      domain_names  = ["nasiona-zietarscy.pl", "www.nasiona-zietarscy.pl"]
      route53_zone_id = "Z05544002629RK849CHOL"
    }
  }

  validation {
    condition     = alltrue([for site in var.sites : site.route53_zone_id != null if length(site.domain_names) > 0])
    error_message = "Every site with domain_names must also set route53_zone_id."
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
