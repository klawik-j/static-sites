output "deploy_role_arn" {
  description = "Set this as the AWS_DEPLOY_ROLE_ARN repository variable in GitHub."
  value       = aws_iam_role.deploy.arn
}

output "plan_role_arn" {
  description = "Set this as the AWS_PLAN_ROLE_ARN repository variable in GitHub."
  value       = aws_iam_role.plan.arn
}

output "state_bucket" {
  description = "Set this as the TF_STATE_BUCKET repository variable in GitHub."
  value       = aws_s3_bucket.state.id
}

output "github_repository_variables" {
  description = "Every repository variable the deployment workflows expect."
  value = {
    AWS_DEPLOY_ROLE_ARN = aws_iam_role.deploy.arn
    AWS_PLAN_ROLE_ARN   = aws_iam_role.plan.arn
    AWS_REGION          = var.aws_region
    TF_STATE_BUCKET     = aws_s3_bucket.state.id
  }
}
