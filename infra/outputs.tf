output "bucket_names" {
  description = "Names of the S3 buckets containing each site."
  value       = { for site_name, bucket in aws_s3_bucket.site : site_name => bucket.id }
}

output "website_endpoints" {
  description = "HTTP endpoints for the S3 static website hosting configurations."
  value       = { for site_name, website in aws_s3_bucket_website_configuration.site : site_name => website.website_endpoint }
}