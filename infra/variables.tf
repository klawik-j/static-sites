variable "aws_region" {
  description = "AWS region where the site buckets are created."
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