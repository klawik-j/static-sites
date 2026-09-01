resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  mime_types = {
    ".css"         = "text/css"
    ".gif"         = "image/gif"
    ".html"        = "text/html"
    ".ico"         = "image/x-icon"
    ".jpg"         = "image/jpeg"
    ".jpeg"        = "image/jpeg"
    ".js"          = "application/javascript"
    ".json"        = "application/json"
    ".map"         = "application/json"
    ".mp4"         = "video/mp4"
    ".pdf"         = "application/pdf"
    ".png"         = "image/png"
    ".svg"         = "image/svg+xml"
    ".txt"         = "text/plain"
    ".webmanifest" = "application/manifest+json"
    ".webp"        = "image/webp"
    ".woff"        = "font/woff"
    ".woff2"       = "font/woff2"
    ".xml"         = "application/xml"
  }

  # HTML is revalidated on every request so a deploy is visible immediately.
  # robots.txt and sitemap.xml get a short TTL so crawl directives are not stale for a day.
  # Assets are cached at the edge and flushed by the invalidation after apply.
  cache_control = {
    ".html" = "public, max-age=0, must-revalidate"
    ".txt"  = "public, max-age=3600"
    ".xml"  = "public, max-age=3600"
  }

  site_files = flatten([
    for site_name in keys(var.sites) : [
      for file_path in fileset("${path.module}/../sites/${site_name}", "**") : {
        site_name = site_name
        file_path = file_path
        source    = "${path.module}/../sites/${site_name}/${file_path}"
      }
      if !can(regex(":Zone\\.Identifier$", file_path))
    ]
  ])

  site_files_by_key = {
    for file in local.site_files : "${file.site_name}/${file.file_path}" => file
  }
}

resource "aws_s3_bucket" "site" {
  for_each = var.sites

  bucket = "${var.project_name}-${each.key}-${random_id.bucket_suffix.hex}"

  tags = {
    Site = each.key
  }
}

resource "aws_s3_bucket_ownership_controls" "site" {
  for_each = aws_s3_bucket.site

  bucket = each.value.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# CloudFront reads the origin with a signed request, so nothing here is public.
resource "aws_s3_bucket_public_access_block" "site" {
  for_each = aws_s3_bucket.site

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  for_each = aws_s3_bucket.site

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }

    bucket_key_enabled = true
  }
}

data "aws_iam_policy_document" "site_origin" {
  for_each = aws_s3_bucket.site

  statement {
    sid    = "AllowCloudFrontOriginAccess"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${each.value.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site[each.key].arn]
    }
  }

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      each.value.arn,
      "${each.value.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "site_origin" {
  for_each = aws_s3_bucket.site

  bucket = each.value.id
  policy = data.aws_iam_policy_document.site_origin[each.key].json

  depends_on = [aws_s3_bucket_public_access_block.site]
}

resource "aws_s3_object" "site_file" {
  for_each = local.site_files_by_key

  bucket        = aws_s3_bucket.site[each.value.site_name].id
  key           = each.value.file_path
  source        = each.value.source
  etag          = filemd5(each.value.source)
  content_type  = lookup(local.mime_types, regex("\\.[^.]+$", each.value.file_path), "application/octet-stream")
  cache_control = lookup(local.cache_control, regex("\\.[^.]+$", each.value.file_path), "public, max-age=86400")
}
