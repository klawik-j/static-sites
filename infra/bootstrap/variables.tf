variable "aws_region" {
  description = "AWS region for the remote state bucket."
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Lowercase prefix used for role, policy, and bucket names."
  type        = string
  default     = "static-sites"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name may contain only lowercase letters, numbers, and hyphens."
  }
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the deploy and plan roles, as owner/name."
  type        = string
  default     = "klawik-j/static-sites"

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "github_repository must be in the form owner/name."
  }
}

variable "default_branch" {
  description = "Branch whose pushes are allowed to assume the deploy role."
  type        = string
  default     = "master"
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set to false if the account already has one."
  type        = bool
  default     = true
}

variable "state_bucket_name" {
  description = "Override for the remote state bucket name. Defaults to <project_name>-terraform-state-<account_id>."
  type        = string
  default     = null
}
