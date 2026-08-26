output "bucket_names" {
  description = "Private S3 origin bucket backing each site."
  value       = { for site_name, bucket in aws_s3_bucket.site : site_name => bucket.id }
}

output "distribution_ids" {
  description = "CloudFront distribution IDs, consumed by the deployment workflow to invalidate the cache."
  value       = { for site_name, distribution in aws_cloudfront_distribution.site : site_name => distribution.id }
}

output "site_urls" {
  description = "HTTPS URL serving each site."
  value = {
    for site_name, site in var.sites :
    site_name => length(site.domain_names) > 0 ? "https://${site.domain_names[0]}" : "https://${aws_cloudfront_distribution.site[site_name].domain_name}"
  }
}
