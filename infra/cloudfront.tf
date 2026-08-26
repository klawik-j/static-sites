data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_origin_access_control" "site" {
  for_each = var.sites

  name                              = "${var.project_name}-${each.key}"
  description                       = "Signs CloudFront requests to the ${each.key} S3 origin."
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_response_headers_policy" "site" {
  name    = "${var.project_name}-security-headers"
  comment = "Baseline security headers for the static sites."

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    xss_protection {
      protection = true
      mode_block = true
      override   = true
    }
  }
}

resource "aws_cloudfront_distribution" "site" {
  for_each = var.sites

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} ${each.key}"
  default_root_object = "index.html"
  price_class         = var.cloudfront_price_class
  aliases             = each.value.domain_names

  origin {
    origin_id                = "s3-${each.key}"
    domain_name              = aws_s3_bucket.site[each.key].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.site[each.key].id
  }

  default_cache_behavior {
    target_origin_id           = "s3-${each.key}"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.site.id
  }

  # The origin is private, so a missing key returns 403 rather than 404. Both are
  # mapped back to a real 404 status so crawlers are not served soft 404s.
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/${var.error_document}"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/${var.error_document}"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = length(each.value.domain_names) == 0
    acm_certificate_arn            = length(each.value.domain_names) > 0 ? aws_acm_certificate_validation.site[each.key].certificate_arn : null
    ssl_support_method             = length(each.value.domain_names) > 0 ? "sni-only" : null
    minimum_protocol_version       = length(each.value.domain_names) > 0 ? "TLSv1.2_2021" : null
  }

  tags = {
    Site = each.key
  }
}
