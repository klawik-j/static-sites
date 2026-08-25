terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  sites = {
    client-1 = "client-1"
    client-2 = "client-2"
  }

  mime_types = {
    ".css"  = "text/css"
    ".gif"  = "image/gif"
    ".html" = "text/html"
    ".ico"  = "image/x-icon"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".svg"  = "image/svg+xml"
    ".webp" = "image/webp"
  }

  site_files = flatten([
    for site_name, site_directory in local.sites : [
      for file_path in fileset("${path.module}/../sites/${site_directory}", "**") : {
        site_name = site_name
        file_path = file_path
        source    = "${path.module}/../sites/${site_directory}/${file_path}"
      }
      if !can(regex(":Zone\\.Identifier$", file_path))
    ]
  ])

  site_files_by_key = {
    for file in local.site_files : "${file.site_name}/${file.file_path}" => file
  }
}

resource "aws_s3_bucket" "site" {
  for_each = local.sites

  bucket = "${var.project_name}-${each.key}-${random_id.bucket_suffix.hex}"

  tags = {
    Project = var.project_name
    Site    = each.key
  }
}

resource "aws_s3_bucket_ownership_controls" "site" {
  for_each = aws_s3_bucket.site

  bucket = each.value.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  for_each = aws_s3_bucket.site

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "site" {
  for_each = aws_s3_bucket.site

  bucket = each.value.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

data "aws_iam_policy_document" "site_public_read" {
  for_each = aws_s3_bucket.site

  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${each.value.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "site_public_read" {
  for_each = aws_s3_bucket.site

  bucket = each.value.id
  policy = data.aws_iam_policy_document.site_public_read[each.key].json

  depends_on = [aws_s3_bucket_public_access_block.site]
}

resource "aws_s3_object" "site_file" {
  for_each = local.site_files_by_key

  bucket       = aws_s3_bucket.site[each.value.site_name].id
  key          = each.value.file_path
  source       = each.value.source
  etag         = filemd5(each.value.source)
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", each.value.file_path), "application/octet-stream")
}