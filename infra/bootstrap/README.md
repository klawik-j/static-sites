# Bootstrap stack

Creates the resources the main stack and the GitHub Actions workflows depend on
before they can run:

- the S3 bucket holding the Terraform remote state, with versioning, encryption,
  public access blocking, and a TLS-only bucket policy
- the GitHub Actions OIDC identity provider
- `static-sites-gha-deploy`, assumable only by pushes to `master`, scoped to the
  S3 origins, CloudFront distributions, ACM certificates, and Route 53 records
  this project manages
- `static-sites-gha-plan`, assumable only by pull requests, read-only apart from
  the state lock

This stack is applied by hand from a workstation and keeps its state locally.
It is the only place that needs administrator credentials, and it changes rarely.

## Apply

```bash
terraform -chdir=infra/bootstrap init
terraform -chdir=infra/bootstrap apply
```

If the account already has a `token.actions.githubusercontent.com` provider,
pass `-var=create_oidc_provider=false`.

If the state bucket already exists from the previous manual setup, import it
before applying so Terraform adopts it instead of failing:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
terraform -chdir=infra/bootstrap import \
  aws_s3_bucket.state "static-sites-terraform-state-${ACCOUNT_ID}"
```

## Wire up GitHub

Copy the outputs into **Settings → Secrets and variables → Actions → Variables**:

```bash
terraform -chdir=infra/bootstrap output github_repository_variables
```

| Repository variable   | Source output     |
| --------------------- | ----------------- |
| `AWS_DEPLOY_ROLE_ARN` | `deploy_role_arn` |
| `AWS_PLAN_ROLE_ARN`   | `plan_role_arn`   |
| `AWS_REGION`          | `eu-central-1`    |
| `TF_STATE_BUCKET`     | `state_bucket`    |

These are variables, not secrets. A role ARN is not a credential, and nothing in
the workflows is sensitive once the static access keys are gone.
