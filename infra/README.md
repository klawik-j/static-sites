# Static site infrastructure

This Terraform configuration creates one S3 static website bucket for each site under `../sites` and uploads its files. The GitHub Actions deployment runs it automatically after every push to `master`, including merged pull requests.

## Prerequisites

- Terraform 1.5 or newer
- AWS credentials configured for the target account
- Permissions to create S3 buckets, bucket policies, and objects
- A GitHub repository with `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and optionally `AWS_SESSION_TOKEN` secrets

## One-time remote state setup

The main stack uses an S3 backend so GitHub Actions can share state between runs. Create the state bucket once before enabling the workflow. The commands below configure versioning, encryption, and public-access blocking without adding a separate bootstrap stack to the repository:

```sh
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
STATE_BUCKET="static-sites-terraform-state-${ACCOUNT_ID}"
AWS_REGION="eu-central-1"

aws s3api create-bucket \
	--bucket "$STATE_BUCKET" \
	--region "$AWS_REGION" \
	--create-bucket-configuration LocationConstraint="$AWS_REGION"
aws s3api put-bucket-versioning \
	--bucket "$STATE_BUCKET" \
	--versioning-configuration Status=Enabled
aws s3api put-bucket-encryption \
	--bucket "$STATE_BUCKET" \
	--server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-public-access-block \
	--bucket "$STATE_BUCKET" \
	--public-access-block-configuration \
	BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

If the state bucket already exists, skip the `create-bucket` command and run the remaining configuration commands.

Migrate the existing local state to that bucket. Run this from the repository root while the current `infra/terraform.tfstate` still exists locally:

```sh
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
terraform -chdir=infra init -migrate-state -force-copy \
	-backend-config="bucket=static-sites-terraform-state-${ACCOUNT_ID}" \
	-backend-config="key=static-sites/terraform.tfstate" \
	-backend-config="region=eu-central-1" \
	-backend-config="encrypt=true"
terraform -chdir=infra plan
```

The migration plan should show no replacement of the existing site buckets. Do not delete the local state until this has been confirmed.

## Local deploy

From the repository root:

```sh
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
terraform -chdir=infra init \
	-backend-config="bucket=static-sites-terraform-state-${ACCOUNT_ID}" \
	-backend-config="key=static-sites/terraform.tfstate" \
	-backend-config="region=eu-central-1" \
	-backend-config="encrypt=true"
terraform -chdir=infra plan
terraform -chdir=infra apply
```

The bucket names and HTTP website endpoints are printed as Terraform outputs. The buckets are intentionally public because native S3 website endpoints require public object reads. Use CloudFront and private buckets for HTTPS, custom domains, and production traffic.

## GitHub Actions

The workflow in `.github/workflows/deploy.yml` runs on every push to `master`. It checks out that exact commit, initializes the remote backend, validates Terraform, creates a plan, and applies it. A concurrency group queues deployments so two runs cannot update the same state at once.

The AWS IAM user or role behind the GitHub secrets needs access to the state bucket and to manage the two site buckets, including bucket policies, website configuration, public access blocks, ownership controls, and objects. Restrict the credentials to this repository where possible and rotate access keys regularly.

To remove the infrastructure, including uploaded site files:

```sh
terraform destroy
```